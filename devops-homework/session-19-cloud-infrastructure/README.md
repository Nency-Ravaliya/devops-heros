# Session 19: Cloud infrastructure with Terraform

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

```text
Client CIDR → Internet Gateway → VPC public subnet → HTTP Security Group → EC2/Apache
AWS account → private encrypted versioned S3 bucket (separate from EC2)
```

The provider creates a VPC, subnet, gateway, routes, a restricted HTTP Security
Group, EC2 with IMDSv2/encrypted EBS, and S3. The AMI comes from Amazon's regional
catalog. There is no SSH rule or embedded AWS credential.

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit allowed_http_cidr to your public IPv4 address /32.
export AWS_PROFILE=student
terraform init
terraform fmt -check
terraform validate
terraform plan -out=practice.tfplan
terraform apply practice.tfplan
terraform output
curl "$(terraform output -raw web_url)"
terraform show
terraform destroy
```

Resource references express dependencies; the EC2 dependency waits for routes
before user-data needs Internet access. Installation may take minutes after apply.
Check cloud-init output if HTTP is not ready. State maps resource addresses to
AWS IDs; keep it private and use a locked remote backend for teamwork.
Empty S3 versions before destroy. AWS deployment and teardown evidence require
an actual account. Local formatting output is in `evidence/`.

## Verification

Terraform formatting passed.

Provider validation, AWS plan/apply/destroy and console evidence need provider downloads and an account.

Command output: [evidence/](evidence/).
