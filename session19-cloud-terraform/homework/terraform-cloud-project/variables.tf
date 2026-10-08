variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project name, used in resource names and tags."
  type        = string
  default     = "session19-web"
}

variable "owner" {
  description = "Owner tag."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.19.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block of the public subnet."
  type        = string
  default     = "10.19.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type (free-tier eligible by default)."
  type        = string
  default     = "t3.micro"
}

variable "allow_ssh" {
  description = "Open port 22 to my current public IP. Off by default; the instance is managed through SSM instead."
  type        = bool
  default     = false
}
