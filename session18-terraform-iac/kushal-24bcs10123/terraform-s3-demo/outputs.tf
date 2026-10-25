output "bucket_name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.demo.arn
}

output "bucket_region" {
  description = "AWS region of the S3 bucket."
  value       = aws_s3_bucket.demo.region
}

output "bucket_domain_name" {
  description = "Virtual-hosted style domain name of the bucket."
  value       = aws_s3_bucket.demo.bucket_domain_name
}

output "versioning_status" {
  description = "Whether object versioning is on."
  value       = aws_s3_bucket_versioning.demo.versioning_configuration[0].status
}

output "readme_object_version" {
  description = "Version id of the uploaded README object (proves versioning works)."
  value       = aws_s3_object.readme.version_id
}
