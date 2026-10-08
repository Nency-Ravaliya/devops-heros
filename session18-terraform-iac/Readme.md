# Session 18: Terraform & Infrastructure as Code (Master Homework Guide)

---

## 👩‍💻 Student Information
- **Name:** Sahasra ambati
- **Enrollment Number:** sahasra10241
- **Course / Track:** DevOps & Cloud Engineering
- **Assignment:** Session 18: Terraform S3 Demo & AWS Cloud Services Architecture

---

## 📑 Assignment Overview & Deliverables Map

This repository module contains the deliverables for **Session 18: Terraform & Infrastructure as Code**, divided into two primary tasks:

```text
session18-terraform-iac/
├── Readme.md                          # Master overview & table of contents (this file)
│
├── terraform-s3-demo/                 # TASK 1: Complete Terraform S3 Bucket Demo
│   ├── main.tf                        # S3 bucket resource definition
│   ├── variables.tf                   # Input variable declarations
│   ├── outputs.tf                     # Output definitions (bucket name, ARN, region)
│   ├── provider.tf                    # Terraform block & AWS provider setup
│   ├── terraform.tfvars               # Variable input values
│   ├── .terraform.lock.hcl            # Cryptographic provider lock file
│   └── README.md                      # Detailed lifecycle & workflow documentation
│
└── aws-services/                      # TASK 2: Comprehensive AWS Cloud Architecture Research
    ├── screenshots/                   # Architecture cards and system diagrams
    ├── 01-iam/
    │   └── README.md                  # IAM: Governance, Users, Groups, Roles, Policies, Best Practices
    ├── 02-ec2/
    │   └── README.md                  # EC2: AMIs, Instance Types, Key Pairs, Security Groups, EBS, Lifecycle
    ├── 03-s3/
    │   └── README.md                  # S3: Buckets, Objects, Storage Classes, Versioning, Lifecycles, Encryption
    ├── 04-vpc/
    │   └── README.md                  # VPC: CIDR, Subnets, Routing, Gateways, SGs vs NACLs, 3-Tier Pattern
    └── 05-dynamodb-rds/
        └── README.md                  # Databases: DynamoDB (Serverless NoSQL) vs RDS (Relational Engines)
```

---

## 🚀 Task 1: Terraform S3 Demo Summary

- **Objective:** Provision an AWS S3 bucket using clean, modular Terraform configuration following standard HashiCorp development patterns.
- **Project Folder:** [`terraform-s3-demo/`](./terraform-s3-demo/)
- **Documentation:** [`terraform-s3-demo/README.md`](./terraform-s3-demo/README.md)
- **Lifecycle Commands Executed & Documented:**
  1. `terraform init` - Downloaded AWS provider `v6.66.0` and generated `.terraform.lock.hcl`.
  2. `terraform fmt` - Formatted all code to canonical HCL standards.
  3. `terraform validate` - Validated syntactic and semantic structure.
  4. `terraform plan` - Generated dry-run diff: `1 to add, 0 to change, 0 to destroy`.
  5. `terraform apply` - Provisioned bucket `sahasra-devops-hero-session18-bucket` in `ap-south-1`.
  6. `terraform show` - Inspected full state attributes including ARNs and hosted zones.
  7. `terraform output` - Exported structured bucket metadata.
  8. `terraform destroy` - Safely deprovisioned bucket to prevent orphaned cloud billing.

---

## ☁️ Task 2: AWS Services Architecture Research Summary

| Service Category | Folder | Core Concepts Covered | Detailed Report |
| :--- | :--- | :--- | :--- |
| **01. IAM - Governance** | [`aws-services/01-iam/`](./aws-services/01-iam/) | What is IAM, Users, Groups, Roles, JSON Policies, Permissions Evaluation, Principle of Least Privilege, Best Practices, STS Temporary Tokens, Use Cases | [IAM Guide](./aws-services/01-iam/README.md) |
| **02. EC2 - Compute** | [`aws-services/02-ec2/`](./aws-services/02-ec2/) | What is EC2, AMIs (Golden Images), Instance Families & Sizing, Key Pairs (SSH), Security Groups (Stateful), EBS Volumes & Snapshots, Public vs Private IP, Instance Lifecycle, Use Cases | [EC2 Guide](./aws-services/02-ec2/README.md) |
| **03. S3 - Storage** | [`aws-services/03-s3/`](./aws-services/03-s3/) | What is S3, Bucket & Object Anatomy, 7 Storage Classes, Object Versioning, Lifecycle Policies, Encryption (SSE-S3, SSE-KMS, TLS), Bucket Policies vs ACLs, Use Cases | [S3 Guide](./aws-services/03-s3/README.md) |
| **04. VPC - Networking** | [`aws-services/04-vpc/`](./aws-services/04-vpc/) | What is VPC, CIDR & Subnetting, Route Tables, Internet Gateways (IGW), NAT Gateways, Security Groups vs Network ACLs, Public vs Private Subnets, 3-Tier Enterprise Pattern | [VPC Guide](./aws-services/04-vpc/README.md) |
| **05. DynamoDB & RDS** | [`aws-services/05-dynamodb-rds/`](./aws-services/05-dynamodb-rds/) | DynamoDB NoSQL Model (Partition/Sort Keys, GSIs, On-Demand Scaling) vs RDS (PostgreSQL/MySQL/Aurora, Multi-AZ High Availability, Read Replicas, Automated Backups, Architectural Comparison) | [Databases Guide](./aws-services/05-dynamodb-rds/README.md) |

---

## 📸 Architecture & Evidence Diagrams
High-resolution visual reference cards are preserved in [`aws-services/screenshots/`](./aws-services/screenshots/):
1. `01-iam-governance.png`: IAM identity hierarchy, trust relationships, and policy structure.
2. `02-ec2-compute.png`: EC2 instance components, hypervisor, EBS, and security group integration.
3. `03-s3-storage.png`: S3 object storage tiers, lifecycle transitions, and encryption standards.
4. `04-vpc-networking.png`: 3-Tier VPC topology across Availability Zones with IGW, NAT, and Route Tables.
5. `05-dynamodb-rds.png`: Serverless NoSQL DynamoDB vs Multi-AZ Relational Amazon RDS comparison.

---

**Submitted by:** Sahasra ambati (`sahasra10241`)  
**Git Branch:** `devops-homework`