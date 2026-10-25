# Terraform S3 Bucket Demo

**Name:** Kushal Talati · **Enrollment No:** 24BCS10123  
**Target:** LocalStack 4.0.3 at `http://localhost:4566` (the laptop's AWS credentials are invalid – see the [session README](../README.md)). Same code works on real AWS by omitting `-var-file=localstack.tfvars`.

Raw log of everything below: [../logs/01-terraform-s3-workflow.txt](../logs/01-terraform-s3-workflow.txt), produced by [../scripts/01-terraform-s3-workflow.sh](../scripts/01-terraform-s3-workflow.sh).

## Project structure

```text
terraform-s3-demo/
├── terraform.tf        # required_version >= 1.6, hashicorp/aws ~> 6.0
├── provider.tf         # provider "aws" { region = var.aws_region ... }  + LocalStack switch
├── variables.tf        # aws_region, bucket_name (validated), environment, aws_endpoint_url (null = real AWS)
├── terraform.tfvars    # region, bucket name, environment (no secrets)
├── localstack.tfvars   # aws_endpoint_url = "http://localhost:4566"
├── main.tf             # aws_s3_bucket + versioning + SSE + public access block + one object
├── outputs.tf          # name, arn, region, domain name, versioning status, object version id
├── .gitignore          # .terraform/, *.tfstate*, tfplan
└── README.md
```

## Architecture

```text
 terraform.tfvars ─┐                     ┌─ aws_s3_bucket.demo                         (the bucket)
 localstack.tfvars ┼─▶ variables.tf ─▶   ├─ aws_s3_bucket_versioning.demo              (Enabled)
                   │                     ├─ aws_s3_bucket_server_side_encryption_configuration.demo (AES256)
 provider.tf ──────┘  (region/endpoint)  ├─ aws_s3_bucket_public_access_block.demo     (4 x true)
                                         └─ aws_s3_object.readme   depends_on versioning  (hello/README.txt)
                                                      │
                                              outputs.tf ─▶ bucket_arn, readme_object_version, ...
```

## The LocalStack switch in `provider.tf`

```hcl
provider "aws" {
  region = var.aws_region
  # ---- LocalStack only (all of this is null/false on real AWS) ----
  access_key                  = var.aws_endpoint_url == null ? null : "test"
  secret_key                  = var.aws_endpoint_url == null ? null : "test"
  skip_credentials_validation = var.aws_endpoint_url != null
  skip_metadata_api_check     = var.aws_endpoint_url != null
  skip_requesting_account_id  = var.aws_endpoint_url != null
  skip_region_validation      = var.aws_endpoint_url != null
  s3_use_path_style           = var.aws_endpoint_url != null
  dynamic "endpoints" {
    for_each = var.aws_endpoint_url == null ? [] : [var.aws_endpoint_url]
    content { s3 = endpoints.value  sts = endpoints.value  iam = endpoints.value }
  }
}
```

With `aws_endpoint_url = null` every line evaluates to the provider's defaults, so the block is identical to the professor's `provider "aws" { region = var.aws_region }`.

## Workflow

### 1. `terraform init`

```text
$ terraform init -input=false
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using hashicorp/aws v6.67.0 from the shared cache directory
Terraform has been successfully initialized!
```

`init` reads `required_providers`, downloads the provider plugin into `.terraform/` and pins the exact version + checksums in `.terraform.lock.hcl` (committed, so everyone gets the same provider). I point `TF_PLUGIN_CACHE_DIR` at a shared folder because the AWS provider binary is ~700 MB.

### 2. `terraform fmt`

```text
$ terraform fmt -recursive -diff; echo "exit code: $?"
exit code: 0
```

No diff: the files were already canonical (2-space indent, aligned `=`).

### 3. `terraform validate`

```text
$ terraform validate
Success! The configuration is valid.
```

Checks syntax, types and references **without** touching any API – a `validate` would have caught the `skip_requests_validation` argument I originally had in `provider.tf`, which does not exist in provider v6 (`skip_requesting_account_id` is the right one).

### 4. `terraform plan`

```text
$ terraform plan -input=false -var-file=localstack.tfvars -out=tfplan
  # aws_s3_bucket.demo will be created
  # aws_s3_bucket_public_access_block.demo will be created
  # aws_s3_bucket_server_side_encryption_configuration.demo will be created
  # aws_s3_bucket_versioning.demo will be created
  # aws_s3_object.readme will be created
Plan: 5 to add, 0 to change, 0 to destroy.
```

Saved to `tfplan` so that `apply` executes exactly this plan and nothing else.

### 5. `terraform apply`

```text
$ terraform apply -input=false -auto-approve tfplan
aws_s3_bucket.demo: Creating...
aws_s3_bucket.demo: Creation complete after 0s [id=kushal-24bcs10123-s18-demo]
aws_s3_bucket_versioning.demo: Creating...
aws_s3_bucket_public_access_block.demo: Creating...
aws_s3_bucket_server_side_encryption_configuration.demo: Creating...
...
aws_s3_object.readme: Creation complete after 0s [id=kushal-24bcs10123-s18-demo/hello/README.txt]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

The bucket is created first; the three configuration resources and the object wait for it because they reference `aws_s3_bucket.demo.id` (implicit dependency), and the object additionally has `depends_on = [aws_s3_bucket_versioning.demo]` so it gets a real version id.

### 6. `terraform show`

```text
$ terraform state list
aws_s3_bucket.demo
aws_s3_bucket_public_access_block.demo
aws_s3_bucket_server_side_encryption_configuration.demo
aws_s3_bucket_versioning.demo
aws_s3_object.readme

$ terraform state show aws_s3_bucket.demo
# aws_s3_bucket.demo:
resource "aws_s3_bucket" "demo" {
    arn                         = "arn:aws:s3:::kushal-24bcs10123-s18-demo"
    bucket                      = "kushal-24bcs10123-s18-demo"
    bucket_domain_name          = "kushal-24bcs10123-s18-demo.s3.amazonaws.com"
    bucket_regional_domain_name = "kushal-24bcs10123-s18-demo.s3.ap-south-1.amazonaws.com"
    force_destroy               = true
    region                      = "ap-south-1"
    tags                        = {}          <- LocalStack 4.0.3 did not keep the bucket tags (see step 9)
    server_side_encryption_configuration { rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } } }
    ...
