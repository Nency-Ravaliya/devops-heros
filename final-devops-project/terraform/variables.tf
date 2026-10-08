variable "aws_region" {
  type        = string
  description = "Target AWS Region"
  default     = "ap-south-1"
}

variable "environment" {
  type        = string
  description = "Deployment Environment (prod/staging/dev)"
  default     = "production"
}

variable "cluster_name" {
  type        = string
  description = "Amazon EKS Cluster Name"
  default     = "devops-hero-prod-cluster"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}
