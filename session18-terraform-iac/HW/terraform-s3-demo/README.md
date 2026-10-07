# Task 1 — Terraform S3 Demo

**Submitted by:** Piyush Bansal

> **Note: this was applied to LocalStack, not a real AWS account.**
> LocalStack is a local AWS emulator running in Docker on my laptop
> (`localstack/localstack:3.8`, endpoint `http://localhost:4566`). The AWS provider in
> [provider.tf](provider.tf) uses LocalStack's dummy credentials (`test`/`test`) and an
> `endpoints { ... }` block that sends S3 calls to LocalStack. Every output below is real
> output from that run, but the "bucket" only existed inside LocalStack.
> **To run this against real AWS**, delete the `endpoints` block, the dummy
> `access_key`/`secret_key`, the `skip_*` flags and `s3_use_path_style` from
> `provider.tf`, use your own AWS credentials, and pick a globally unique `bucket_name`.

## Files

| File | What it has |
|---|---|
| [provider.tf](provider.tf) | `terraform {}` block (Terraform `>= 1.6`, `hashicorp/aws ~> 6.0`) and the `aws` provider pointed at LocalStack |
| [variables.tf](variables.tf) | `aws_region`, `bucket_name` (no default, must be set), `environment`, `localstack_endpoint` |
| [terraform.tfvars](terraform.tfvars) | The values I used: `ap-south-1`, `piyush-session18-tf-demo`, `dev` |
| [main.tf](main.tf) | `aws_s3_bucket.demo` with tags + `aws_s3_bucket_versioning.demo` (versioning on) |
| [outputs.tf](outputs.tf) | `bucket_name`, `bucket_arn`, `bucket_region`, `versioning_status` |
| `.terraform.lock.hcl` | Provider version lock (committed on purpose) |

`.terraform/`, `*.tfstate*`, plan files and crash logs are ignored by
[../.gitignore](../.gitignore). `terraform.tfvars` is normally ignored in this repo, but
it is a deliverable here and holds no secrets, so I un-ignored it.

## Setup

```bash
docker run -d --name piyush-localstack -p 4566:4566 localstack/localstack:3.8
# dummy credentials for the aws CLI, only valid for LocalStack
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-south-1
```

Tool versions:

```text
$ terraform version
Terraform v1.16.4
on darwin_arm64
+ provider registry.terraform.io/hashicorp/aws v6.67.0
```

## 1. `terraform init`

Downloads the AWS provider into `.terraform/` and writes `.terraform.lock.hcl`.

