variable "cluster_name" {
  description = "Name of the Kubernetes (kind) cluster"
  type        = string
  default     = "final-devops"
}

variable "node_image" {
  description = "kindest/node image = Kubernetes version"
  type        = string
  default     = "kindest/node:v1.33.1"
}

variable "workers" {
  description = "Number of worker nodes"
  type        = number
  default     = 1
}

variable "install_monitoring" {
  description = "Install kube-prometheus-stack"
  type        = bool
  default     = true
}
