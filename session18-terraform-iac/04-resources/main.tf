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
  bucket_prefix = "session18-resource-"

  tags = {
    Name        = "Session 18 Resource Demo"
    Environment = "dev"
  }
}
