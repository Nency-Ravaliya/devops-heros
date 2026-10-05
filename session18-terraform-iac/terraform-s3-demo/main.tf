resource "aws_s3_bucket" "assignment" {
  bucket_prefix = var.bucket_prefix
  force_destroy = true

  tags = {
    Name        = "session18-terraform-demo"
    Environment = "learning"
  }
}

resource "aws_s3_bucket_versioning" "assignment" {
  bucket = aws_s3_bucket.assignment.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assignment" {
  bucket = aws_s3_bucket.assignment.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assignment" {
  bucket = aws_s3_bucket.assignment.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
