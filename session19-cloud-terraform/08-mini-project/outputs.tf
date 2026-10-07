# ==============================================================================
# Outputs Definition - Session 19 Cloud & Terraform Architecture
# ==============================================================================

output "vpc_id" {
  description = "The ID of the provisioned Virtual Private Cloud."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The CIDR block allocated to the VPC."
  value       = aws_vpc.main.cidr_block
}

output "subnet_id" {
  description = "The ID of the Public Subnet."
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "The ID of the Web Security Group."
  value       = aws_security_group.web.id
}

output "ec2_instance_id" {
  description = "The ID of the provisioned EC2 instance."
  value       = aws_instance.web.id
}

output "ec2_public_ip" {
  description = "The Public IPv4 Address of the EC2 Web Server."
  value       = aws_instance.web.public_ip
}

output "s3_bucket_name" {
  description = "The unique name of the provisioned S3 bucket."
  value       = aws_s3_bucket.app_storage.id
}

output "s3_bucket_arn" {
  description = "The Amazon Resource Name (ARN) of the S3 bucket."
  value       = aws_s3_bucket.app_storage.arn
}
