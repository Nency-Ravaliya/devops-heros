terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region for this lab"
  type        = string
  default     = "ap-south-1"
}

resource "aws_s3_bucket" "provider_demo" {
  bucket_prefix = "session18-provider-"

  tags = {
    Name = "Session 18 Provider Demo"
  }
}

output "bucket_id" {
  value = aws_s3_bucket.provider_demo.id
}
