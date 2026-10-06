variable "aws_region" {
  description = "AWS region for the lab bucket."
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name. Change this before apply."
  type        = string
}
