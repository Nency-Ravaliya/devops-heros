# AWS Elastic Compute Cloud (EC2) - Compute

**Name:** Smit Rupani  
**Enrollment:** 24bcs10256  

---

## 1. What is EC2?
Amazon EC2 provides resizable compute capacity in the cloud. It eliminates the need to invest in on-premise hardware and lets you launch virtual servers on-demand.

## 2. Core Concepts
- **AMI (Amazon Machine Image):** Pre-configured template containing OS (Ubuntu, Amazon Linux), application server, and packages.
- **Instance Types:** Optimized for varying workloads:
  - *General Purpose:* `t3`, `m5` (balanced compute, memory, network).
  - *Compute Optimized:* `c5`, `c6g` (high-performance processors).
  - *Memory Optimized:* `r5` (in-memory databases, caching).
- **Key Pairs:** SSH public/private key mechanism used to securely log in to Linux instances without passwords.
- **Security Groups:** Virtual firewalls controlling inbound and outbound traffic at the instance level (stateful).
- **EBS (Elastic Block Store):** High-performance block storage volumes attached to EC2 instances (like hard drives/SSDs).
- **Public vs Private IP:** Public IP allows internet routability; Private IP is used for secure intra-VPC communication.