```

`terraform show` prints the whole state; `state show <addr>` one resource. This is what Terraform *believes* exists.

### 7. `terraform output`

```text
$ terraform output
bucket_arn = "arn:aws:s3:::kushal-24bcs10123-s18-demo"
bucket_domain_name = "kushal-24bcs10123-s18-demo.s3.amazonaws.com"
bucket_name = "kushal-24bcs10123-s18-demo"
bucket_region = "ap-south-1"
readme_object_version = "3TybyxjZtFeuflxuhhibpmuyWoep601_"
versioning_status = "Enabled"

$ terraform output -raw bucket_arn
arn:aws:s3:::kushal-24bcs10123-s18-demo
```

`-raw` is for shell scripts, `-json` for anything else that needs to consume the values (a CI job, another Terraform root module).

### 8. Verify with the AWS CLI – what actually exists

```text
$ aws --endpoint-url=http://localhost:4566 s3 ls
2026-10-07 23:10:51 kushal-24bcs10123-s18-demo

$ awsl s3api get-bucket-versioning --bucket kushal-24bcs10123-s18-demo
{ "Status": "Enabled" }

$ awsl s3api get-bucket-encryption --bucket kushal-24bcs10123-s18-demo
{ "ServerSideEncryptionConfiguration": { "Rules": [ { "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" }, "BucketKeyEnabled": false } ] } }

$ awsl s3api get-public-access-block --bucket kushal-24bcs10123-s18-demo
{ "PublicAccessBlockConfiguration": { "BlockPublicAcls": true, "IgnorePublicAcls": true, "BlockPublicPolicy": true, "RestrictPublicBuckets": true } }