```text
$ terraform init
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 6.0"...
- Installing hashicorp/aws v6.67.0...
- Installed hashicorp/aws v6.67.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

## 2. `terraform fmt`

Rewrites the files to the canonical style. Nothing printed and exit code 0 means the
files were already formatted.

```text
$ terraform fmt -check -diff; echo "exit=$?"
exit=0
$ terraform fmt
```

## 3. `terraform validate`

Checks syntax and references without calling AWS.

```text
$ terraform validate
Success! The configuration is valid.
```

## 4. `terraform plan`

Shows what would change. I saved the plan to a file so `apply` does exactly this.

```text
$ terraform plan -out=tfplan

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.demo will be created
  + resource "aws_s3_bucket" "demo" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "piyush-session18-tf-demo"
      + bucket_domain_name          = (known after apply)
      + bucket_namespace            = (known after apply)
      + bucket_prefix               = (known after apply)
      + bucket_region               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = true
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = "ap-south-1"
      + request_payer               = (known after apply)
      + tags                        = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "piyush-session18-tf-demo"
          + "Owner"       = "piyush"
          + "Session"     = "18"
        }
      + tags_all                    = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "piyush-session18-tf-demo"
          + "Owner"       = "piyush"
          + "Session"     = "18"
        }
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

  # aws_s3_bucket_versioning.demo will be created
  + resource "aws_s3_bucket_versioning" "demo" {
      + bucket = (known after apply)
      + id     = (known after apply)
      + region = "ap-south-1"

      + versioning_configuration {
          + mfa_delete = (known after apply)
          + status     = "Enabled"
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_arn        = (known after apply)
  + bucket_name       = "piyush-session18-tf-demo"
  + bucket_region     = "ap-south-1"
  + versioning_status = "Enabled"

─────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
```

## 5. `terraform apply`

Terraform created the bucket first and then the versioning resource, because
`aws_s3_bucket_versioning.demo` references `aws_s3_bucket.demo.id` (implicit dependency).

```text
$ terraform apply tfplan
aws_s3_bucket.demo: Creating...
aws_s3_bucket.demo: Still creating... [00m10s elapsed]
aws_s3_bucket.demo: Still creating... [00m20s elapsed]
aws_s3_bucket.demo: Still creating... [00m30s elapsed]
aws_s3_bucket.demo: Still creating... [00m40s elapsed]
aws_s3_bucket.demo: Still creating... [00m50s elapsed]
aws_s3_bucket.demo: Creation complete after 53s [id=piyush-session18-tf-demo]
aws_s3_bucket_versioning.demo: Creating...
aws_s3_bucket_versioning.demo: Creation complete after 3s [id=piyush-session18-tf-demo]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::piyush-session18-tf-demo"
bucket_name = "piyush-session18-tf-demo"
bucket_region = "ap-south-1"
versioning_status = "Enabled"
```

### Verify with the AWS CLI (against LocalStack)

```text
$ aws --endpoint-url=http://localhost:4566 s3 ls
2026-10-07 21:25:01 piyush-session18-tf-demo
$ aws --endpoint-url=http://localhost:4566 s3api get-bucket-versioning --bucket piyush-session18-tf-demo
{
    "Status": "Enabled"
}
```

## 6. `terraform show`

Reads the state file and prints every attribute Terraform knows about.

```text
$ terraform show
# aws_s3_bucket.demo:
resource "aws_s3_bucket" "demo" {
    acceleration_status         = null
    arn                         = "arn:aws:s3:::piyush-session18-tf-demo"
    bucket                      = "piyush-session18-tf-demo"
    bucket_domain_name          = "piyush-session18-tf-demo.s3.amazonaws.com"
    bucket_namespace            = "global"
    bucket_prefix               = null
    bucket_region               = "ap-south-1"
    bucket_regional_domain_name = "piyush-session18-tf-demo.s3.ap-south-1.amazonaws.com"
    force_destroy               = true
    hosted_zone_id              = "Z11RGJOFQNVJUP"
    id                          = "piyush-session18-tf-demo"
    object_lock_enabled         = false
    policy                      = null
    region                      = "ap-south-1"
    request_payer               = "BucketOwner"
    tags                        = {}
    tags_all                    = {}

    grant {
        id          = "75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a"
        permissions = [
            "FULL_CONTROL",
        ]
        type        = "CanonicalUser"
        uri         = null
    }

    server_side_encryption_configuration {
        rule {
            bucket_key_enabled = false

            apply_server_side_encryption_by_default {
                kms_master_key_id = null
                sse_algorithm     = "AES256"
            }
        }
    }

    versioning {
        enabled    = false
        mfa_delete = false
    }
}

# aws_s3_bucket_versioning.demo:
resource "aws_s3_bucket_versioning" "demo" {
    bucket                = "piyush-session18-tf-demo"
    expected_bucket_owner = null
    id                    = "piyush-session18-tf-demo"
    region                = "ap-south-1"

    versioning_configuration {
        mfa_delete = "Disabled"
        status     = "Enabled"
    }
}


Outputs:

bucket_arn = "arn:aws:s3:::piyush-session18-tf-demo"
bucket_name = "piyush-session18-tf-demo"
bucket_region = "ap-south-1"
versioning_status = "Enabled"
```

Two things I noticed here:

- `versioning.enabled = false` on the bucket resource while the separate versioning
  resource says `Enabled`. The bucket was read back *before* the versioning resource was
  created, so that copy is just stale until the next refresh (on destroy it showed
  `enabled = true`).
- `tags = {}`, even though I set 5 tags. See the drift section below.

## 7. `terraform output`

```text
$ terraform output
bucket_arn = "arn:aws:s3:::piyush-session18-tf-demo"
bucket_name = "piyush-session18-tf-demo"
bucket_region = "ap-south-1"
versioning_status = "Enabled"
$ terraform output -raw bucket_arn
arn:aws:s3:::piyush-session18-tf-demo
$ terraform state list
aws_s3_bucket.demo
aws_s3_bucket_versioning.demo
```

## A real drift: tags missing after the first apply

`terraform show` had `tags = {}`, so I checked the bucket directly:

```text
$ aws --endpoint-url=http://localhost:4566 s3api get-bucket-tagging --bucket piyush-session18-tf-demo

An error occurred (NoSuchTagSet) when calling the GetBucketTagging operation: The TagSet does not exist
```

A second `terraform plan` caught it and wanted to add the tags:

```text
$ terraform plan
aws_s3_bucket.demo: Refreshing state... [id=piyush-session18-tf-demo]
aws_s3_bucket_versioning.demo: Refreshing state... [id=piyush-session18-tf-demo]
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place
Terraform will perform the following actions:
  # aws_s3_bucket.demo will be updated in-place
  ~ resource "aws_s3_bucket" "demo" {
        id                          = "piyush-session18-tf-demo"
      ~ tags                        = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "piyush-session18-tf-demo"
          + "Owner"       = "piyush"
          + "Session"     = "18"
        }
      ~ tags_all                    = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "piyush-session18-tf-demo"
          + "Owner"       = "piyush"
          + "Session"     = "18"
        }
        # (14 unchanged attributes hidden)
        # (3 unchanged blocks hidden)
    }
