output "cluster_name" { value = aws_eks_cluster.main.name }
output "region" { value = var.aws_region }
output "vpc_id" { value = aws_vpc.main.id }
output "github_role_arn" { value = aws_iam_role.github.arn }
output "load_balancer_controller_role_arn" { value = aws_iam_role.alb.arn }
output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}
