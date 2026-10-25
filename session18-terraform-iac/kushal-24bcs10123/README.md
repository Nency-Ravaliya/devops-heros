# Session 18 – Terraform & Infrastructure as Code

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123  
**Environment:** Terraform v1.16.4 (hashicorp/aws provider v6.67.0), AWS CLI 2.32, macOS / Apple Silicon. Target: **LocalStack 4.0.3** (AWS API emulator, community edition) in Docker Desktop 29.0.1 at `http://localhost:4566`.

> **Why LocalStack and not real AWS.** The AWS access key on this laptop is rejected (`aws sts get-caller-identity` → `InvalidClientTokenId`, see [logs/00-why-localstack.txt](logs/00-why-localstack.txt)) and I do not have an AWS account with billing set up. So every `terraform apply` in this session and in session 19 runs against LocalStack, which speaks the real AWS API on `localhost:4566`. The Terraform code is unchanged real-AWS code: the only LocalStack-specific lines are in `provider.tf`, switched on by a single variable from `localstack.tfvars`. Without that var-file the same project talks to `amazonaws.com` – and fails on the bad credentials, which I also logged.

Every command was really run; the unedited output is in [`logs/`](logs) and the exact commands are in [`scripts/`](scripts).

```text
kushal-24bcs10123/
├── README.md                          # this write-up
├── terraform-s3-demo/                 # Task 1 - S3 bucket with Terraform
│   ├── terraform.tf                   #   required_version + required_providers
│   ├── provider.tf                    #   provider "aws" (LocalStack switch inside)
│   ├── variables.tf  terraform.tfvars #   inputs + safe default values
│   ├── localstack.tfvars              #   aws_endpoint_url = http://localhost:4566
│   ├── main.tf  outputs.tf            #   5 resources, 6 outputs
│   ├── .gitignore                     #   .terraform/, *.tfstate*, plans
│   └── README.md                      #   complete workflow with output
├── aws-services/                      # Task 2 - study notes, one README per service
│   ├── 01-iam/README.md  (+ least-privilege-policy.json, ec2-trust-policy.json)
│   ├── 02-ec2/README.md
│   ├── 03-s3/README.md   (+ lifecycle.json, bucket-policy.json)
│   ├── 04-vpc/README.md
│   └── 05-dynamodb-rds/README.md
├── scripts/
│   ├── lib.sh                         # helpers: x(), hr(), awsl (aws --endpoint-url), tf
│   ├── 00-why-localstack.sh           # real AWS rejects the key; LocalStack health
│   ├── 01-terraform-s3-workflow.sh    # init → fmt → validate → plan → apply → show → output → verify → destroy
│   └── 02-aws-services-hands-on.sh    # IAM / EC2 / S3 / VPC / DynamoDB / RDS API calls behind the notes
├── logs/                              # one .txt per script, raw output
└── screenshots/
```

## 0. The setup

Log: [logs/00-why-localstack.txt](logs/00-why-localstack.txt)

```text
$ aws sts get-caller-identity --region ap-south-1
An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.

$ terraform plan        # no -var-file -> real AWS endpoints
Error: Retrieving AWS account details: validating provider credentials: retrieving caller identity from STS:
  operation error STS: GetCallerIdentity, https response error StatusCode: 403, api error InvalidClientTokenId

$ docker ps --filter name=localstack-kushal
NAMES               IMAGE                         STATUS                   PORTS
localstack-kushal   localstack/localstack:4.0.3   Up 4 minutes (healthy)   0.0.0.0:4566->4566/tcp

$ aws --endpoint-url=http://localhost:4566 sts get-caller-identity
{ "UserId": "AKIAIOSFODNN7EXAMPLE", "Account": "000000000000", "Arn": "arn:aws:iam::000000000000:root" }
```

LocalStack accepts any access key (I use `test`/`test` from the environment) and always reports account `000000000000`. In the scripts `awsl` is just `aws --endpoint-url=http://localhost:4566`.

## 1. Task 1 – Terraform S3 demo

Full write-up with every step's output: [terraform-s3-demo/README.md](terraform-s3-demo/README.md). Log: [logs/01-terraform-s3-workflow.txt](logs/01-terraform-s3-workflow.txt).

