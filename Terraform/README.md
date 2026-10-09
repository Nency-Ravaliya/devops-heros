# Session 18: Terraform & Infrastructure as Code

> 📸 **Screenshots:** the terminal images are **real screenshots of my terminal window** (Git Bash on Windows 11) taken while I re-ran the same Terraform workflow locally against **Moto** (the AWS API emulator, running in Docker on `localhost:5000`) - the same setup the pipeline uses. Generated IDs (bucket suffix, instance/VPC IDs) therefore differ from the *Text output (original run)* sections, which keep the output from my first run. The GitHub Actions images are real browser screenshots of the run pages.

**Name:** Tejas Varshney

| Task | Where |
|---|---|
| 1. Terraform S3 demo | [terraform-s3-demo/](terraform-s3-demo) (`main.tf`, `variables.tf`, `outputs.tf`, `provider.tf`, `terraform.tfvars`) |
| 2. AWS services research | [aws-services/](aws-services): [01-iam](aws-services/01-iam/README.md) · [02-ec2](aws-services/02-ec2/README.md) · [03-s3](aws-services/03-s3/README.md) · [04-vpc](aws-services/04-vpc/README.md) · [05-dynamodb-rds](aws-services/05-dynamodb-rds/README.md) |
| Pipeline that ran the workflow | [.github/workflows/terraform-sessions-18-19.yml](../.github/workflows/terraform-sessions-18-19.yml) |
| Raw command output | [terraform-s3-demo/outputs/](terraform-s3-demo/outputs) |

---

## Task 1 – Terraform S3 demo

### Project structure

```
terraform-s3-demo/
├── provider.tf        # terraform{} block (required_version, aws ~> 5.0, random ~> 3.6) + provider "aws"
├── variables.tf       # aws_region, bucket_prefix, environment, enable_versioning
├── main.tf            # random suffix + bucket + versioning + SSE encryption + public access block
├── outputs.tf         # bucket_name, bucket_arn, bucket_region
├── terraform.tfvars   # my values (ap-south-1, prefix tejas-devops-heros, dev, versioning on)
├── .terraform.lock.hcl# exact provider versions (committed)
├── .gitignore         # never commit .terraform/ or *.tfstate
└── outputs/           # captured output of every command
```

### What the code creates

| Resource | Why |
|---|---|
| `random_id.suffix` | S3 bucket names are global, so a random hex suffix keeps the name unique |
| `aws_s3_bucket.demo` | The bucket `tejas-devops-heros-<hex>` with tags; `force_destroy` so `destroy` works on a non-empty bucket |
| `aws_s3_bucket_versioning.demo` | Keeps previous object versions (driven by `var.enable_versioning`) |
| `aws_s3_bucket_server_side_encryption_configuration.demo` | AES-256 encryption at rest |
| `aws_s3_bucket_public_access_block.demo` | Blocks all public ACLs/policies |

Since AWS provider v4, versioning, encryption and public-access settings are **separate resources** that reference the bucket (`bucket = aws_s3_bucket.demo.id`). That reference also gives Terraform its **implicit dependency** order: the bucket first, then the three settings in parallel.

### Where it ran (honest note)

![GitHub Actions - Terraform workflow (sessions 18 + 19)](screenshots/actions-terraform-run.png)


I don't have AWS credentials set up for this repo, so the workflow runs in **GitHub Actions** with the AWS provider pointed at **[Moto](https://github.com/getmoto/moto)**, an open-source emulator of the AWS APIs, running as a service container. The pipeline writes a small `ci_moto_override.tf` with the endpoint and fake credentials *only inside CI* (Terraform merges `*_override.tf` files into the provider block). **The Terraform code in this folder is unchanged and targets real AWS** when run with real credentials:

```bash
aws configure            # or export AWS_PROFILE=...
terraform init && terraform apply
```

```text
runner: Linux / ubuntu24
Terraform v1.13.3
on linux_amd64
+ provider registry.terraform.io/hashicorp/aws v5.100.0
+ provider registry.terraform.io/hashicorp/random v3.9.1

Your version of Terraform is out of date! The latest version
is 1.16.5. You can update by downloading from https://developer.hashicorp.com/terraform/install
AWS API: Moto 200 (motoserver/moto:5.1.4)
Wed Oct  7 19:52:37 UTC 2026
```

### `terraform init`
Downloads the providers listed in `required_providers` into `.terraform/`, writes `.terraform.lock.hcl`, and sets up the backend (local state here).
![terminal: `terraform init`](terminal-screenshots/s18-001.png)
![terminal: `terraform init`](terminal-screenshots/s18-002.png)

