# Session 19: Cloud & Terraform in Action

This session covers an end-to-end cloud infrastructure project provisioned on AWS using HashiCorp Terraform.

---

## 1. Project Overview & Suggested Architecture

```text
                           [ Terraform Configuration ]
                                        │
                   ┌────────────────────┴────────────────────┐
                   ▼                                         ▼
         [ AWS VPC: 10.20.0.0/16 ]                  [ S3 Asset Bucket ]
                   │
         [ Internet Gateway (IGW) ]
                   │
         [ Public Subnet: 10.20.1.0/24 ]
                   │
         [ Security Group (Ports 80, 22) ]
                   │
         [ EC2 Instance (Web Server) ]
```

### Components Demonstrated:
1. **Terraform Providers:** Official HashiCorp `hashicorp/aws` provider.
2. **Variables:** Parameterized AWS region (`var.aws_region`), VPC CIDR, instance types, and environment tags.
3. **Resources:** `aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_route_table`, `aws_route_table_association`, `aws_security_group`, `aws_instance`, `aws_s3_bucket`.
4. **Outputs:** Public IP address of the EC2 instance, VPC ID, S3 bucket name.
5. **Resource Dependencies:** Explicit (`depends_on`) and implicit attribute references (`vpc_id = aws_vpc.main.id`).
6. **State Management:** Tracking real-world cloud state in `terraform.tfstate`.

---

## 2. Directory Structure

```text
session19-cloud-terraform/
├── 01-cloud-service-models/
├── 02-regions-and-availability-zones/
├── 03-vpc-and-subnets/
├── 04-route-tables-and-internet-gateway/
├── 05-security-groups/
├── 06-terraform-vpc/         # Modular VPC IaC codebase
├── 07-terraform-workflow/    # Terraform execution commands & notes
├── 08-mini-project/          # Complete AWS deployment manifests
└── README.md
```

---

## 3. Step-by-Step Terraform Commands

```bash
cd 08-mini-project

# 1. Initialize AWS provider plugins
terraform init

# 2. Validate configuration syntax
terraform validate

# 3. Preview planned infrastructure additions
terraform plan -out=tfplan

# 4. Provision resources on AWS
terraform apply tfplan

# 5. Inspect deployed outputs (Public IP, Bucket Name)
terraform output

# 6. Tear down all AWS resources
terraform destroy -auto-approve
```

---

## 4. Deliverables & Screenshot Evidence

* **Screenshot 1: Architecture Diagram / AWS Console Resources**  
  <!-- Add screenshot: ![AWS Resources](screenshots/aws-resources.png) -->

* **Screenshot 2: `terraform plan` Output**  
  <!-- Add screenshot: ![Terraform Plan](screenshots/terraform-plan.png) -->

* **Screenshot 3: `terraform apply` Success & Outputs**  
  <!-- Add screenshot: ![Terraform Apply](screenshots/terraform-apply.png) -->

* **Screenshot 4: `terraform destroy` Completion**  
  <!-- Add screenshot: ![Terraform Destroy](screenshots/terraform-destroy.png) -->
