variable "aws_region" { default = "ap-south-1" }
variable "cluster_name" { default = "taskboard-eks" }
variable "environment" { default = "dev" }

variable "kubernetes_version" {
  description = "Choose an EKS version currently supported in the target AWS region before apply."
  type        = string
}
