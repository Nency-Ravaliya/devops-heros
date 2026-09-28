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

resource "aws_s3_bucket" "architecture_demo" {
  bucket_prefix = "session18-architecture-"

  tags = {
    Name = "Session 18 Architecture Demo"
  }
}

output "bucket_arn" {
  value = aws_s3_bucket.architecture_demo.arn
}
