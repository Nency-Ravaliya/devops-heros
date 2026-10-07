output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}

output "route_table_id" {
  value = aws_route_table.public.id
}

output "security_group_id" {
  value = aws_security_group.web.id
}

output "instance_id" {
  value = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP of the web server - open http://<ip>/ once user_data has finished."
  value       = aws_instance.web.public_ip
}

output "instance_private_ip" {
  value = aws_instance.web.private_ip
}

output "ami_id" {
  value = aws_instance.web.ami
}

output "bucket_name" {
  value = aws_s3_bucket.assets.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.assets.arn
}

output "ssh_private_key_pem" {
  description = "Private key for the instance (sensitive - only printed with terraform output -raw)."
  value       = tls_private_key.ssh.private_key_openssh
  sensitive   = true
}
