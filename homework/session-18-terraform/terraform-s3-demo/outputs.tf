output "bucket_name" {
  description = "Name of the lab bucket."
  value       = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  description = "ARN of the lab bucket."
  value       = aws_s3_bucket.demo.arn
}
