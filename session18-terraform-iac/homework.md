# Session 18: Terraform & Infrastructure as Code

## Task 1: Terraform S3 Demo

**Name:** Ankita Tripathi  
**Roll Number:** 24BCS10062  
**Session:** 18  
**Topic:** Terraform & Infrastructure as Code (IaC)

---

## Objective

The objective of this task was to understand the fundamentals of **Infrastructure as Code (IaC)** using Terraform and provision an AWS resource through Terraform configuration files.

In this project, I created and managed an **Amazon S3 bucket using Terraform** and performed the complete Terraform workflow including:

- Initialization
- Formatting
- Configuration validation
- Execution planning
- Infrastructure creation
- State inspection
- Output retrieval
- Infrastructure destruction

The complete lifecycle of the infrastructure was managed using Terraform rather than manually creating the resource from the AWS Management Console.

---

## What is Infrastructure as Code?

Infrastructure as Code (IaC) is the practice of defining and managing infrastructure using configuration files instead of manually configuring resources.

With IaC, infrastructure such as servers, storage, databases, and networks can be created and managed in a repeatable and automated way.

Some major advantages of Infrastructure as Code are:

- Automation
- Repeatability
- Version control
- Consistency
- Reduced manual errors
- Faster infrastructure provisioning
- Easier infrastructure management
- Reproducible environments

---

## What is Terraform?

Terraform is an Infrastructure as Code tool developed by HashiCorp.

Terraform allows infrastructure to be defined using **HashiCorp Configuration Language (HCL)**. It communicates with cloud platforms through providers and creates or modifies resources according to the desired configuration.

In this project, Terraform was used with the **AWS Provider** to provision an Amazon S3 bucket.

---

## Technologies Used

| Technology | Purpose |
|---|---|
| Terraform | Infrastructure as Code |
| AWS | Cloud platform |
| Amazon S3 | Object storage service |
| AWS Provider | Allows Terraform to communicate with AWS |
| AWS CLI | AWS authentication and configuration |
| HCL | Terraform configuration language |
| VS Code | Development environment |
| Git | Version control |

---

## Project Structure

The Terraform project was organized as follows:

```text
terraform-s3-demo/
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
├── terraform.tfvars
├── README.md
├── .gitignore
├── .terraform.lock.hcl
└── .terraform/
```

The `.terraform/` directory is automatically generated after running `terraform init` and should normally not be committed to Git.

---

# Terraform Configuration Files

## 1. provider.tf

The `provider.tf` file configures the AWS provider used by Terraform.

Example:

```hcl
provider "aws" {
  region = var.aws_region
}
```

The AWS provider allows Terraform to communicate with AWS APIs and create the required cloud resources.

For this project, the AWS region used was:

```text
ap-south-1
```

which corresponds to the AWS Mumbai region.

---

## 2. variables.tf

The `variables.tf` file defines variables used by the Terraform configuration.

Using variables makes the Terraform configuration reusable and prevents values from being unnecessarily hardcoded throughout the project.

Example:

```hcl
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}
```

---

## 3. terraform.tfvars

The `terraform.tfvars` file contains values assigned to the variables declared in `variables.tf`.

Example:

```hcl
aws_region  = "ap-south-1"
bucket_name = "yatri01"
```

Terraform automatically reads values from this file while executing commands.

---

## 4. main.tf

The `main.tf` file contains the main infrastructure resource definition.

The primary resource created in this project was an **AWS S3 bucket**.

Example structure:

```hcl
resource "aws_s3_bucket" "yatri01" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name        = var.bucket_name
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "Session18"
  }
}
```

The resource is managed completely by Terraform.

The `force_destroy` option allows Terraform to remove the bucket even if objects exist inside it.

Tags were also added to identify and organize the resource.

---

## 5. outputs.tf

The `outputs.tf` file defines useful information that Terraform displays after successfully creating the infrastructure.

The project exposes information such as:

- S3 bucket name
- S3 bucket ARN
- AWS region

Example:

```hcl
output "bucket_name" {
  value = aws_s3_bucket.yatri01.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.yatri01.arn
}

output "bucket_region" {
  value = var.aws_region
}
```

---

# Complete Terraform Workflow

## Step 1: Configure AWS CLI

Before Terraform could communicate with AWS, AWS credentials were configured using the AWS CLI.

Command:

```bash
aws configure
```

The AWS CLI requests:

```text
AWS Access Key ID
AWS Secret Access Key
Default region name
Default output format
```

The default AWS region was configured as:

```text
ap-south-1
```

### Security Note

AWS credentials must never be stored directly inside Terraform configuration files or committed to a Git repository.

Sensitive credentials and secret access keys are not included in this README or repository.

