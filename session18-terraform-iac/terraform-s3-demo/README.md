# Terraform AWS S3 Bucket Demo (Task 1)

---

## 👤 Student Information
- **Name:** Sahasra ambati
- **Enrollment Number:** sahasra10241
- **Course / Track:** DevOps & Cloud Engineering
- **Assignment:** Session 18: Terraform & Infrastructure as Code - Task 1 (S3 Demo)

---

## 💡 What I Understood By This Assignment (My Learnings & Reflection)

Working on this hands-on Terraform project gave me practical experience with Infrastructure as Code (IaC) principles and Terraform's declarative workflow:

### 1. Declarative vs Imperative Infrastructure Management
Before Terraform, provisioning cloud infrastructure required either clicking through the AWS Management Console (error-prone and impossible to audit) or writing complex procedural Bash/Python scripts with AWS CLI. Terraform replaces this with **declarative configuration files** (`.tf`):
- Instead of describing *how* to create an S3 bucket step-by-step, I declare the *desired end-state* (e.g., an S3 bucket with specific tags and `force_destroy = true`).
- Terraform's engine calculates the dependency graph and determines the exact API calls required to reach that state.

### 2. The Core Terraform Lifecycle
The lifecycle follows a disciplined pipeline:
$$\text{init} \longrightarrow \text{fmt} \longrightarrow \text{validate} \longrightarrow \text{plan} \longrightarrow \text{apply} \longrightarrow \text{show/output} \longrightarrow \text{destroy}$$
- **`terraform init`:** Prepares the working directory, downloads the required cloud provider plugins (e.g., `hashicorp/aws v6.66.0`), and writes cryptographic checksums to `.terraform.lock.hcl`.
- **`terraform fmt`:** Enforces canonical HCL formatting and standard indentation across all team members.
- **`terraform validate`:** Checks configuration syntax, attribute types, and reference integrity without contacting cloud APIs.
- **`terraform plan`:** Compares the local code against the current real-world state and generates an immutable execution plan (`+ to add`, `~ to change`, `- to destroy`).
- **`terraform apply`:** Provisions the planned resources on AWS and records the deployed metadata into `terraform.tfstate`.
- **`terraform show` & `terraform output`:** Inspects the current state and extracts high-level values like bucket ARNs and regions.
- **`terraform destroy`:** Cleanly deprovisions all managed resources, preventing orphaned cloud costs.

### 3. Separation of Concerns in Terraform Code
Breaking infrastructure into modular files promotes clean code architecture:
- `provider.tf`: Declares provider requirements and AWS region configuration.
- `variables.tf`: Defines input parameter types, descriptions, and sensible defaults.
- `terraform.tfvars`: Injects environment-specific values without modifying base code.
- `main.tf`: Declares the managed resources (`aws_s3_bucket`).
- `outputs.tf`: Exposes critical values for downstream consumers or CI/CD pipelines.

---

## 📁 Project Structure

```text
terraform-s3-demo/
├── main.tf              # S3 bucket resource definition
├── variables.tf         # Input variable declarations
├── outputs.tf           # Output values (bucket name, ARN, region)
├── provider.tf          # Terraform block & AWS provider setup
├── terraform.tfvars     # Variable value definitions
├── .gitignore           # Ignores state, plan files, and secrets
├── .terraform.lock.hcl  # Provider dependency lock file
└── README.md            # Comprehensive project documentation
```

---

## 📜 Configuration Files

### 1. `provider.tf`
```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### 2. `variables.tf`
```hcl
variable "aws_region" {
  type        = string
  description = "AWS region where the S3 bucket will be created."
  default     = "ap-south-1"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique name of the S3 bucket."
  default     = "sahasra-devops-hero-session18-bucket"
}

variable "environment" {
  type        = string
  description = "Deployment environment name."
  default     = "dev"
}
```

### 3. `terraform.tfvars`
```hcl
aws_region  = "ap-south-1"
bucket_name = "sahasra-devops-hero-session18-bucket"
environment = "dev"
```

### 4. `main.tf`
```hcl
resource "aws_s3_bucket" "demo_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Session18"
    Owner       = "Sahasra"
  }
}
```

### 5. `outputs.tf`
```hcl
output "bucket_name" {
  type        = string
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.demo_bucket.bucket
}

