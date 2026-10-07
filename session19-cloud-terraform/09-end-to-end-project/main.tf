# ---------------------------------------------------------------------------
# Networking: VPC, public subnet, Internet Gateway, route table
# ---------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "${var.project_name}-vpc"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

# Implicit dependency: references aws_vpc.main.id, so Terraform creates the VPC first.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.project_name}-public-subnet"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.project_name}-igw"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name      = "${var.project_name}-public-rt"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# Security group: SSH (restricted by variable) + HTTP
# ---------------------------------------------------------------------------

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Allow SSH and HTTP for Session 19"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound IPv4"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project_name}-web-sg"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

# ---------------------------------------------------------------------------
# Compute: latest Amazon Linux 2023 AMI + EC2 running nginx
# ---------------------------------------------------------------------------

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    cat > /usr/share/nginx/html/index.html <<HTML
    <html>
      <body>
        <h1>Hello from Session 19 - deployed with Terraform</h1>
        <p>Served by host: $(hostname -f)</p>
      </body>
    </html>
    HTML
    systemctl enable --now nginx
  EOF

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  # Enforce IMDSv2 (session tokens) for the instance metadata service.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Explicit dependency: nothing in this block references the Internet Gateway,
  # so Terraform cannot infer the ordering on its own. user_data runs
  # `dnf install nginx` at first boot and needs outbound internet access,
  # so we force the IGW to exist before the instance is launched.
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name      = "${var.project_name}-web"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

# ---------------------------------------------------------------------------
# Storage: S3 bucket with a globally unique name
# ---------------------------------------------------------------------------

# S3 bucket names are global, so a random suffix avoids name collisions.
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "main" {
  bucket        = "${var.project_name}-tf-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true # lets `terraform destroy` delete a non-empty bucket (demo only)

  tags = {
    Name      = "${var.project_name}-tf-bucket"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "welcome" {
  bucket       = aws_s3_bucket.main.id
  key          = "welcome.txt"
  content      = "Welcome to Session 19! This object was uploaded by Terraform.\n"
  content_type = "text/plain"

  tags = {
    Name      = "${var.project_name}-welcome-object"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}
