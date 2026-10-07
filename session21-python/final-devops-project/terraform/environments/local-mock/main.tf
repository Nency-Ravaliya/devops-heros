# ---------------------------------------------------------------------------
# Local mock environment: the SAME module as the real root, but the AWS
# provider talks to Moto (motoserver/moto) on http://localhost:4577 with fake
# credentials. Nothing here touches a real AWS account or costs money.
#
#   docker run -d --name moto-aws -p 4577:5000 motoserver/moto:latest
#   terraform init && terraform apply
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  moto = var.moto_endpoint
}

provider "aws" {
  region     = var.aws_region
  access_key = "test" # fake - Moto accepts anything
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2  = local.moto
    eks  = local.moto
    ecr  = local.moto
    iam  = local.moto
    kms  = local.moto
    logs = local.moto
    sts  = local.moto
    s3   = local.moto
  }

  default_tags {
    tags = {
      Project     = "taskboard"
      Environment = "local-mock"
      ManagedBy   = "terraform"
    }
  }
}

module "taskboard" {
  source = "../../modules/taskboard-infra"

  name = "taskboard-mock"
  tags = { Environment = "local-mock" }

  vpc_cidr             = "10.20.0.0/16"
  azs                  = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnet_cidrs  = ["10.20.101.0/24", "10.20.102.0/24"]
  private_subnet_cidrs = ["10.20.1.0/24", "10.20.2.0/24"]

  enable_nat_gateway = var.enable_nat_gateway
  enable_flow_logs   = var.enable_flow_logs
  enable_eks         = var.enable_eks
  enable_node_group  = var.enable_node_group
}
