terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Pinned to v5: this project was run against LocalStack Community, which doesn't implement
      # the S3 Control ListTagsForResource API that provider v6 uses for bucket tags.
      # On real AWS, "~> 6.0" works as well.
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Tags added to every resource this configuration creates
  default_tags {
    tags = {
      Project   = "session18-terraform-s3-demo"
      ManagedBy = "Terraform"
      Owner     = var.owner
    }
  }
}
