variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS cluster name (also used as a prefix for the network resources)"
  type        = string
  default     = "stockpilot-eks"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version (latest in EKS standard support at the time of writing)"
  type        = string
  default     = "1.37"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.40.0.0/16"
}

variable "node_instance_type" {
  description = "Instance type of the managed node group"
  type        = string
  default     = "t3.small"
}

variable "node_count" {
  description = "Desired (and maximum) number of worker nodes"
  type        = number
  default     = 1
}
