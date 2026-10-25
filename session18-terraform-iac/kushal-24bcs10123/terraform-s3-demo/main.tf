# The bucket itself. force_destroy lets `terraform destroy` remove it even when it still holds objects.
resource "aws_s3_bucket" "demo" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Session18"
    Owner       = "kushal-24bcs10123"
  }
}

# Keep every version of every object (protects against accidental overwrite / delete).
resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt every object at rest with an S3-managed key (SSE-S3 / AES256).
resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block every form of public access - the bucket is private no matter what ACL/policy somebody adds later.
resource "aws_s3_bucket_public_access_block" "demo" {
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# A small object so `terraform apply` leaves something visible inside the bucket.
resource "aws_s3_object" "readme" {
  bucket       = aws_s3_bucket.demo.id
  key          = "hello/README.txt"
  content      = "Created by Terraform for Session 18 (kushal-24bcs10123).\n"
  content_type = "text/plain"

  # implicit dependency on the bucket via aws_s3_bucket.demo.id; versioning must exist first so the object gets a version id
  depends_on = [aws_s3_bucket_versioning.demo]
}
