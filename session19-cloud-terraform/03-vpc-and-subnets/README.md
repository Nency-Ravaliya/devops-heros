# 03 - VPC and Subnets

Two important things:

```text
VPC
Subnet
```

---

## What is a VPC?

VPC means:

> Virtual Private Cloud

It is your private network inside a cloud provider.

Think:

```text
Cloud
 |
 +-- Your VPC
      |
      +-- Your subnets
      +-- Your routes
      +-- Your security rules
```

Example:

```text
VPC: 10.0.0.0/16
```

The `/16` is CIDR notation.

For now, think:

> "This VPC has a large private IP range."

---

## What is a Subnet?

A subnet is a smaller network inside the VPC.

Example:

```text
VPC
10.0.0.0/16
 |
 +-- Public Subnet
 |   10.0.1.0/24
 |
 +-- Private Subnet
     10.0.2.0/24
```

---

## Public vs Private Subnet

A subnet is commonly called "public" when its route table provides a path to an Internet Gateway.

A private subnet does not have a direct route to an Internet Gateway.

Simple picture:

```text
Internet
   |
Internet Gateway
   |
Public Subnet
   |
Web Server
```

Private example:

```text
Internet
   X
Private Subnet
   |
Database
```

The exact architecture can be more complicated in real systems.

---

## CIDR - Super Simple

CIDR describes an IP range.

Example:

```text
10.0.0.0/16
```

A smaller range:

```text
10.0.1.0/24
```

The `/24` subnet fits inside the `/16` VPC.

```text
10.0.0.0/16
 |
 +-- 10.0.1.0/24
 +-- 10.0.2.0/24
 +-- 10.0.3.0/24
```

Do not worry about calculating every IP address yet. The important idea is:

> VPC = bigger network, subnet = smaller network.

---

## Terraform Example

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}
```

---

## Check VPCs Using AWS CLI (Optional -> You can check directly in dashboard too)

```bash
aws ec2 describe-vpcs \
  --query 'Vpcs[].{VpcId:VpcId,Cidr:CidrBlock,State:State}'
```

Example shape:

```text
VpcId            Cidr
vpc-0123456789   10.0.0.0/16
```

Exact IDs are different for every account.

---

## Check Subnets

```bash
aws ec2 describe-subnets \
  --query 'Subnets[].{SubnetId:SubnetId,Cidr:CidrBlock,AZ:AvailabilityZone}'
```

---

## Practice Questions

1. What is a VPC?
2. What is a subnet?
3. Can a subnet be larger than its VPC?
4. What does `10.0.0.0/16` represent?
5. What is the difference between a public and private subnet?
