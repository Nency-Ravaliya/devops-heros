# ==============================================================================
# Variables Definition - Session 19 Cloud & Terraform Architecture
# ==============================================================================

variable "aws_region" {
  description = "The AWS Region where resources will be provisioned."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Base identifier name for resources."
  type        = string
  default     = "session19-cloud"
}

variable "environment" {
  description = "Deployment lifecycle environment name."
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the Virtual Private Cloud (VPC)."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the Public Web Subnet."
  type        = string
  default     = "10.20.1.0/24"
}

variable "instance_type" {
  description = "EC2 compute instance type."
  type        = string
  default     = "t3.micro"
}

variable "enable_s3_versioning" {
  description = "Enable object versioning on the S3 bucket."
  type        = bool
  default     = true
}
