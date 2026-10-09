# 04. VPC – Virtual Private Cloud (Networking)

## What is a VPC?
A VPC is your own **logically isolated virtual network** inside an AWS region. You define its IP range, carve it into subnets, and control routing and firewalls. Every EC2 instance, RDS database, EKS node and Lambda (when VPC-attached) lives in a VPC. Each region has a *default VPC* (`172.31.0.0/16`) for quick starts. Production uses custom VPCs.

```
Region ap-south-1 ─ VPC 10.0.0.0/16
├── AZ ap-south-1a
│   ├── Public subnet  10.0.1.0/24   → route 0.0.0.0/0 → Internet Gateway   (ALB, NAT GW, bastion)
│   └── Private subnet 10.0.11.0/24  → route 0.0.0.0/0 → NAT Gateway        (app servers, EKS nodes)
├── AZ ap-south-1b
│   ├── Public subnet  10.0.2.0/24
│   └── Private subnet 10.0.12.0/24
└── (DB subnets 10.0.21.0/24, 10.0.22.0/24: no internet route at all)
```

## CIDR
**Classless Inter-Domain Routing** notation: `IP/prefix`. The prefix is the number of fixed network bits, and the rest are host addresses.

| CIDR | Addresses | Typical use |
|---|---|---|
| `10.0.0.0/16` | 65,536 | Whole VPC (allowed range /16 to /28) |
| `10.0.1.0/24` | 256 (**251 usable** in AWS) | One subnet |
| `10.0.1.0/28` | 16 (11 usable) | Smallest subnet |

- Use private RFC 1918 ranges (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`).
- **Don't overlap** with other VPCs or on-prem networks you may later peer or VPN to.
- AWS reserves 5 IPs per subnet: network, VPC router (.1), DNS (.2), future use (.3), broadcast.

## Subnets
- A slice of the VPC CIDR that lives in **exactly one Availability Zone**. For high availability, create one per tier per AZ.
- "Public" or "private" is decided by the **route table**, not by a checkbox.
- Optional `map_public_ip_on_launch` gives instances a public IP automatically (used for public subnets).

## Route tables
- A set of rules `destination CIDR → target` that every subnet is associated with (the main route table by default).
- There is always a `local` route (`10.0.0.0/16 → local`), so all subnets in a VPC can talk to each other.
- Targets: `igw-` (Internet Gateway), `nat-` (NAT Gateway), `pcx-` (peering), `tgw-` (Transit Gateway), `vgw-` (VPN), VPC endpoints.
- The most specific (longest-prefix) match wins.

## Internet Gateway (IGW)
- A horizontally scaled, highly available VPC component that allows **two-way** internet traffic. One per VPC, and free.
- To be "public", a subnet needs: a route `0.0.0.0/0 → igw-…` **and** instances with a public or Elastic IP **and** security groups/NACLs that allow the traffic.
- It does 1:1 NAT between an instance's private IP and its public IP.

## NAT Gateway
- Lets instances in **private** subnets make **outbound-only** connections (OS updates, pulling container images, calling APIs) without being reachable from the internet.
- Sits in a **public** subnet with an Elastic IP. The private route table points `0.0.0.0/0 → nat-…`.
- Managed and AZ-scoped: use one per AZ for resilience. It is billed per hour plus per GB (often a surprisingly big cost). Cheaper options: VPC endpoints for S3/DynamoDB (gateway endpoints are free), or a NAT instance for labs.

## Security Groups
- A **stateful** firewall on each ENI (instance level). **Allow rules only.** Inbound is denied by default, outbound allowed by default.
- Can reference other security groups (`app-sg` allows 8080 from `alb-sg`), which is ideal for tiered apps.
- All rules are evaluated together; there is no rule order.

## Network ACLs (NACLs)
- A **stateless** firewall at the **subnet** boundary. Return traffic must be allowed explicitly (ephemeral ports `1024–65535`).
- Supports **allow and deny** rules, evaluated **in number order**, first match wins. The final `*` rule denies.
- The default NACL allows everything. Use custom NACLs for coarse subnet-wide blocks (e.g. deny a malicious CIDR).

| | Security Group | Network ACL |
|---|---|---|
| Level | Instance / ENI | Subnet |
| State | Stateful | Stateless |
| Rules | Allow only | Allow + Deny |
| Evaluation | All rules | In order, first match |
| Default | Deny in, allow out | Allow all (default NACL) |

## Public vs private subnet
| | Public subnet | Private subnet |
|---|---|---|
| Default route | `0.0.0.0/0 → Internet Gateway` | `0.0.0.0/0 → NAT Gateway` (or none) |
| Instance IPs | Private + public/Elastic IP | Private only |
| Reachable from internet | Yes (if SG allows) | **No** |
| Outbound internet | Directly via IGW | Via NAT (outbound only) |
| What goes here | Load balancers, NAT GWs, bastion hosts | App servers, EKS nodes, databases, caches |

**Rule of thumb:** put as little as possible in public subnets. Only the load balancer should face the internet, and everything else sits behind it in private subnets.

## Related
VPC Peering and Transit Gateway (connect VPCs), Site-to-Site VPN and Direct Connect (on-prem), VPC Endpoints / PrivateLink (reach AWS services without the internet), VPC Flow Logs (traffic logs for troubleshooting). Session 19 builds a VPC + public subnet + IGW + route table + SG with Terraform.
