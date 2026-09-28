# 07 - Terraform Init, Plan and Apply

This folder demonstrates the main Terraform workflow.

## Step 1 - Init

Run:

```bash
terraform init
```

`terraform init` prepares the working directory, installs required providers, configures the backend, and creates/updates the dependency lock file. It is safe to run repeatedly.

Expected:

```text
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 6.0"...
- Installing hashicorp/aws v6.x.x...
- Installed hashicorp/aws v6.x.x...

Terraform has been successfully initialized!
```

## Step 2 - Format

```bash
terraform fmt
```

Expected:

```text
main.tf
```

or no output if already formatted.

## Step 3 - Validate

```bash
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

## Step 4 - Plan

```bash
terraform plan
```

Terraform previews the changes without creating the resource. The plan symbols include:

```text
+ create
~ update
- destroy
-/+ replace
```

For a new bucket:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

Terraform's plan compares configuration and state to determine the required actions.

## Step 5 - Apply

```bash
terraform apply
```

Terraform shows the plan and asks:

```text
Do you want to perform these actions?
  Only 'yes' will be accepted to approve.

Enter a value:
```

Type:

```text
yes
```

Expected:

```text
aws_s3_bucket.lifecycle_demo: Creating...
aws_s3_bucket.lifecycle_demo: Creation complete after ...s

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

bucket_name = "session18-lifecycle-xxxxxxxx"
```

## Saved Plan

For controlled CI/CD workflows:

```bash
terraform plan -out=tfplan
```

Then:

```bash
terraform apply tfplan
```

A saved plan allows the apply step to execute the reviewed plan rather than generating a new plan.

## Student Exercise

Run the complete sequence:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output
terraform state list
```
