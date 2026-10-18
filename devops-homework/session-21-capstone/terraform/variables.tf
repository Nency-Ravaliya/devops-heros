variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "queuedesk"
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "allowed_api_cidrs" {
  description = "Public EKS API client CIDRs. Include your workstation IP and the CI runner egress."
  type        = list(string)
  validation {
    condition     = length(var.allowed_api_cidrs) > 0 && alltrue([for c in var.allowed_api_cidrs : can(cidrnetmask(c))])
    error_message = "Provide at least one valid IPv4 CIDR."
  }
}

variable "github_repository" {
  description = "GitHub owner/repo permitted to use the deployment role."
  type        = string
  default     = "chinna-328/devops-heros"
}

variable "github_oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN. Leave empty to create it (only one per AWS account)."
  type        = string
  default     = ""
}

variable "node_instance_type" {
  type    = string
  default = "t3.large"
}
