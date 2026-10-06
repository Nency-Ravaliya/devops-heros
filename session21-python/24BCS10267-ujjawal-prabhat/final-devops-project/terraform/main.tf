locals {
  name = "${var.project}-${var.environment}"
}

# ----------------------------------------------------------------- network --
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

# Public subnets: load balancers / ingress. Tagged the way EKS expects.
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name                     = "${local.name}-public-${var.azs[count.index]}"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private subnets: worker nodes + database.
resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.azs[count.index]
  tags = {
    Name                              = "${local.name}-private-${var.azs[count.index]}"
    "kubernetes.io/role/internal-elb" = "1"
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

# ---------------------------------------------------------- security groups --
resource "aws_security_group" "app" {
  name        = "${local.name}-app-sg"
  description = "StockPilot API nodes: HTTP(S) from the internet via LB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP (redirected to HTTPS by ingress)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.name}-app-sg" }
}

resource "aws_security_group" "db" {
  name        = "${local.name}-db-sg"
  description = "PostgreSQL reachable only from the app security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.name}-db-sg" }
}

# ---------------------------------------------- S3: artifacts and backups --
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${local.name}-artifacts-24bcs10267"
  force_destroy = true
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

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Real AWS only: LocalStack Community stores the rule, but the AWS provider's
# post-create consistency waiter never sees the expected response and times
# out after 3m (see docs/outputs/terraform-apply-attempt1-lifecycle-timeout.txt).
resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  count  = var.use_localstack ? 0 : 1
  bucket = aws_s3_bucket.artifacts.id
  rule {
    id     = "expire-db-backups"
    status = "Enabled"
    filter {
      prefix = "db-backups/"
    }
    expiration {
      days = 30
    }
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# ------------------------------------------ DynamoDB: terraform state lock --
resource "aws_dynamodb_table" "tf_locks" {
  name         = "${local.name}-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

# --------------------------------- ECR (optional: LocalStack Pro / real AWS) --
resource "aws_ecr_repository" "api" {
  count                = var.create_ecr ? 1 : 0
  name                 = "${var.project}-api"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ----------------------------------------------------------- EKS (not here) --
# On real AWS the Kubernetes cluster would be created here with the
# terraform-aws-modules/eks module in the private subnets above, e.g.
#
# module "eks" {
#   source          = "terraform-aws-modules/eks/aws"
#   cluster_name    = local.name
#   cluster_version = "1.33"
#   vpc_id          = aws_vpc.main.id
#   subnet_ids      = aws_subnet.private[*].id
#   eks_managed_node_groups = {
#     default = { instance_types = ["t3.medium"], min_size = 2, max_size = 4, desired_size = 2 }
#   }
# }
#
# EKS is not available in LocalStack Community, so in this project the local
# kind cluster "devops-heros" plays the role of the EKS cluster.
