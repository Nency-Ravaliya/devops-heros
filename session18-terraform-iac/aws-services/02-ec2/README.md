# 02 · EC2 — Elastic Compute Cloud (Compute)

## What is EC2?

**Amazon EC2** provides resizable **virtual servers (instances)** in the AWS cloud. You choose the operating system, CPU, memory, storage and networking, start the instance in minutes, and pay only while it runs (per second for Linux).

EC2 is **Infrastructure as a Service (IaaS)**. AWS manages the physical hardware and the hypervisor (Nitro). You manage the OS, patches, runtime and application.

```text
                    Region (ap-south-1)
┌──────────────────────── VPC 10.0.0.0/16 ────────────────────────┐
│  AZ ap-south-1a                                                 │
│  ┌──────────── Public subnet 10.0.1.0/24 ─────────────┐         │
│  │   ┌───────────── EC2 instance ──────────────┐      │         │
│  │   │  AMI: Amazon Linux 2023                  │      │         │
│  │   │  Type: t3.micro (2 vCPU, 1 GiB)          │      │         │
│  │   │  Private IP 10.0.1.25 / Public IP 13.x   │      │         │
│  │   │  Key pair: my-key   IAM role: app-role   │      │         │
│  │   └───────┬──────────────────────────┬───────┘      │         │
│  │     Security Group             EBS volume (gp3)     │         │
│  │     (22, 80, 443 in)           root 8 GiB           │         │
│  └─────────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

## AMI (Amazon Machine Image)

An **AMI** is the template used to launch an instance. It contains:
- a root volume snapshot (OS plus any pre-installed software)
- launch permissions (public, private, or shared with specific accounts)
- block device mappings (which volumes to attach)

| Source | Examples |
|---|---|
| AWS-provided | Amazon Linux 2023, Ubuntu, RHEL, Windows Server |
| AWS Marketplace | Pre-built images from vendors (some are paid) |
| Community | Public AMIs shared by others (verify before use) |
| Custom | Your own *golden image*, built with Packer or "Create image" |

- AMIs are **regional**. Copy an AMI to use it in another region.
- AMI IDs differ per region. In Terraform, look them up with a `data "aws_ami"` block instead of hard-coding them.

## Instance types

The name format is **`family` `generation` `[attributes]` . `size`**. For example, in `m7g.large`, `m` is the family, `7` is the generation, `g` means Graviton (ARM), and `large` is the size.

| Family | Optimized for | Examples | Typical workload |
|---|---|---|---|
| **General purpose** | balanced CPU/RAM | `t3`, `t4g`, `m7i`, `m7g` | web servers, dev/test, small DBs |
| **Compute optimized** | high CPU | `c7i`, `c7g` | batch processing, game servers, encoding |
| **Memory optimized** | high RAM | `r7i`, `x2idn`, `z1d` | in-memory caches, large databases |
| **Storage optimized** | high local disk I/O | `i4i`, `d3` | NoSQL, data warehousing |
| **Accelerated computing** | GPU / ML chips | `p5`, `g5`, `inf2`, `trn1` | ML training/inference, graphics |

- **`t` (burstable)** instances earn CPU credits while idle and spend them under load. `t3.micro` and `t4g.micro` are Free Tier eligible (`t2.micro` only on older accounts or in regions without `t3`).
- Suffixes: `g` = Graviton (ARM, cheaper), `a` = AMD, `i` = Intel, `d` = local NVMe disk, `n` = enhanced networking.

**Purchase options**

| Option | Discount | Use when |
|---|---|---|
| On-Demand | none | short-term or unpredictable workloads |
| Savings Plans / Reserved | up to ~72% | steady 1- or 3-year usage |
| Spot | up to ~90% | fault-tolerant work (can be reclaimed with 2 minutes' notice) |
| Dedicated Hosts | n/a | licensing or compliance needs a physical server |

## Key pairs

A **key pair** is used for SSH login to Linux instances, or to decrypt the Windows admin password.
- AWS stores the **public key** and injects it into `~/.ssh/authorized_keys` at first boot.
- You download the **private key** (`.pem`) **once**. AWS cannot recover it for you.
- Types: RSA or ED25519.

```bash
aws ec2 create-key-pair --key-name my-key --query KeyMaterial --output text > my-key.pem
chmod 400 my-key.pem
ssh -i my-key.pem ec2-user@<public-ip>      # Amazon Linux (Ubuntu uses "ubuntu")
```

> **Alternatives:** **EC2 Instance Connect** and **SSM Session Manager** give shell access without managing keys or opening port 22.

## Security Groups

A **security group** is a **stateful virtual firewall** attached to an instance's network interface (ENI).

| Property | Detail |
|---|---|
| Rules | **Allow only**. You cannot write deny rules. |
| Default | all inbound **denied**, all outbound **allowed** |
| Stateful | return traffic for an allowed request is automatically allowed |
| Sources | CIDR (`0.0.0.0/0`), prefix list, or **another security group** |
| Scope | an instance can have several SGs, and one SG can be shared by many instances |

```text
Inbound rules (web-sg)
  Type   Port  Source
  SSH    22    203.0.113.10/32   ← your IP only, never 0.0.0.0/0
  HTTP   80    0.0.0.0/0
  HTTPS  443   0.0.0.0/0
