<<<<<<< HEAD
resource "aws_s3_bucket" "thebaburao" {
=======
resource "aws_s3_bucket" "devops553" {
>>>>>>> 7a66a0f4b361914ab2b8aeffd363b9f7ed86cd79
  bucket        = var.bucket_name
  force_destroy = true
  tags = {
    Name        = var.bucket_name
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "Session18"
  }
}
