# Terraform S3 Demo

This is my hands-on project for creating and removing an S3 bucket with Terraform. I added versioning, encryption, and a public-access block so the example reflects the defaults I would want on a private bucket.

## Files

| File | Purpose |
|---|---|
| `terraform.tf` | Terraform and AWS provider versions |
| `provider.tf` | AWS region and common tags |
| `variables.tf` | Region and bucket-prefix inputs |
| `main.tf` | Bucket and security settings |
| `outputs.tf` | Bucket name, ARN, and region |
| `terraform.tfvars.example` | Safe example values |

## Commands I use

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform show
terraform output
terraform state list
aws s3api head-bucket --bucket "$(terraform output -raw bucket_name)"
terraform destroy
```

The bucket uses `force_destroy = true` for classroom cleanup. I would be more cautious with that setting for production data because it permits Terraform to delete a non-empty bucket.

I never commit `.terraform/`, state, plan files, or my real `terraform.tfvars`. The example values are enough to reproduce the configuration in an authorized account.
