resource "aws_s3_bucket" "workflow_demo" {
  bucket_prefix = "session19-workflow-"

  tags = {
    Name      = "Session 19 Workflow Demo"
    ManagedBy = "Terraform"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.workflow_demo.bucket
}
