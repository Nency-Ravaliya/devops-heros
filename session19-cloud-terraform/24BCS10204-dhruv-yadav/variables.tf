variable "aws_region" {
  description = "AWS region for the project."
  type        = string
  default     = "ap-south-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]$", var.aws_region))
    error_message = "aws_region must look like a region name, e.g. ap-south-1."
  }
}

variable "use_localstack" {
  description = "true = run against LocalStack (AWS emulator); false = real AWS."
  type        = bool
  default     = true
}

variable "localstack_endpoint" {
  description = "LocalStack edge URL (used only when use_localstack = true)."
  type        = string
  default     = "http://localhost:4566"
}

variable "project_name" {
  description = "Prefix used in resource names and tags."
  type        = string
  default     = "session19-mini"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.project_name))
    error_message = "project_name must be 3-24 chars: lowercase letters, digits, hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) >= 16 && tonumber(split("/", var.vpc_cidr)[1]) <= 28
    error_message = "vpc_cidr must be a valid IPv4 CIDR between /16 and /28 (AWS VPC limits)."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR of the public subnet (must be inside vpc_cidr)."
  type        = string
  default     = "10.20.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "public_subnet_cidr must be a valid IPv4 CIDR."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR of the private subnet (must be inside vpc_cidr)."
  type        = string
  default     = "10.20.2.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "private_subnet_cidr must be a valid IPv4 CIDR."
  }
}

variable "ssh_allowed_cidr" {
  description = "Only this CIDR may SSH (port 22) to the web server - normally your own IP /32."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0)) && var.ssh_allowed_cidr != "0.0.0.0/0"
    error_message = "ssh_allowed_cidr must be a valid CIDR and must NOT be 0.0.0.0/0 (SSH open to the world)."
  }
}

variable "ami_id" {
  description = "AMI ID for the web server. Must exist in the chosen region (LocalStack ships a mock catalog)."
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-f]{8,17}$", var.ami_id))
    error_message = "ami_id must look like ami-xxxxxxxx (8 or 17 hex chars)."
  }
}

variable "instance_type" {
  description = "EC2 instance type (restricted to small, cheap types)."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro", "t3.small", "t4g.micro"], var.instance_type)
    error_message = "instance_type must be one of t2.micro, t3.micro, t3.small, t4g.micro."
  }
}

variable "key_name" {
  description = "Optional existing EC2 key pair name for SSH. null = no key pair."
  type        = string
  default     = null
}
