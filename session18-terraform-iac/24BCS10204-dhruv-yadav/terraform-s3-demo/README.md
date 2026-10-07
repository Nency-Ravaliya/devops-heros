# Terraform S3 Demo

- **Student:** Dhruv Yadav
- **Enrollment No.:** 24BCS10204
- **Session:** 18 - Terraform & Infrastructure as Code
- **Task:** Task 1 - Create an S3 bucket with Terraform

## Task Checklist

- [x] Project with exactly `main.tf`, `variables.tf`, `outputs.tf`, `provider.tf`, `terraform.tfvars`, `README.md`
- [x] S3 bucket with versioning, server-side encryption (SSE-S3 / AES256), public access block and tags
- [x] `terraform init`
- [x] `terraform fmt`
- [x] `terraform validate`
- [x] `terraform plan`
- [x] `terraform apply -auto-approve`
- [x] `terraform show`
- [x] `terraform output`
- [x] Verify the bucket with the AWS CLI
- [x] `terraform destroy`

> **Where this ran:** every `apply`/`destroy` below ran against **LocalStack 3.8** (an AWS emulator running
> locally in Docker at `http://localhost:4566`), **not** a real AWS account. All output shown is the real
> output from those runs. See [Real AWS vs LocalStack](#real-aws-vs-localstack) for what changes on real AWS.

Tools used: Terraform `v1.16.4`, `hashicorp/aws` provider `v6.67.0` (pinned in the committed
`.terraform.lock.hcl`), aws-cli `2.37.9`.

## Files

| File | Purpose |
|------|---------|
| `provider.tf` | `terraform {}` block (Terraform + provider version constraints) and the `aws` provider. LocalStack settings are switched on/off by `var.use_localstack`. |
| `variables.tf` | Input variables: region, `use_localstack`, LocalStack endpoint, bucket name (with a validation rule), environment, versioning toggle. |
| `main.tf` | The bucket and its three configuration resources (versioning, encryption, public access block). |
| `outputs.tf` | Bucket name, ARN, region, versioning status. |
| `terraform.tfvars` | Values for this run. |

Since AWS provider v4, bucket settings are **separate resources** (`aws_s3_bucket_versioning`,
`aws_s3_bucket_server_side_encryption_configuration`, `aws_s3_bucket_public_access_block`) that
reference the bucket with `bucket = aws_s3_bucket.demo.id`. That reference is an *implicit dependency*,
so Terraform creates the bucket first and the three settings in parallel afterwards (visible in the apply log).

### LocalStack switch (provider.tf)

```hcl
provider "aws" {
  region = var.aws_region

  access_key = var.use_localstack ? "test" : null
  secret_key = var.use_localstack ? "test" : null

  skip_credentials_validation = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  s3_use_path_style           = var.use_localstack

  dynamic "endpoints" {
    for_each = var.use_localstack ? [1] : []
    content {
      s3  = var.localstack_endpoint
      sts = var.localstack_endpoint
      iam = var.localstack_endpoint
    }
  }
  ...
}
```

With `use_localstack = false` the `endpoints` block disappears, the credentials become `null` (so the
normal AWS credential chain is used) and all `skip_*` flags are `false` - i.e. the exact same code targets real AWS.

## 1. `terraform init`

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
...
```

## 2. `terraform fmt`

`terraform fmt` rewrites files to canonical style and prints the names of files it changed. The files were
already formatted, so it printed nothing. A CI-style check confirms it:

```text
$ terraform fmt
$ terraform fmt -check -recursive; echo "exit code: $?"
exit code: 0
```

## 3. `terraform validate`

```text
$ terraform validate
Success! The configuration is valid.
```

## 4. `terraform plan`

```text
$ terraform plan

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.demo will be created
  + resource "aws_s3_bucket" "demo" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "Dhruv-24BCS10204-tf-demo"
      ...
      + force_destroy               = true
      + id                          = (known after apply)
      ...
      + region                      = "ap-south-1"
      + tags                        = {
          + "Environment" = "dev"
          + "Name"        = "Dhruv-24BCS10204-tf-demo"
          + "Student"     = "Dhruv Yadav"
        }
      + tags_all                    = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "Dhruv-24BCS10204-tf-demo"
          + "Owner"       = "24BCS10204"
          + "Session"     = "18"
          + "Student"     = "Dhruv Yadav"
        }
      ...
    }

  # aws_s3_bucket_public_access_block.demo will be created
  + resource "aws_s3_bucket_public_access_block" "demo" {
      + block_public_acls       = true
      + block_public_policy     = true
      + bucket                  = (known after apply)
      + id                      = (known after apply)
      + ignore_public_acls      = true
      + region                  = "ap-south-1"
      + restrict_public_buckets = true
    }

  # aws_s3_bucket_server_side_encryption_configuration.demo will be created
  + resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
      + bucket = (known after apply)
      + id     = (known after apply)
      + region = "ap-south-1"

      + rule {
          + blocked_encryption_types = (known after apply)
          + bucket_key_enabled       = true

          + apply_server_side_encryption_by_default {
              + kms_master_key_id = (known after apply)
              + sse_algorithm     = "AES256"
            }
        }
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

