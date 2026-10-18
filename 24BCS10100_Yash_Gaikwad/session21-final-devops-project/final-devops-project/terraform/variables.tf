variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster. Also used as a prefix for the VPC."
  type        = string
  default     = "stockpilot-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane (must be in EKS standard support)."
  type        = string
  default     = "1.35"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "How many availability zones to spread subnets over (at least 2 for EKS)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_desired_size" {
  description = "Desired number of worker nodes at creation time."
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway (cheap, fine for a lab) instead of one per AZ (highly available)."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Allow the Kubernetes API endpoint to be reached from the internet (IAM still protects it)."
  type        = bool
  default     = true
}
