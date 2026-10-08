output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet."
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the web security group."
  value       = aws_security_group.web.id
}

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP of the web server."
  value       = aws_instance.web.public_ip
}

output "website_url" {
  description = "URL of the website served by nginx."
  value       = "http://${aws_instance.web.public_ip}"
}

output "s3_bucket" {
  description = "Bucket holding the site content."
  value       = aws_s3_bucket.site.bucket
}

output "ssm_connect_command" {
  description = "Shell into the instance without SSH."
  value       = "aws ssm start-session --target ${aws_instance.web.id} --region ${var.aws_region}"
}
