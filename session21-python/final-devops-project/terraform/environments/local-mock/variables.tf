variable "aws_region" {
  description = "Region name passed to the mock."
  type        = string
  default     = "ap-south-1"
}

variable "moto_endpoint" {
  description = "URL of the Moto server."
  type        = string
  default     = "http://localhost:4577"
}

# Toggles - flip off anything the mock cannot emulate.
variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "enable_flow_logs" {
  type    = bool
  default = true
}

variable "enable_eks" {
  type    = bool
  default = true
}

variable "enable_node_group" {
  type    = bool
  default = true
}