```

## EBS (Elastic Block Store)

**EBS** provides network-attached **block storage volumes** for EC2. Think of it as a virtual hard disk.

- Lives in **one Availability Zone** and can only attach to instances in that AZ.
- Data **persists independently** of the instance (unless *Delete on termination* is set, which is the default for root volumes).
- **Snapshots** are incremental backups stored in S3. Use them to restore, copy across regions, or create AMIs.
- Encryption with KMS is transparent and can be enabled by default per region.

| Volume type | Category | Use |
|---|---|---|
| `gp3` | General purpose SSD | default choice. 3,000 IOPS baseline, independently tunable |
| `gp2` | General purpose SSD | older type. IOPS scale with size |
| `io2` Block Express | Provisioned IOPS SSD | critical databases, up to 256k IOPS |
| `st1` | Throughput HDD | big data, logs |
| `sc1` | Cold HDD | infrequently accessed data, lowest cost |

**EBS vs Instance Store:** an instance store is physically attached NVMe. It is very fast but **ephemeral**, so data is lost when the instance stops or terminates.

## Public vs private IP

| | Private IP | Public IP | Elastic IP |
|---|---|---|---|
| Reachable from | inside the VPC (and peered/VPN networks) | the internet | the internet |
| Assigned | always, from the subnet CIDR | if the subnet has auto-assign enabled or you request it at launch | you allocate it and attach it |
| On stop/start | **kept** | **changes** (released on stop) | **kept** |
| Cost | free | charged per hour (IPv4) | charged per hour |

- A public IP alone is not enough to be reachable from the internet. The subnet also needs a route `0.0.0.0/0 → Internet Gateway`, and the security group must allow the traffic.
- The instance OS only sees its **private** IP. The IGW performs 1:1 NAT to the public IP.

## Instance lifecycle

```text
            launch
              │
              ▼
          ┌────────┐
          │pending │
          └───┬────┘
              ▼
   reboot ┌────────┐  stop       ┌────────┐       ┌────────┐
  ┌──────►│running │────────────►│stopping│──────►│stopped │
  └───────┤        │◄────────────┴────────┴───────┤        │
          └───┬────┘          start               └───┬────┘
              │ hibernate ─► stopping ─► stopped       │
              │ terminate                    terminate │
              ▼                                        ▼
        ┌────────────┐                         ┌────────────┐
        │shutting-down├───────────────────────►│ terminated │
        └────────────┘                         └────────────┘
```

| State | Billed for compute? | Notes |
|---|---|---|
| pending | no | booting |
| running | **yes** | |
| stopping / stopped | no (EBS still billed) | public IP is released, instance store is wiped |
| stopped (hibernated) | no (EBS billed; billed while *stopping* to hibernate) | RAM is saved to the EBS root volume |
| terminated | no | permanent. Root EBS is deleted by default. |

Use **termination protection** on important instances. **User data** scripts run on first boot, which is useful for bootstrapping (installing nginx, for example).

## Common use cases

- Hosting web applications and APIs, often behind an **ALB** and an **Auto Scaling Group**
- Bastion or jump hosts for private networks
- Self-managed databases or caches when a managed service does not fit
- CI/CD build runners (Jenkins agents, self-hosted GitHub runners)
- Batch, HPC and ML training on GPU instances or Spot fleets
- Kubernetes worker nodes (EKS managed node groups, Karpenter)
- Lift-and-shift migration of on-premises VMs

## Terraform example

```hcl
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = "my-key"
  user_data              = <<-EOF
    #!/bin/bash
    dnf install -y nginx && systemctl enable --now nginx
  EOF
  tags                   = { Name = "web-server" }
}
```

## Useful CLI commands

```bash
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]' --output table
aws ec2 start-instances --instance-ids i-0abc123
aws ec2 stop-instances  --instance-ids i-0abc123
aws ec2 terminate-instances --instance-ids i-0abc123
aws ec2 describe-instance-types --instance-types t3.micro
```
