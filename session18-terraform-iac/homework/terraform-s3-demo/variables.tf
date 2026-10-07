variable "aws_region" {
  type        = string
  description = "AWS region where the S3 bucket is created."
  default     = "us-east-2"
}

variable "bucket_prefix" {
  type        = string
  description = "Prefix for the bucket name; a random hex suffix is appended for global uniqueness."
  default     = "chhavi-24bcs10201-"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,40}$", var.bucket_prefix))
    error_message = "bucket_prefix must be 3-41 chars of lowercase letters, digits or hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Environment tag value."
  default     = "dev"
}

variable "enable_versioning" {
  type        = bool
  description = "Enable S3 object versioning."
  default     = true
}
