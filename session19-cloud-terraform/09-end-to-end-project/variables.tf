variable "aws_region" {
  description = "AWS region for the Session 19 end-to-end project."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used for resource names and tags."
  type        = string
  default     = "session19"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.30.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block, e.g. 10.30.0.0/16."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (must sit inside vpc_cidr)."
  type        = string
  default     = "10.30.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "public_subnet_cidr must be a valid IPv4 CIDR block, e.g. 10.30.1.0/24."
  }
}

variable "instance_type" {
  description = "EC2 instance type. t3.micro is free-tier eligible in ap-south-1."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro", "t3.small"], var.instance_type)
    error_message = "instance_type must be one of: t2.micro, t3.micro, t3.small (keep costs low)."
  }
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH (port 22). Default is open to the world for the demo; restrict it to your own IP, e.g. \"203.0.113.10/32\"."
  type        = string
  default     = "0.0.0.0/0"
}
