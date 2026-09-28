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

resource "aws_s3_bucket" "state_demo" {
  bucket_prefix = "session18-state-"

  tags = {
    Name = "Session 18 State Demo"
  }
}

output "bucket_id" {
  value = aws_s3_bucket.state_demo.id
}
