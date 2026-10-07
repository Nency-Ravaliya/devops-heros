terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Applied to every AWS resource created by this provider.
  default_tags {
    tags = {
      Project   = var.project_name
      Session   = "19"
      ManagedBy = "Terraform"
    }
  }
}
