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

output "ingress_rules" {
  description = "Inbound rules of the web security group (built with a for expression)."
  value = {
    for name, rule in aws_vpc_security_group_ingress_rule.web :
    name => "${rule.ip_protocol}/${rule.from_port} from ${rule.cidr_ipv4}"
  }
}

output "instance_ids" {
  description = "IDs of the web servers (splat expression over count)."
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of the web servers."
  value       = aws_instance.web[*].public_ip
}

output "website_urls" {
  description = "URLs to open once nginx is running on a real instance."
  value       = [for ip in aws_instance.web[*].public_ip : "http://${ip}"]
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.assets.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.assets.arn
}

output "iam_role_name" {
  description = "Role attached to the instances through the instance profile."
  value       = aws_iam_role.web.name
}

output "app_secret_parameter" {
  description = "Name of the SSM parameter that holds the secret (not the secret itself)."
  value       = aws_ssm_parameter.app_secret.name
}

# Derived from a sensitive variable, so Terraform insists on sensitive = true.
# It proves the secret arrived without ever printing it.
output "app_secret_length" {
  description = "Number of characters in the secret."
  value       = length(var.app_secret)
  sensitive   = true
}
