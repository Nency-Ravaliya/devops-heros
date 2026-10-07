# ==============================================================================
# Main Infrastructure Definition - Session 19 Cloud & Terraform Architecture
# Suggested Architecture: VPC -> Subnet -> Security Group -> EC2 -> S3
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Virtual Private Cloud (VPC)
# ------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
    Role = "Networking Core"
  }
}

# ------------------------------------------------------------------------------
# 2. Internet Gateway (IGW) - Grants Internet Connectivity
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
    Role = "VPC Internet Edge"
  }
}

# ------------------------------------------------------------------------------
# 3. Public Web Subnet
# ------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Tier = "Public Web Tier"
  }
}

# ------------------------------------------------------------------------------
# 4. Route Table & Internet Gateway Association
# ------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------------------
# 5. Security Group (Stateful Firewall for EC2 Web Server)
# ------------------------------------------------------------------------------
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security Group allowing inbound HTTP/HTTPS/SSH traffic"
  vpc_id      = aws_vpc.main.id

  # Inbound HTTP rule
  ingress {
    description = "Allow Inbound HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTPS rule
  ingress {
    description = "Allow Inbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound SSH rule (Restricted in production, demonstrated for administrative access)
  ingress {
    description = "Allow Inbound SSH Administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule (allow all egress traffic)
  egress {
    description = "Allow all outbound IPv4 traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# ------------------------------------------------------------------------------
# 6. EC2 Compute Instance (Web Server)
# ------------------------------------------------------------------------------
resource "aws_instance" "web" {
  ami                         = "ami-053b0d53c279acc90" # Amazon Linux 2023 HVM
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  # Explicit dependency demonstration: Instance requires IGW for updates
  depends_on = [aws_internet_gateway.main]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>DevOps Heroes - Session 19 Cloud & Terraform Architecture</h1><p>Provisioned by Sahasra with Terraform</p>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "${var.project_name}-web-server"
    Role = "Compute Web Server"
  }
}

# ------------------------------------------------------------------------------
# 7. S3 Cloud Object Storage (Secure Bucket with Versioning & Encryption)
# ------------------------------------------------------------------------------
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "app_storage" {
  bucket        = "${var.project_name}-storage-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-s3-bucket"
    Tier = "Object Storage"
  }
}

resource "aws_s3_bucket_versioning" "app_storage_versioning" {
  bucket = aws_s3_bucket.app_storage.id

  versioning_configuration {
    status = var.enable_s3_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_storage_encryption" {
  bucket = aws_s3_bucket.app_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_storage_pab" {
  bucket = aws_s3_bucket.app_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
