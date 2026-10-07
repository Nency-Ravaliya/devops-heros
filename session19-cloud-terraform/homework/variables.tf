variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-2"
}

variable "owner" {
  description = "Owner tag value."
  type        = string
  default     = "chhavi"
}

variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
  default     = "chhavi-s19"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.30.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH (port 22). Use your own IP, e.g. 1.2.3.4/32."
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "Optional existing EC2 key pair name for SSH. Leave null to skip."
  type        = string
  default     = null
}
