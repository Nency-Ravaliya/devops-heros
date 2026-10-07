output "target" {
  description = "Where this was applied"
  value       = var.use_localstack ? "LocalStack (${var.localstack_endpoint})" : "AWS ${var.region}"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "artifacts_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}

output "tf_lock_table" {
  value = aws_dynamodb_table.tf_locks.name
}

output "ecr_repository_url" {
  value = var.create_ecr ? aws_ecr_repository.api[0].repository_url : "not created (ECR needs LocalStack Pro) - images are in ghcr.io/Aana-1025 Utane/stockpilot-api"
}
