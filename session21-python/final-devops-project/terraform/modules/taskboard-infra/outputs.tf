output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (one per AZ)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (one per AZ) - EKS nodes run here."
  value       = aws_subnet.private[*].id
}

output "nat_gateway_public_ip" {
  description = "Egress IP of the NAT gateway (null when disabled)."
  value       = try(aws_eip.nat[0].public_ip, null)
}

output "cluster_security_group_id" {
  description = "Additional security group attached to the EKS control plane."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group for worker nodes."
  value       = aws_security_group.nodes.id
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = try(aws_eks_cluster.this[0].name, null)
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = try(aws_eks_cluster.this[0].endpoint, null)
}

output "cluster_version" {
  description = "Kubernetes version of the cluster."
  value       = try(aws_eks_cluster.this[0].version, null)
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA bundle of the EKS API server."
  value       = try(aws_eks_cluster.this[0].certificate_authority[0].data, null)
  sensitive   = true
}

output "node_group_name" {
  description = "Managed node group name."
  value       = try(aws_eks_node_group.default[0].node_group_name, null)
}

output "ecr_repository_urls" {
  description = "Map of ECR repository name => URL."
  value       = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}

output "ecr_registry" {
  description = "ECR registry host (for docker login)."
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

output "kms_key_arn" {
  description = "KMS key used for EKS secrets, ECR and logs."
  value       = aws_kms_key.this.arn
}