<details><summary>Text output (original run)</summary>

```text
$ terraform init -input=false
Initializing the backend...
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/random from the dependency lock file
- Installing hashicorp/aws v5.100.0...
- Installed hashicorp/aws v5.100.0 (signed by HashiCorp)
- Installing hashicorp/random v3.9.1...
- Installed hashicorp/random v3.9.1 (signed by HashiCorp)

Terraform has been successfully initialized!
[exit code: 0]
```

</details>

### `terraform fmt`
Rewrites files into canonical style. `-check -diff` makes it a CI gate: an empty diff and exit 0 mean it's already formatted.
```text
$ terraform fmt -check -diff -recursive
[exit code: 0]
```

![terminal: `terraform fmt`](terminal-screenshots/s18-003.png)


### `terraform validate`
Checks syntax, types and references without contacting AWS.
![terminal: `terraform validate`](terminal-screenshots/s18-004.png)

<details><summary>Text output (original run)</summary>

```text
$ terraform validate
Success! The configuration is valid.

[exit code: 0]
```

</details>

### `terraform plan`
Compares the desired configuration with the state and the real infrastructure, and shows what would change. `-out=tfplan` saves the exact plan so `apply` does precisely what was reviewed.
![terminal: `terraform plan`](terminal-screenshots/s18-005.png)
![terminal: `terraform plan`](terminal-screenshots/s18-006.png)
![terminal: `terraform plan`](terminal-screenshots/s18-007.png)
![terminal: `terraform plan`](terminal-screenshots/s18-008.png)

<details><summary>Text output (original run)</summary>

```text
$ terraform plan -input=false -out=tfplan

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.demo will be created
  + resource "aws_s3_bucket" "demo" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = (known after apply)
      + bucket_domain_name          = (known after apply)
      + bucket_prefix               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = true
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = (known after apply)
      + request_payer               = (known after apply)
      + tags                        = (known after apply)
      + tags_all                    = (known after apply)
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)

      + cors_rule (known after apply)

      + grant (known after apply)

      + lifecycle_rule (known after apply)

      + logging (known after apply)

      + object_lock_configuration (known after apply)

      + replication_configuration (known after apply)

      + server_side_encryption_configuration (known after apply)

      + versioning (known after apply)

      + website (known after apply)
    }

  # aws_s3_bucket_public_access_block.demo will be created
  + resource "aws_s3_bucket_public_access_block" "demo" {
      + block_public_acls       = true
      + block_public_policy     = true
      + bucket                  = (known after apply)
      + id                      = (known after apply)
      + ignore_public_acls      = true
      + restrict_public_buckets = true
    }

  # aws_s3_bucket_server_side_encryption_configuration.demo will be created
  + resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
      + bucket = (known after apply)
      + id     = (known after apply)

      + rule {
          + apply_server_side_encryption_by_default {
              + sse_algorithm     = "AES256"
                # (1 unchanged attribute hidden)
            }
        }
    }

  # aws_s3_bucket_versioning.demo will be created
  + resource "aws_s3_bucket_versioning" "demo" {
      + bucket = (known after apply)
      + id     = (known after apply)

      + versioning_configuration {
          + mfa_delete = (known after apply)
          + status     = "Enabled"
        }
    }

  # random_id.suffix will be created
  + resource "random_id" "suffix" {
      + b64_std     = (known after apply)
      + b64_url     = (known after apply)
      + byte_length = 4
      + dec         = (known after apply)
      + hex         = (known after apply)
      + id          = (known after apply)
    }

Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_arn    = (known after apply)
  + bucket_name   = (known after apply)
  + bucket_region = (known after apply)
[exit code: 0]
```

</details>

### `terraform apply`
![terminal: `terraform apply`](terminal-screenshots/s18-009.png)

<details><summary>Text output (original run)</summary>

```text
$ terraform apply -input=false -auto-approve tfplan
random_id.suffix: Creating...
random_id.suffix: Creation complete after 0s [id=173XPg]
aws_s3_bucket.demo: Creating...
aws_s3_bucket.demo: Creation complete after 1s [id=tejas-devops-heros-d7bdd73e]
aws_s3_bucket_public_access_block.demo: Creating...
aws_s3_bucket_versioning.demo: Creating...
aws_s3_bucket_server_side_encryption_configuration.demo: Creating...
aws_s3_bucket_public_access_block.demo: Creation complete after 0s [id=tejas-devops-heros-d7bdd73e]
aws_s3_bucket_server_side_encryption_configuration.demo: Creation complete after 0s [id=tejas-devops-heros-d7bdd73e]
aws_s3_bucket_versioning.demo: Creation complete after 1s [id=tejas-devops-heros-d7bdd73e]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::tejas-devops-heros-d7bdd73e"
bucket_name = "tejas-devops-heros-d7bdd73e"
bucket_region = "ap-south-1"
[exit code: 0]
```

