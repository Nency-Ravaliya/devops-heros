# 08 - Terraform Destroy

Terraform can remove infrastructure that it manages.

Command:

```bash
terraform destroy
```

Terraform creates a destroy plan and asks for confirmation.

## Before Destroy

Check:

```bash
terraform state list
```

Example:

```text
aws_s3_bucket.lifecycle_demo
```

## Destroy

```bash
terraform destroy
```

Expected:

```text
Terraform will perform the following actions:

  # aws_s3_bucket.lifecycle_demo will be destroyed
  - resource "aws_s3_bucket" "lifecycle_demo" {
      ...
    }

Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Only 'yes' will be accepted to confirm.

Enter a value: yes
```

Then:

```text
aws_s3_bucket.lifecycle_demo: Destroying...
aws_s3_bucket.lifecycle_demo: Destruction complete after ...s

Destroy complete! Resources: 1 destroyed.
```

Terraform documents `destroy` as a destroy-mode plan followed by an approval before resources are removed.

## Important Warning

Destroy means **delete real infrastructure**.

Always inspect:

```bash
terraform plan -destroy
```

before:

```bash
terraform destroy
```

## Practice Questions:

1. What is the difference between `plan` and `apply`?
2. What does `destroy` do?
3. Why should we run `plan -destroy` before deleting production infrastructure?