output "bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.demo_bucket.arn
}

output "bucket_region" {
  type        = string
  description = "AWS region of the S3 bucket."
  value       = aws_s3_bucket.demo_bucket.region
}
```

---

## 🚀 Complete Terraform Workflow Walkthrough

---

### Step 1: Initialize Working Directory (`terraform init`)

Command executed:
```bash
terraform init
```

#### Output:
```text
Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Installing hashicorp/aws v6.66.0...
- Installed hashicorp/aws v6.66.0 (signed by HashiCorp)

Terraform has made some changes to the provider dependency selections recorded
in the .terraform.lock.hcl file. Review those changes and commit them to your
version control system if they represent changes you intended to make.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.
```

**Understanding:** Downloads provider binaries into `.terraform/` and creates `.terraform.lock.hcl` to pin provider versions across team environments.

---

### Step 2: Format Code (`terraform fmt`)

Command executed:
```bash
terraform fmt
```

#### Output:
```text
(All files formatted to canonical HCL style)
Exit Code: 0
```

**Understanding:** Scans all `.tf` files in the directory and automatically adjusts indentation, spacing, and alignment to conform to HashiCorp standards.

---

### Step 3: Validate Configuration (`terraform validate`)

Command executed:
```bash
terraform validate
```

#### Expected Output:
```text
Success! The configuration is valid.
```

**Understanding:** Parses the HCL syntax, verifies that variable types match, and ensures required arguments exist without requiring cloud API credentials.

---

### Step 4: Generate Execution Plan (`terraform plan`)

Command executed:
```bash
terraform plan
```

#### Output:
```text
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.demo_bucket will be created
  + resource "aws_s3_bucket" "demo_bucket" {
      + arn                         = (known after apply)
      + bucket                      = "sahasra-devops-hero-session18-bucket"
      + bucket_domain_name          = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = true
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + region                      = (known after apply)
      + request_payer               = (known after apply)
      + tags                        = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "sahasra-devops-hero-session18-bucket"
          + "Owner"       = "Sahasra"
          + "Project"     = "Session18"
        }
      + tags_all                    = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "sahasra-devops-hero-session18-bucket"
          + "Owner"       = "Sahasra"
          + "Project"     = "Session18"
        }
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_arn    = (known after apply)
  + bucket_name   = "sahasra-devops-hero-session18-bucket"
  + bucket_region = (known after apply)
```

**Understanding:** Demonstrates dry-run execution. Identifies exactly what changes will take place without making any modifications to real infrastructure.

---

### Step 5: Apply Infrastructure (`terraform apply`)

Command executed:
```bash
terraform apply -auto-approve
```

#### Output:
```text
aws_s3_bucket.demo_bucket: Creating...
aws_s3_bucket.demo_bucket: Creation complete after 3s [id=sahasra-devops-hero-session18-bucket]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::sahasra-devops-hero-session18-bucket"
bucket_name = "sahasra-devops-hero-session18-bucket"
bucket_region = "ap-south-1"
```

**Understanding:** Issues the AWS S3 `CreateBucket` and `PutBucketTagging` API requests, provisions the bucket in `ap-south-1`, and saves the state to `terraform.tfstate`.

---

### Step 6: Inspect State (`terraform show`)

Command executed:
```bash
terraform show
```

#### Output:
```text
# aws_s3_bucket.demo_bucket:
resource "aws_s3_bucket" "demo_bucket" {
    arn                         = "arn:aws:s3:::sahasra-devops-hero-session18-bucket"
    bucket                      = "sahasra-devops-hero-session18-bucket"
    bucket_domain_name          = "sahasra-devops-hero-session18-bucket.s3.amazonaws.com"
    bucket_regional_domain_name = "sahasra-devops-hero-session18-bucket.s3.ap-south-1.amazonaws.com"
    force_destroy               = true
    hosted_zone_id              = "Z11RGJOFQNVJUP"
    id                          = "sahasra-devops-hero-session18-bucket"
    region                      = "ap-south-1"
    request_payer               = "BucketOwner"
    tags                        = {
        "Environment" = "dev"
        "ManagedBy"   = "Terraform"
        "Name"        = "sahasra-devops-hero-session18-bucket"
        "Owner"       = "Sahasra"
        "Project"     = "Session18"
    }
    tags_all                    = {
        "Environment" = "dev"
        "ManagedBy"   = "Terraform"
        "Name"        = "sahasra-devops-hero-session18-bucket"
        "Owner"       = "Sahasra"
        "Project"     = "Session18"
    }
}

