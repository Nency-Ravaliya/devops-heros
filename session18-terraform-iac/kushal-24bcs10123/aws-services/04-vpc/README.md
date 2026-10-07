# 04 – VPC (Virtual Private Cloud) – Networking

**Name:** Kushal Talati · **Enrollment No:** 24BCS10123

A VPC is my own private slice of the AWS network in one region: an IP range I choose, cut into subnets across Availability Zones, with route tables deciding where packets go and two layers of firewall (security groups, network ACLs) deciding whether they are allowed. Every EC2 instance, RDS instance, EKS node and Lambda-in-VPC lives in a subnet of some VPC.

The complete "build it with Terraform" version of this page is [session 19](../../../../session19-cloud-terraform/kushal-24bcs10123) (VPC → subnet → IGW → route table → SG → EC2). Here I only describe the pieces and look at LocalStack's default VPC (raw output in [`../../logs/02-aws-services-hands-on.txt`](../../logs/02-aws-services-hands-on.txt) under `04 VPC`).

```text
                               Internet
                                  │
                        ┌─────────┴──────────┐
                        │  Internet Gateway  │  (1 per VPC, horizontally scaled, does 1:1 NAT for public IPs)
                        └─────────┬──────────┘
 VPC 10.20.0.0/16                 │
 ┌────────────────────────────────┼─────────────────────────────────────────────────┐
 │  Public route table            │                Private route table               │
 │  10.20.0.0/16 → local          │                10.20.0.0/16 → local              │
 │  0.0.0.0/0    → igw-xxx        │                0.0.0.0/0    → nat-xxx            │
 │        │                       │                       │                          │
 │  ┌─────┴───────────────┐       │        ┌──────────────┴──────────────┐           │
 │  │ Public subnet (AZ a)│       │        │ Private subnet (AZ a)       │           │
 │  │ 10.20.1.0/24        │ ──────┘        │ 10.20.11.0/24               │           │
 │  │ [NAT Gateway]       │◀───────────────│ app servers, RDS, EKS nodes │           │
 │  │ web / ALB / bastion │   outbound only│ (no public IPs at all)      │           │
 │  └─────────────────────┘                └─────────────────────────────┘           │
 │   NACL (stateless, subnet edge)           NACL (stateless, subnet edge)           │
 │   Security groups (stateful, per ENI)     Security groups (stateful, per ENI)     │
 └───────────────────────────────────────────────────────────────────────────────────┘
```

## CIDR
The VPC's address range in CIDR notation: `10.20.0.0/16` = 65 536 addresses (`10.20.0.0`–`10.20.255.255`). Allowed sizes are /16 to /28; private ranges (RFC 1918: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) are the convention. Pick a range that **does not overlap** with the office network or other VPCs you will ever peer with – this is the one decision that is painful to change later. Secondary CIDRs can be added.

## Subnets
A subnet is a slice of the VPC CIDR **inside exactly one Availability Zone**. `10.20.1.0/24` = 256 addresses, of which AWS reserves 5 (network, router `.1`, DNS `.2`, future `.3`, broadcast), so 251 usable. "Public" and "private" are *not* a subnet property – they are a consequence of the route table attached to it (see below). `map_public_ip_on_launch = true` makes instances in it get a public IP automatically.

```text
$ awsl ec2 describe-subnets --query 'Subnets[].{SubnetId:SubnetId,Cidr:CidrBlock,AZ:AvailabilityZone,PublicIpOnLaunch:MapPublicIpOnLaunch}' --output table
|  AZ           |     Cidr        |  PublicIpOnLaunch  |   SubnetId      |
|  ap-south-1a  |  172.31.0.0/20  |  True              |  subnet-86d59592 |
|  ap-south-1b  |  172.31.16.0/20 |  True              |  subnet-02e0a05b |
|  ap-south-1c  |  172.31.32.0/20 |  True              |  subnet-8717eb53 |
      (LocalStack's default VPC vpc-5a308e7b: one /20 per AZ, 172.31.0.0/16 like a real account's default VPC)
```

