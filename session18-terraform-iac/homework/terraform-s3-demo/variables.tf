variable "aws_region" {
  description = "AWS region for the bucket."
  type        = string
  default     = "ap-south-1"
}

variable "bucket_prefix" {
  description = "Prefix of the bucket name. A random suffix is appended because S3 bucket names are globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,40}$", var.bucket_prefix))
    error_message = "bucket_prefix must be 3-41 characters: lowercase letters, digits and hyphens."
  }
}

variable "environment" {
  description = "Environment name, used as a tag."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Who owns these resources (tag)."
  type        = string
}

variable "versioning_enabled" {
  description = "Keep previous versions of objects."
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Delete old object versions after this many days."
  type        = number
  default     = 30
}
