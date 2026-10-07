variable "aws_region" {
  type        = string
  description = "AWS region where the S3 bucket will be created."
  default     = "ap-south-1"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique name of the S3 bucket (lowercase, 3-63 chars)."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket names must be 3-63 lowercase letters, digits, dots or hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Environment tag (dev / staging / prod)."
  default     = "dev"
}

variable "aws_endpoint_url" {
  type        = string
  description = "Set to http://localhost:4566 to run against LocalStack instead of real AWS. Leave null for AWS."
  default     = null
}
