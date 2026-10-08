# 02. EC2: Elastic Compute Cloud (Compute)

## What is EC2?

**Amazon EC2** provides resizable virtual servers (**instances**) in the cloud. You choose the operating system image, CPU/memory size, storage and network placement, and pay per second (Linux) while the instance runs. It's IaaS: AWS manages the hardware and hypervisor (Nitro), and you manage the OS and everything above it.

```text
Region ─ Availability Zone ─ VPC subnet ─ EC2 instance
                                          ├─ AMI (OS image)
                                          ├─ instance type (CPU/RAM)
                                          ├─ EBS volume(s) (disk)
                                          ├─ ENI with private IP (+ optional public IP)
                                          ├─ security group(s) (firewall)
                                          ├─ key pair (SSH)
                                          └─ IAM role (instance profile)
```

## AMI (Amazon Machine Image)

An **AMI** is the template an instance boots from: root volume snapshot + OS + preinstalled software + launch permissions. Sources:
- **AWS-provided:** Amazon Linux 2023, Ubuntu, Windows Server, Red Hat…
- **AWS Marketplace:** vendor images (often with licence fees).
- **Custom AMIs:** bake your own image (e.g. with Packer) for fast, consistent launches ("golden image").

AMIs are **regional** and are referenced by ID (`ami-0abc…`). In Terraform you usually look up the latest one with a `data "aws_ami"` filter rather than hard-coding the ID.

## Instance types

Named as **family + generation + options + size**. For example, `t3.micro` = `t` family, generation `3`, size `micro`; `m7g.large` = general purpose, gen 7, `g` = Graviton (ARM).

| Family | Purpose | Examples |
|---|---|---|
| **T** | Burstable general purpose (CPU credits) | `t3.micro`, `t4g.small` |
| **M** | Balanced general purpose | `m7i.large` |
| **C** | Compute optimised | `c7g.xlarge` |
| **R / X** | Memory optimised | `r7i.2xlarge` |
| **I / D** | Storage optimised (local NVMe) | `i4i.large` |
| **P / G / Inf / Trn** | Accelerated (GPU / ML chips) | `g5.xlarge` |

Pricing models: **On-Demand**; **Savings Plans / Reserved Instances** (1–3 year commitment, up to ~70% cheaper); **Spot** (spare capacity, up to ~90% cheaper, can be interrupted with a 2-minute warning); **Dedicated Hosts**. The **free tier** includes 750 hours/month of `t2.micro`/`t3.micro` for eligible accounts.

## Key pairs

EC2 uses **public-key cryptography** for SSH (Linux) or to decrypt the Windows admin password. AWS stores the **public key** and injects it into `~/.ssh/authorized_keys`; you keep the **private key** (`.pem`), which AWS never stores, so if you lose it, you lose that access path. Use `chmod 400 key.pem`, then `ssh -i key.pem ec2-user@<public-ip>`.

Modern alternatives that need no inbound SSH port at all: **EC2 Instance Connect** (temporary keys) and **AWS Systems Manager Session Manager** (shell through the SSM agent, audited, IAM-controlled).

## Security groups

A **security group** is a **stateful virtual firewall** attached to an instance's network interface:
- **Allow rules only** (no deny rules). Inbound is denied by default; outbound is allowed by default.
- **Stateful:** if inbound traffic is allowed, the reply is automatically allowed.
- Rules specify protocol, port range and source/destination (a CIDR **or another security group**).
- Changes apply immediately; an instance can have several SGs.

Example: a web server SG allows `80/443` from `0.0.0.0/0` and `22` only from my IP. A database SG allows `5432` only *from the web server's SG* (referencing the SG instead of IPs).

## EBS (Elastic Block Store)

**EBS volumes** are network-attached block disks for EC2:
- Live in **one Availability Zone**; attach to an instance in the same AZ.
- **Persist independently** of the instance (unless `DeleteOnTermination` is set, the default for root volumes).
- Types: **gp3** (general SSD, default; IOPS and throughput configurable separately), **io2** (provisioned IOPS for databases), **st1/sc1** (throughput/cold HDD).
- **Snapshots** are incremental backups stored in S3 (can be copied across regions and used to create AMIs).
- Can be **encrypted** with KMS (enable "encryption by default" per region).
- Different from **instance store**: local ephemeral disks that are lost when the instance stops.

## Public vs private IP

| | Private IP | Public IP (auto-assigned) | Elastic IP |
|---|---|---|---|
| Reachable from | Inside the VPC (and peered/VPN networks) | Internet | Internet |
| Lifetime | For the life of the instance | **Released on stop/start** | Static until you release it |
| Assigned by | Subnet CIDR | Subnet setting `map_public_ip_on_launch` or launch option | You allocate and associate it |
| Cost | Free | Charged per hour (all public IPv4 since 2024) | Charged per hour |

An instance in a **public subnet** (route `0.0.0.0/0 → Internet Gateway`) with a public IP is reachable from the internet. An instance in a **private subnet** has only a private IP and reaches the internet via a **NAT gateway**. The OS itself only sees the private IP; the public IP is translated by the Internet Gateway.

## Instance lifecycle

```text
          launch
pending ─────────▶ running ──stop──▶ stopping ──▶ stopped ──start──▶ pending
                     │  ▲                              │
              reboot │  │                              │ terminate
                     ▼  │                              ▼
                  (rebooting)      terminate ──▶ shutting-down ──▶ terminated
```

| State | Billed for compute? | Notes |
|---|---|---|
| pending | no | booting |
| running | **yes** | |
| stopping / stopped | no (EBS still billed) | stop/start may move it to new hardware; public IP changes; instance store lost |
| hibernated | no (EBS billed) | RAM saved to EBS; resumes faster |
| shutting-down / terminated | no | gone; root EBS deleted by default |

**User data** scripts run on first boot (e.g. install nginx). Termination protection prevents accidental deletes.

## Scaling and availability

- **Auto Scaling Groups** keep N instances healthy across AZs and scale on metrics.
- An **Elastic Load Balancer** (ALB/NLB) spreads traffic across instances in multiple AZs.
- **Launch templates** describe the AMI, type, SG, user data and IAM profile used by ASGs.

## Common use cases

- Web/application servers behind a load balancer with auto scaling.
- Self-managed databases or software that needs full OS control.
- Batch processing and CI runners (often on Spot).
- Kubernetes worker nodes (EKS managed node groups are EC2 instances).
- Bastion hosts and lift-and-shift migrations of on-prem VMs.
- GPU instances for ML training and inference.

In **Session 19** I launch a `t3.micro` EC2 instance with Terraform in a public subnet, with a security group, user data that installs nginx, and an IAM instance profile.
