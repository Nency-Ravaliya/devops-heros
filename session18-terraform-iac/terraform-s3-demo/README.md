# Terraform S3 Demo

This project creates an **AWS S3 bucket with Terraform** and walks through the complete Terraform workflow:
`init → fmt → validate → plan → apply → show → output → destroy`.

All output below is real, captured from running the commands in this folder.

## Project structure

```text
terraform-s3-demo/
├── main.tf             # the S3 bucket resource
├── variables.tf        # input variables (region, bucket name, environment, endpoint)
├── outputs.tf          # values printed after apply (name, ARN, region)
├── provider.tf         # terraform {} block (version pins) + AWS provider config
├── terraform.tfvars    # values for the variables
├── screenshots/        # terminal screenshots of every step
└── README.md
```

| File | Purpose |
|---|---|
| [provider.tf](provider.tf) | Pins Terraform `>= 1.6.0` and the `hashicorp/aws ~> 6.0` provider, and configures the AWS region (plus optional emulator endpoint) |
| [variables.tf](variables.tf) | Declares `aws_region`, `bucket_name`, `environment`, `aws_endpoint_url` |
| [terraform.tfvars](terraform.tfvars) | Sets the variable values. Terraform loads this file automatically. |
| [main.tf](main.tf) | `aws_s3_bucket.demo` with tags and `force_destroy = true`, so `destroy` works even if the bucket has objects |
| [outputs.tf](outputs.tf) | `bucket_name`, `bucket_arn`, `bucket_region` |

## How the files fit together

```text
terraform.tfvars ──► variables.tf ──► provider.tf (region, endpoint)
                                  └─► main.tf  ── aws_s3_bucket.demo ──► S3 bucket
                                                          │
                                                          ▼
                                                     outputs.tf ──► terraform output
                         terraform.tfstate ◄── records what was created
```

## Where the bucket is created: real AWS vs local emulator