## Route tables
Each subnet is associated with one route table (the VPC's *main* table if nothing explicit). A table is a list of `destination CIDR → target`. The `local` route for the VPC CIDR is always there and cannot be removed; everything else is mine:

| Destination | Target | Meaning |
|---|---|---|
| `10.20.0.0/16` | `local` | anything inside the VPC is routed directly |
| `0.0.0.0/0` | `igw-…` | **public subnet**: the internet via the Internet Gateway |
| `0.0.0.0/0` | `nat-…` | **private subnet**: outbound internet via a NAT Gateway, inbound impossible |
| `10.30.0.0/16` | `pcx-…` | a peered VPC |
| `pl-… (S3 prefix list)` | `vpce-…` | Gateway endpoint: reach S3 without leaving AWS |

```text
$ awsl ec2 describe-route-tables --query 'RouteTables[0].Routes[].{Dest:DestinationCidrBlock,Target:GatewayId}' --output table
|      Dest        |  Target  |
|  172.31.0.0/16   |  local   |      <- only the mandatory local route; LocalStack's default VPC has no IGW route
                                        (a real account's default VPC has 0.0.0.0/0 -> igw-... here)
```

## Internet Gateway (IGW)
The VPC's door to the internet. One per VPC, attached once, no bandwidth limit to think about. It does two things: routes traffic for `0.0.0.0/0` out, and performs **1:1 NAT between an instance's private IP and its public/Elastic IP** – the instance never knows its public address. Without a route to the IGW *and* a public IP, an instance cannot be reached from the internet even in a "public" subnet.

## NAT Gateway
Lets instances in **private** subnets start outbound connections (apt/yum updates, pulling Docker images, calling external APIs) while refusing anything inbound. It lives *in a public subnet*, has an Elastic IP, is managed and AZ-scoped (one per AZ for HA), and costs per hour + per GB – usually the biggest line item of a small VPC. For AWS services (S3, DynamoDB, ECR…) a **VPC endpoint** avoids both the NAT cost and the internet path.

## Security Groups
Stateful firewall **attached to a network interface** (instance, RDS, ALB, Lambda…). Allow rules only; return traffic is automatically allowed; default SG allows all outbound and only inbound from itself. Rules can target CIDRs, prefix lists or **other security groups**, so "DB accepts 5432 from the app SG" needs no IP addresses. Evaluated *after* the NACL on the way in.

## Network ACLs
Stateless firewall **at the subnet boundary**. Numbered rules evaluated in order, both allow and **deny** possible, and because it is stateless I must open ephemeral ports (1024–65535) for return traffic explicitly. The default NACL allows everything; custom NACLs are mostly used for coarse blocks (deny a hostile IP range, isolate a subnet) while security groups do the fine-grained work.

```text
$ awsl ec2 describe-network-acls --query 'NetworkAcls[0].Entries[].{Rule:RuleNumber,Egress:Egress,Action:RuleAction,Cidr:CidrBlock}' --output table
|  Action  |    Cidr     |  Egress  |  Rule   |
|  allow   |  0.0.0.0/0  |  True    |  100    |     <- default NACL: rule 100 allows all, rule 32767 (*) denies the rest
|  deny    |  0.0.0.0/0  |  True    |  32767  |
|  allow   |  0.0.0.0/0  |  False   |  100    |
|  deny    |  0.0.0.0/0  |  False   |  32767  |
```

| | Security Group | Network ACL |
|---|---|---|
| Attaches to | ENI (instance) | subnet |
| State | stateful | stateless |
| Rules | allow only | allow + deny, numbered |
| Evaluation | all rules, any match allows | first match in order wins |
| Typical use | per-application firewall | subnet-wide guard rail / block list |

## Public vs private subnet

| | Public subnet | Private subnet |
|---|---|---|
| Route for `0.0.0.0/0` | → Internet Gateway | → NAT Gateway (or nothing) |
| Instances have public IPs | usually (`map_public_ip_on_launch`) | never |
| Reachable from internet | yes, if the SG allows | no |
| Can reach the internet | yes | only outbound, via NAT |
| What lives there | load balancers, NAT gateway, bastion | app servers, databases, Kubernetes nodes, caches |

The point of the split: the internet only ever talks to a load balancer; everything with data sits where no inbound route exists at all.

## Common use cases / patterns
* **Three-tier web app**: public subnets (ALB) → private app subnets (EC2/ECS/EKS) → isolated DB subnets (RDS, no NAT either), across 2–3 AZs.
* **EKS cluster**: control plane ENIs + worker nodes in private subnets, ALB/NLB in public subnets, cluster endpoint private.
* **Hybrid**: VPN or Direct Connect from the office into the VPC, non-overlapping CIDRs matter here.
* **Multi-VPC**: VPC peering for two VPCs, Transit Gateway as a hub for many.
* **Flow Logs** to CloudWatch/S3 to see accepted/rejected traffic per ENI – the first thing to check when "the app cannot connect".

## What I understood

* "Public" is **a route, not a label** – a subnet is public exactly when its route table sends `0.0.0.0/0` to an IGW and the instance has a public IP.
* **Two firewalls, two jobs**: NACL is the stateless, subnet-level, order-matters blunt instrument; the security group is the stateful, per-instance precise one. Almost all day-to-day rules go in security groups.
* NAT Gateway is what makes a private subnet usable (updates, image pulls) and also the thing that quietly costs money – prefer VPC endpoints for AWS services.
