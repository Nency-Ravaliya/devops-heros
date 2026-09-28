# 06 - Outputs

Outputs expose useful values from Terraform.

Example:

```hcl
output "bucket_id" {
  value = aws_s3_bucket.demo.id
}
```

## Apply

```bash
terraform init
terraform plan
terraform apply
```

After approval:

```text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn    = "arn:aws:s3:::session18-output-xxxxxxxx"
bucket_id     = "session18-output-xxxxxxxx"
bucket_region = "ap-south-1"
```

The exact bucket name is generated dynamically.

## Read outputs

```bash
terraform output
```

Read one output:

```bash
terraform output bucket_id
```

Example:

```text
session18-output-xxxxxxxx
```

## Why Outputs Matter

Outputs are useful when:

- Passing information to another module
- Displaying resource IDs
- Feeding values into automation
- CI/CD pipelines
- Sharing infrastructure information

## Exercise

Add:

```hcl
output "bucket_name" {
  value = aws_s3_bucket.demo.bucket
}
```

Then run:

```bash
terraform apply
terraform output bucket_name
```
