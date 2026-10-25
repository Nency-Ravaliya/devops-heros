output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "web_security_group_id" {
  value = aws_security_group.web.id
}

output "backup_bucket" {
  value = aws_s3_bucket.backups.bucket
}

output "eks_cluster_name" {
  value = var.create_eks ? module.eks[0].cluster_name : "not created (create_eks=false)"
}

output "eks_cluster_endpoint" {
  value = var.create_eks ? module.eks[0].cluster_endpoint : null
}