---

## Step 2: Initialize Terraform

Command:

```bash
terraform init
```

`terraform init` initializes the Terraform working directory.

It performs operations such as:

- Initializing the backend
- Downloading required providers
- Installing provider plugins
- Creating/updating the dependency lock file
- Preparing the directory for Terraform operations

During this project, Terraform successfully installed the AWS provider.

Result:

```text
Terraform has been successfully initialized!
```

This confirmed that the project was ready for further Terraform commands.

---

## Step 3: Format Terraform Files

Command:

```bash
terraform fmt
```

`terraform fmt` automatically formats Terraform configuration files according to Terraform's standard formatting conventions.

This helps maintain:

- Consistent indentation
- Clean configuration files
- Better readability
- Standard Terraform formatting

The command completed successfully.

---

## Step 4: Validate Configuration

Command:

```bash
terraform validate
```

This command checks whether the Terraform configuration is syntactically valid and internally consistent.

Result:

```text
Success! The configuration is valid.
```

This confirmed that the Terraform files contained a valid configuration.

---

## Step 5: Generate Terraform Plan

Command:

```bash
terraform plan
```

`terraform plan` creates an execution plan showing what Terraform intends to change before any infrastructure is actually modified.

The plan indicated that Terraform would create the configured S3 bucket.

Terraform represented the action using:

```text
+ create
```

The plan showed the S3 resource:

```text
aws_s3_bucket.yatri01
```

and displayed its configured properties, including:

```text
bucket = "yatri01"
region = "ap-south-1"
force_destroy = true
```

Tags configured for the bucket included:

```text
Environment = "dev"
ManagedBy   = "Terraform"
Name        = "yatri01"
Project     = "Session18"
```

This allowed the proposed infrastructure changes to be reviewed before applying them.

---

## Step 6: Apply Terraform Configuration

Command:

```bash
terraform apply
```

`terraform apply` executes the Terraform configuration and creates the infrastructure described in the project.

Terraform first displayed the proposed execution plan and requested confirmation before creating the resource.

After confirmation, Terraform created the S3 bucket successfully.

Result:

```text
aws_s3_bucket.yatri01: Creating...
aws_s3_bucket.yatri01: Creation complete

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

This confirmed that one AWS resource was successfully provisioned using Terraform.

---

# Created Infrastructure

The following resource was successfully created:

| Property | Value |
|---|---|
| Resource | Amazon S3 Bucket |
| Terraform Resource | `aws_s3_bucket.yatri01` |
| Bucket Name | `yatri01` |
| Region | `ap-south-1` |
| Environment | `dev` |
| Managed By | Terraform |
| Project | Session18 |

Terraform also returned the configured output values after creation.

Example:

```text
bucket_arn    = "arn:aws:s3:::yatri01"
bucket_name   = "yatri01"
bucket_region = "ap-south-1"
```

---

## Step 7: Inspect Terraform State

Command:

```bash
terraform show
```

`terraform show` displays the resources currently recorded in the Terraform state.

It can be used to inspect detailed information about the infrastructure managed by Terraform.

After creating the S3 bucket, this command was used to inspect the provisioned infrastructure and its attributes.

---

## Step 8: Display Terraform Outputs

Command:

```bash
terraform output
```

`terraform output` displays the values declared inside `outputs.tf`.

The project outputs included:

```text
bucket_arn
bucket_name
bucket_region
```

These outputs provide useful information about the infrastructure without requiring manual inspection of the Terraform state.

---

# Terraform State

Terraform maintains information about managed infrastructure in its state.

The state allows Terraform to map resources defined in configuration files to actual resources created in AWS.

It enables Terraform to determine whether infrastructure should be:

```text
Created
Updated
Replaced
Destroyed
```

Terraform state is therefore an important part of infrastructure lifecycle management.

---

# Resource Destruction

After successfully creating and verifying the S3 bucket, the resource was removed to complete the full infrastructure lifecycle.

## Optional Destroy Plan Verification

Before destroying the resource, the destruction plan was inspected using:

```bash
terraform plan -destroy
```

Terraform showed:

```text
- destroy
```

and identified:

```text
aws_s3_bucket.yatri01
```

as the resource that would be removed.

The plan summary showed:

```text
Plan: 0 to add, 0 to change, 1 to destroy.
```

This provided an opportunity to verify the destructive action before executing it.

---

## Step 9: Destroy Infrastructure

Command:

```bash
terraform destroy
```

Terraform displayed all resources scheduled for deletion and requested confirmation.

After entering:

```text
yes
```

Terraform removed the S3 bucket.

Result:

```text
aws_s3_bucket.yatri01: Destroying...
aws_s3_bucket.yatri01: Destruction complete

