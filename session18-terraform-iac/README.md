# Session 18: Terraform & Infrastructure as Code (IaC)

This session covers Infrastructure as Code fundamentals with HashiCorp Terraform and in-depth architectural research across core Amazon Web Services (AWS).

---

## Task 1: Terraform S3 Demo Project

A complete, working Terraform module provisioning an AWS S3 Bucket with custom tags and variables:
* **Project Directory:** [`terraform-s3-demo/`](file:///home/akshanshsinha/DevOps/devops-heros/session18-terraform-iac/terraform-s3-demo)
* **Project Documentation:** [terraform-s3-demo/README.md](file:///home/akshanshsinha/DevOps/devops-heros/session18-terraform-iac/terraform-s3-demo/README.md)

### File Structure:
```text
terraform-s3-demo/
├── main.tf             # S3 bucket resource definition
├── variables.tf        # AWS region & bucket name variables
├── outputs.tf          # Bucket ARN & domain outputs
├── providers.tf        # AWS provider configuration
├── terraform.tfvars    # Environment variable overrides
└── README.md           # Step-by-step execution guide
```

### Complete Terraform Workflow Commands:
```bash
cd terraform-s3-demo

# 1. Initialize provider plugins and working directory
terraform init

# 2. Format configuration files to standard convention
terraform fmt

# 3. Validate syntax and configuration semantics
terraform validate

# 4. Generate and inspect execution plan
terraform plan

# 5. Provision resources on AWS
terraform apply -auto-approve

# 6. Inspect current live state
terraform show

# 7. Query output values
terraform output

# 8. Destroy created infrastructure
terraform destroy -auto-approve
```

---

## Task 2: AWS Services Research & Documentation

In-depth technical guides covering governance, compute, storage, networking, and databases:

1. [**01. IAM - Governance**](file:///home/akshanshsinha/DevOps/devops-heros/session18-terraform-iac/aws-services/01-iam/README.md): Users, Groups, Roles, Policies, Principle of Least Privilege, and best practices.
2. [**02. EC2 - Compute**](file:///home/akshanshsinha/DevOps/devops-heros/session18-terraform-iac/aws-services/02-ec2/README.md): AMIs, instance types, key pairs, security groups, EBS volumes, and instance lifecycle.
3. [**03. S3 - Storage**](file:///home/akshanshsinha/DevOps/devops-heros/session18-terraform-iac/aws-services/03-s3/README.md): Buckets, objects, storage tiers, versioning, lifecycle rules, encryption, and bucket policies.
4. [**04. VPC - Networking**](file:///home/akshanshsinha/DevOps/devops-heros/session18-terraform-iac/aws-services/04-vpc/README.md): CIDR, public/private subnets, Route Tables, Internet Gateways, NAT Gateways, and Security Groups vs NACLs.
5. [**05. DynamoDB & RDS - Database Services**](file:///home/akshanshsinha/DevOps/devops-heros/session18-terraform-iac/aws-services/05-dynamodb-rds/README.md): NoSQL key-value store vs managed relational database instances (Multi-AZ, Read Replicas).