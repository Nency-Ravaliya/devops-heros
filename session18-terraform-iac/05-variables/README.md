# 05 - Variables

Without variables:

```hcl
bucket_prefix = "student-project-dev-"
```

With variables:

```hcl
bucket_prefix = "${var.project_name}-${var.environment}-"
```

Now the same code can be reused for:

```text
dev
test
staging
prod
```

## Variable Structure

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
```

Use it:

```hcl
var.environment
```

## Variable Values

Terraform can receive variables from several sources. For this lab, use `terraform.tfvars`.

Copy:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit if required:

```hcl
aws_region   = "ap-south-1"
environment  = "dev"
project_name = "student-project"
```

## Commands

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

You should see a resource using your variable values.

## Important

Do not commit sensitive variable values.

Add this to `.gitignore` in real projects:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
*.tfplan
```

## Exercise

Change:

```hcl
environment = "dev"
```

to:

```hcl
environment = "test"
```

Run:

```bash
terraform plan
```

## Practice Question:

**Why does changing a variable change the desired infrastructure configuration?**
