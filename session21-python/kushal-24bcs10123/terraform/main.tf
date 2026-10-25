data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
}

# ------------------------------------------------------------------ network
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${local.name}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name}-igw" }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name                                      = "${local.name}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                  = "1"
    "kubernetes.io/cluster/${local.name}-eks" = "shared"
  }
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
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------ security group
resource "aws_security_group" "web" {
  name        = "${local.name}-web-sg"
  description = "HTTP/HTTPS in from anywhere, everything out"
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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.name}-web-sg" }
}

# ------------------------------------------------------------------ storage
resource "aws_s3_bucket" "backups" {
  bucket        = var.backup_bucket_name
  force_destroy = true
  tags          = { Name = var.backup_bucket_name }
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "readme" {
  bucket  = aws_s3_bucket.backups.id
  key     = "README.txt"
  content = "StudyTrack ${var.environment} backups bucket, created by Terraform on ${timestamp()}\n"
  lifecycle {
    ignore_changes = [content]
  }
}

# ------------------------------------------------------------------ kubernetes (EKS)
module "eks" {
  source = "./modules/eks"
  count  = var.create_eks ? 1 : 0

  cluster_name       = "${local.name}-eks"
  cluster_version    = var.eks_cluster_version
  subnet_ids         = aws_subnet.public[*].id
  node_instance_type = var.eks_node_instance_type
  node_desired_size  = var.eks_node_desired_size

  depends_on = [aws_route_table_association.public]
}
