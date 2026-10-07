# ---------------------------------------------------------------------------
# 1. Network: VPC -> public subnet -> Internet Gateway -> route table
# ---------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id # implicit dependency on the VPC
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true # instances launched here get a public IP

  tags = { Name = "${var.project_name}-public-subnet" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project_name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id # this route is what makes the subnet "public"
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# 2. Firewall: security group for the web server
# ---------------------------------------------------------------------------
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "HTTP/HTTPS from anywhere, SSH from the admin range"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from admin range only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    description = "all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-web-sg" }
}

# ---------------------------------------------------------------------------
# 3. Compute: AMI lookup + key pair + EC2 instance with user_data
# ---------------------------------------------------------------------------
# On real AWS: newest Amazon Linux 2023 arm64 image. Skipped when var.ami_id is given (LocalStack).
data "aws_ami" "al2023" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-arm64"]
  }
}

locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.al2023[0].id
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "web" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "aws_instance" "web" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = aws_key_pair.web.key_name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/scripts/user_data.sh")

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  # Explicit dependency: without the IGW route the instance would boot before it can reach the internet,
  # and user_data (dnf install nginx) would fail. Terraform cannot infer this from attributes.
  depends_on = [aws_route_table_association.public]

  tags = { Name = "${var.project_name}-web" }
}

# ---------------------------------------------------------------------------
# 4. Storage: private S3 bucket for the app's assets / logs
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "assets" {
  bucket        = "${var.project_name}-assets-${var.bucket_suffix}"
  force_destroy = true

  tags = { Name = "${var.project_name}-assets" }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration { status = "Enabled" }
}

# A file that records which instance the bucket belongs to: shows outputs of one resource feeding another.
resource "aws_s3_object" "instance_info" {
  bucket  = aws_s3_bucket.assets.id
  key     = "infra/instance.json"
  content = jsonencode({ instance_id = aws_instance.web.id, private_ip = aws_instance.web.private_ip, vpc_id = aws_vpc.main.id })

  content_type = "application/json"
}