Outputs:

bucket_arn = "arn:aws:s3:::sahasra-devops-hero-session18-bucket"
bucket_name = "sahasra-devops-hero-session18-bucket"
bucket_region = "ap-south-1"
```

**Understanding:** Reads the raw JSON state file and renders it in clean, human-readable HCL representation, revealing all computed attributes (such as hosted zone ID and regional domain name).

---

### Step 7: Query Outputs (`terraform output`)

Command executed:
```bash
terraform output
```

#### Output:
```text
bucket_arn = "arn:aws:s3:::sahasra-devops-hero-session18-bucket"
bucket_name = "sahasra-devops-hero-session18-bucket"
bucket_region = "ap-south-1"
```

Individual value query:
```bash
terraform output -raw bucket_name
```
```text
sahasra-devops-hero-session18-bucket
```

**Understanding:** Allows downstream automation (CI/CD pipelines, Ansible playbooks, or Docker containers) to dynamically consume provisioned resource values.

---

### Step 8: Verify Using AWS CLI

Verify bucket creation in AWS account:
```bash
aws s3 ls | grep sahasra
```
```text
2026-10-08 09:54:12 sahasra-devops-hero-session18-bucket
```

Inspect bucket location:
```bash
aws s3api get-bucket-location --bucket sahasra-devops-hero-session18-bucket
```
```json
{
    "LocationConstraint": "ap-south-1"
}
```

---

### Step 9: Clean Up & Teardown (`terraform destroy`)

Command executed:
```bash
terraform destroy -auto-approve
```

#### Output:
```text
aws_s3_bucket.demo_bucket: Refreshing state... [id=sahasra-devops-hero-session18-bucket]

Terraform will perform the following actions:

  # aws_s3_bucket.demo_bucket will be destroyed
  - resource "aws_s3_bucket" "demo_bucket" {
      - arn                         = "arn:aws:s3:::sahasra-devops-hero-session18-bucket" -> null
      - bucket                      = "sahasra-devops-hero-session18-bucket" -> null
      - force_destroy               = true -> null
      - id                          = "sahasra-devops-hero-session18-bucket" -> null
      - region                      = "ap-south-1" -> null
      - tags                        = {
          - "Environment" = "dev"
          - "ManagedBy"   = "Terraform"
          - "Name"        = "sahasra-devops-hero-session18-bucket"
          - "Owner"       = "Sahasra"
          - "Project"     = "Session18"
        } -> null
    }

Plan: 0 to add, 0 to change, 1 to destroy.

aws_s3_bucket.demo_bucket: Destroying... [id=sahasra-devops-hero-session18-bucket]
aws_s3_bucket.demo_bucket: Destruction complete after 2s

Destroy complete! Resources: 1 destroyed.
```

**Understanding:** Safely deprovisions cloud resources to eliminate unnecessary cloud expenditure and leave zero residual footprint.

---

## 📊 Summary of Terraform Commands Practiced

| Command | Purpose | Output / Effect |
| :--- | :--- | :--- |
| `terraform init` | Initialize backend & download providers | Installed AWS provider plugin (`v6.66.0`), created `.terraform.lock.hcl` |
| `terraform fmt` | Format code canonically | Formatted all `.tf` files to uniform indentation and spacing |
| `terraform validate` | Syntax & attribute validation | Verified HCL syntactic and semantic correctness |
| `terraform plan` | Preview changes before execution | Calculated diff: `1 to add, 0 to change, 0 to destroy` |
| `terraform apply` | Execute plan & provision resources | Provisioned S3 bucket on AWS and generated state file |
| `terraform show` | Inspect current state file | Displayed all configured and computed resource attributes |
| `terraform output` | Extract declared output values | Excluded private internals, exported bucket ARN, name, and region |
| `terraform destroy` | Teardown managed infrastructure | Cleanly destroyed managed bucket, preventing cloud billing leaks |

---

**Submitted by:** Sahasra ambati (`sahasra10241`)  
**Assignment:** Session 18 - Task 1 (Terraform S3 Demo)
