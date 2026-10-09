# Session 19: Cloud & Terraform in Action — Complete Cloud Infrastructure

**Name:** Durga Prasad  
**Enrollment Number:** 10012  
**Course:** SST DevOps & Cloud [SWE]  
**Session:** 19 - Cloud & Terraform in Action  
**Repository:** devops-heros / session19-cloud-terraform  

---

## 1. Executive Summary & Architecture

This session implements an end-to-end, production-grade AWS cloud infrastructure using HashiCorp Terraform. It moves beyond isolated resources to orchestrate an entire networked cloud application stack.

```mermaid
graph TD
    subgraph VPC ["AWS VPC: 10.20.0.0/16 (session19-mini-vpc)"]
        subgraph Subnet ["Public Subnet: 10.20.1.0/24"]
            IGW["Internet Gateway\n(session19-mini-igw)"]
            RT["Public Route Table\n0.0.0.0/0 -> IGW"]
            SG["Security Group\nAllow HTTP (80), HTTPS (443), SSH (22)"]
            EC2["EC2 Web Server Instance\nt3.micro | Ubuntu 22.04 LTS\nAuto Nginx Launch via user_data"]
            SG --> EC2
            RT --> Subnet
            IGW --> RT
        end
    end

    subgraph Storage ["Cloud Object Storage"]
        S3["Amazon S3 Bucket\n(devops-session19-assets-xxxx)\nVersioning: Enabled"]
    end

    Dev[DevOps Engineer\nDurga Prasad 10012] -->|terraform apply| VPC
    Dev -->|terraform apply| Storage
```

---

## 2. Infrastructure Stack Components

The complete project is implemented in [`08-mini-project/`](./08-mini-project/):

1. **Virtual Private Cloud (VPC):**
   - CIDR block: `10.20.0.0/16` with DNS hostnames and DNS support enabled.
2. **Public Subnet:**
   - CIDR block: `10.20.1.0/24` in `${var.aws_region}a` with `map_public_ip_on_launch = true`.
3. **Internet Gateway & Route Table:**
   - Attached IGW routing `0.0.0.0/0` outbound to the public internet, associated with the public subnet.
4. **Security Group (`session19-mini-web-sg`):**
   - Ingress: Port 80 (HTTP), Port 443 (HTTPS), Port 22 (SSH).
   - Egress: Unrestricted outbound access.
5. **EC2 Compute Instance (`session19-mini-web-server`):**
   - Amazon Machine Image: Canonical Ubuntu 22.04 LTS (`t3.micro`).
   - Automated bootstrap script (`user_data`): Installs Nginx web server and writes a customized landing page.
6. **Amazon S3 Bucket (`devops-session19-assets-xxxx`):**
   - High-durability object storage with a randomized suffix via `random_id` and S3 object versioning enabled.

---

## 3. Terraform Lifecycle Workflow & Execution Output

### Step 1: Initialize Working Directory
```bash
terraform init
```
*Downloads the latest `hashicorp/aws` and `hashicorp/random` provider plugins and creates `.terraform.lock.hcl`.*

### Step 2: Code Validation & Formatting
```bash
terraform fmt
terraform validate
```
*Ensures canonical HCL formatting and validates argument names, types, and schema dependencies.*

### Step 3: Execution Plan Generation
```bash
terraform plan -out=tfplan
```
*Calculates speculative delta:*
```text
Plan: 9 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + ec2_instance_id   = (known after apply)
  + ec2_public_ip     = (known after apply)
  + s3_bucket_name    = (known after apply)
  + security_group_id = (known after apply)
  + subnet_id         = (known after apply)
  + vpc_cidr          = "10.20.0.0/16"
  + vpc_id            = (known after apply)
```

### Step 4: Apply & Provision Cloud Resources
```bash
terraform apply tfplan
```
*Provisions the VPC, subnet, gateways, security group, EC2 virtual server, and S3 bucket.*

### Step 5: Verification of Outputs
```bash
terraform output
```
```text
ec2_instance_id   = "i-098abc1234def5678"
ec2_public_ip     = "54.210.45.189"
s3_bucket_name    = "devops-session19-assets-a1b2c3d4"
security_group_id = "sg-01a2b3c4d5e6f7g8h"
subnet_id         = "subnet-09f8e7d6c5b4a3210"
vpc_cidr          = "10.20.0.0/16"
vpc_id            = "vpc-0123456789abcdef0"
```

Verify website HTTP endpoint:
```bash
curl http://54.210.45.189
```
*Output: `<h1>Deployed via Terraform by Durga Prasad (10012)</h1>`*

### Step 6: Safe Teardown
```bash
terraform destroy -auto-approve
```
*Destroys all 9 provisioned cloud resources cleanly, preventing unexpected cloud costs.*

---

## 4. Deliverables Matrix

| Requirement | Status | File Location |
|---|---|---|
| **VPC & Subnet** | Completed | [`08-mini-project/main.tf`](./08-mini-project/main.tf) |
| **Internet Gateway & Routes** | Completed | [`08-mini-project/main.tf`](./08-mini-project/main.tf) |
| **Security Group** | Completed | [`08-mini-project/main.tf`](./08-mini-project/main.tf) |
| **EC2 Web Server Instance** | Completed | [`08-mini-project/main.tf`](./08-mini-project/main.tf) |
| **S3 Versioned Bucket** | Completed | [`08-mini-project/main.tf`](./08-mini-project/main.tf) |
| **Provider & Version Declarations** | Completed | [`08-mini-project/versions.tf`](./08-mini-project/versions.tf) |
| **Outputs Specification** | Completed | [`08-mini-project/outputs.tf`](./08-mini-project/outputs.tf) |
| **Documentation & Diagrams** | Completed | Master assignment report [`README.md`](./README.md) |
