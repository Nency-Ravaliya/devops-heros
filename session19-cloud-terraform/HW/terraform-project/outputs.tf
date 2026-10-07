output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet."
  value       = aws_subnet.public.id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway."
  value       = aws_internet_gateway.main.id
}

output "security_group_id" {
  description = "ID of the web security group."
  value       = aws_security_group.web.id
}

output "ami_id" {
  description = "AMI chosen by the data source."
  value       = data.aws_ami.amazon_linux.id
}

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.web.id
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance."
  value       = aws_instance.web.private_ip
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance."
  value       = aws_instance.web.public_ip
}

output "bucket_name" {
  description = "Name of the S3 assets bucket."
  value       = aws_s3_bucket.assets.bucket
}

output "index_object" {
  description = "S3 URI of the uploaded page."
  value       = "s3://${aws_s3_bucket.assets.bucket}/${aws_s3_object.index.key}"
}
