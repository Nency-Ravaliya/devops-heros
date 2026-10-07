# Session 19 — Cloud & Terraform in Action

> **End-to-end AWS infrastructure project built entirely with Terraform**

---

## 📐 Architecture

```
                          Internet
                             │
                    ┌────────▼────────┐
                    │ Internet Gateway │
                    └────────┬────────┘
                             │
              ┌──────────────▼──────────────┐
              │         VPC                  │
              │      10.20.0.0/16            │
              │                              │
              │  ┌───────────────────────┐   │
              │  │    Public Subnet      │   │
              │  │    10.20.1.0/24       │   │
              │  │                       │   │
              │  │  ┌─────────────────┐  │   │
              │  │  │ Security Group  │  │   │
              │  │  │  Port 22/80/443 │  │   │
              │  │  └────────┬────────┘  │   │
              │  │           │           │   │
              │  │  ┌────────▼────────┐  │   │
              │  │  │   EC2 Instance  │  │   │
              │  │  │   t3.micro      │  │   │
              │  │  │   Nginx Server  │  │   │
              │  │  └─────────────────┘  │   │
              │  └───────────────────────┘   │
              │                              │
              │  ┌───────────────────────┐   │
              │  │       S3 Bucket       │   │
              │  │  session19-artifacts  │   │
              │  │  Versioning + AES256  │   │
              │  └───────────────────────┘   │
              └──────────────────────────────┘

Terraform manages all resources above
```

---

## 📁 Project Structure

```
session19-cloud-terraform/
├── 01-cloud-service-models/       # IaaS, PaaS, SaaS concepts
├── 02-regions-and-availability-zones/  # AWS global infrastructure
├── 03-vpc-and-subnets/            # VPC and subnet fundamentals
├── 04-route-tables-and-internet-gateway/  # Routing concepts
├── 05-security-groups/            # Security group rules
├── 06-terraform-vpc/              # Terraform VPC lab
├── 07-terraform-workflow/         # Terraform core commands
└── 08-mini-project/               # ← Full end-to-end project
    ├── versions.tf                # Terraform & provider version pins
    ├── variables.tf               # Input variable declarations
    ├── terraform.tfvars           # Variable values
    ├── main.tf                    # All AWS resources
    ├── outputs.tf                 # Output values
    └── .gitignore
```

---

## ☁️ AWS Resources Provisioned

| Resource | Name | Description |
|---|---|---|
| `aws_vpc` | `session19-mini-vpc` | VPC with CIDR 10.20.0.0/16 |
| `aws_subnet` | `session19-mini-public-subnet` | Public subnet 10.20.1.0/24 |
| `aws_internet_gateway` | `session19-mini-igw` | Internet access for VPC |
| `aws_route_table` | `session19-mini-public-rt` | Routes 0.0.0.0/0 → IGW |
| `aws_route_table_association` | — | Links subnet to route table |
| `aws_security_group` | `session19-mini-web-sg` | Ports 22, 80, 443 |
| `aws_instance` | `session19-mini-web-server` | t3.micro EC2 with Nginx |
| `aws_s3_bucket` | `session19-cloud-terraform-artifacts` | Versioned, AES256 encrypted |

---

## 🚀 Terraform Workflow

### Prerequisites

```bash
# Install Terraform
terraform --version

# Configure AWS credentials
aws configure
aws sts get-caller-identity
```

### Step 1 — Initialize

```bash
cd 08-mini-project
terraform init
```

**Output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.52.0...

Terraform has been successfully initialized!
```

### Step 2 — Format & Validate

```bash
terraform fmt
terraform validate
```

**Output:**
```
Success! The configuration is valid.
```

### Step 3 — Plan

```bash
terraform plan
```

**Output:**
```
Terraform will perform the following actions:

  # aws_instance.web will be created
  + resource "aws_instance" "web" {
      + ami           = "ami-0f58b397bc5c1f2e8"
      + instance_type = "t3.micro"
      ...
    }

  # aws_internet_gateway.main will be created
  # aws_route_table.public will be created
  # aws_route_table_association.public will be created
  # aws_s3_bucket.artifacts will be created
  # aws_s3_bucket_server_side_encryption_configuration.artifacts will be created
  # aws_s3_bucket_versioning.artifacts will be created
  # aws_security_group.web will be created
  # aws_subnet.public will be created
  # aws_vpc.main will be created

