# 04 · VPC — Virtual Private Cloud (Networking)

## What is VPC?

A **VPC** is your own **logically isolated virtual network** inside an AWS region. You control its IP address range, subnets, routing, gateways and firewalls, much like a traditional data-centre network but software-defined.

- A VPC is **regional** and spans all Availability Zones in the region. Its **subnets** each live in **one AZ**.
- Every region comes with a **default VPC** (`172.31.0.0/16`, public subnets in every AZ). For real workloads, create a custom VPC.
- There is no charge for the VPC itself. NAT Gateways, public IPv4 addresses, VPC endpoints and similar components are billed.

```text
Region ap-south-1
┌────────────────────────────── VPC 10.0.0.0/16 ──────────────────────────────┐
│                         ┌──────────────────┐                               │
│                         │ Internet Gateway │◄──────────── Internet          │
│                         └────────┬─────────┘                               │
│        AZ ap-south-1a            │               AZ ap-south-1b             │
│ ┌──── Public 10.0.1.0/24 ────┐   │   ┌──── Public 10.0.2.0/24 ────┐        │
│ │  ALB    Bastion   NAT GW ◄─┼───┘   │  ALB                        │        │
│ └───────────────────┬────────┘       └─────────────────────────────┘        │
│                     │ 0.0.0.0/0 → NAT                                       │
│ ┌──── Private 10.0.11.0/24 ──┐       ┌──── Private 10.0.12.0/24 ───┐        │
│ │  App EC2 / EKS nodes       │       │  App EC2 / EKS nodes        │        │
│ └────────────────────────────┘       └─────────────────────────────┘        │
│ ┌──── DB 10.0.21.0/24 ───────┐       ┌──── DB 10.0.22.0/24 ────────┐        │
│ │  RDS primary               │       │  RDS standby (Multi-AZ)     │        │
│ └────────────────────────────┘       └─────────────────────────────┘        │
└─────────────────────────────────────────────────────────────────────────────┘
```

## CIDR (Classless Inter-Domain Routing)

**CIDR notation** describes an IP range as `base-address/prefix-length`. The prefix length is how many leading bits are fixed, and the remaining bits are available for hosts.

| CIDR | Host bits | Total IPs | Usable in an AWS subnet (−5) |
|---|---|---|---|
| `10.0.0.0/16` | 16 | 65,536 | – (VPC range) |
| `10.0.1.0/24` | 8 | 256 | **251** |
| `10.0.1.0/26` | 6 | 64 | 59 |
| `10.0.1.0/28` | 4 | 16 | 11 |

- A VPC CIDR must be between **/16 and /28**. Use **RFC 1918** private ranges: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.
- You can add **secondary CIDRs** later, and optionally an IPv6 `/56`.
- **Plan for no overlap** with other VPCs and on-premises networks. Overlapping ranges cannot be peered or routed.
- AWS **reserves 5 IPs in every subnet**. In `10.0.1.0/24`, these are: `.0` network, `.1` VPC router, `.2` DNS, `.3` reserved, `.255` broadcast.

In Terraform, `cidrsubnet("10.0.0.0/16", 8, 1)` returns `"10.0.1.0/24"`.

## Subnets

A **subnet** is a slice of the VPC CIDR that lives in exactly **one AZ**. Resources such as EC2, RDS and Lambda ENIs are launched into subnets.

- Subnet CIDRs must sit inside the VPC CIDR and must not overlap each other.
- Spread each tier across **at least 2 AZs** for high availability.
- `map_public_ip_on_launch` controls whether instances get a public IPv4 automatically.
- Each subnet is associated with exactly **one route table** and **one network ACL**.

## Route tables

A **route table** is a set of rules (routes) that decides where traffic leaving a subnet goes. The **most specific match** (longest prefix) wins.

Public route table:
| Destination | Target |
|---|---|
| `10.0.0.0/16` | `local` (always present, cannot be deleted. All subnets in the VPC can reach each other.) |
| `0.0.0.0/0` | `igw-0abc…` (Internet Gateway) |

Private route table:
| Destination | Target |
|---|---|
| `10.0.0.0/16` | `local` |
| `0.0.0.0/0` | `nat-0def…` (NAT Gateway) |

- The **main route table** applies to any subnet that is not explicitly associated with another table. Keep it private and create explicit public tables.
- Other possible targets: VPC peering (`pcx-`), Transit Gateway (`tgw-`), VPN gateway (`vgw-`), gateway VPC endpoints (S3, DynamoDB) and network interfaces.

## Internet Gateway (IGW)

An **IGW** is a horizontally scaled, highly available VPC component that allows communication between the VPC and the **internet**.

- **One IGW per VPC**. There is no bandwidth limit and no hourly charge.
- It performs **1:1 NAT** between an instance's private IP and its public or Elastic IP.
- Internet access requires **all four** of these:
  1. an IGW attached to the VPC
  2. a route `0.0.0.0/0 → igw` in the subnet's route table
  3. a public or Elastic IP on the instance
  4. SG and NACL rules that allow the traffic