</details>

### `terraform show`
Human-readable dump of the **state**, i.e. every attribute Terraform now knows about.
![terminal: `terraform show`](terminal-screenshots/s18-010.png)
![terminal: `terraform show`](terminal-screenshots/s18-011.png)
![terminal: `terraform show`](terminal-screenshots/s18-012.png)

<details><summary>Text output (original run)</summary>

```text
$ terraform show
# aws_s3_bucket.demo:
resource "aws_s3_bucket" "demo" {
    acceleration_status         = null
    arn                         = "arn:aws:s3:::tejas-devops-heros-d7bdd73e"
    bucket                      = "tejas-devops-heros-d7bdd73e"
    bucket_domain_name          = "tejas-devops-heros-d7bdd73e.s3.amazonaws.com"
    bucket_prefix               = null
    bucket_regional_domain_name = "tejas-devops-heros-d7bdd73e.s3.ap-south-1.amazonaws.com"
    force_destroy               = true
    hosted_zone_id              = "Z11RGJOFQNVJUP"
    id                          = "tejas-devops-heros-d7bdd73e"
    object_lock_enabled         = false
    policy                      = null
    region                      = "ap-south-1"
    request_payer               = null
    tags                        = {
        "Environment" = "dev"
        "ManagedBy"   = "terraform"
        "Name"        = "tejas-devops-heros-d7bdd73e"
    }
    tags_all                    = {
        "Environment" = "dev"
        "ManagedBy"   = "terraform"
        "Name"        = "tejas-devops-heros-d7bdd73e"
    }

    grant {
        id          = "75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a"
        permissions = [
            "FULL_CONTROL",
        ]
        type        = "CanonicalUser"
        uri         = null
    }

    versioning {
        enabled    = false
        mfa_delete = false
    }
}

# aws_s3_bucket_public_access_block.demo:
resource "aws_s3_bucket_public_access_block" "demo" {
    block_public_acls       = true
    block_public_policy     = true
    bucket                  = "tejas-devops-heros-d7bdd73e"
    id                      = "tejas-devops-heros-d7bdd73e"
    ignore_public_acls      = true
    restrict_public_buckets = true
}

# aws_s3_bucket_server_side_encryption_configuration.demo:
resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
    bucket                = "tejas-devops-heros-d7bdd73e"
    expected_bucket_owner = null
    id                    = "tejas-devops-heros-d7bdd73e"

    rule {
        apply_server_side_encryption_by_default {
            kms_master_key_id = null
            sse_algorithm     = "AES256"
        }
    }
}

# aws_s3_bucket_versioning.demo:
resource "aws_s3_bucket_versioning" "demo" {
    bucket                = "tejas-devops-heros-d7bdd73e"
    expected_bucket_owner = null
    id                    = "tejas-devops-heros-d7bdd73e"

    versioning_configuration {
        mfa_delete = null
        status     = "Enabled"
    }
}

# random_id.suffix:
resource "random_id" "suffix" {
    b64_std     = "173XPg=="
    b64_url     = "173XPg"
    byte_length = 4
    dec         = "3619542846"
    hex         = "d7bdd73e"
    id          = "173XPg"
}


Outputs:

bucket_arn = "arn:aws:s3:::tejas-devops-heros-d7bdd73e"
bucket_name = "tejas-devops-heros-d7bdd73e"
bucket_region = "ap-south-1"
[exit code: 0]
```

</details>

### `terraform output`
![terminal: `terraform output`](terminal-screenshots/s18-013.png)

<details><summary>Text output (original run)</summary>

```text
$ terraform output
bucket_arn = "arn:aws:s3:::tejas-devops-heros-d7bdd73e"
bucket_name = "tejas-devops-heros-d7bdd73e"
bucket_region = "ap-south-1"
[exit code: 0]
```

</details>

### State: `terraform state list` and re-plan
![terminal: State: `terraform state list` and re-plan](terminal-screenshots/s18-014.png)

<details><summary>Text output (original run)</summary>

```text
$ terraform state list
aws_s3_bucket.demo
aws_s3_bucket_public_access_block.demo
aws_s3_bucket_server_side_encryption_configuration.demo
aws_s3_bucket_versioning.demo
random_id.suffix
[exit code: 0]
```