Plan: 4 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_arn        = (known after apply)
  + bucket_name       = (known after apply)
  + bucket_region     = "ap-south-1"
  + versioning_status = "Enabled"
```

`tags_all` = resource `tags` merged with the provider's `default_tags`.

## 5. `terraform apply -auto-approve`

```text
$ terraform apply -auto-approve
...
Plan: 4 to add, 0 to change, 0 to destroy.
...
aws_s3_bucket.demo: Creating...
aws_s3_bucket.demo: Creation complete after 1s [id=Dhruv-24BCS10204-tf-demo]
aws_s3_bucket_public_access_block.demo: Creating...
aws_s3_bucket_versioning.demo: Creating...
aws_s3_bucket_server_side_encryption_configuration.demo: Creating...
aws_s3_bucket_server_side_encryption_configuration.demo: Creation complete after 0s [id=Dhruv-24BCS10204-tf-demo]
aws_s3_bucket_public_access_block.demo: Creation complete after 0s [id=Dhruv-24BCS10204-tf-demo]
aws_s3_bucket_versioning.demo: Creation complete after 1s [id=Dhruv-24BCS10204-tf-demo]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::Dhruv-24BCS10204-tf-demo"
bucket_name = "Dhruv-24BCS10204-tf-demo"
bucket_region = "ap-south-1"
versioning_status = "Enabled"
```

A follow-up `terraform plan -detailed-exitcode` returned exit code `0` (no drift).

## 6. `terraform show`

```text
$ terraform show
# aws_s3_bucket.demo:
resource "aws_s3_bucket" "demo" {
    acceleration_status         = null
    arn                         = "arn:aws:s3:::Dhruv-24BCS10204-tf-demo"
    bucket                      = "Dhruv-24BCS10204-tf-demo"
    bucket_domain_name          = "Dhruv-24BCS10204-tf-demo.s3.amazonaws.com"
    bucket_namespace            = "global"
    bucket_prefix               = null
    bucket_region               = "ap-south-1"
    bucket_regional_domain_name = "Dhruv-24BCS10204-tf-demo.s3.ap-south-1.amazonaws.com"
    force_destroy               = true
    hosted_zone_id              = "Z11RGJOFQNVJUP"
    id                          = "Dhruv-24BCS10204-tf-demo"
    object_lock_enabled         = false
    policy                      = null
    region                      = "ap-south-1"
    request_payer               = "BucketOwner"
    tags                        = {
        "Environment" = "dev"
        "Name"        = "Dhruv-24BCS10204-tf-demo"
        "Student"     = "Dhruv Yadav"
    }
    tags_all                    = {
        "Environment" = "dev"
        "ManagedBy"   = "Terraform"
        "Name"        = "Dhruv-24BCS10204-tf-demo"
        "Owner"       = "24BCS10204"
        "Session"     = "18"
        "Student"     = "Dhruv Yadav"
    }

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

# aws_s3_bucket_public_access_block.demo:
resource "aws_s3_bucket_public_access_block" "demo" {
    block_public_acls       = true
    block_public_policy     = true
    bucket                  = "Dhruv-24BCS10204-tf-demo"
    id                      = "Dhruv-24BCS10204-tf-demo"
    ignore_public_acls      = true
    region                  = "ap-south-1"
    restrict_public_buckets = true
}

# aws_s3_bucket_server_side_encryption_configuration.demo:
resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
    bucket                = "Dhruv-24BCS10204-tf-demo"
    expected_bucket_owner = null
    id                    = "Dhruv-24BCS10204-tf-demo"
    region                = "ap-south-1"

    rule {
        blocked_encryption_types = []
        bucket_key_enabled       = true

        apply_server_side_encryption_by_default {
            kms_master_key_id = null
            sse_algorithm     = "AES256"
        }
    }
}

