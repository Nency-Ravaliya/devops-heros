variable "aws_region" {
  description = "AWS region for every resource"
  type        = string
  default     = "ap-south-1"
}

variable "aws_endpoint_url" {
  description = "Leave empty for real AWS. Set to http://localhost:4566 to target LocalStack."
  type        = string
  default     = ""
}

variable "project" {
  description = "Name prefix for every resource"
  type        = string
  default     = "studytrack"
}

variable "environment" {
  description = "Environment name used in tags and the bucket name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "One public subnet per AZ (EKS needs at least two)"
  type        = list(string)
  default     = ["10.42.1.0/24", "10.42.2.0/24"]
}

variable "backup_bucket_name" {
  description = "Globally unique S3 bucket name for database backups and frontend assets"
  type        = string
  default     = "studytrack-24bcs10123-backups-dev"
}

variable "create_eks" {
  description = "Create the EKS control plane and node group. Off by default because the EKS API is not available on LocalStack community and a real cluster costs money."
  type        = bool
  default     = false
}

variable "eks_cluster_version" {
  type    = string
  default = "1.31"
}

variable "eks_node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "eks_node_desired_size" {
  type    = number
  default = 2
}
