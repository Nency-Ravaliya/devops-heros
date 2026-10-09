variable "aws_region" {
  type        = string
  description = "AWS region where the S3 bucket will be created."
  default     = "ap-south-1"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique name of the S3 bucket."
}

variable "environment" {
  type        = string
  description = "Environment tag applied to the bucket."
  default     = "dev"
}

variable "aws_endpoint_url" {
  type        = string
  description = "Custom AWS endpoint for a local emulator such as Moto or LocalStack. Leave empty for real AWS."
  default     = ""
}