$ awsl s3 ls s3://kushal-24bcs10123-s18-demo --recursive
2026-10-07 23:10:52         57 hello/README.txt

$ awsl s3 cp /tmp/s18-note.txt s3://kushal-24bcs10123-s18-demo/hello/note.txt      (twice)
$ awsl s3api list-object-versions --bucket kushal-24bcs10123-s18-demo --prefix hello/note.txt ... --output table
| IsLatest |       Key       | Size  |              VersionId              |
|  True    |  hello/note.txt |  51   |  ZNYoVBu0b7LjU7oVbGrpfFfU3kgHcyoW   |
|  False   |  hello/note.txt |  51   |  6OCGfQjCPgwqrf40KO68FCU7xOqAl6gI   |

$ awsl s3 cp s3://kushal-24bcs10123-s18-demo/hello/README.txt -
Created by Terraform for Session 18 (kushal-24bcs10123).
```

Versioning, encryption and the public-access block are all really set; uploading the same key twice kept both versions. One honest gap: `get-bucket-tagging` returned `NoSuchTagSet` – LocalStack's S3 did not store the tags sent on `CreateBucket`.

### 9. Plan again – drift and unmanaged objects

```text
$ terraform plan -var-file=localstack.tfvars -detailed-exitcode | tail -4
exit code: 2  (0 = no changes, 2 = changes pending)
```

Two things in one step. The object I uploaded by hand (`hello/note.txt`) does **not** appear in the plan at all – Terraform only reconciles resources that are in its state. And the plan is not empty because of the tag problem above: Terraform refreshed the bucket, saw `tags = {}` and wants to put the five tags back. On real AWS, where tags stick, this step returns exit code 0. That is exactly what "drift detection" means – `plan` compares desired (code) vs recorded (state) vs real (API).

### 10. Change an input – in-place update

```text
$ terraform plan -var-file=localstack.tfvars -var environment=staging | grep -E '~|Plan:'
  ~ update in-place
  ~ resource "aws_s3_bucket" "demo" {
      ~ tags                        = {
Plan: 0 to add, 1 to change, 0 to destroy.
```

Changing a tag is an update (`~`), not a replace (`-/+`) – Terraform knows from the provider schema which attributes force a new resource (e.g. `bucket` name) and which do not.

### 11. `terraform destroy`

```text
$ terraform destroy -input=false -auto-approve -var-file=localstack.tfvars
Plan: 0 to add, 0 to change, 5 to destroy.
aws_s3_bucket_public_access_block.demo: Destroying...
aws_s3_bucket_server_side_encryption_configuration.demo: Destroying...
aws_s3_object.readme: Destroying...
aws_s3_bucket_versioning.demo: Destroying...
aws_s3_bucket.demo: Destroying... [id=kushal-24bcs10123-s18-demo]
aws_s3_bucket.demo: Destruction complete after 0s
Destroy complete! Resources: 5 destroyed.

$ awsl s3 ls
(buckets left: 0)
$ terraform state list
(state is empty)
```

Destroy runs the dependency graph backwards (object and settings first, bucket last). `force_destroy = true` is what allowed deleting a bucket that still had the manually uploaded `note.txt` (and its two versions) inside – without it, S3 refuses to delete a non-empty bucket.

## What I understood

* Six commands, one mental model: **`init` fetches plugins, `validate`/`fmt` check the code, `plan` is a diff, `apply` executes the diff and writes state, `destroy` is a plan whose target is "nothing".**
* The **dependency graph is derived from references** (`aws_s3_bucket.demo.id`), explicit `depends_on` is only for ordering the provider cannot infer.
* **State ≠ reality**: a manual upload was invisible, a dropped tag was flagged. Plan before every apply, and keep state somewhere shared and locked.
* The provider block is the only place the target cloud leaks in; the same `main.tf` creates the bucket on LocalStack today and on AWS the day I have a working account.