</details>

Running `plan` again right after `apply` proves the infrastructure matches the code (`-detailed-exitcode` returns **0** = no changes):

<details><summary>Text output (original run)</summary>

```text
$ terraform plan -input=false -detailed-exitcode
random_id.suffix: Refreshing state... [id=173XPg]
aws_s3_bucket.demo: Refreshing state... [id=tejas-devops-heros-d7bdd73e]
aws_s3_bucket_versioning.demo: Refreshing state... [id=tejas-devops-heros-d7bdd73e]
aws_s3_bucket_public_access_block.demo: Refreshing state... [id=tejas-devops-heros-d7bdd73e]
aws_s3_bucket_server_side_encryption_configuration.demo: Refreshing state... [id=tejas-devops-heros-d7bdd73e]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
[exit code: 0]
```

</details>

### `terraform destroy`
![terminal: `terraform destroy`](terminal-screenshots/s18-015.png)
![terminal: `terraform destroy`](terminal-screenshots/s18-016.png)
![terminal: `terraform destroy`](terminal-screenshots/s18-017.png)
![terminal: `terraform destroy`](terminal-screenshots/s18-018.png)
![terminal: `terraform destroy`](terminal-screenshots/s18-019.png)
![terminal: `terraform destroy`](terminal-screenshots/s18-020.png)

<details><summary>Text output (original run)</summary>

```text
$ terraform destroy -input=false -auto-approve
random_id.suffix: Refreshing state... [id=173XPg]
aws_s3_bucket.demo: Refreshing state... [id=tejas-devops-heros-d7bdd73e]
aws_s3_bucket_versioning.demo: Refreshing state... [id=tejas-devops-heros-d7bdd73e]
aws_s3_bucket_public_access_block.demo: Refreshing state... [id=tejas-devops-heros-d7bdd73e]
aws_s3_bucket_server_side_encryption_configuration.demo: Refreshing state... [id=tejas-devops-heros-d7bdd73e]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # aws_s3_bucket.demo will be destroyed
  - resource "aws_s3_bucket" "demo" {
      - arn                         = "arn:aws:s3:::tejas-devops-heros-d7bdd73e" -> null
      - bucket                      = "tejas-devops-heros-d7bdd73e" -> null
      - bucket_domain_name          = "tejas-devops-heros-d7bdd73e.s3.amazonaws.com" -> null
      - bucket_regional_domain_name = "tejas-devops-heros-d7bdd73e.s3.ap-south-1.amazonaws.com" -> null
      - force_destroy               = true -> null
      - hosted_zone_id              = "Z11RGJOFQNVJUP" -> null
      - id                          = "tejas-devops-heros-d7bdd73e" -> null
      - object_lock_enabled         = false -> null
      - region                      = "ap-south-1" -> null
      - tags                        = {
          - "Environment" = "dev"
          - "ManagedBy"   = "terraform"
          - "Name"        = "tejas-devops-heros-d7bdd73e"
        } -> null
      - tags_all                    = {
          - "Environment" = "dev"
          - "ManagedBy"   = "terraform"
          - "Name"        = "tejas-devops-heros-d7bdd73e"
        } -> null
        # (4 unchanged attributes hidden)

      - grant {
          - id          = "75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a" -> null
          - permissions = [
              - "FULL_CONTROL",
            ] -> null
          - type        = "CanonicalUser" -> null
            # (1 unchanged attribute hidden)
        }

      - server_side_encryption_configuration {
          - rule {
              - bucket_key_enabled = false -> null

              - apply_server_side_encryption_by_default {
                  - sse_algorithm     = "AES256" -> null
                    # (1 unchanged attribute hidden)
                }
            }
        }

      - versioning {
          - enabled    = true -> null
          - mfa_delete = false -> null
        }
    }

  # aws_s3_bucket_public_access_block.demo will be destroyed
  - resource "aws_s3_bucket_public_access_block" "demo" {
      - block_public_acls       = true -> null
      - block_public_policy     = true -> null
      - bucket                  = "tejas-devops-heros-d7bdd73e" -> null
      - id                      = "tejas-devops-heros-d7bdd73e" -> null
      - ignore_public_acls      = true -> null
      - restrict_public_buckets = true -> null
    }

  # aws_s3_bucket_server_side_encryption_configuration.demo will be destroyed
  - resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
      - bucket                = "tejas-devops-heros-d7bdd73e" -> null
      - id                    = "tejas-devops-heros-d7bdd73e" -> null
        # (1 unchanged attribute hidden)

      - rule {
          - bucket_key_enabled = false -> null

          - apply_server_side_encryption_by_default {
              - sse_algorithm     = "AES256" -> null
                # (1 unchanged attribute hidden)
            }
        }
    }

  # aws_s3_bucket_versioning.demo will be destroyed
  - resource "aws_s3_bucket_versioning" "demo" {
      - bucket                = "tejas-devops-heros-d7bdd73e" -> null
      - id                    = "tejas-devops-heros-d7bdd73e" -> null
        # (1 unchanged attribute hidden)

      - versioning_configuration {
          - status     = "Enabled" -> null
            # (1 unchanged attribute hidden)
        }
    }

  # random_id.suffix will be destroyed
  - resource "random_id" "suffix" {
      - b64_std     = "173XPg==" -> null
      - b64_url     = "173XPg" -> null
      - byte_length = 4 -> null
      - dec         = "3619542846" -> null
      - hex         = "d7bdd73e" -> null
      - id          = "173XPg" -> null
    }

Plan: 0 to add, 0 to change, 5 to destroy.

Changes to Outputs:
  - bucket_arn    = "arn:aws:s3:::tejas-devops-heros-d7bdd73e" -> null
  - bucket_name   = "tejas-devops-heros-d7bdd73e" -> null
  - bucket_region = "ap-south-1" -> null
aws_s3_bucket_public_access_block.demo: Destroying... [id=tejas-devops-heros-d7bdd73e]
aws_s3_bucket_versioning.demo: Destroying... [id=tejas-devops-heros-d7bdd73e]
aws_s3_bucket_server_side_encryption_configuration.demo: Destroying... [id=tejas-devops-heros-d7bdd73e]
aws_s3_bucket_server_side_encryption_configuration.demo: Destruction complete after 0s
aws_s3_bucket_versioning.demo: Destruction complete after 0s
aws_s3_bucket_public_access_block.demo: Destruction complete after 0s
aws_s3_bucket.demo: Destroying... [id=tejas-devops-heros-d7bdd73e]
aws_s3_bucket.demo: Destruction complete after 1s
random_id.suffix: Destroying... [id=173XPg]
random_id.suffix: Destruction complete after 0s

Destroy complete! Resources: 5 destroyed.
[exit code: 0]
```

