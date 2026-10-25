variable "aws_region" {
  description = "AWS region for the whole stack."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used in every resource Name tag."
  type        = string
  default     = "s19-kushal"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block of the public subnet (must be inside vpc_cidr)."
  type        = string
  default     = "10.20.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for the web server."
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidr" {
  description = "Where SSH (22) is allowed from. Narrow this to your own IP on real AWS."
  type        = string
  default     = "10.0.0.0/8"
}

variable "bucket_suffix" {
  description = "Suffix that makes the S3 bucket name globally unique."
  type        = string
  default     = "24bcs10123"
}

variable "aws_endpoint_url" {
  description = "Set to http://localhost:4566 for LocalStack. Leave null for real AWS."
  type        = string
  default     = null
}

variable "ami_id" {
  description = "AMI to launch. null = look up the newest Amazon Linux 2023 image via data.aws_ami (real AWS); LocalStack needs an id from its own catalogue."
  type        = string
  default     = null
}
