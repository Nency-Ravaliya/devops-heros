variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 Bucket Name"
  type        = string
  default     = "devops-heros-terraform-s3-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
