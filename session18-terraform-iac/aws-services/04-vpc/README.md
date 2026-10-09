# Amazon Virtual Private Cloud (VPC) — Cloud Networking Guide

**Author:** Durga Prasad  
**Enrollment Number:** 10012  
**Session:** 18 - AWS Cloud & Infrastructure as Code  
**Course:** SST DevOps & Cloud  

---

## 1. What is Amazon VPC?

**Amazon Virtual Private Cloud (Amazon VPC)** enables you to launch AWS resources into a logically isolated virtual network that you define. You have complete control over your virtual networking environment, including selection of your own IP address range, creation of subnets, and configuration of route tables and network gateways.

---

## 2. VPC Architectural Blueprint

```text
                           PRODUCTION VPC ARCHITECTURE (10.0.0.0/16)
                           
               ┌────────────────────────────────────────────────────────┐
               │              Internet Gateway (IGW)                    │
               └───────────────────────────┬────────────────────────────┘
                                           │
 ┌─────────────────────────────────────────┼──────────────────────────────────────────┐
 │ Availability Zone A                     │ Availability Zone B                      │
 │                                         │                                          │
 │  ┌───────────────────────────────────┐  │  ┌────────────────────────────────────┐  │
 │  │ Public Subnet (10.0.1.0/24)       │  │  │ Public Subnet (10.0.2.0/24)        │  │
 │  │ Route: 0.0.0.0/0 ──► IGW          │  │  │ Route: 0.0.0.0/0 ──► IGW           │  │
 │  │                                   │  │  │                                    │  │
 │  │  ┌──────────────┐                 │  │  │  ┌──────────────┐                  │  │
 │  │  │ Public ALB   │  [NAT Gateway]  │  │  │  │ Public ALB   │                  │  │
 │  │  └──────────────┘  (Elastic IP)   │  │  │  └──────────────┘                  │  │
 │  └──────────────────────────┬────────┘  │  └────────────────────────────────────┘  │
 │                             │           │                                          │
 │                             ▼           │                                          │
 │  ┌───────────────────────────────────┐  │  ┌────────────────────────────────────┐  │
 │  │ Private Subnet (10.0.10.0/24)     │  │  │ Private Subnet (10.0.20.0/24)      │  │
 │  │ Route: 0.0.0.0/0 ──► NAT Gateway  │  │  │ Route: 0.0.0.0/0 ──► NAT Gateway   │  │
 │  │                                   │  │  │                                    │  │
 │  │  ┌──────────────┐                 │  │  │  ┌──────────────┐                  │  │
 │  │  │ App EC2 / K8s│                 │  │  │  │ App EC2 / K8s│                  │  │
 │  │  └──────────────┘                 │  │  │  └──────────────┘                  │  │
 │  └───────────────────────────────────┘  │  └────────────────────────────────────┘  │
 └────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Core Networking Primitives

### 1. Classless Inter-Domain Routing (CIDR)
Specifies the IP address range for the VPC.
* Example: `10.0.0.0/16` gives 65,536 total private IPv4 addresses (`10.0.0.0` to `10.0.255.255`).
* RFC 1918 Private Ranges: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.

### 2. Subnets (Public vs Private)
Subdivisions of a VPC CIDR bound to a specific Availability Zone.
* **AWS Reserved IPs:** In any subnet, AWS reserves 5 IP addresses (`.0` network, `.1` VPC router, `.2` DNS server, `.3` future use, `.255` broadcast). A `/24` subnet yields 251 usable IPs.
* **Public Subnet:** Associated with a Route Table containing a route to the Internet Gateway (`0.0.0.0/0 -> igw-xxxx`). Instances can receive public IPs and communicate directly with the internet.
* **Private Subnet:** Does NOT route directly to an IGW. Instances receive only private IPs and cannot be initiated from the public internet. Outbound updates route via a NAT Gateway.

### 3. Internet Gateway (IGW)
A horizontally scaled, redundant, and highly available VPC component that enables communication between instances in your VPC and the internet.

### 4. NAT Gateway (Network Address Translation)
Enables instances in a private subnet to connect to external services (package managers, OS security patches) while preventing the internet from initiating inbound connections with those instances.
* Deployed in a **public subnet** with an **Elastic IP**.

### 5. Route Tables
A set of rules (routes) used to determine where network traffic is directed.
* Every subnet must be associated with exactly one route table.

### 6. Security Groups vs Network Access Control Lists (NACLs)

| Feature | Security Group (SG) | Network ACL (NACL) |
|---|---|---|
| **Scope** | Instance / ENI level | Subnet boundary level |
| **Statefulness** | **Stateful** (Return traffic automatically permitted) | **Stateless** (Inbound & Outbound rules evaluated independently) |
| **Rule Evaluation** | All rules evaluated before decision | Evaluated in sequential numerical order (100, 200, 300) |
| **Default** | Deny all inbound, Allow all outbound | Default NACL: Allow all. Custom NACL: Deny all. |
| **Allow/Deny Rules** | Supports **Allow** rules only | Supports both **Allow** and **Deny** rules |

---

## 4. Best Practices for VPC Design

1. **Multi-AZ Architecture:** Always deploy subnets across at least 2 Availability Zones for high availability.
2. **Strict Layering:** Separate workloads into Public (ALB), Private (Application servers/containers), and Database/Isolated tiers.
3. **No Database in Public Subnets:** Keep databases (RDS, Aurora) in dedicated private subnets with no public internet routes.
