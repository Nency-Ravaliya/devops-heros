variable "use_localstack" {
  description = "Target LocalStack (http://localhost:4566) instead of real AWS"
  type        = bool
  default     = true
}

variable "localstack_endpoint" {
  description = "LocalStack edge endpoint"
  type        = string
  default     = "http://localhost:4566"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Name prefix for all resources"
  type        = string
  default     = "stockpilot"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.40.0.0/16"
}

variable "azs" {
  description = "Availability zones used for subnets"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "create_ecr" {
  description = "Create an ECR repository (ECR is a LocalStack Pro feature, so off by default; images live in GHCR)"
  type        = bool
  default     = false
}
