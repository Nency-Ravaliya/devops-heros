resource "random_id" "suffix" {
  byte_length = 4
}

# Bucket holding the website content the EC2 instance downloads at boot
resource "aws_s3_bucket" "site" {
  bucket        = "${var.project}-site-${random_id.suffix.hex}"
  force_destroy = true # lab only
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  content_type = "text/html"
  content = templatefile("${path.module}/templates/index.html.tftpl", {
    project = var.project
    region  = var.aws_region
    bucket  = aws_s3_bucket.site.bucket
  })
}
