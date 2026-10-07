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

resource "aws_s3_bucket" "demo" {
  bucket_prefix = "session18-output-"

  tags = {
    Name = "Session 18 Output Demo"
  }
}

output "bucket_id" {
  description = "The S3 bucket ID"
  value       = aws_s3_bucket.demo.id
}

output "bucket_arn" {
  description = "The S3 bucket ARN"
  value       = aws_s3_bucket.demo.arn
}

output "bucket_region" {
  description = "The AWS region"
  value       = "ap-south-1"
}
