variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Name prefix for every resource"
  type        = string
  default     = "devops-heros"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI for the web server (Amazon Linux 2023 in ap-south-1; override per region)"
  type        = string
  default     = "ami-0f58b397bc5c1f2e8"
}

variable "allowed_ssh_cidr" {
  description = "Only this CIDR may SSH to the instance (use your own IP/32)"
  type        = string
  default     = "203.0.113.10/32"
}
