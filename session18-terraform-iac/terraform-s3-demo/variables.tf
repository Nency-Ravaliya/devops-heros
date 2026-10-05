variable "aws_region" {
  type        = string
  description = "AWS region where the S3 bucket will be created."
  default     = "ap-south-1"
}
variable "bucket_prefix" {
  type        = string
  description = "Prefix Terraform uses when AWS generates the unique bucket name."
  default     = "anshal-session18-"

  validation {
    condition     = can(regex("^[a-z0-9-]+-$", var.bucket_prefix))
    error_message = "Use lowercase letters, numbers, and hyphens, ending with a hyphen."
  }
}
