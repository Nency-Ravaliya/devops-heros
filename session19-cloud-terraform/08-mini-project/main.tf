resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
<<<<<<< HEAD
    Name        = "session19-mini-vpc"
    Session     = "19"
    Owner       = "Durga Prasad"
    Enrollment  = "10012"
    ManagedBy   = "Terraform"
=======
    Name      = "session19-mini-vpc"
    Session   = "19"
    ManagedBy = "Terraform"
>>>>>>> upstream/main
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
<<<<<<< HEAD
    Name        = "session19-mini-public-subnet"
    Session     = "19"
    Owner       = "Durga Prasad"
    ManagedBy   = "Terraform"
=======
    Name      = "session19-mini-public-subnet"
    Session   = "19"
    ManagedBy = "Terraform"
>>>>>>> upstream/main
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
<<<<<<< HEAD
    Name        = "session19-mini-igw"
    Session     = "19"
    ManagedBy   = "Terraform"
=======
    Name      = "session19-mini-igw"
    Session   = "19"
    ManagedBy = "Terraform"
>>>>>>> upstream/main
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
<<<<<<< HEAD
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "session19-mini-public-rt"
    Session     = "19"
    ManagedBy   = "Terraform"
=======
    gateway_id  = aws_internet_gateway.main.id
  }

  tags = {
    Name      = "session19-mini-public-rt"
    Session   = "19"
    ManagedBy = "Terraform"
>>>>>>> upstream/main
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name        = "session19-mini-web-sg"
<<<<<<< HEAD
  description = "Allow HTTP, HTTPS, and SSH for Session 19"
=======
  description = "Allow HTTP and HTTPS for Session 19"
>>>>>>> upstream/main
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

<<<<<<< HEAD
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

=======
>>>>>>> upstream/main
  egress {
    description = "Allow outbound IPv4"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
<<<<<<< HEAD
    Name        = "session19-mini-web-sg"
    Session     = "19"
    ManagedBy   = "Terraform"
  }
}

# EC2 Web Server Instance
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              echo "<h1>Deployed via Terraform by Durga Prasad (10012)</h1>" > /var/www/html/index.html
              systemctl enable nginx
              systemctl start nginx
              EOF

  tags = {
    Name        = "session19-mini-web-server"
    Session     = "19"
    Owner       = "Durga Prasad"
    Enrollment  = "10012"
    ManagedBy   = "Terraform"
  }
}

# S3 Storage Bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "assets" {
  bucket = "devops-session19-assets-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "session19-assets-bucket"
    Session     = "19"
    Owner       = "Durga Prasad"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
=======
    Name      = "session19-mini-web-sg"
    Session   = "19"
    ManagedBy = "Terraform"
>>>>>>> upstream/main
  }
}
