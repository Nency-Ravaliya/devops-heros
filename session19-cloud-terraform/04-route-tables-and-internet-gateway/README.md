# 04 - Route Tables and Internet Gateway

We have:

```text
VPC
 |
 +-- Subnet
```

But how does traffic know where to go?

Enter:

```text
Route Table
```

---

## Route Table

A route table is like a road map.

Example:

```text
Destination       Target
0.0.0.0/0         Internet Gateway
```

Meaning:

> "For traffic going anywhere on the internet, send it to the Internet Gateway."

---

## Internet Gateway

An Internet Gateway, or IGW, connects a VPC to the internet.

See this kiddo:

```text
Internet
   |
   v
Internet Gateway
   |
   v
VPC
   |
   v
Public Subnet
```

Important:

> Creating an Internet Gateway does not automatically make every subnet public.

The subnet also needs an appropriate route.

---

## Making a Public Subnet

We need:

```text
VPC
 |
 +-- Internet Gateway
 |
 +-- Route Table
 |     |
 |     +-- 0.0.0.0/0 -> IGW
 |
 +-- Public Subnet
       |
       +-- Associated with Route Table
```

Now the subnet has a route toward the internet.

---

## Terraform

Internet Gateway:

```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```

Route table:

```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.main.id
  }
}
```

Associate it with the subnet:

```hcl
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

---

## Why `0.0.0.0/0`?

For beginner purposes:

```text
0.0.0.0/0 = any IPv4 destination
```

So:

```text
0.0.0.0/0 -> Internet Gateway
```

means:

> "Send internet-bound IPv4 traffic toward the Internet Gateway."

---

## Check Route Tables

```bash
aws ec2 describe-route-tables \
  --query 'RouteTables[].Routes[]'
```

You may see entries like:

```text
DestinationCidrBlock: 10.0.0.0/16
GatewayId: local
```

and for a public route:

```text
DestinationCidrBlock: 0.0.0.0/0
GatewayId: igw-...
```

Exact values depend on your AWS account.

---

## Important Distinction

Do not confuse these:

```text
Route Table
    =
Where traffic should go

Security Group
    =
Which traffic is allowed
```

They solve different problems.

---

## Practice

Explain this path:

```text
Laptop
  |
Internet
  |
Internet Gateway
  |
Route Table
  |
Public Subnet
  |
EC2
```

Then explain why a route table alone does not replace a security group.
