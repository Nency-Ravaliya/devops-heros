variable "aws_region" {
  description = "AWS region for the Session 19 mini project."
  type        = string
  default     = "ap-south-1"
}

variable "ec2_ami" {
  description = "AMI ID for the EC2 web server (Amazon Linux 2023)."
  type        = string
  default     = "ami-0f58b397bc5c1f2e8" # Amazon Linux 2023 — ap-south-1
}

variable "ec2_instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "s3_bucket_name" {
  description = "Globally unique S3 bucket name for artifacts."
  type        = string
  default     = "session19-cloud-terraform-artifacts"
}

variable "my_ip_cidr" {
  description = "Your IP CIDR for SSH access (e.g. 203.0.113.5/32)."
  type        = string
  default     = "0.0.0.0/0" # Restrict to your IP in production
}
