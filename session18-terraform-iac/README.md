# Session 18: Terraform & Infrastructure as Code (IaC)

**Name:** Durga Prasad  
**Enrollment Number:** 10012  
**Course:** SST DevOps & Cloud [SWE]  
**Session:** 18 - Infrastructure as Code & Terraform  
**Repository:** devops-heros / session18-terraform-iac  

---

## Executive Summary

Manually clicking through the AWS Web Console to provision servers, storage buckets, and networks is slow, impossible to audit, prone to human error, and fails to reproduce environments reliably.

**Infrastructure as Code (IaC)** treats cloud infrastructure with the same rigor as application source code: version-controlled, modular, tested, and automated.

**HashiCorp Terraform** is the industry-standard declarative IaC tool. You define the *desired end state* using HashiCorp Configuration Language (HCL), and Terraform calculates the delta required to provision, modify, or destroy infrastructure across any cloud provider.

```
                           TERRAFORM WORKFLOW LIFECYCLE
                                                                               
   ┌───────────────────────┐                                                   
   │    Terraform Code     │ (main.tf, variables.tf, terraform.tfvars)          
   └───────────┬───────────┘                                                   
               │                                                               
               ▼                                                               
       terraform init      ──► Downloads cloud provider plugins (hashicorp/aws)
               │                                                               
               ▼                                                               
       terraform plan      ──► Compares code against real cloud state (etcd/state)
               │               Calculates Execution Plan (+Create, ~Modify, -Destroy)
               ▼                                                               
       terraform apply     ──► Provisions real cloud infrastructure via AWS APIs
               │               Updates terraform.tfstate (Source of truth)     
               ▼                                                               
      terraform destroy    ──► Safely deprovisions all resources                     
```

---

## Assignment Tasks & Deliverables

### Task 1: Terraform S3 Demo Project
Located in [`terraform-s3-demo/`](./terraform-s3-demo/):
* [`main.tf`](./terraform-s3-demo/main.tf): Declares `aws_s3_bucket` with random ID suffix and resource tags.
* [`variables.tf`](./terraform-s3-demo/variables.tf): Parameterizes AWS region, environment, bucket prefix, and metadata tags.
* [`providers.tf`](./terraform-s3-demo/providers.tf): Configures AWS provider and default region.
* [`terraform.tf`](./terraform-s3-demo/terraform.tf): Declares required providers (`hashicorp/aws` and `hashicorp/random`).
* [`terraform.tfvars`](./terraform-s3-demo/terraform.tfvars): Environment variable values.
* [`outputs.tf`](./terraform-s3-demo/outputs.tf): Exports bucket ID, ARN, and regional domain name.
* [`README.md`](./terraform-s3-demo/README.md): Step-by-step verification commands (`init`, `fmt`, `validate`, `plan`, `apply`, `show`, `output`, `destroy`).

#### Execution Commands Walkthrough:
```bash
# 1. Initialize working directory
terraform init

# 2. Canonical formatting & syntax validation
terraform fmt
terraform validate

# 3. Speculative execution plan
terraform plan

# 4. Provision infrastructure
terraform apply -auto-approve

# 5. Inspect state and outputs
terraform show
terraform output

# 6. Teardown resources
terraform destroy -auto-approve
```

---

### Task 2: In-Depth AWS Cloud Services Research
Located in [`aws-services/`](./aws-services/):

| Directory | Topic & Coverage |
|---|---|
| [`01-iam/`](./aws-services/01-iam/README.md) | **Identity and Access Management:** Users, Groups, Roles, Policies, Permissions, Principle of Least Privilege, OIDC integration, Security Best Practices |
| [`02-ec2/`](./aws-services/02-ec2/README.md) | **Elastic Compute Cloud:** AMIs, Instance Types/Families, Key Pairs, Stateful Security Groups, EBS gp3/io2 block storage, Public vs Private IP, Instance Lifecycle |
| [`03-s3/`](./aws-services/03-s3/README.md) | **Simple Storage Service:** Buckets, 5 TB Objects, Storage Classes (Standard, Intelligent-Tiering, Glacier), Versioning & Delete Markers, Lifecycle Rules, SSE Encryption, Bucket Policies |
| [`04-vpc/`](./aws-services/04-vpc/README.md) | **Virtual Private Cloud:** CIDR allocation, Public vs Private Subnets, Internet Gateways (IGW), NAT Gateways, Route Tables, Stateful Security Groups vs Stateless NACLs |
| [`05-dynamodb-rds/`](./aws-services/05-dynamodb-rds/README.md) | **Database Services:** DynamoDB serverless NoSQL (Partition/Sort keys, On-Demand mode) vs Amazon RDS relational SQL (Multi-AZ synchronous failover, Read Replicas, PITR backups) |

---

## Summary of Deliverables

| Deliverable | Status | Location |
|---|---|---|
| **Terraform S3 Project** | Completed | [`terraform-s3-demo/`](./terraform-s3-demo/) |
| **All Terraform Manifests** | Completed | `main.tf`, `variables.tf`, `providers.tf`, `terraform.tf`, `terraform.tfvars`, `outputs.tf` |
| **IAM Research Guide** | Completed | [`aws-services/01-iam/README.md`](./aws-services/01-iam/README.md) |
| **EC2 Research Guide** | Completed | [`aws-services/02-ec2/README.md`](./aws-services/02-ec2/README.md) |
| **S3 Research Guide** | Completed | [`aws-services/03-s3/README.md`](./aws-services/03-s3/README.md) |
| **VPC Research Guide** | Completed | [`aws-services/04-vpc/README.md`](./aws-services/04-vpc/README.md) |
| **DynamoDB & RDS Guide** | Completed | [`aws-services/05-dynamodb-rds/README.md`](./aws-services/05-dynamodb-rds/README.md) |
| **Master Documentation** | Completed | [`README.md`](./README.md) |
