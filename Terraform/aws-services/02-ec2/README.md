# 02. EC2 – Elastic Compute Cloud (Compute)

## What is EC2?
Amazon EC2 provides **resizable virtual servers (instances)** in the cloud. You choose the OS image, CPU/RAM/network size, storage and firewall rules, and pay per second (Linux) while the instance runs. It is AWS's core **IaaS** service: you manage the OS and everything above it.

## AMI (Amazon Machine Image)
- The **template** an instance boots from: root volume snapshot + OS + preinstalled software + launch permissions.
- Sources: AWS (Amazon Linux 2023, Ubuntu, Windows), AWS Marketplace, community, or **your own** (bake one with Packer or "Create image" from a configured instance → a "golden AMI").
- AMIs are **regional** (copy them to use elsewhere) and identified by `ami-xxxxxxxx`. In Terraform, look them up with a `data "aws_ami"` filter instead of hard-coding IDs.

## Instance types
Format: `family` + `generation` + `attributes` + `.size`, e.g. `t3.micro`, `m7g.large` (g = Graviton/ARM), `c6i.2xlarge`.

| Family | Optimized for | Examples / use |
|---|---|---|
| **T** (burstable) | Baseline CPU + credits | `t3.micro`, `t4g.small`: dev, small sites (free tier) |
| **M** | General purpose | `m7i.large`: app servers, backends |
| **C** | Compute | `c7g.xlarge`: CI runners, batch, encoding |
| **R / X** | Memory | `r7i.2xlarge`: in-memory caches, big databases |
| **I / D** | Storage (local NVMe) | `i4i`: NoSQL, data warehouses |
| **P / G / Inf / Trn** | Accelerated (GPU / ML chips) | ML training and inference, graphics |

**Purchase options:** On-Demand · Savings Plans / Reserved (1–3 yr commitment, up to ~72% off) · **Spot** (spare capacity, up to ~90% off, can be reclaimed with a 2-min warning) · Dedicated Hosts.

## Key pairs
- An SSH **public key** stored in AWS and injected into the instance at launch (`~/.ssh/authorized_keys`). You keep the **private key** (`.pem`), and AWS can't recover it.
- Linux: `ssh -i my-key.pem ec2-user@<public-ip>`. Windows: the key decrypts the Administrator password.
- Modern alternative: **SSM Session Manager** or **EC2 Instance Connect**, so no port 22 is open and no keys need managing.

## Security Groups
- A **stateful virtual firewall** at the instance's network interface (ENI).
- **Allow rules only.** Inbound is denied by default and all outbound is allowed by default. Return traffic is allowed automatically (that's what stateful means).
- A source can be a CIDR **or another security group**. For example, "DB SG allows 5432 only from the App SG" is the standard way to tier an app.
- Example: web SG = inbound 80/443 from `0.0.0.0/0`, 22 from *my IP only*.

## EBS (Elastic Block Store)
- **Network-attached block storage** (a virtual disk) that lives independently of the instance, in **one Availability Zone**.

| Type | Use |
|---|---|
| `gp3` (SSD, default) | General purpose; IOPS and throughput tunable separately |
| `io2 Block Express` | Databases needing very high, consistent IOPS |
| `st1` / `sc1` (HDD) | Throughput-heavy / cold sequential data |

- **Snapshots** are incremental backups to S3 and can be copied across regions. Volumes can be **encrypted with KMS**, and resized or retyped live.
- Root volumes are deleted on termination by default (`DeleteOnTermination`). Extra data volumes are kept.
- **Instance store** = physically attached, very fast, but **ephemeral** (lost on stop/terminate).

## Public vs private IP
| | Private IP | Public IP | Elastic IP |
|---|---|---|---|
| From | The subnet CIDR (e.g. `10.0.1.25`) | AWS pool, assigned if the subnet/launch setting enables it | Allocated to your account |
| Reachable from | Inside the VPC (or VPN/peering) | The internet (via the Internet Gateway, 1:1 NAT) | The internet |
| On stop/start | **Kept** | **Changes** | Kept, can move between instances |
| Cost | Free | Charged per hour (since 2024) | Charged per hour |

An instance in a **private subnet** has only a private IP and reaches the internet outbound through a **NAT Gateway**.

## Instance lifecycle
```
           launch
             │
          pending ──► running ◄──────────── start
             │          │   │  reboot (same host, keeps everything)
             │          │   ▼
             │          │  stopping ──► stopped   (EBS kept; no compute charge; public IP released)
             │          │                  │
             │          │  (hibernate: RAM saved to the EBS root, then stopped)
             │          ▼                  ▼
             └──────► shutting-down ──► terminated  (root EBS deleted by default, irreversible)
```
Billing runs only in `running` (EBS storage is billed always). Enable **termination protection** on important instances. **Auto Scaling Groups** replace unhealthy instances automatically.

## Common use cases
- Web/app servers behind an **Application Load Balancer** in an **Auto Scaling Group** across AZs
- Self-managed databases or legacy apps that need OS-level control (lift-and-shift migrations)
- **Kubernetes worker nodes** (EKS managed node groups / Karpenter are EC2 under the hood)
- CI/CD build agents (Jenkins agents, GitHub Actions self-hosted runners), often on Spot
- Bastion hosts, VPN servers, GPU machine-learning training
