# VPC — Virtual Private Cloud

**What:** Your own logically isolated private network inside an AWS region. You control IP ranges, subnets, routing and firewalls. Every account has a default VPC per region.

## CIDR
- IP range of the VPC written as CIDR, e.g. `10.0.0.0/16` = 65,536 addresses. Allowed size `/16` to `/28`.
- Use private ranges (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`); avoid overlap with peered VPCs / on-prem.
- AWS reserves **5 IPs** in every subnet (network, router, DNS, future, broadcast).

## Components
| Component | Description |
|---|---|
| **Subnet** | Slice of the VPC CIDR in **one AZ**, e.g. `10.0.1.0/24`. |
| **Route table** | Rules that decide where traffic goes (`destination → target`). Every subnet is associated with exactly one. Each has a `local` route for the VPC CIDR. |
| **Internet Gateway (IGW)** | Attached to the VPC; enables two-way internet access for resources with public IPs. |
| **NAT Gateway** | Sits in a **public** subnet with an Elastic IP; lets **private** subnets reach the internet outbound only (updates, APIs). Charged per hour + per GB. |
| **Security Group** | Instance-level firewall. |
| **NACL** | Subnet-level firewall. |

## Public vs Private Subnet
| | Public subnet | Private subnet |
|---|---|---|
| Route table | `0.0.0.0/0 → IGW` | `0.0.0.0/0 → NAT GW` (or none) |
| Public IP | Yes | No |
| Reachable from internet | Yes (if SG allows) | No |
| Typical resources | Load balancer, bastion, NAT GW | App servers, databases |

```
Internet ⇄ IGW ⇄ [Public subnet: ALB, NAT GW] → [Private subnet: EC2, RDS]
                                     ↑ outbound only via NAT
```

## Security Group vs NACL
| | Security Group | NACL |
|---|---|---|
| Level | Instance / ENI | Subnet |
| State | **Stateful** (return traffic auto-allowed) | **Stateless** (allow both directions, incl. ephemeral ports) |
| Rules | Allow only | Allow **and** Deny |
| Evaluation | All rules evaluated | Numbered, lowest first, first match wins |
| Default | Deny all in, allow all out | Default NACL allows all |

## Other Features
VPC Peering / Transit Gateway (connect VPCs) · VPC Endpoints (private access to S3, DynamoDB) · Flow Logs (traffic logging) · Site-to-Site VPN / Direct Connect (on-prem).

## Best Practice Layout
2+ AZs, each with one public and one private subnet; NAT GW per AZ for HA; databases only in private subnets.
