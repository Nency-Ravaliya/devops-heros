output "bucket_name" {
  type        = string
  description = "Name of the S3 bucket."
<<<<<<< HEAD
  value       = aws_s3_bucket.thebaburao.bucket
=======
  value       = aws_s3_bucket.devops553.bucket
>>>>>>> 7a66a0f4b361914ab2b8aeffd363b9f7ed86cd79
}
output "bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket."
<<<<<<< HEAD
  value       = aws_s3_bucket.thebaburao.arn
=======
  value       = aws_s3_bucket.devops553.arn
>>>>>>> 7a66a0f4b361914ab2b8aeffd363b9f7ed86cd79
}
output "bucket_region" {
  type        = string
  description = "AWS region of the S3 bucket."
<<<<<<< HEAD
  value       = aws_s3_bucket.thebaburao.region
=======
  value       = aws_s3_bucket.devops553.region
>>>>>>> 7a66a0f4b361914ab2b8aeffd363b9f7ed86cd79
}
