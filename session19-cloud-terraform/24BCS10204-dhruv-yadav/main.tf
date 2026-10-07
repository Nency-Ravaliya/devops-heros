locals {
  name = var.project_name
  # First AZ of the region, e.g. ap-south-1a
  az = "${var.aws_region}a"
}

# ---------------------------------------------------------------------------
# NETWORK
# ---------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${local.name}-vpc" }
}

# Public subnet: instances get a public IP and its route table points to the IGW.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id # implicit dependency on the VPC
  cidr_block              = var.public_subnet_cidr
  availability_zone       = local.az
  map_public_ip_on_launch = true

  tags = { Name = "${local.name}-public-subnet", Tier = "public" }
}

# Private subnet: no public IPs, no route to the internet.
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = local.az

  tags = { Name = "${local.name}-private-subnet", Tier = "private" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${local.name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${local.name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private route table has only the implicit "local" route.
# (On real AWS you would add 0.0.0.0/0 -> NAT Gateway here for outbound-only access.)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${local.name}-private-rt" }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ---------------------------------------------------------------------------
# SECURITY GROUP
# ---------------------------------------------------------------------------
resource "aws_security_group" "web" {
  name        = "${local.name}-web-sg"
  description = "HTTP from anywhere, SSH only from ssh_allowed_cidr"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from trusted CIDR only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    description = "All outbound IPv4"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-web-sg" }
}

# ---------------------------------------------------------------------------
# COMPUTE
# ---------------------------------------------------------------------------
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id        # implicit dependency
  vpc_security_group_ids = [aws_security_group.web.id] # implicit dependency
  key_name               = var.key_name

  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    project = local.name
  })
  user_data_replace_on_change = true

  # Enforce IMDSv2 on real AWS. Skipped on LocalStack because its mocked EC2
  # does not return metadata_options, which would cause a permanent diff.
  dynamic "metadata_options" {
    for_each = var.use_localstack ? [] : [1]
    content {
      http_tokens = "required"
    }
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  # EXPLICIT dependency: nothing in this resource references the IGW or the
  # public route table, but user_data runs "dnf/apt install nginx" at first
  # boot, which needs a working route to the internet. Without depends_on,
  # Terraform could start the instance before the 0.0.0.0/0 -> IGW route exists.
  depends_on = [
    aws_internet_gateway.main,
    aws_route_table_association.public,
  ]

  tags = { Name = "${local.name}-web" }
}

# ---------------------------------------------------------------------------
# STORAGE
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "assets" {
  bucket        = "${local.name}-assets-24BCS10204"
  force_destroy = true

  tags = { Name = "${local.name}-assets" }
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
