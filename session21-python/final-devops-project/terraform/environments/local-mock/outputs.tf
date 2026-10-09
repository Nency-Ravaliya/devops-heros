output "vpc_id" {
  value = module.taskboard.vpc_id
}

output "public_subnet_ids" {
  value = module.taskboard.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.taskboard.private_subnet_ids
}

output "nat_gateway_public_ip" {
  value = module.taskboard.nat_gateway_public_ip
}

output "cluster_name" {
  value = module.taskboard.cluster_name
}

output "cluster_endpoint" {
  value = module.taskboard.cluster_endpoint
}

output "node_group_name" {
  value = module.taskboard.node_group_name
}

output "ecr_repository_urls" {
  value = module.taskboard.ecr_repository_urls
}

output "configure_kubectl" {
  value = module.taskboard.cluster_name == null ? null : "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.taskboard.cluster_name} --endpoint-url ${var.moto_endpoint}"
}
