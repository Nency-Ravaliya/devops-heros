output "region" {
  description = "AWS region the infrastructure lives in."
  value       = var.region
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnets (load balancers, NAT gateway)."
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnets (worker nodes)."
  value       = module.vpc.private_subnets
}

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Run this command to point kubectl at the new cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
