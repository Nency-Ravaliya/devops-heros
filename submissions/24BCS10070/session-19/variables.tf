variable "region" {
  type    = string
  default = "ap-south-1"
}
variable "allowed_http_cidr" {
  type        = string
  description = "Your client public IPv4 CIDR"
  validation {
    condition     = can(cidrnetmask(var.allowed_http_cidr)) && var.allowed_http_cidr != "0.0.0.0/0"
    error_message = "Use a restricted IPv4 CIDR, not the whole Internet."
  }
}
