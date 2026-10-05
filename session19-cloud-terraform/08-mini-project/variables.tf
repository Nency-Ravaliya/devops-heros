variable "aws_region" {
  description = "AWS region for the Session 19 mini project."
  type        = string
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "Amazon Linux AMI ID valid in the selected region."
  type        = string
}

variable "instance_type" {
  description = "Small EC2 instance type used for the web demo."
  type        = string
  default     = "t3.micro"
}

variable "bucket_prefix" {
  description = "Prefix for the unique S3 bucket name."
  type        = string
  default     = "anshal-session19-"
}
