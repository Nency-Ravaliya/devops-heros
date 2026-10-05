variable "aws_region" {
  description = "AWS region used for the TaskBoard infrastructure."
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "taskboard-eks"
}

variable "kubernetes_version" {
  description = "EKS control-plane version. Change this to a version supported in the selected region before applying."
  type        = string
  default     = "1.31"
}

variable "environment" {
  description = "Environment tag applied to AWS resources."
  type        = string
  default     = "dev"
}
