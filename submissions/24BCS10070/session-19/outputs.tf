output "web_url" {
  value = "http://${aws_instance.web.public_ip}"
}
output "vpc_id" {
  value = aws_vpc.lab.id
}
output "bucket_name" {
  value = aws_s3_bucket.practice.bucket
}