# aws_s3_bucket_versioning.demo:
resource "aws_s3_bucket_versioning" "demo" {
    bucket                = "Dhruv-24BCS10204-tf-demo"
    expected_bucket_owner = null
    id                    = "Dhruv-24BCS10204-tf-demo"
    region                = "ap-south-1"

    versioning_configuration {
        mfa_delete = "Disabled"
        status     = "Enabled"
    }
}


Outputs:

bucket_arn = "arn:aws:s3:::Dhruv-24BCS10204-tf-demo"
bucket_name = "Dhruv-24BCS10204-tf-demo"
bucket_region = "ap-south-1"
versioning_status = "Enabled"
```

> Note: the `versioning { enabled = false }` and `bucket_key_enabled = false` inside `aws_s3_bucket.demo`
> are *read-only, computed* attributes captured when the bucket itself was created - i.e. **before** the
> separate versioning/encryption resources ran. The authoritative values are in
> `aws_s3_bucket_versioning.demo` (`status = "Enabled"`) and
> `aws_s3_bucket_server_side_encryption_configuration.demo` (`bucket_key_enabled = true`), and the AWS CLI
> check below confirms them. They would refresh on the next `plan`/`apply`.

## 7. `terraform output`

```text
$ terraform output
bucket_arn = "arn:aws:s3:::Dhruv-24BCS10204-tf-demo"
bucket_name = "Dhruv-24BCS10204-tf-demo"
bucket_region = "ap-south-1"
versioning_status = "Enabled"

$ terraform output -raw bucket_arn
arn:aws:s3:::Dhruv-24BCS10204-tf-demo

$ terraform state list
aws_s3_bucket.demo
aws_s3_bucket_public_access_block.demo
aws_s3_bucket_server_side_encryption_configuration.demo
aws_s3_bucket_versioning.demo
```

## 8. Verify with the AWS CLI (pointed at LocalStack)

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-south-1
# on real AWS: drop --endpoint-url and use real credentials
```

```text
$ aws --endpoint-url http://localhost:4566 s3 ls
2026-10-06 19:16:12 Dhruv-24BCS10204-tf-demo

$ aws --endpoint-url http://localhost:4566 s3api get-bucket-versioning --bucket Dhruv-24BCS10204-tf-demo
{
    "Status": "Enabled"
}

$ aws --endpoint-url http://localhost:4566 s3api get-bucket-encryption --bucket Dhruv-24BCS10204-tf-demo
{
    "ServerSideEncryptionConfiguration": {
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }
        ]
    }
}

$ aws --endpoint-url http://localhost:4566 s3api get-public-access-block --bucket Dhruv-24BCS10204-tf-demo
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}

$ aws --endpoint-url http://localhost:4566 s3api get-bucket-tagging --bucket Dhruv-24BCS10204-tf-demo
{
    "TagSet": [
        { "Key": "Owner", "Value": "24BCS10204" },
        { "Key": "Name", "Value": "Dhruv-24BCS10204-tf-demo" },
        { "Key": "Environment", "Value": "dev" },
        { "Key": "Student", "Value": "Dhruv Yadav" },
        { "Key": "Session", "Value": "18" },
        { "Key": "ManagedBy", "Value": "Terraform" }
    ]
}
```

Upload an object and confirm it is versioned and encrypted at rest:

```text
$ aws --endpoint-url http://localhost:4566 s3 cp ./hello.txt s3://Dhruv-24BCS10204-tf-demo/hello.txt
upload: ./hello.txt to s3://Dhruv-24BCS10204-tf-demo/hello.txt

$ aws --endpoint-url http://localhost:4566 s3 ls s3://Dhruv-24BCS10204-tf-demo/
2026-10-06 19:16:35         32 hello.txt

$ aws --endpoint-url http://localhost:4566 s3api head-object --bucket Dhruv-24BCS10204-tf-demo --key hello.txt
{
    "AcceptRanges": "bytes",
    "LastModified": "2026-10-06T11:16:35+00:00",
    "ContentLength": 32,
    "ETag": "\"5e8d0d53ab5793fa168cfb9ecd164a19\"",
    "VersionId": "FJCEm2mf5cmkW5WARLYaGGL6ZXgCZd.O",
    "ContentType": "text/plain",
    "ServerSideEncryption": "AES256",
    "Metadata": {}
}
```

