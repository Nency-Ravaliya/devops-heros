resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "assets" {
  bucket        = "${var.project}-assets-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = { Name = "${var.project}-assets" }
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "welcome" {
  bucket  = aws_s3_bucket.assets.id
  key     = "welcome.txt"
  content = "Uploaded by Terraform for ${var.project}"
}
