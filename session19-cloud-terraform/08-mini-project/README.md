# Session 19 Terraform Mini Project

This project creates the network, compute, and storage parts from the assignment in one Terraform state.

## Resources

- VPC `10.20.0.0/16`
- public subnet `10.20.1.0/24`
- Internet Gateway and default route
- Security Group for HTTP/HTTPS
- encrypted EC2 instance running Nginx
- versioned and encrypted S3 bucket with public access blocked

## Architecture

```text
                         Internet
                            |
                   Internet Gateway
                            |
                    Public Route Table
                            |
                 Public Subnet 10.20.1.0/24
                            |
                     Security Group
                            |
                       EC2 + Nginx

             Terraform-managed private S3 bucket
```

## Run

```bash
cp terraform.tfvars.example terraform.tfvars
# Replace ami_id with an Amazon Linux 2023 AMI from the selected region.

terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Verify the results:

```bash
terraform output
terraform state list
curl "http://$(terraform output -raw web_public_ip)"
aws s3api head-bucket --bucket "$(terraform output -raw bucket_name)"
```

Expected state addresses include the VPC, subnet, route resources, Security Group, EC2 instance, and the four S3 resources.

## Cleanup

```bash
terraform plan -destroy
terraform destroy
```

I run cleanup after collecting the outputs because EC2 and other AWS resources can generate charges while they remain provisioned.
