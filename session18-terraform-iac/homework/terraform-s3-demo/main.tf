# Random suffix -> globally unique bucket name
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "demo" {
  bucket        = "${var.bucket_prefix}-${random_id.suffix.hex}"
  force_destroy = true # lab only: lets `terraform destroy` remove a bucket that still has objects

  tags = {
    Name        = "${var.bucket_prefix}-${random_id.suffix.hex}"
    Environment = var.environment
  }
}

# Never allow public access
resource "aws_s3_bucket_public_access_block" "demo" {
  bucket                  = aws_s3_bucket.demo.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# Encrypt every object at rest with S3-managed keys (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Clean up old object versions automatically
resource "aws_s3_bucket_lifecycle_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.demo]
}

# A sample object, to prove the bucket works
resource "aws_s3_object" "hello" {
  bucket       = aws_s3_bucket.demo.id
  key          = "hello.txt"
  content      = "Hello from Terraform - Session 18\n"
  content_type = "text/plain"

  depends_on = [aws_s3_bucket_server_side_encryption_configuration.demo]
}
