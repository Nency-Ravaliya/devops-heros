# Session 18 — Terraform

**Name:** Viraj Bhanage
**Roll number:** 24BCS10274

The S3 lab is `homework/session-18-terraform/terraform-s3-demo`. It creates one private bucket, enables versioning, and blocks public access. Change `bucket_name` before apply. I have not created that bucket.

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy
```

Destroy the same day if you do apply. Notes on IAM, EC2, S3, VPC, DynamoDB, and RDS are in `homework/session-18-terraform/aws-services/`. Those notes are mine.