Destroy complete! Resources: 1 destroyed.
```

This confirmed that the AWS resource was successfully removed and that the complete Terraform lifecycle had been performed.

---

# Complete Workflow Summary

The complete workflow performed in this project was:

```text
Configure AWS Credentials
        ↓
terraform init
        ↓
terraform fmt
        ↓
terraform validate
        ↓
terraform plan
        ↓
terraform apply
        ↓
S3 Bucket Created
        ↓
terraform show
        ↓
terraform output
        ↓
Verify Infrastructure
        ↓
terraform plan -destroy
        ↓
terraform destroy
        ↓
S3 Bucket Destroyed
```

---

# Terraform Commands Summary

| Command | Purpose | Status |
|---|---|---|
| `aws configure` | Configure AWS CLI credentials and region | Completed |
| `terraform init` | Initialize Terraform project and providers | Completed |
| `terraform fmt` | Format Terraform configuration files | Completed |
| `terraform validate` | Validate Terraform configuration | Completed |
| `terraform plan` | Preview infrastructure changes | Completed |
| `terraform apply` | Create the AWS infrastructure | Completed |
| `terraform show` | Inspect Terraform state/resources | Completed |
| `terraform output` | Display configured output values | Completed |
| `terraform plan -destroy` | Preview resource destruction | Completed |
| `terraform destroy` | Destroy Terraform-managed resources | Completed |

---

# Screenshots / Execution Evidence

Screenshots of the Terraform execution have been submitted **separately** as part of the assignment deliverables.

The screenshots provide execution evidence for the workflow, including:

- AWS/Terraform environment setup
- `terraform init`
- `terraform fmt`
- `terraform validate`
- `terraform plan`
- S3 bucket creation plan
- `terraform apply`
- Successful resource creation
- Terraform outputs
- Destroy plan
- `terraform destroy`
- Successful resource destruction

Screenshots are intentionally not embedded inside this README and are provided separately with the submission.

---

# Security Practices Followed

The following security practices are important when using Terraform with AWS:

1. AWS Secret Access Keys should never be committed to Git.
2. Credentials should not be hardcoded inside `.tf` files.
3. Sensitive `.tfvars` files should be excluded from public repositories when they contain secrets.
4. `.terraform/` should normally not be committed because Terraform can recreate it using `terraform init`.
5. IAM permissions should follow the principle of least privilege.
6. Secrets should be rotated immediately if accidentally exposed.
7. Terraform state should be protected because state files may contain sensitive infrastructure information.

Example `.gitignore`:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
crash.log
crash.*.log
*.tfplan
```

If `.tfvars` contains secrets, it should also be ignored:

```gitignore
*.tfvars
```

---

# Key Learnings

Through this task, I learned how Terraform can be used to manage AWS infrastructure through code.

I gained hands-on experience with:

- Infrastructure as Code concepts
- Terraform project structure
- Terraform providers
- Terraform resources
- Terraform variables
- Terraform outputs
- Terraform state
- AWS authentication
- AWS S3 provisioning
- Terraform execution plans
- Infrastructure creation
- Infrastructure inspection
- Infrastructure destruction
- Resource tagging
- Basic cloud security practices

The most important concept demonstrated by this project is that the **entire lifecycle of a cloud resource can be managed through code**.

Instead of manually creating and deleting an S3 bucket through the AWS Console, Terraform was able to define, preview, create, inspect, and destroy the infrastructure in a controlled and repeatable manner.

---

# Final Result

The Terraform S3 demo was completed successfully.

An Amazon S3 bucket was:

```text
Defined using Terraform
        ↓
Validated
        ↓
Planned
        ↓
Created successfully
        ↓
Inspected
        ↓
Outputs retrieved
        ↓
Destroy plan verified
        ↓
Destroyed successfully
```

Final Terraform destruction result:

```text
Destroy complete! Resources: 1 destroyed.
```

This successfully demonstrates the complete Terraform Infrastructure as Code workflow on AWS.

---

## Assignment Deliverables

- [x] `main.tf`
- [x] `variables.tf`
- [x] `outputs.tf`
- [x] `provider.tf`
- [x] `terraform.tfvars`
- [x] `README.md`
- [x] Terraform initialization
- [x] Terraform formatting
- [x] Terraform validation
- [x] Terraform plan
- [x] Terraform apply
- [x] AWS S3 bucket creation
- [x] Terraform show
- [x] Terraform outputs
- [x] Terraform destroy
- [x] Execution screenshots submitted separately

---

**Name:** Ankita Tripathi  
**Roll Number:** 24BCS10062  
**Session:** 18 - Terraform & Infrastructure as Code