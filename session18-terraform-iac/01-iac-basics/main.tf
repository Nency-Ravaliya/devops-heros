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
  region = "ap-south-1"
}

resource "aws_s3_bucket" "iac_demo" {
  bucket_prefix = "session18-iac-"

  tags = {
    Name        = "Session 18 IaC Demo"
    Environment = "dev"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.iac_demo.bucket
}
