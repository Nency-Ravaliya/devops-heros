variable "aws_region" {
  description = "AWS region for the bucket."
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique on real AWS)."
  type        = string
}

variable "environment" {
  description = "Environment tag value."
  type        = string
  default     = "dev"
}

variable "localstack_endpoint" {
  description = "LocalStack edge endpoint used instead of real AWS."
  type        = string
  default     = "http://localhost:4566"
}