An **egress-only IGW** is the IPv6 equivalent of a NAT gateway: it allows outbound traffic only.

## NAT Gateway

A **NAT Gateway** lets instances in **private subnets** start **outbound** connections to the internet (for OS updates, pulling images or calling external APIs) while **blocking inbound** connections from the internet.

- A zonal (classic) public NAT gateway is placed **in a public subnet** and uses an **Elastic IP**.
- Private route tables point `0.0.0.0/0 → nat-gw`.
- It is managed by AWS, scales automatically (up to 100 Gbps) and is **AZ-scoped** by default. For high availability, deploy **one NAT gateway per AZ**, or use a **regional NAT gateway** (since November 2025), which spans AZs automatically and needs no public subnet.
- It is **billed hourly plus per GB processed**, so it is often the most expensive part of a VPC. Use **gateway endpoints** for S3 and DynamoDB to avoid sending that traffic through NAT.
- A NAT **instance** (a self-managed EC2) is the older, cheaper alternative, but you have to maintain it.
- *Private NAT gateway* variant: NAT between private networks, with no internet access.

## Security Groups

A **security group** is a **stateful firewall at the instance (ENI) level**.

- **Allow rules only**. All rules are evaluated together.
- Stateful: if inbound is allowed, the response is automatically allowed out, and vice versa.
- Rules can reference **other security groups**, e.g. *DB-SG allows 5432 from App-SG*. This is how you build tiered access without hard-coding IPs.

```text
alb-sg  : in 443 from 0.0.0.0/0
app-sg  : in 8080 from alb-sg
db-sg   : in 5432 from app-sg
```

## Network ACLs (NACLs)

A **network ACL** is a **stateless firewall at the subnet level**.

- It supports **both allow and deny** rules.
- Rules are **numbered** and evaluated in **ascending order**. The first match wins, and the final `*` rule denies everything else.
- Stateless: you must allow return traffic explicitly, usually **ephemeral ports 1024–65535**.
- The default NACL allows all traffic in and out. A newly created custom NACL **denies everything** until you add rules.
- Typical use: block a known-bad IP range for a whole subnet.

### Security Group vs NACL

| | Security Group | Network ACL |
|---|---|---|
| Level | instance / ENI | subnet |
| State | **stateful** | **stateless** |
| Rules | allow only | allow **and** deny |
| Evaluation | all rules together | in number order, first match wins |
| Applies to | only the instances it is attached to | everything in the associated subnet |
| Default (new custom) | deny in, allow out | deny all |

```text
Internet → IGW → [Route table] → [NACL: subnet] → [SG: instance] → EC2
```

## Public vs private subnet

There is no "public" checkbox. **A subnet is public if its route table has a route to an Internet Gateway.**

| | Public subnet | Private subnet |
|---|---|---|
| Default route | `0.0.0.0/0 → IGW` | `0.0.0.0/0 → NAT GW` (or none) |
| Reachable from internet | yes (with public IP + SG) | **no** |
| Outbound internet | directly through the IGW | through the NAT gateway |
| Typical residents | ALB/NLB, NAT GW, bastion host | app servers, EKS nodes, Lambda, RDS, ElastiCache |

**Best practice:** keep only internet-facing load balancers and NAT gateways in public subnets, and run all compute and data in private subnets.

## Other VPC components worth knowing

- **VPC endpoints**: private access to AWS services without IGW or NAT. *Gateway* endpoints (S3, DynamoDB, free) and *Interface* endpoints (PrivateLink, for most other services).
- **VPC peering**: 1:1 private connectivity between two VPCs. It is non-transitive.
- **Transit Gateway**: a hub-and-spoke router for many VPCs and on-premises networks.
- **Site-to-Site VPN / Direct Connect**: hybrid connectivity to on-premises.
- **VPC Flow Logs**: capture accepted and rejected IP traffic metadata to CloudWatch or S3 for troubleshooting and security.
- **DHCP option sets and Route 53 private hosted zones**: DNS inside the VPC.

## Terraform example (minimal public + private)

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "main-vpc" }
}

resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.main.id }

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_eip" "nat" { domain = "vpc" }

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
```

A full hands-on build is in [session19-cloud-terraform/06-terraform-vpc](../../../session19-cloud-terraform/06-terraform-vpc).

## Useful CLI commands

```bash
aws ec2 describe-vpcs --query 'Vpcs[].[VpcId,CidrBlock,IsDefault]' --output table
aws ec2 describe-subnets --filters Name=vpc-id,Values=vpc-0abc --query 'Subnets[].[SubnetId,CidrBlock,AvailabilityZone]' --output table
aws ec2 describe-route-tables --filters Name=vpc-id,Values=vpc-0abc
aws ec2 describe-security-groups --group-ids sg-0abc
aws ec2 describe-network-acls --filters Name=vpc-id,Values=vpc-0abc
```