</details>
```text
$ terraform state list
[exit code: 0]
```

### Workflow summary

```
write .tf ─▶ init ─▶ fmt ─▶ validate ─▶ plan ─▶ apply ─▶ show / output ─▶ (change code ─▶ plan ─▶ apply) ─▶ destroy
```

| Command | Touches AWS? | Changes infra? | Notes |
|---|---|---|---|
| `init` | No (downloads providers) | No | Safe to run any time; re-run after adding providers or modules |
| `fmt` | No | No | Use `-check` in CI |
| `validate` | No | No | Catches typos and wrong references |
| `plan` | Reads | No | Always review it; save it with `-out` |
| `apply` | Yes | **Yes** | Creates/updates/deletes to match the code, and updates state |
| `show` / `output` | No (reads state) | No | `output -json` for scripts |
| `destroy` | Yes | **Yes, deletes everything in state** | Used to avoid AWS bills after labs |

**What I learned about state:** `terraform.tfstate` maps each resource address (`aws_s3_bucket.demo`) to the real object ID (`tejas-devops-heros-9286a039`). It can contain secrets and is the source of truth for `plan`, so in a team it belongs in a **remote backend** (S3 + versioning + encryption + locking), never in Git. That's why `.gitignore` excludes it.

---

## Task 2 – AWS services research

| # | Service | Category | README |
|---|---|---|---|
| 01 | IAM | Governance | [aws-services/01-iam/README.md](aws-services/01-iam/README.md) |
| 02 | EC2 | Compute | [aws-services/02-ec2/README.md](aws-services/02-ec2/README.md) |
| 03 | S3 | Storage | [aws-services/03-s3/README.md](aws-services/03-s3/README.md) |
| 04 | VPC | Networking | [aws-services/04-vpc/README.md](aws-services/04-vpc/README.md) |
| 05 | DynamoDB & RDS | Databases | [aws-services/05-dynamodb-rds/README.md](aws-services/05-dynamodb-rds/README.md) |

The VPC, EC2 and S3 concepts are put into practice in [Session 19](../Cloud%20Terraform/README.md), which builds a VPC → subnet → IGW → route table → security group → EC2 + S3 with Terraform.
