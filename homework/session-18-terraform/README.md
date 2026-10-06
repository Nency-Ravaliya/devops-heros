# Session 18 — Terraform S3 demo

Student: Viraj Bhanage, roll 24BCS10274

Project: [terraform-s3-demo](terraform-s3-demo)

```text
terraform-s3-demo/
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
├── versions.tf
├── terraform.tfvars
└── README.md
```

The configuration creates a private S3 bucket with versioning and Block Public Access. No AWS credentials are stored in the repo.

## Workflow

Change `bucket_name` in `terraform.tfvars` to something globally unique before you apply. Then:

```bash
cd homework/session-18-terraform/terraform-s3-demo
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform show
terraform output
terraform destroy
```

`init` downloads the AWS provider. `fmt` rewrites layout. `validate` checks syntax. `plan` shows the create. `apply` creates the bucket. `show` prints state. `output` prints the bucket name and ARN. `destroy` deletes the bucket. `force_destroy` lets destroy succeed even if a lab object was uploaded.

These commands were not run against a real account from this workspace, because apply would create a billable bucket and needs your AWS login. Screenshot `plan`, the S3 console, and `destroy` once you run them. Destroy the same day so the bucket does not sit around.

Service notes:

- [IAM](aws-services/01-iam/README.md)
- [EC2](aws-services/02-ec2/README.md)
- [S3](aws-services/03-s3/README.md)
- [VPC](aws-services/04-vpc/README.md)
- [DynamoDB and RDS](aws-services/05-dynamodb-rds/README.md)
