# Session 19 — Cloud & Terraform in Action (Homework)

**Name:** Chhavi Ahlawat
**Enrollment Number:** 24BCS10201
**Email:** chhavi.24bcs10201@sst.scaler.com

---

## Homework Tasks

| Task | Description | Status |
|---|---|---|
| 1 | VPC lab — VPC, subnet, IGW, route table, SG ([`06-terraform-vpc`](06-terraform-vpc/README.md#my-lab-submission)) | ✅ |
| 2 | End-to-end project — VPC + Subnet + SG + EC2 (nginx) + S3 ([`homework/`](homework/)) | ✅ |
| 3 | Architecture diagram, terraform workflow (init → plan → apply → destroy), state | ✅ |

**Region:** `us-east-2` · **Names:** `chhavi-s19-*` · **Tag:** `Owner = chhavi`

---

## Architecture

```mermaid
flowchart TB
    user(("Internet")) --> igw["Internet Gateway<br/>chhavi-s19-igw"]
    subgraph region["AWS Region: us-east-2"]
        subgraph vpc["VPC chhavi-s19-vpc (10.30.0.0/16)"]
            igw --> rt["Route Table<br/>0.0.0.0/0 to IGW"]
            rt --> ec2
            subgraph subnet["Public Subnet (10.30.1.0/24)"]
                subgraph sg["SG chhavi-s19-web-sg: 22 from ssh_cidr, 80 from anywhere"]
                    ec2["EC2 t3.micro<br/>Amazon Linux 2023 + nginx"]
                end
            end
        end
        s3[("S3 bucket chhavi-24bcs10201-*<br/>versioning + public access blocked")]
    end
```

## Project Files (`homework/`)

| File | Concept |
|---|---|
| `versions.tf` | Provider (`hashicorp/aws ~> 6.0`) + `default_tags` |
| `variables.tf` | Variables: region, CIDRs, instance type, `ssh_cidr`, optional `key_name` |
| `main.tf` | Resources + data sources (latest AL2023 AMI, AZs) |
| `outputs.tf` | `vpc_id`, `subnet_id`, `sg_id`, `instance_public_ip`, `website_url`, `s3_bucket_name` |

**Dependencies**
- *Implicit:* references like `vpc_id = aws_vpc.main.id` and `subnet_id = aws_subnet.public.id` tell Terraform the order (VPC → subnet/IGW → route table → association).
- *Explicit:* `aws_instance.web` has `depends_on = [aws_route_table_association.public]` so the subnet has internet access before nginx is installed by `user_data`.

---

## Terraform Workflow in Action (VPC lab, `06-terraform-vpc/`)

Run on AWS in `us-east-2`: 6 resources (VPC, public subnet, IGW, route table + association, security group), all named `chhavi-session19-*`.

```bash
cd 06-terraform-vpc
terraform init
terraform plan
terraform apply
terraform state list
terraform show
terraform destroy
```

### Plan: execution plan with the resources to be created
![terraform apply plan showing chhavi-session19 resources to be created in us-east-2](06-terraform-vpc/screenshots/ss3.png)

### Apply: 6 added, outputs, and `terraform state list`
![Apply complete: 6 added, outputs, and terraform state list](06-terraform-vpc/screenshots/ss1.png)

### State: `terraform show` for the Internet Gateway and Route Table
![terraform show for the internet gateway and public route table](06-terraform-vpc/screenshots/ss2.png)

### State: `terraform show` for the Subnet, VPC and Outputs
![terraform show for the public subnet, VPC, and outputs](06-terraform-vpc/screenshots/ss4.png)

---

## Full Project: VPC + EC2 + S3 (`homework/`)

Extends the VPC lab with an EC2 web server (nginx, "Hello from Chhavi") and a versioned, private S3 bucket. 10 resources; `terraform validate` passes.

```bash
cd homework
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform validate
terraform plan                                   # 10 to add
terraform apply
curl $(terraform output -raw website_url)        # Hello from Chhavi
terraform destroy
```
