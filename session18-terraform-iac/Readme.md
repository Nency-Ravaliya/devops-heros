# Session 18 — Terraform & Infrastructure as Code

> **Provision AWS infrastructure with code using Terraform**

---

## 📁 Folder Structure

```
session18-terraform-iac/
├── 01-iac-basics/              # What is IaC? Terraform vs Ansible vs CloudFormation
├── 02-terraform-architecture/  # Providers, state, core workflow
├── 03-providers/               # AWS provider configuration
├── 04-resources/               # Resource blocks
├── 05-variables/               # Input variables & tfvars
├── 06-outputs/                 # Output values
├── 07-init-plan-apply/         # Core Terraform workflow
├── 08-destroy/                 # Destroy infrastructure
├── 09-state/                   # Terraform state management
├── terraform-s3-demo/          # Task 1 — S3 bucket mini project
└── aws-services/               # Task 2 — AWS services research
    ├── 01-iam/
    ├── 02-ec2/
    ├── 03-s3/
    ├── 04-vpc/
    └── 05-dynamodb-rds/
```

---

## Task 1 — Terraform S3 Demo

A complete Terraform project that provisions an AWS S3 bucket.

### Project files

| File | Purpose |
|------|---------|
| `provider.tf` / `providers.tf` | AWS provider configuration |
| `variables.tf` | Input variable declarations |
| `terraform.tfvars` | Variable values |
| `main.tf` | S3 bucket resource |
| `outputs.tf` | Output values (bucket name, ARN, region) |
| `terraform.tf` | Terraform version & backend config |

### Terraform Workflow

```bash
# 1. Initialize — download provider plugins
terraform init

# 2. Format — fix code style
terraform fmt

# 3. Validate — check syntax
terraform validate
# → Success! The configuration is valid.

# 4. Plan — preview changes
terraform plan
# → Plan: 1 to add, 0 to change, 0 to destroy.

# 5. Apply — create infrastructure
terraform apply
# → Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

# 6. Show — inspect state
terraform show

# 7. Output — print outputs
terraform output
# → bucket_arn    = "arn:aws:s3:::devops553-session18-terraform-demo"
# → bucket_name   = "devops553-session18-terraform-demo"
# → bucket_region = "ap-south-1"

# 8. Verify via AWS CLI
aws s3 ls | grep devops553

# 9. Destroy — delete infrastructure
terraform destroy
# → Destroy complete! Resources: 1 destroyed.
```

### Output

```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn    = "arn:aws:s3:::devops553-session18-terraform-demo"
bucket_name   = "devops553-session18-terraform-demo"
bucket_region = "ap-south-1"
```

---

## Task 2 — AWS Services Research

| Service | Folder | Topic |
|---------|--------|-------|
| **IAM** | `aws-services/01-iam/` | Users, Groups, Roles, Policies, Least Privilege |
| **EC2** | `aws-services/02-ec2/` | AMI, Instance types, Key pairs, Security Groups, EBS |
| **S3** | `aws-services/03-s3/` | Buckets, Objects, Storage classes, Versioning, Encryption |
| **VPC** | `aws-services/04-vpc/` | CIDR, Subnets, Route tables, IGW, NAT Gateway, NACLs |
| **DynamoDB & RDS** | `aws-services/05-dynamodb-rds/` | NoSQL vs SQL, Tables, Keys, Multi-AZ, Read replicas |

---

## Prerequisites

```bash
# Install Terraform (macOS)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform --version

# Install AWS CLI
pip install awscli
aws --version

# Configure AWS credentials
aws configure
# AWS Access Key ID: ****
# AWS Secret Access Key: ****
# Default region: ap-south-1
# Default output: json

# Verify identity
aws sts get-caller-identity
```

---

## Terraform Lifecycle

```
Write .tf files
      │
terraform init    → Download providers, initialise backend
      │
terraform fmt     → Format code consistently
      │
terraform validate → Check syntax and logic
      │
terraform plan    → Preview changes (dry run)
      │
terraform apply   → CREATE / UPDATE infrastructure
      │
terraform show    → Inspect current state
      │
terraform output  → Print output values
      │
terraform destroy → DELETE infrastructure
```

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Provider** | Plugin connecting Terraform to a cloud (AWS, GCP, Azure) |
| **Resource** | Infrastructure component (S3 bucket, EC2 instance) |
| **Variable** | Input values for reusability |
| **Output** | Values printed after apply |
| **State** | `terraform.tfstate` — tracks real infrastructure |
| **Backend** | Where state is stored (local or S3 + DynamoDB) |
| **Module** | Reusable group of resources |