variable "aws_region" {
  description = "AWS region to create the bucket in"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_prefix" {
  description = "Prefix for the bucket name (a random suffix keeps it globally unique)"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

variable "enable_versioning" {
  description = "Turn on S3 object versioning"
  type        = bool
  default     = true
}
