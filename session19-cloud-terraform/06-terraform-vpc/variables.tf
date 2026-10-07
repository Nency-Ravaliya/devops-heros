variable "aws_region" {
  description = "AWS region where the lab will be created."
  type        = string
  default     = "ap-south-1"
}

variable "student_name" {
  description = "Prefix for resource names so each student's resources are identifiable."
  type        = string
  default     = "chhavi"
}
