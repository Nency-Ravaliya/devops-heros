# AWS EC2 (Elastic Compute Cloud) - Compute

## 1. What is EC2?
**Amazon Elastic Compute Cloud (Amazon EC2)** provides scalable, on-demand virtual computing capacity in the AWS cloud, removing the need to invest in upfront hardware.

---

## 2. Core EC2 Concepts

* **AMI (Amazon Machine Image):** Pre-configured virtual appliance template containing the operating system (Ubuntu, Amazon Linux), applications, and default configurations required to launch an instance.
* **Instance Types:** Families optimized for compute (`c`), memory (`r`), storage (`i`), or general-purpose workloads (`t`, `m`). Formatted as `family.generation.size` (e.g., `t3.micro`).
* **Key Pairs:** Asymmetric cryptography pair (public key stored in AWS, private `.pem` file downloaded by user) used to authenticate SSH or RDP connections.
* **Security Groups:** Virtual stateful firewalls controlling inbound and outbound traffic at the network interface level.
* **EBS (Elastic Block Store):** High-performance block storage volumes mounted to EC2 instances for persistent OS root volumes and databases.
* **Public vs Private IP:**
  * **Private IP:** Internal routable address retained throughout the instance lifecycle within the VPC.
  * **Public IP / Elastic IP:** Publicly routable IPv4 address reachable over the internet.

---

## 3. EC2 Instance Lifecycle

```text
[ Pending ] ---> [ Running ] <---> [ Stopping ] ---> [ Stopped ]
                     |                                    |
                     +------------------------------------+
                                      |
                                      v
                               [ Terminated ]
```

* **Running:** Instance is actively executing workloads and incurring hourly compute charges.
* **Stopped:** Instance OS shuts down; EBS root volume persists, compute charges stop, storage charges continue.
* **Terminated:** Instance and ephemeral volumes are permanently deleted.

---

## 4. Common Use Cases
* Hosting monolithic web applications and microservices (Nginx, Node.js, Spring Boot).
* Self-managed database instances (MongoDB, PostgreSQL) on dedicated EBS volumes.
* Batch processing jobs, CI/CD self-hosted runners, and machine learning training nodes.