No AWS account was available for this assignment, so the workflow was run against **[Moto](https://github.com/getmoto/moto)**, a free, open-source AWS emulator running in Docker. It implements the real S3 and STS APIs, so Terraform and the AWS CLI behave exactly as they do against AWS. (LocalStack was tried first, but its latest image now requires a paid licence token.)

The same code deploys to **real AWS** by changing one value in `terraform.tfvars`:

```hcl
aws_endpoint_url = ""                        # real AWS (uses your `aws configure` credentials)
aws_endpoint_url = "http://localhost:4577"   # local Moto emulator (used for this run)
```

When `aws_endpoint_url` is set, [provider.tf](provider.tf) points the S3 and STS endpoints at it and turns on path-style S3 URLs. It also skips the credential and account-ID checks that only real AWS supports.

> **Emulator limitation:** AWS provider v6 sends the bucket tags inside the `CreateBucket` request. Real AWS applies them, but Moto ignores them, so `terraform show` below lists `tags = {}`. The plan shows the four tags that would be applied on real AWS.

## Prerequisites

| Tool | Install | Used version |
|---|---|---|
| Terraform | `brew tap hashicorp/tap && brew install hashicorp/tap/terraform` | v1.16.4 |
| AWS CLI | `brew install awscli` | aws-cli 1.46 |
| Docker | Docker Desktop (only for the emulator) | – |

For real AWS, run `aws configure` and give it an access key for an IAM user with S3 permissions. For the emulator, set dummy credentials as shown in step 0.

---

## Step 0 · Start the AWS emulator and point the CLI at it

```bash
docker run -d --name moto-aws -p 4577:5000 motoserver/moto:latest
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-south-1 AWS_ENDPOINT_URL=http://localhost:4577
aws sts get-caller-identity
aws s3 ls
```

```text
NAMES      IMAGE                    STATUS              PORTS
moto-aws   motoserver/moto:latest   Up About a minute   0.0.0.0:4577->5000/tcp, [::]:4577->5000/tcp
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
(no buckets yet)
```

![AWS emulator setup](screenshots/01-aws-emulator-setup.png)

```bash
terraform version
```

![terraform version](screenshots/02-terraform-version.png)

## Step 1 · `terraform init`

**Initializes the working directory.** It downloads the providers declared in `required_providers` into `.terraform/`, sets up the backend (local state here), and creates or reads `.terraform.lock.hcl` to pin the exact provider version.

```text
Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Installing hashicorp/aws v6.66.0...
- Installed hashicorp/aws v6.66.0 (signed by HashiCorp)

Terraform has been successfully initialized!
```

![terraform init](screenshots/03-terraform-init.png)

## Step 2 · `terraform fmt`

**Rewrites `.tf` files into the canonical style** (indentation, aligned `=`). It prints the names of the files it changed and prints nothing when they are already formatted. `-check` only reports and does not write changes, which is useful in CI.

```text
$ terraform fmt
$ terraform fmt -check -diff && echo 'All files are correctly formatted'
All files are correctly formatted
```

![terraform fmt](screenshots/04-terraform-fmt.png)

## Step 3 · `terraform validate`

**Checks that the configuration is syntactically valid and internally consistent**: correct argument names and types, and variables and resources that exist. It does not contact AWS.

```text
Success! The configuration is valid.
```

![terraform validate](screenshots/05-terraform-validate.png)

> While preparing this project, `validate` would have failed on the original `outputs.tf` because it had `type = string` inside `output` blocks. `type` is only valid on `variable` blocks, so it was removed.

## Step 4 · `terraform plan`

**Shows what Terraform will change**, without changing anything. It compares the configuration with the state and the real infrastructure. `+` means create, `~` means update in place, `-` means destroy.

```text
Terraform will perform the following actions:

  # aws_s3_bucket.demo will be created
  + resource "aws_s3_bucket" "demo" {
      + arn                         = (known after apply)
      + bucket                      = "anuskaroy-session18-tf-demo"
      + force_destroy               = true
      + region                      = "ap-south-1"
      + tags                        = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "anuskaroy-session18-tf-demo"
          + "Project"     = "Session18"
        }
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_arn    = (known after apply)
  + bucket_name   = "anuskaroy-session18-tf-demo"
  + bucket_region = "ap-south-1"
```

![terraform plan](screenshots/06-terraform-plan.png)

## Step 5 · `terraform apply`

**Executes the plan.** Terraform shows the plan again and waits for `yes`. It then calls the AWS API to create the bucket, records the result in `terraform.tfstate`, and prints the outputs.

```text
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_s3_bucket.demo: Creating...
aws_s3_bucket.demo: Creation complete after 1s [id=anuskaroy-session18-tf-demo]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::anuskaroy-session18-tf-demo"
bucket_name = "anuskaroy-session18-tf-demo"
bucket_region = "ap-south-1"
```

![terraform apply](screenshots/07-terraform-apply.png)

**Verify the bucket exists with the AWS CLI:**

```text
$ aws s3 ls
2026-10-07 21:09:13 anuskaroy-session18-tf-demo
$ aws s3api head-bucket --bucket anuskaroy-session18-tf-demo
{
    "BucketRegion": "ap-south-1"
}
$ aws s3api get-bucket-location --bucket anuskaroy-session18-tf-demo
{
    "LocationConstraint": "ap-south-1"
}
```

![verify bucket with AWS CLI](screenshots/08-verify-bucket-aws-cli.png)

## Step 6 · `terraform show`

**Prints the current state in readable form**: every attribute Terraform knows about the managed resources, including values computed by AWS such as `arn`, `bucket_domain_name` and `hosted_zone_id`.

```text
# aws_s3_bucket.demo:
resource "aws_s3_bucket" "demo" {
    arn                         = "arn:aws:s3:::anuskaroy-session18-tf-demo"
    bucket                      = "anuskaroy-session18-tf-demo"
    bucket_domain_name          = "anuskaroy-session18-tf-demo.s3.amazonaws.com"
    bucket_region               = "ap-south-1"
    bucket_regional_domain_name = "anuskaroy-session18-tf-demo.s3.ap-south-1.amazonaws.com"
    force_destroy               = true
    hosted_zone_id              = "Z11RGJOFQNVJUP"
    id                          = "anuskaroy-session18-tf-demo"
    object_lock_enabled         = false
    region                      = "ap-south-1"
    ...
    versioning {
        enabled    = false
        mfa_delete = false
    }
}
```

![terraform show](screenshots/09-terraform-show.png)

`terraform state list` lists every resource address in the state:

```text
aws_s3_bucket.demo
```

![terraform state list](screenshots/10-terraform-state-list.png)

## Step 7 · `terraform output`

**Reads output values from the state** without re-running apply. Use it to pass values to scripts or other tools.

```text
$ terraform output
bucket_arn = "arn:aws:s3:::anuskaroy-session18-tf-demo"
bucket_name = "anuskaroy-session18-tf-demo"
bucket_region = "ap-south-1"
$ terraform output bucket_name
"anuskaroy-session18-tf-demo"
$ terraform output -raw bucket_arn
arn:aws:s3:::anuskaroy-session18-tf-demo
$ terraform output -json
{
  "bucket_arn": { "sensitive": false, "type": "string", "value": "arn:aws:s3:::anuskaroy-session18-tf-demo" },
  ...
}
```

![terraform output](screenshots/11-terraform-output.png)

## Step 8 · `terraform destroy`

**Deletes everything this configuration manages.** Terraform shows a destroy plan (`-`) and asks for `yes`. Because of `force_destroy = true`, the bucket is deleted even if it still contains objects.

```text
Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

aws_s3_bucket.demo: Destroying... [id=anuskaroy-session18-tf-demo]
aws_s3_bucket.demo: Destruction complete after 1s

Destroy complete! Resources: 1 destroyed.
```

![terraform destroy](screenshots/12-terraform-destroy.png)

**Verify that nothing is left:**

```text
$ terraform state list; echo "state entries: $(terraform state list | wc -l | tr -d ' ')"
state entries: 0
$ aws s3 ls; echo "buckets: $(aws s3 ls | wc -l | tr -d ' ')"
buckets: 0
```

![verify destroyed](screenshots/13-verify-destroyed.png)

---

## Command summary

| Command | What it does | Changes infrastructure? |
|---|---|---|
| `terraform init` | download providers, set up backend, write lock file | no |
| `terraform fmt` | format `.tf` files | no (rewrites files only) |
| `terraform validate` | check syntax and internal consistency | no |
| `terraform plan` | preview create/update/destroy actions | no |
| `terraform apply` | perform the changes, update state | **yes** |
| `terraform show` | display state in human-readable form | no |
| `terraform output` | print output values from state | no |
| `terraform destroy` | delete all managed resources | **yes** |

## Files that are not committed

`.gitignore` excludes `.terraform/` (downloaded providers), `*.tfstate*` (state can contain sensitive values and belongs in a remote backend such as S3 for teams) and `*.tfplan`.
`terraform.tfvars` **is** committed here because it is a deliverable and contains no secrets. Never put credentials in it.

## Cleanup

```bash
terraform destroy           # already done above
docker rm -f moto-aws       # stop the emulator
```
