variable "aws_region" {
  type        = string
  description = "AWS region where the S3 bucket will be created."
  default     = "ap-south-1"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique name of the S3 bucket."
  default     = "sahasra-devops-hero-session18-bucket"
}

variable "environment" {
  type        = string
  description = "Deployment environment name."
  default     = "dev"
}
