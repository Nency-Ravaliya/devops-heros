# 03 - Providers

A provider is a plugin that lets Terraform interact with an external API.

For AWS:

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

The AWS provider is maintained by HashiCorp and manages AWS services including S3, EC2, VPC, EKS, ECS and more.
## Provider Source

```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 6.0"
  }
}
```

The important parts are:

```text
aws
│
├── namespace: hashicorp
├── type: aws
└── version constraint: ~> 6.0
```

## Authentication

```bash
aws configure
```

Check:

```bash
aws sts get-caller-identity
```

Do not put access keys directly inside:

```hcl
provider "aws" {
  access_key = "..."
  secret_key = "..."
}
```

Credentials in configuration can expose secrets when code is committed to version control. 

## Commands

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

## Expected init output

Provider versions may differ, so the exact output will not be identical.

```text
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 6.0"...
- Installing hashicorp/aws v6.x.x...
- Installed hashicorp/aws v6.x.x...

Terraform has been successfully initialized!
```

## Expected plan

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

## Apply

```bash
terraform apply
```

Type:

```text
yes
```

Expected final output:

```text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

bucket_id = "session18-provider-xxxxxxxx"
```

## Cleanup

```bash
terraform destroy
```
