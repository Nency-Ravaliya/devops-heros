output "bucket_name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.demo.arn
}

output "bucket_region" {
  description = "Region the bucket lives in."
  value       = aws_s3_bucket.demo.region
}

output "versioning_status" {
  description = "Versioning status of the bucket."
  value       = aws_s3_bucket_versioning.demo.versioning_configuration[0].status
}

output "sample_object_uri" {
  description = "S3 URI of the sample object."
  value       = "s3://${aws_s3_bucket.demo.bucket}/${aws_s3_object.hello.key}"
}
