# S3 with Terraform

Authenticate using AWS SSO or a profile outside Git. No access keys belong in tfvars.
The bucket has a generated unique name, public access blocked, AES256 encryption,
and versioning enabled.

```bash
aws sso login --profile student
export AWS_PROFILE=student
terraform init
terraform fmt -check
terraform validate
terraform plan -out=practice.tfplan
terraform apply practice.tfplan
terraform show
terraform output
terraform destroy
```

init installs providers; fmt standardizes layout; validate checks configuration;
plan previews changes; apply creates resources; show reads state; output prints
selected attributes; destroy previews and removes the managed resources.
References order the bucket and its settings automatically. Keep the generated
lock file after initialization, but keep state/plans private. Empty all bucket
objects, versions, and delete markers before destroy; force deletion is disabled.
Actual AWS create/destroy output requires a configured account; see ../evidence/.
