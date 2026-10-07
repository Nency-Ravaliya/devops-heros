# 02 — EC2 (Elastic Compute Cloud)

> **Virtual Servers in the AWS Cloud**

---

## What is EC2?

Amazon EC2 (Elastic Compute Cloud) provides **resizable virtual machines** in the cloud. You can launch, stop, and terminate servers on demand — paying only for what you use.

**Why EC2?**
- No upfront hardware cost
- Launch in seconds
- Scale up/down on demand
- Wide choice of instance types

---

## Core EC2 Concepts

### 🖼️ AMI (Amazon Machine Image)

An **AMI** is a pre-configured template used to launch EC2 instances. It includes:
- Operating system (Amazon Linux, Ubuntu, Windows)
- Application server
- Pre-installed software

```
AMI: ami-0c02fb55956c7d316  →  Amazon Linux 2023
AMI: ami-0e86e20dae9224db8  →  Ubuntu 24.04 LTS
```

| AMI Type | Description |
|---|---|
| AWS provided | Official OS images |
| Marketplace | Third-party (e.g. CIS hardened images) |
| Custom | Your own AMI (baked from existing instance) |

---

### ⚙️ Instance Types

Instance types define **CPU, memory, network, and storage** capacity.

| Family | Use Case | Example |
|--------|----------|---------|
| **t** (General) | Dev/test, low cost | `t3.micro`, `t3.medium` |
| **m** (General) | Balanced workloads | `m5.large`, `m6i.xlarge` |
| **c** (Compute) | CPU-intensive (ML, encoding) | `c5.xlarge`, `c6g.2xlarge` |
| **r** (Memory) | In-memory DBs, caching | `r5.large`, `r6i.4xlarge` |
| **p/g** (GPU) | ML training, graphics | `p3.2xlarge`, `g4dn.xlarge` |

**Naming convention:** `t3.micro` = Family `t`, Generation `3`, Size `micro`

---

### 🔑 Key Pairs

Key pairs enable **SSH access** to Linux EC2 instances.

```
AWS generates:
  Private key → you download (.pem file)
  Public key  → stored on EC2 instance (~/.ssh/authorized_keys)

SSH:
  ssh -i my-key.pem ec2-user@<public-ip>
```

**Best practice:**
- Store `.pem` files securely (never commit to Git)
- Use `chmod 400 my-key.pem` on Linux/Mac

---

### 🔒 Security Groups

A **Security Group** is a virtual firewall that controls **inbound and outbound traffic** for EC2 instances.

```
Security Group: web-sg
  Inbound Rules:
    Port 22   (SSH)   → My IP only
    Port 80   (HTTP)  → 0.0.0.0/0
    Port 443  (HTTPS) → 0.0.0.0/0
  Outbound Rules:
    All traffic → 0.0.0.0/0
```

- **Stateful** — if inbound allowed, response is automatically allowed
- Multiple security groups can be applied to one instance

---

### 💾 EBS (Elastic Block Store)

**EBS** is persistent block storage attached to EC2 instances.

| Volume Type | Use Case | Max IOPS |
|---|---|---|
| `gp3` (General SSD) | Boot volumes, general workloads | 16,000 |
| `io2` (Provisioned SSD) | High-performance databases | 64,000 |
| `st1` (Throughput HDD) | Big data, log processing | 500 MB/s |
| `sc1` (Cold HDD) | Infrequent access | 250 MB/s |

- EBS volumes persist independently of the EC2 instance
- Can be detached and re-attached to another instance

---

### 🌐 Public vs Private IP

| | Public IP | Private IP |
|---|---|---|
| **Scope** | Internet-accessible | Internal VPC only |
| **Persistence** | Changes on stop/start | Permanent |
| **Cost** | Charged when idle (since 2024) | Free |
| **Use** | Web servers, bastion hosts | Internal services, databases |

> Use **Elastic IP** for a static public IP that doesn't change.

---

## Instance Lifecycle

```
Launch (Pending)
      │
      ▼
   Running  ←──────────────────────────┐
      │                                │
      ├── Stop → Stopped → Start ──────┘
      │
      ├── Reboot → Running
      │
      └── Terminate → Terminated (permanent, data deleted)
```

| State | Billing |
|-------|---------|
| Running | ✅ Charged |
| Stopped | ❌ Not charged (EBS still charged) |
| Terminated | ❌ Not charged |

---

## Common Use Cases

| Use Case | EC2 Setup |
|---|---|
| Web server | t3.medium, Amazon Linux, port 80/443 open |
| CI/CD runner | c5.xlarge, GitHub Actions self-hosted runner |
| Development environment | t3.micro (free tier eligible) |
| Database server | r5.large + EBS io2 |
| Bastion host | t3.micro, port 22 from your IP only |

---

## Key CLI Commands

```bash
# List instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' --output table

# Start an instance
aws ec2 start-instances --instance-ids i-0abc123def456

# Stop an instance
aws ec2 stop-instances --instance-ids i-0abc123def456

# Terminate an instance
aws ec2 terminate-instances --instance-ids i-0abc123def456

# Describe security groups
aws ec2 describe-security-groups --group-names web-sg

# List key pairs
aws ec2 describe-key-pairs

# SSH into instance
ssh -i my-key.pem ec2-user@<public-ip>
```
