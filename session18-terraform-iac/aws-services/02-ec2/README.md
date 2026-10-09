# Amazon Elastic Compute Cloud (EC2) — Technical Architecture & Operations Guide

**Author:** Durga Prasad  
**Enrollment Number:** 10012  
**Session:** 18 - AWS Cloud & Infrastructure as Code  
**Course:** SST DevOps & Cloud  

---

## 1. What is Amazon EC2?

**Amazon Elastic Compute Cloud (Amazon EC2)** provides scalable on-demand computing capacity in the AWS Cloud. It eliminates the need to invest in hardware upfront, allowing teams to develop and deploy applications faster by provisioning virtual server instances in seconds.

---

## 2. Core EC2 Architectural Components

```text
                             AMAZON EC2 INSTANCE ARCHITECTURE
                             
                     Virtual Private Cloud (VPC) / Subnet
                     ┌───────────────────────────────────────────────┐
                     │                                               │
                     │   ┌───────────────────────────────────────┐   │
                     │   │         Security Group (Firewall)     │   │
                     │   │   Inbound: Port 22 (SSH), 80/443      │   │
                     │   │   Outbound: All Traffic (Default)     │   │
                     │   │   ┌───────────────────────────────┐   │   │
                     │   │   │        EC2 Instance           │   │   │
                     │   │   │   AMI: Ubuntu 24.04 LTS       │   │   │
                     │   │   │   Type: t3.micro (2 vCPU, 1G) │   │   │
                     │   │   │   Key Pair: devops-key.pem    │   │   │
                     │   │   │   Private IP: 10.0.1.45       │   │   │
                     │   │   │   Public IP: 54.210.xx.xx     │   │   │
                     │   │   └───────────────┬───────────────┘   │   │
                     │   └───────────────────┼───────────────────┘   │
                     │                       │                       │
                     └───────────────────────┼───────────────────────┘
                                             │ Network Block Storage
                                             ▼
                                 ┌───────────────────────┐
                                 │   Amazon EBS Volume   │
                                 │   gp3 / 30 GB         │
                                 │   Root Filesystem (/) │
                                 └───────────────────────┘
```

### 1. Amazon Machine Image (AMI)
A pre-configured template that contains the software configuration (operating system, application server, and applications) required to launch your instance.
* **Types:** AWS-provided (Amazon Linux 2023, Ubuntu, Debian, Windows), AWS Marketplace AMIs, and Custom/Golden AMIs built via HashiCorp Packer.

### 2. Instance Types & Families
Categorized by hardware optimization:
* **General Purpose (`t3`, `t4g`, `m6i`):** Balanced compute, memory, and networking.
* **Compute Optimized (`c6i`, `c7g`):** High-performance processors for batch processing, media transcoding, machine learning inference.
* **Memory Optimized (`r6i`, `r7g`):** Fast performance for high-memory in-memory databases (Redis, Memcached) and relational databases.
* **Storage / Accelerated Computing (`i3`, `g5`, `p4`):** Direct NVMe storage or NVIDIA GPUs for deep learning models.

### 3. Key Pairs
Amazon EC2 uses public–private key cryptography to encrypt and decrypt login information:
* The **public key** is injected into `~/.ssh/authorized_keys` during launch.
* The **private key** (`.pem` file) is retained securely by the user to authenticate via SSH (`ssh -i key.pem ubuntu@public-ip`).

### 4. Security Groups (Stateful Virtual Firewalls)
Control inbound and outbound network traffic at the instance level.
* **Stateful:** If an inbound request is permitted on port 80, the return outbound response is automatically allowed regardless of outbound rules.
* **Default:** Denies all inbound traffic; allows all outbound traffic.

### 5. Elastic Block Store (EBS)
Network-attached block storage devices that persist independently from the lifecycle of an EC2 instance.
* **gp3 (General Purpose SSD):** Baseline 3,000 IOPS and 125 MB/s throughput, dynamically scalable.
* **io2 (Provisioned IOPS SSD):** For critical transactional workloads.
* **Snapshots:** Point-in-time incremental backups saved into Amazon S3.

### 6. Public IP vs Private IP vs Elastic IP
* **Private IP:** Internal IP address allocated within the VPC subnet CIDR block; retained throughout the instance life.
* **Public IP:** Automatically assigned from Amazon's pool on launch; changes when the instance is stopped and started.
* **Elastic IP (EIP):** Static, persistent public IPv4 address that does not change across stop/start cycles.

---

## 3. EC2 Instance Lifecycle States

```text
[Launch] ──► [pending] ──► [running] ──► [stopping] ──► [stopped]
                              │                           │
                              ├────────► [rebooting]      └─► [start] ──► [pending]
                              │
                              └────────► [shutting-down] ──► [terminated] (Storage deleted)
```

---

## 4. Common Use Cases

1. **Web and Application Hosting:** Running container hosts (Docker, Kubernetes worker nodes) or standard monolithic stacks (Nginx, Node.js, Python).
2. **CI/CD Build Runners:** Dedicated GitHub Actions or Jenkins self-hosted agents executing resource-intensive builds.
3. **Database Servers:** Hosting self-managed PostgreSQL, MySQL, or MongoDB instances with provisioned IOPS EBS volumes.
