# EC2 — Elastic Compute Cloud

**What:** Resizable virtual machines (instances) in the cloud, billed per second/hour. Lives inside a VPC subnet in one Availability Zone.

## Building Blocks
| Concept | Description |
|---|---|
| **AMI** (Amazon Machine Image) | Template with OS + software used to launch an instance (Amazon Linux, Ubuntu, Windows, or your own custom AMI). Region-specific. |
| **Instance type** | CPU/memory/network size, e.g. `t3.micro` (2 vCPU, 1 GiB). |
| **Key pair** | SSH public key stored in AWS, private key (`.pem`) kept by you. `ssh -i key.pem ec2-user@<ip>`. |
| **Security Group** | Stateful virtual firewall at instance level; **allow rules only** (e.g. 22 from my IP, 80/443 from anywhere). |
| **EBS** | Network block storage (root + data volumes). Persists after stop; types `gp3` (general), `io2` (high IOPS), `st1`/`sc1` (HDD). Snapshots back up to S3. |
| **Instance store** | Ephemeral local disk; data lost on stop/terminate. |
| **User data** | Script run at first boot (install packages, start app). |

## Instance Type Families
| Family | Optimised for | Example |
|---|---|---|
| T / M | General purpose (T = burstable) | `t3.micro`, `m7i.large` |
| C | Compute | `c7g.xlarge` |
| R / X | Memory | `r7i.large` |
| I / D | Storage (fast local disk) | `i4i.large` |
| P / G | GPU / accelerated | `g5.xlarge` |

## Public vs Private IP
| | Private IP | Public IP | Elastic IP |
|---|---|---|---|
| Reachable from | Inside VPC only | Internet | Internet |
| Lifetime | Fixed for instance life | **Changes on stop/start** | Static until released |
| Cost | Free | Charged (IPv4) | Charged |

## Instance Lifecycle
```
pending → running ⇄ stopping → stopped
              ↓                    ↓
         shutting-down → terminated
```
- **Running:** billed for compute. **Stopped:** no compute charge, EBS still billed.
- **Reboot** keeps IPs and data. **Terminate** deletes the instance (root EBS deleted by default).
- Hibernate saves RAM to EBS for fast resume.

## Pricing Models
On-Demand (pay as you go) · Reserved / Savings Plans (1–3 yr commit, up to ~72% off) · Spot (spare capacity, up to ~90% off, can be interrupted).

## Use Cases
- Web/app servers behind a Load Balancer with Auto Scaling.
- Jenkins / build agents, bastion hosts.
- Self-managed databases, batch jobs, ML training on GPU instances.
