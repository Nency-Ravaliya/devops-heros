# Terraform -> VPC -> Subnet -> Security Group -> EC2 -> S3 (plus the IAM role that lets the EC2
# instance read the bucket and the secret). Read top to bottom: each block uses the one above it.

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  az          = "${var.aws_region}${var.availability_zone_suffix}"
  bucket_name = "${var.bucket_prefix}-${var.bucket_suffix}"

  # merge() combines maps; keys on the right win. Used on every resource below.
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
    },
    var.extra_tags
  )

  # One entry per inbound rule. The security group rules below are created with for_each over
  # this map, so adding a port is a one-line change.
  ingress_rules = {
    ssh = {
      port        = 22
      cidr        = var.ssh_cidr
      description = "SSH from the admin CIDR only"
    }
    http = {
      port        = 80
      cidr        = "0.0.0.0/0"
      description = "HTTP from anywhere"
    }
  }
}

# ---- 1. Network: VPC, internet gateway, public subnet, route table -------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-vpc" })
}

# Implicit dependency: vpc_id references aws_vpc.main, so Terraform builds the VPC first.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-igw" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = local.az
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-public-subnet" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Send all non-local traffic to the internet gateway: this is what makes the subnet "public".
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-public-rt" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---- 2. Security group ---------------------------------------------------------------

resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Web server: SSH from the admin CIDR, HTTP from anywhere"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-web-sg" })
}

# for_each creates one rule resource per entry of local.ingress_rules (ssh and http).
resource "aws_vpc_security_group_ingress_rule" "web" {
  for_each = local.ingress_rules

  security_group_id = aws_security_group.web.id
  description       = each.value.description
  cidr_ipv4         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-allow-${each.key}" })
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-allow-all-out" })
}

# ---- 3. S3 bucket (versioned, encrypted, private) --------------------------------------

resource "aws_s3_bucket" "assets" {
  bucket        = local.bucket_name
  force_destroy = true # demo only: lets terraform destroy remove a bucket that still has objects

  tags = merge(local.common_tags, { Name = local.bucket_name })
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "welcome" {
  bucket       = aws_s3_bucket.assets.id
  key          = "welcome.txt"
  content      = "Uploaded by Terraform for ${local.name_prefix}\n"
  content_type = "text/plain"

  tags = local.common_tags
}

# ---- 4. Secret kept out of user_data and out of the .tf files --------------------------

# var.app_secret is marked sensitive, so plan/apply print (sensitive value) instead of it.
resource "aws_ssm_parameter" "app_secret" {
  name        = "/${var.project_name}/${var.environment}/app_secret"
  description = "Application secret supplied through TF_VAR_app_secret"
  type        = "SecureString"
  value       = var.app_secret

  tags = local.common_tags
}

# ---- 5. IAM role so the instance can read the bucket and the secret ---------------------

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "web" {
  name               = "${local.name_prefix}-web-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = local.common_tags
}

# Least privilege: read-only on this one bucket and this one parameter, nothing else.
data "aws_iam_policy_document" "web_access" {
  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.assets.arn]
  }

  statement {
    sid       = "ReadObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]
  }

  statement {
    sid       = "ReadSecret"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.app_secret.arn]
  }
}

resource "aws_iam_role_policy" "web_access" {
  name   = "read-bucket-and-secret"
  role   = aws_iam_role.web.id
  policy = data.aws_iam_policy_document.web_access.json
}

resource "aws_iam_instance_profile" "web" {
  name = "${local.name_prefix}-web-profile"
  role = aws_iam_role.web.name

  tags = local.common_tags
}

# ---- 6. EC2 web server -----------------------------------------------------------------

resource "aws_instance" "web" {
  count = var.instance_count # count.index is 0, 1, 2 ...

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id              # implicit: subnet first
  vpc_security_group_ids = [aws_security_group.web.id]       # implicit: security group first
  iam_instance_profile   = aws_iam_instance_profile.web.name # implicit: profile first
  key_name               = var.key_name

  # No associate_public_ip_address here: map_public_ip_on_launch on the subnet already gives
  # the instance a public IP. (Setting both makes the Moto emulator report a security group
  # diff that real AWS does not.)

  # Amazon Linux 2023: install and start nginx at first boot.
  user_data = <<-EOT
    #!/bin/bash
    dnf install -y nginx
    echo "<h1>${local.name_prefix}: server ${count.index + 1}</h1>" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOT

  user_data_replace_on_change = true

  # On real AWS also add: root_block_device { encrypted = true }. It is left out here because
  # the emulator cannot look up the root device of the fake AMI id.

  # IMDSv2 only: blocks the SSRF-style credential theft that IMDSv1 allows.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-web-${count.index + 1}" })

  # Explicit dependency. Nothing in this block references the internet gateway or the route
  # table association, but user_data needs internet access (dnf install) the moment the instance
  # boots. depends_on makes Terraform finish both before it launches the instance.
  depends_on = [
    aws_internet_gateway.main,
    aws_route_table_association.public,
  ]
}
