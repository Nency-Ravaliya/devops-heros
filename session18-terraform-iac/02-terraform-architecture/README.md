# 02 - Terraform Architecture

Think of Terraform as a translator between configuration and infrastructure.

```text
                 Terraform Configuration
                         |
                         v
                +------------------+
                | Terraform CLI    |
                +------------------+
                         |
                 Provider Plugin
                         |
                         v
                +------------------+
                |   AWS Provider   |
                +------------------+
                         |
                         v
                +------------------+
                |       AWS        |
                | S3 / EC2 / VPC   |
                +------------------+

             Terraform State
                    |
                    v
          terraform.tfstate
```

## Main Components

### 1. Terraform Configuration

Written in HashiCorp Configuration Language (HCL).

```hcl
resource "aws_s3_bucket" "architecture_demo" {
  bucket_prefix = "session18-architecture-"
}
```

### 2. Terraform CLI

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

### 3. Provider

A provider allows Terraform to communicate with an external API.

Examples:

- AWS
- Azure
- Google Cloud
- Kubernetes
- GitHub

### 4. Resource

A resource represents infrastructure managed by Terraform.

```hcl
resource "aws_s3_bucket" "architecture_demo" {
  bucket_prefix = "session18-architecture-"
}
```

### 5. State

Terraform records managed infrastructure in state.

```text
Configuration
      +
   State
      +
  Real World
      |
      v
 Terraform Plan
```

## Run the Example

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Expected:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

After approval:

```text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::session18-architecture-xxxxxxxx"
```

## Inspect

```bash
terraform state list
terraform show
```

## Cleanup

```bash
terraform destroy
```

## Important Idea

Terraform is declarative.

You describe **what you want**, not every API call required to create it.