Plan: 0 to add, 1 to change, 0 to destroy.
```

(blank lines removed with `grep`). My guess is that AWS provider v6 sends the tags as
part of `CreateBucket`, which LocalStack 3.8 ignores (that is probably also why the create
took 53 s). One more `apply` set them with a separate tagging call, and after that the
plan was clean:

```text
$ terraform apply -auto-approve
aws_s3_bucket.demo: Modifying... [id=piyush-session18-tf-demo]
aws_s3_bucket.demo: Modifications complete after 2s [id=piyush-session18-tf-demo]
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
$ aws --endpoint-url=http://localhost:4566 s3api get-bucket-tagging --bucket piyush-session18-tf-demo --output table
-----------------------------------------------
|              GetBucketTagging               |
+---------------------------------------------+
||                  TagSet                   ||
|+--------------+----------------------------+|
||      Key     |           Value            ||
|+--------------+----------------------------+|
||  Environment |  dev                       ||
||  ManagedBy   |  Terraform                 ||
||  Owner       |  piyush                    ||
||  Session     |  18                        ||
||  Name        |  piyush-session18-tf-demo  ||
|+--------------+----------------------------+|
$ terraform plan -detailed-exitcode > /dev/null; echo "plan exit code: $?"
plan exit code: 0
```

`-detailed-exitcode` returns 0 = no changes, 2 = changes pending, 1 = error, which is
handy in CI to detect drift.

I also put an object in the bucket (used for the S3 research in
[../aws-services/03-s3](../aws-services/03-s3/)):

```text
$ aws --endpoint-url=http://localhost:4566 s3 cp hello.txt s3://piyush-session18-tf-demo/hello.txt
upload: ./hello.txt to s3://piyush-session18-tf-demo/hello.txt
$ aws --endpoint-url=http://localhost:4566 s3 ls s3://piyush-session18-tf-demo/
2026-10-07 21:40:19         29 hello.txt
```

## 8. `terraform destroy`

The bucket was not empty, but `force_destroy = true` lets Terraform delete the objects
too. Destroy order is the reverse of create: versioning first, then the bucket. The plan
also listed the lifecycle rule I added from the CLI during the S3 research, because the
refresh read it from the bucket.

```text
$ terraform destroy -auto-approve
aws_s3_bucket.demo: Refreshing state... [id=piyush-session18-tf-demo]
aws_s3_bucket_versioning.demo: Refreshing state... [id=piyush-session18-tf-demo]
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  - destroy
Terraform will perform the following actions:
  # aws_s3_bucket.demo will be destroyed
  - resource "aws_s3_bucket" "demo" {
      - arn                         = "arn:aws:s3:::piyush-session18-tf-demo" -> null
      - bucket                      = "piyush-session18-tf-demo" -> null
      ...
      - versioning {
          - enabled    = true -> null
          - mfa_delete = false -> null
        }
    }
  # aws_s3_bucket_versioning.demo will be destroyed
  - resource "aws_s3_bucket_versioning" "demo" {
      - bucket                = "piyush-session18-tf-demo" -> null
      - id                    = "piyush-session18-tf-demo" -> null
      - region                = "ap-south-1" -> null
        # (1 unchanged attribute hidden)
      - versioning_configuration {
          - mfa_delete = "Disabled" -> null
          - status     = "Enabled" -> null
        }
    }
Plan: 0 to add, 0 to change, 2 to destroy.
Changes to Outputs:
  - bucket_arn        = "arn:aws:s3:::piyush-session18-tf-demo" -> null
  - bucket_name       = "piyush-session18-tf-demo" -> null
  - bucket_region     = "ap-south-1" -> null
  - versioning_status = "Enabled" -> null
aws_s3_bucket_versioning.demo: Destroying... [id=piyush-session18-tf-demo]
aws_s3_bucket_versioning.demo: Destruction complete after 0s
aws_s3_bucket.demo: Destroying... [id=piyush-session18-tf-demo]
aws_s3_bucket.demo: Destruction complete after 1s
Destroy complete! Resources: 2 destroyed.
$ aws --endpoint-url=http://localhost:4566 s3 ls
$ terraform state list
```

(`...` = I cut the long middle of the bucket resource from the README.) Both commands
print nothing: the bucket is gone and the state is empty.

## Workflow summary

```text
write .tf -> init -> fmt -> validate -> plan -> apply -> show / output -> (change -> plan -> apply) -> destroy
```

| Command | Talks to AWS? | Changes anything? |
|---|---|---|
| `init` | Registry only | Creates `.terraform/` and lock file |
| `fmt` | No | Reformats `.tf` files |
| `validate` | No | No |
| `plan` | Yes (refresh, read-only) | No |
| `apply` | Yes | Creates/updates resources and state |
| `show` / `output` | No (reads state) | No |
| `destroy` | Yes | Deletes resources, empties state |

## What I learned

- `plan -out` + `apply <planfile>` guarantees that what I reviewed is what gets applied.
- References between resources (`aws_s3_bucket.demo.id`) decide the order of create and
  destroy without me writing `depends_on`.
- Running `plan` again after an apply is a cheap drift check; it caught tags that never
  reached the bucket.
- `force_destroy` is needed to delete a non-empty bucket; useful in a demo, risky in prod.
