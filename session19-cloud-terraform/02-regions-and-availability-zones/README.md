# 02 - Regions and Availability Zones

Cloud providers have data centers around the world.

We need two important words:

```text
Region
Availability Zone
```

---

## Region

A **Region** is a geographic area where a cloud provider operates infrastructure.

Examples:

```text
ap-south-1
us-east-1
eu-west-1
```

For AWS:

```text
ap-south-1 = Mumbai
```

A region contains multiple Availability Zones.

```text
AWS Region
 |
 +-- Availability Zone A
 |
 +-- Availability Zone B
 |
 +-- Availability Zone C
```

---

## Availability Zone

An Availability Zone, or AZ, is an isolated location inside a Region.

Think:

```text
Region = City
AZ     = Separate buildings/campuses in that city
```

The goal is to reduce the impact of failures.

---

## Why Multiple AZs?

Imagine:

```text
Application
   |
   +-- Server A -> AZ-A
   |
   +-- Server B -> AZ-B
```

If AZ-A has a problem, the application may still have capacity in AZ-B.

This is the basic idea behind high availability.

---

## Region vs AZ

| Concept | Simple Meaning |
|---|---|
| Region | Geographic cloud area |
| AZ | Isolated location inside a Region |

---

## Terraform Example

In Terraform, we normally select a Region:

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

Terraform can then create resources in that region.

Some resources are **regional**, while others are **AZ-specific**.

For example:

```text
VPC       -> Regional
Subnet    -> One Availability Zone
```

---

## Check Your AWS Region

```bash
aws configure get region
```

Example:

```text
ap-south-1
```

You can also check the identity:

```bash
aws sts get-caller-identity
```

---

## Simple Picture

```text
                  AWS
                   |
             +-------------+
             |   Region    |
             |  ap-south-1 |
             +------+------+
                    |
          +---------+---------+
          |                   |
       AZ-a                AZ-b
          |                   |
       Subnet              Subnet
```

---

## Practice Questions

1. Is an AZ bigger than a Region?
2. Can one Region contain multiple AZs?
3. Why would an application use multiple AZs?
4. Is a subnet associated with a Region or a specific AZ?

Expected:

```text
Region > Availability Zone
One Region -> Multiple AZs
Multiple AZs -> Better fault isolation
Subnet -> One AZ
```
