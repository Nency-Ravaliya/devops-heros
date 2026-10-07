# Session 18 — Terraform & Infrastructure as Code (Homework)

**Name:** Chhavi Ahlawat
**Enrollment Number:** 24BCS10201
**Email:** chhavi.24bcs10201@sst.scaler.com

---

## Homework Tasks

| Task | Description | Status |
|---|---|---|
| 1 | [Terraform S3 demo](terraform-s3-demo/) — init, fmt, validate, plan, apply, show, output, destroy | ✅ |
| 2.1 | [IAM](aws-services/01-iam/README.md) | ✅ |
| 2.2 | [EC2](aws-services/02-ec2/README.md) | ✅ |
| 2.3 | [S3](aws-services/03-s3/README.md) | ✅ |
| 2.4 | [VPC](aws-services/04-vpc/README.md) | ✅ |
| 2.5 | [DynamoDB & RDS](aws-services/05-dynamodb-rds/README.md) | ✅ |

## Task 1 — Terraform S3 Bucket

Bucket `chhavi-24bcs10201-<random-hex>` in `us-east-2` with versioning, AES-256 encryption and public access blocked. Details in [terraform-s3-demo/README.md](terraform-s3-demo/README.md).

```bash
cd session18-terraform-iac/homework/terraform-s3-demo
```

### Commands
```bash
terraform init
terraform fmt
terraform validate
terraform plan          # 5 to add
terraform apply
terraform show
terraform output
terraform destroy
```

### Terraform workflow screenshots
These are from my session 19 VPC run (`session19-cloud-terraform/06-terraform-vpc`), which uses the same plan → apply → state → show workflow.

![terraform plan: resources to be created](../../session19-cloud-terraform/06-terraform-vpc/screenshots/ss3.png)
![terraform apply complete, outputs and state list](../../session19-cloud-terraform/06-terraform-vpc/screenshots/ss1.png)
![terraform show](../../session19-cloud-terraform/06-terraform-vpc/screenshots/ss4.png)

## Task 2 — AWS Services Research

| Service | Notes |
|---|---|
| IAM | [01-iam](aws-services/01-iam/README.md) |
| EC2 | [02-ec2](aws-services/02-ec2/README.md) |
| S3 | [03-s3](aws-services/03-s3/README.md) |
| VPC | [04-vpc](aws-services/04-vpc/README.md) |
| DynamoDB & RDS | [05-dynamodb-rds](aws-services/05-dynamodb-rds/README.md) |
