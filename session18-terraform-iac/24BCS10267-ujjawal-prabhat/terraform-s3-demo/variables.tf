variable "aws_region" {
  description = "AWS region to create the bucket in."
  type        = string
  default     = "ap-south-1"
}

variable "use_localstack" {
  description = "If true, point the AWS provider at LocalStack (AWS emulator) instead of real AWS."
  type        = bool
  default     = true
}

variable "localstack_endpoint" {
  description = "LocalStack edge endpoint (only used when use_localstack = true)."
  type        = string
  default     = "http://localhost:4566"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name (3-63 chars, lowercase, digits, dots, hyphens)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters of lowercase letters, digits, dots or hyphens."
  }
}

variable "environment" {
  description = "Environment tag value."
  type        = string
  default     = "dev"
}

variable "enable_versioning" {
  description = "Enable S3 object versioning."
  type        = bool
  default     = true
}
