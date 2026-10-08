# 04. VPC: Virtual Private Cloud (Networking)

## What is a VPC?

A **VPC** is your own logically isolated virtual network inside an AWS region. You choose its IP range, split it into subnets across Availability Zones, and control routing and firewalls. Everything with a network interface (EC2, RDS, EKS nodes, Lambda in VPC, load balancers) lives in a VPC. Each region has a **default VPC** (all public subnets) for quick tests; real workloads use a custom VPC, usually built with Terraform.

```text
Region ap-south-1
└── VPC 10.0.0.0/16
    ├── AZ ap-south-1a
    │   ├── public subnet  10.0.1.0/24   ── route 0.0.0.0/0 → Internet Gateway
    │   │     ├── ALB, NAT Gateway, bastion
    │   └── private subnet 10.0.11.0/24  ── route 0.0.0.0/0 → NAT Gateway
    │         └── app servers, EKS nodes
    ├── AZ ap-south-1b
    │   ├── public subnet  10.0.2.0/24
    │   └── private subnet 10.0.12.0/24
    │         └── RDS (Multi-AZ standby)
    └── Internet Gateway (attached to the VPC)
```

## CIDR

**CIDR (Classless Inter-Domain Routing)** notation describes an IP range as `address/prefix-length`. The prefix is the number of fixed network bits; the remaining bits are host addresses.

| CIDR | Addresses | Typical use |
|---|---|---|
| `10.0.0.0/16` | 65,536 | a VPC (AWS allows /16 down to /28) |
| `10.0.1.0/24` | 256 (251 usable in AWS) | a subnet |
| `10.0.1.0/28` | 16 (11 usable) | smallest subnet |
| `203.0.113.10/32` | 1 | a single IP, e.g. "my IP" in a security group |
| `0.0.0.0/0` | everything | default route / "anywhere" |

- Use **private (RFC 1918)** ranges: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.
- Plan ranges so they **don't overlap** with other VPCs or on-prem networks you may want to peer or connect by VPN later.
- AWS **reserves 5 addresses per subnet**: network address, `.1` VPC router, `.2` DNS, `.3` reserved, and the broadcast address.
- Terraform's `cidrsubnet("10.0.0.0/16", 8, 1)` gives `10.0.1.0/24`.

## Subnets

A **subnet** is a range of the VPC CIDR inside **one Availability Zone**. Spread subnets across at least 2 AZs for high availability. What makes a subnet "public" or "private" is **only its route table**.

## Route tables

A **route table** is a set of rules (destination CIDR → target) that decides where traffic from a subnet goes. Every subnet is associated with exactly one route table (or the VPC's **main** route table).

| Destination | Target | Meaning |
|---|---|---|
| `10.0.0.0/16` | `local` | traffic inside the VPC (always present, can't be removed) |
| `0.0.0.0/0` | `igw-…` | internet via Internet Gateway → **public subnet** |
| `0.0.0.0/0` | `nat-…` | outbound internet via NAT → **private subnet** |
| `10.1.0.0/16` | `pcx-…` / `tgw-…` | peered VPC / Transit Gateway |
| `pl-…` (S3 prefix list) | `vpce-…` | S3 via gateway VPC endpoint (no NAT cost) |

The **most specific** (longest prefix) route wins.

## Internet Gateway (IGW)

A horizontally scaled, highly available VPC component that lets resources with a **public IP** talk to the internet, in both directions. It also performs 1:1 NAT between an instance's private IP and its public IP. One IGW per VPC; free. To make a subnet public: attach an IGW, add `0.0.0.0/0 → igw` to its route table, and give instances public IPs.

## NAT Gateway

Lets instances in **private subnets** start **outbound** connections to the internet (OS updates, pulling images, calling APIs) while staying **unreachable from the internet**:
- Lives in a **public subnet** and needs an **Elastic IP**.
- Private subnet route: `0.0.0.0/0 → nat-…`.
- Managed and scalable, but **zonal**. For HA, use one NAT per AZ; for cost-saving labs, a single NAT.
- **Costs money** per hour and per GB processed. That's why labs often skip it, and why VPC endpoints for S3/DynamoDB are used to avoid NAT data charges.
- For IPv6, the equivalent is an **egress-only Internet Gateway**.

## Security groups

Stateful, instance/ENI-level firewalls with **allow rules only** (see the [EC2 notes](../02-ec2/README.md#security-groups)). They can reference other security groups (`db-sg allows 5432 from app-sg`), which keeps rules valid as IPs change.

## Network ACLs (NACLs)

Stateless firewalls at the **subnet** level:

| | Security group | Network ACL |
|---|---|---|
| Level | instance / ENI | subnet |
| State | **stateful** (return traffic auto-allowed) | **stateless** (must allow return traffic, incl. ephemeral ports 1024–65535) |
| Rules | allow only | allow **and deny** |
| Evaluation | all rules together | in number order; first match wins |
| Default | deny in, allow out | default NACL allows all; custom NACL denies all |
| Typical use | main access control | coarse guardrails, e.g. block a malicious CIDR |

Traffic must pass **both**: NACL of the subnet, then the SG of the instance (and the reverse for the response).

## Public vs private subnet

| | Public subnet | Private subnet |
|---|---|---|
| Default route | `0.0.0.0/0 → Internet Gateway` | `0.0.0.0/0 → NAT Gateway` (or none at all) |
| Instance public IP | yes (auto-assign) | no |
| Reachable from internet | yes (if SG allows) | **no** |
| Outbound internet | directly via IGW | via NAT |
| Put here | load balancers, NAT gateways, bastion hosts | app servers, databases, EKS worker nodes, caches |

Best practice is a **multi-tier** layout: only the load balancer is public, apps and data are private, and admin access goes through SSM Session Manager instead of a bastion.

## Other VPC features

VPC Peering, Transit Gateway (hub-and-spoke for many VPCs and VPN), Site-to-Site VPN and Direct Connect (to on-prem), VPC Endpoints (Gateway for S3/DynamoDB; Interface/PrivateLink for other services), VPC Flow Logs (network traffic logs to CloudWatch/S3), DHCP option sets, and Route 53 private hosted zones.

In **Session 19** I build a VPC with Terraform (VPC, public subnet, Internet Gateway, route table, security group, EC2 and S3), and the [VPC Terraform lesson](../../../../session19-cloud-terraform/06-terraform-vpc/README.md) builds the public/private, multi-AZ version.