Plan: 10 to add, 0 to change, 0 to destroy.
```

### Step 4 — Apply

```bash
terraform apply
# Type: yes
```

**Output:**
```
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 2s [id=vpc-0a1b2c3d4e5f]
aws_subnet.public: Creating...
aws_internet_gateway.main: Creating...
aws_subnet.public: Creation complete after 1s [id=subnet-0f1e2d3c4b5a]
aws_internet_gateway.main: Creation complete after 1s [id=igw-0a9b8c7d6e5f]
aws_route_table.public: Creating...
aws_security_group.web: Creating...
aws_s3_bucket.artifacts: Creating...
aws_route_table.public: Creation complete after 1s [id=rtb-0a1b2c3d4e5f]
aws_route_table_association.public: Creating...
aws_security_group.web: Creation complete after 2s [id=sg-0a1b2c3d4e5f]
aws_s3_bucket.artifacts: Creation complete after 3s [id=session19-cloud-terraform-artifacts]
aws_s3_bucket_versioning.artifacts: Creating...
aws_s3_bucket_server_side_encryption_configuration.artifacts: Creating...
aws_instance.web: Creating...
aws_instance.web: Still creating... [10s elapsed]
aws_instance.web: Creation complete after 32s [id=i-0a1b2c3d4e5f6789]

Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

ec2_instance_id  = "i-0a1b2c3d4e5f6789"
ec2_public_dns   = "ec2-13-233-12-45.ap-south-1.compute.amazonaws.com"
ec2_public_ip    = "13.233.12.45"
s3_bucket_arn    = "arn:aws:s3:::session19-cloud-terraform-artifacts"
s3_bucket_name   = "session19-cloud-terraform-artifacts"
security_group_id = "sg-0a1b2c3d4e5f"
subnet_id        = "subnet-0f1e2d3c4b5a"
vpc_cidr         = "10.20.0.0/16"
vpc_id           = "vpc-0a1b2c3d4e5f"
```

### Step 5 — Show & Inspect

```bash
# Show all resources in state
terraform show

# List resources
terraform state list
```

**State list output:**
```
aws_instance.web
aws_internet_gateway.main
aws_route_table.public
aws_route_table_association.public
aws_s3_bucket.artifacts
aws_s3_bucket_server_side_encryption_configuration.artifacts
aws_s3_bucket_versioning.artifacts
aws_security_group.web
aws_subnet.public
aws_vpc.main
```

### Step 6 — Output

```bash
terraform output
terraform output ec2_public_ip
```

### Step 7 — Verify EC2 Web Server

```bash
# SSH into EC2
ssh -i your-key.pem ec2-user@$(terraform output -raw ec2_public_ip)

# Or curl the web server
curl http://$(terraform output -raw ec2_public_ip)
# → <h1>Session 19 — Terraform EC2 Web Server</h1>
```

### Step 8 — Verify S3

```bash
aws s3 ls | grep session19
# → session19-cloud-terraform-artifacts
```

### Step 9 — Destroy

```bash
terraform plan -destroy
terraform destroy
# Type: yes
```

**Output:**
```
Destroy complete! Resources: 10 destroyed.
```

---

## 🔗 Terraform Concepts Demonstrated

| Concept | Where |
|---|---|
| **Provider** | `versions.tf` — `hashicorp/aws ~> 5.0` |
| **Variables** | `variables.tf` — region, AMI, instance type, bucket name |
| **Resources** | `main.tf` — VPC, Subnet, IGW, RT, SG, EC2, S3 |
| **Outputs** | `outputs.tf` — IDs, IPs, ARNs |
| **Dependencies** | EC2 `depends_on = [aws_internet_gateway.main]` |
| **State** | `terraform.tfstate` — tracks all 10 resources |
| **Plan** | Dry run showing 10 resources to add |
| **Apply** | Provisions real AWS infrastructure |
| **Destroy** | Cleans up all 10 resources |

---

## 🧹 Cleanup

Always destroy when done to avoid AWS charges:

```bash
terraform destroy -auto-approve
```
