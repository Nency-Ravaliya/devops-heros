resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "session19-mini-vpc"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "session19-mini-public-subnet"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "session19-mini-igw"
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
    Name      = "session19-mini-public-rt"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name        = "session19-mini-web-sg"
  description = "Allow HTTP, HTTPS and SSH for Session 19"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

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

  egress {
    description = "Allow outbound IPv4"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "session19-mini-web-sg"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

# ── EC2 Instance ────────────────────────────────────────────────────────────────
resource "aws_instance" "web" {
  ami                         = var.ec2_ami
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Session 19 — Terraform EC2 Web Server</h1>" > /usr/share/nginx/html/index.html
  EOF

  tags = {
    Name      = "session19-mini-web-server"
    Session   = "19"
    ManagedBy = "Terraform"
  }

  depends_on = [aws_internet_gateway.main]
}

# ── S3 Bucket ───────────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "artifacts" {
  bucket        = var.s3_bucket_name
  force_destroy = true

  tags = {
    Name      = var.s3_bucket_name
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
