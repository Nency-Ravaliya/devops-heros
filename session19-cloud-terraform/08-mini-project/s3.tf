resource "aws_s3_bucket" "homework" {
  bucket        = "yatri1107-session19-2026"
  force_destroy = true

  tags = {
    Name      = "Session 19 Terraform S3"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}
