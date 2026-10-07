# Session 18 - Terraform & Infrastructure as Code

- **Student:** Antara Utane
- **Enrollment No.:** 24BCS10106
- **Session:** 18 - Terraform & IaC

## Task Checklist

- [x] **Task 1** - [`terraform-s3-demo/`](terraform-s3-demo/README.md): S3 bucket with versioning, encryption,
  public access block and tags; real output of `init`, `fmt`, `validate`, `plan`, `apply`, `show`, `output`,
  AWS CLI verification and `destroy`
- [x] **Task 2** - AWS core services notes in [`aws-services/`](aws-services/):
  - [x] [`01-iam`](aws-services/01-iam/README.md) - users, groups, roles, policies, permissions, least privilege, best practices, use cases
  - [x] [`02-ec2`](aws-services/02-ec2/README.md) - AMI, instance types, key pairs, SGs, EBS, public vs private IP, lifecycle, use cases
  - [x] [`03-s3`](aws-services/03-s3/README.md) - buckets, objects, storage classes, versioning, lifecycle, encryption, bucket policies, use cases
  - [x] [`04-vpc`](aws-services/04-vpc/README.md) - CIDR, subnets, route tables, IGW, NAT GW, SGs, NACLs, public vs private subnet, mermaid diagram
  - [x] [`05-dynamodb-rds`](aws-services/05-dynamodb-rds/README.md) - DynamoDB (keys, items, attributes) and RDS (engines, security, backups, Multi-AZ, replicas)

## Environment note

No real AWS account was used. All `terraform apply`/`destroy` runs and AWS CLI commands were executed against
**LocalStack 3.8 (community edition)**, a local AWS emulator at `http://localhost:4566`. The Terraform
provider is configured so that setting `use_localstack = false` targets real AWS with the same code. RDS is not
available in LocalStack community, so the RDS section is theory + an unapplied Terraform snippet.

`.gitignore` in this folder excludes `.terraform/`, `*.tfstate*`, `*.tfplan` and crash logs;
`.terraform.lock.hcl` is committed.
