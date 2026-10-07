output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet."
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the web security group."
  value       = aws_security_group.web.id
}

output "instance_id" {
  description = "ID of the EC2 web server."
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IPv4 address of the EC2 web server."
  value       = aws_instance.web.public_ip
}

output "website_url" {
  description = "URL of the nginx page served by the EC2 instance."
  value       = "http://${aws_instance.web.public_ip}"
}

output "ami_id" {
  description = "Amazon Linux 2023 AMI ID chosen by the data source."
  value       = data.aws_ami.al2023.id
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.main.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.main.arn
}
