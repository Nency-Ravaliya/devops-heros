variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name (dev / staging / prod)."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner tag (team or person)."
  type        = string
  default     = "devops-heros"
}

variable "azs" {
  description = "Two (or more) availability zones in aws_region."
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.20.0.0/16"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.31"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API (set to your IP, e.g. [\"203.0.113.10/32\"])."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "Worker node instance types."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT (SPOT is ~60-70% cheaper for a demo)."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_desired_size" {
  description = "Desired worker node count."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum worker node count."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum worker node count."
  type        = number
  default     = 4
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway for private subnet egress."
  type        = bool
  default     = true
}

variable "ecr_repositories" {
  description = "ECR repositories to create."
  type        = list(string)
  default     = ["taskboard-backend", "taskboard-frontend"]
}
