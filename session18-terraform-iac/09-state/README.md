# 09 - Terraform State

Terraform state is Terraform's record of the infrastructure it manages.

Common local state file:

```text
terraform.tfstate
```

Conceptually:

```text
main.tf
   |
   | desired configuration
   v
Terraform
   |
   +------ terraform.tfstate
   |
   v
AWS infrastructure
```

Terraform uses state to map Terraform resource addresses to real infrastructure and to determine what needs to change.

## Create Infrastructure

```bash
terraform init
terraform apply
```

Confirm:

```text
yes
```

## Inspect State

List resources:

```bash
terraform state list
```

Expected:

```text
aws_s3_bucket.state_demo
```

Show one resource:

```bash
terraform state show aws_s3_bucket.state_demo
```

Example output will contain values such as:

```text
resource "aws_s3_bucket" "state_demo" {
    arn    = "arn:aws:s3:::session18-state-xxxxxxxx"
    bucket = "session18-state-xxxxxxxx"
    id     = "session18-state-xxxxxxxx"
    ...
}
```

## Inspect Complete State

```bash
terraform show
```

## State Pull

```bash
terraform state pull
```

This prints the current state as JSON.

## Important Security Rule

Do not commit:

```text
terraform.tfstate
terraform.tfstate.*
```

State can contain sensitive infrastructure information.

Add to `.gitignore`:

```gitignore
.terraform/
terraform.tfstate
terraform.tfstate.*
*.tfplan
```

## State Refresh

Modern Terraform automatically reconciles state during normal `plan`, `apply`, and `destroy` operations.

## Never Manually Edit State

Do not open:

```text
terraform.tfstate
```

and change values manually.

Use Terraform state commands when state operations are genuinely required.

## Cleanup

```bash
terraform destroy
```

Then verify:

```bash
terraform state list
```

Expected:

```text
```

No managed resources should remain.

## Exercise

1. Run `terraform apply`.
2. Run `terraform state list`.
3. Run `terraform state show aws_s3_bucket.state_demo`.
4. Change a tag in `main.tf`.
5. Run `terraform plan`.
6. Observe the planned change.
7. Apply it.
8. Run `terraform show`.
9. Destroy the resource.