(Tag JSON compacted to one line per tag and the local file path shortened to `./hello.txt`; values unchanged.)
`VersionId` proves versioning is on; `ServerSideEncryption: AES256` proves default encryption was applied.

## 9. `terraform destroy`

```text
$ terraform destroy -auto-approve
aws_s3_bucket.demo: Refreshing state... [id=Dhruv-24BCS10204-tf-demo]
aws_s3_bucket_public_access_block.demo: Refreshing state... [id=Dhruv-24BCS10204-tf-demo]
aws_s3_bucket_server_side_encryption_configuration.demo: Refreshing state... [id=Dhruv-24BCS10204-tf-demo]
aws_s3_bucket_versioning.demo: Refreshing state... [id=Dhruv-24BCS10204-tf-demo]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  - destroy
...
Plan: 0 to add, 0 to change, 4 to destroy.

Changes to Outputs:
  - bucket_arn        = "arn:aws:s3:::Dhruv-24BCS10204-tf-demo" -> null
  - bucket_name       = "Dhruv-24BCS10204-tf-demo" -> null
  - bucket_region     = "ap-south-1" -> null
  - versioning_status = "Enabled" -> null
aws_s3_bucket_public_access_block.demo: Destroying... [id=Dhruv-24BCS10204-tf-demo]
aws_s3_bucket_server_side_encryption_configuration.demo: Destroying... [id=Dhruv-24BCS10204-tf-demo]
aws_s3_bucket_versioning.demo: Destroying... [id=Dhruv-24BCS10204-tf-demo]
aws_s3_bucket_server_side_encryption_configuration.demo: Destruction complete after 0s
aws_s3_bucket_versioning.demo: Destruction complete after 0s
aws_s3_bucket_public_access_block.demo: Destruction complete after 0s
aws_s3_bucket.demo: Destroying... [id=Dhruv-24BCS10204-tf-demo]
aws_s3_bucket.demo: Destruction complete after 0s

Destroy complete! Resources: 4 destroyed.

$ aws --endpoint-url http://localhost:4566 s3api head-bucket --bucket Dhruv-24BCS10204-tf-demo
aws: [ERROR]: An error occurred (404) when calling the HeadBucket operation: Not Found
```

Destroy runs in **reverse dependency order**: the three settings first, the bucket last. Because the bucket
still contained `hello.txt` (and its version), `force_destroy = true` was what allowed Terraform to empty and
delete it.

## Real AWS vs LocalStack

| | This run (LocalStack) | Real AWS |
|---|---|---|
| Credentials | dummy `test` / `test`, validation skipped | real IAM credentials (`aws configure`, SSO, env vars); STS validates them |
| Endpoint | `http://localhost:4566`, path-style URLs | `https://s3.ap-south-1.amazonaws.com`, virtual-hosted style |
| Bucket name | only needs to be unique inside this emulator | must be **globally** unique across all AWS accounts |
| Cost / billing | none | S3 storage + requests are billed (tiny for this demo; free tier covers it) |
| Encryption, public access block | emulated: the settings are stored and returned by the API exactly like AWS | enforced by the real service (KMS/S3 storage layer, account-level policy evaluation) |
| `force_destroy` | convenient for a demo | dangerous in production - deletes all objects and versions |

**Known LocalStack quirk:** provider 6.67.0 sends bucket tags inside the `CreateBucket` request (the newer
S3 ABAC API). On my very first apply, LocalStack 3.8 didn't store them, and the next `plan` wanted to re-add the tags
(a second `apply` fixed it with `PutBucketTagging`). I destroyed that run, and the run documented above came out clean
(`plan -detailed-exitcode` = 0 and the tags confirmed with `get-bucket-tagging`). If you see the tag diff on LocalStack,
re-apply or limit the provider to `< 6.21` (that's what the Session 19 project does). Real AWS doesn't have this problem.

To run against real AWS: set `use_localstack = false` in `terraform.tfvars`, choose a globally unique
`bucket_name`, make sure AWS credentials are configured, then run the same commands.

## Cleanup / Git hygiene

`.terraform/`, `*.tfstate*`, `*.tfplan` and crash logs are ignored by the `.gitignore` in the student folder.
`.terraform.lock.hcl` **is** committed so everybody gets the same provider version (`6.67.0`).
