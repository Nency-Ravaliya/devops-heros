output "vpc_id" {
  description = "VPC ID."
  value       = module.taskboard.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnets."
  value       = module.taskboard.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnets (EKS nodes)."
  value       = module.taskboard.private_subnet_ids
}

output "nat_gateway_public_ip" {
  description = "NAT gateway egress IP."
  value       = module.taskboard.nat_gateway_public_ip
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.taskboard.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint."
  value       = module.taskboard.cluster_endpoint
}

output "cluster_version" {
  description = "EKS Kubernetes version."
  value       = module.taskboard.cluster_version
}

output "node_group_name" {
  description = "Managed node group."
  value       = module.taskboard.node_group_name
}

output "ecr_repository_urls" {
  description = "ECR repository URLs (image prefix for docker push / Helm values)."
  value       = module.taskboard.ecr_repository_urls
}

output "configure_kubectl" {
  description = "Command to point kubectl at the new cluster."
  value       = module.taskboard.cluster_name == null ? null : "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.taskboard.cluster_name}"
}

output "ecr_login" {
  description = "Command to log Docker in to ECR."
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${module.taskboard.ecr_registry}"
}
