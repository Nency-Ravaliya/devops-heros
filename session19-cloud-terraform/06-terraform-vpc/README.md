# 06 - Terraform VPC Lab

Terraform will create:

```text
VPC
 |
 +-- Public Subnet
 |
 +-- Internet Gateway
 |
 +-- Public Route Table
 |
 +-- Route Table Association
 |
 +-- Security Group
```

No EC2 instance is created here.

That keeps the main lab simple and avoids unnecessary compute charges.

---

# Project Structure

```text
06-terraform-vpc/
|
|-- README.md
|-- versions.tf
|-- variables.tf
|-- main.tf
|-- outputs.tf
|-- terraform.tfvars.example
|-- .gitignore
```

---

# Architecture

```text
                    Internet
                        |
                        v
              +------------------+
              | Internet Gateway |
              +--------+---------+
                       |
                +------+------+
                |     VPC     |
                | 10.0.0.0/16 |
                |              |
                | +----------+ |
                | |  Public  | |
                | |  Subnet  | |
                | |10.0.1.0/24||
                | +----------+ |
                |       |
                |  Route Table
                |       |
                | Security Group
                +--------------+
```

---

# Step 1 - Prepare Variables

Copy:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and change the Region if required.

Example:

```hcl
aws_region = "ap-south-1"
```

---

# Step 2 - Initialize Terraform

```bash
terraform init
```

Expected:

```text
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 6.0"...
- Installing hashicorp/aws v6.x.x...
Terraform has been successfully initialized!
```

The exact provider version may differ within the allowed `6.x` range.

---

# Step 3 - Format

```bash
terraform fmt
```

Expected:

```text
main.tf
outputs.tf
variables.tf
```

Or no output if everything is already formatted.

---

# Step 4 - Validate

```bash
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

---

# Step 5 - Plan

```bash
terraform plan
```

You should see resources being created.

Expected shape:

```text
Plan: 6 to add, 0 to change, 0 to destroy.
```

Terraform is showing us what it intends to create.

It has not created the resources yet.

---

# Step 6 - Apply

```bash
terraform apply
```

Terraform asks:

```text
Do you want to perform these actions?
  Only 'yes' will be accepted to approve.

Enter a value:
```

Type:

```text
yes
```

Expected shape:

```text
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

security_group_id = "sg-..."
subnet_id = "subnet-..."
vpc_cidr = "10.0.0.0/16"
vpc_id = "vpc-..."
```

The exact IDs are different for every account.

---

# Step 7 - Inspect Terraform State

```bash
terraform state list
```

Expected:

```text
aws_internet_gateway.main
aws_route_table.public
aws_route_table_association.public
aws_security_group.web
aws_subnet.public
aws_vpc.main
```

There are six resources in this configuration. The plan count can vary if Terraform/provider behavior or configuration is changed.

---

# Step 8 - Inspect Outputs

```bash
terraform output
```

Example:

```text
security_group_id = "sg-012345..."
subnet_id = "subnet-012345..."
vpc_cidr = "10.0.0.0/16"
vpc_id = "vpc-012345..."
```

---

# Step 9 - Verify with AWS CLI (Optional -> You can check directly in dashboard too)

List VPC:

```bash
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=session19-vpc" \
  --query 'Vpcs[].{VpcId:VpcId,Cidr:CidrBlock,State:State}'
```

List subnet:

```bash
aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=session19-public-subnet" \
  --query 'Subnets[].{SubnetId:SubnetId,Cidr:CidrBlock,AZ:AvailabilityZone}'
```

List route table:

```bash
aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=session19-public-rt" \
  --query 'RouteTables[].{RouteTableId:RouteTableId,VpcId:VpcId}'
```

---

# Step 10 - Destroy

This is important.

When the lab is complete:

```bash
terraform plan -destroy
```

Then:

```bash
terraform destroy
```

Enter:

```text
yes
```

Expected:

```text
Destroy complete! Resources: 6 destroyed.
```

---

# What Terraform Did

We described the desired infrastructure:

```text
main.tf
   |
   v
Terraform
   |
   v
AWS API
   |
   +-- VPC
   +-- Subnet
   +-- Internet Gateway
   +-- Route Table
   +-- Association
   +-- Security Group
```

Terraform is the translator between our infrastructure code and the cloud APIs.

---

# Student Exercise

Change:

```hcl
cidr_block = "10.0.0.0/16"
```

to:

```hcl
cidr_block = "10.10.0.0/16"
```

Then change the subnet to:

```hcl
10.10.1.0/24
```

Run:

```bash
terraform fmt
terraform validate
terraform plan
```

Do not apply until you understand what Terraform plans to change.
