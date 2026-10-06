# Session 19 — VPC, EC2, and S3

**Name:** Viraj Bhanage
**Roll number:** 24BCS10274

`homework/session-19-cloud/main.tf` builds VPC `10.40.0.0/16`, two public subnets, an internet gateway, a security group for TCP 80, one `t3.micro` that installs Nginx from user data, and a private S3 bucket.

The instance references the subnet, the security group, and the AMI lookup, so Terraform creates those first. State stays on disk and is gitignored. I have not applied this. If it is applied, `terraform destroy` has to follow the same day.