| Step | Command | Result |
|---|---|---|
| 1 | `terraform init` | provider `hashicorp/aws v6.67.0` installed (from a shared plugin cache, the binary is ~700 MB) |
| 2 | `terraform fmt -recursive -diff` | no diff, exit 0 |
| 3 | `terraform validate` | `Success! The configuration is valid.` |
| 4 | `terraform plan -var-file=localstack.tfvars -out=tfplan` | `Plan: 5 to add, 0 to change, 0 to destroy.` |
| 5 | `terraform apply tfplan` | `Apply complete! Resources: 5 added` |
| 6 | `terraform show` / `state list` / `state show` | bucket, versioning, SSE, public-access-block, object |
| 7 | `terraform output` | `bucket_arn = "arn:aws:s3:::kushal-24bcs10123-s18-demo"` … |
| 8 | `aws s3 ls`, `get-bucket-versioning`, `get-bucket-encryption`, `get-public-access-block` | the bucket really exists with versioning `Enabled`, `AES256`, all four public blocks `true` |
| 9 | re-`plan` after a manual upload | Terraform ignores objects it does not manage |
| 10 | `plan -var environment=staging` | `Plan: 0 to add, 1 to change, 0 to destroy.` (tag update in place) |
| 11 | `terraform destroy` | `Destroy complete! Resources: 5 destroyed.` – `aws s3 ls` empty, state empty |

## 2. Task 2 – AWS services research

Each service has its own README written as my study notes, with the hands-on calls from [logs/02-aws-services-hands-on.txt](logs/02-aws-services-hands-on.txt):

| Folder | Covers | Hands-on backing it |
|---|---|---|
| [aws-services/01-iam](aws-services/01-iam/README.md) | users, groups, roles, policies, permissions, least privilege, best practices, use cases | created a user + group, a least-privilege managed policy, an EC2 trust-policy role, an access key |
| [aws-services/02-ec2](aws-services/02-ec2/README.md) | AMI, instance types, key pairs, security groups, EBS, public vs private IP, lifecycle, use cases | describe-images / instance-types, key pair, SG rules, run → stop → start → terminate, gp3 volume attach/detach |
| [aws-services/03-s3](aws-services/03-s3/README.md) | buckets, objects, storage classes, versioning, lifecycle, encryption, bucket policies, use cases | objects in STANDARD / STANDARD_IA / GLACIER, lifecycle rule, TLS-only bucket policy, presigned URL |
| [aws-services/04-vpc](aws-services/04-vpc/README.md) | CIDR, subnets, route tables, IGW, NAT, SG, NACL, public vs private subnet | looked at LocalStack's default VPC: 3 subnets, route table, default NACL (full build is session 19) |
| [aws-services/05-dynamodb-rds](aws-services/05-dynamodb-rds/README.md) | DynamoDB: NoSQL, tables, items, attributes, partition/sort key; RDS: engines, instances, security, backups, Multi-AZ, read replicas | table with partition + sort key, put/get/query/scan; RDS API is Pro-only in LocalStack, call + error shown |

## What I understood

* **Terraform's loop is always the same**: `init` (get providers) → `plan` (diff desired vs state vs real) → `apply` (make real match desired, record in state) → `destroy`. `fmt` and `validate` are free checks before any API call.
* **State is the memory.** Terraform only knows what is in `terraform.tfstate`; an object I uploaded by hand was invisible to it, and LocalStack losing the tags showed up as a change the next plan wanted to make. That is why state is kept remote and locked in a team.
* **Provider config is the only cloud-specific part.** Moving the same code from LocalStack to AWS is dropping one var-file; the resource blocks never change – that is the point of IaC.
* **IAM / VPC / EC2 / S3 / databases are the vocabulary** the Terraform resources map to one-to-one (`aws_vpc`, `aws_subnet`, `aws_security_group`, `aws_instance`, `aws_s3_bucket`), which is what session 19 builds end to end.

## Checklist

- [x] `terraform-s3-demo/` with `main.tf`, `variables.tf`, `outputs.tf`, `provider.tf`, `terraform.tfvars`, `README.md`
- [x] S3 bucket created with Terraform (+ versioning, encryption, public access block, tags, one object)
- [x] `init`, `fmt`, `validate`, `plan`, `apply`, `show`, `output`, `destroy` all run and logged
- [x] Complete workflow documented in `terraform-s3-demo/README.md`
- [x] `aws-services/01-iam … 05-dynamodb-rds` each with a README covering every bullet of the assignment
- [x] Stated plainly that the target was LocalStack because the real AWS credentials are invalid
