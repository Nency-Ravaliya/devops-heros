# Terraform S3 Demo — Chhavi Ahlawat (24BCS10201)

Creates a private, encrypted, versioned S3 bucket in **us-east-2** named `chhavi-24bcs10201-<random-hex>`.

| File | Purpose |
|---|---|
| `provider.tf` | Terraform version, `aws` + `random` providers, region, default tags (`Owner=chhavi`) |
| `variables.tf` | `aws_region`, `bucket_prefix`, `environment`, `enable_versioning` |
| `terraform.tfvars` | Values for the variables |
| `main.tf` | `random_id` suffix, S3 bucket, versioning, SSE-AES256, public-access block |
| `outputs.tf` | Bucket name, ARN, region, versioning status |

## Prerequisites
```bash
aws configure                 # region us-east-2
aws sts get-caller-identity   # confirm credentials work
```

## Workflow
| # | Command | What it does |
|---|---|---|
| 1 | `terraform init` | Downloads `aws` and `random` providers into `.terraform/` |
| 2 | `terraform fmt` | Formats `.tf` files to canonical style |
| 3 | `terraform validate` | Checks syntax and references (no AWS calls) |
| 4 | `terraform plan` | Shows what will change → `Plan: 5 to add` |
| 5 | `terraform apply` | Creates the bucket + settings after typing `yes` |
| 6 | `terraform show` | Prints the current state (all resource attributes) |
| 7 | `terraform output` | Prints bucket name / ARN / region / versioning |
| 8 | `aws s3 ls \| grep chhavi` | Verify the bucket exists in AWS |
| 9 | `terraform destroy` | Deletes all 5 resources after typing `yes` |

`terraform.tfstate` and `.terraform/` are git-ignored; `terraform.tfvars` is committed since it contains no secrets.
