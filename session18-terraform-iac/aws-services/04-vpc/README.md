# 04 — VPC (Virtual Private Cloud)

> **Your Isolated Network in AWS**

---

## What is VPC?

A **VPC (Virtual Private Cloud)** is a logically isolated section of the AWS cloud where you launch your AWS resources. It's your own private network within AWS.

**Why VPC?**
- Full control over your network topology
- Isolate resources from the public internet
- Define custom IP ranges, subnets, routing, and security rules
- Connect to on-premises networks via VPN or Direct Connect

Every AWS account comes with a **default VPC** in each region.

---

## Core VPC Concepts

### 📐 CIDR (Classless Inter-Domain Routing)

A **CIDR block** defines the IP address range for your VPC or subnet.

```
VPC CIDR:         10.0.0.0/16   →  65,536 IP addresses
  ├── Subnet 1:   10.0.1.0/24   →  256 IPs (public)
  ├── Subnet 2:   10.0.2.0/24   →  256 IPs (public)
  ├── Subnet 3:   10.0.10.0/24  →  256 IPs (private)
  └── Subnet 4:   10.0.11.0/24  →  256 IPs (private)
```

| CIDR | IP Count | Use Case |
|------|----------|----------|
| `/16` | 65,536 | Large VPC |
| `/24` | 256 | Standard subnet |
| `/28` | 16 | Small subnet |

---

### 🏘️ Subnets

A **Subnet** is a range of IP addresses in your VPC. Subnets are always in **one Availability Zone**.

| Subnet Type | Internet Access | Use Case |
|---|---|---|
| **Public** | Yes (via Internet Gateway) | Web servers, load balancers, bastion hosts |
| **Private** | No (or via NAT Gateway) | Databases, app servers, internal services |

```
VPC: 10.0.0.0/16
  ├── ap-south-1a
  │   ├── Public Subnet:  10.0.1.0/24  → EC2 Web Server
  │   └── Private Subnet: 10.0.10.0/24 → RDS Database
  └── ap-south-1b
      ├── Public Subnet:  10.0.2.0/24  → EC2 Web Server (HA)
      └── Private Subnet: 10.0.11.0/24 → RDS Replica (HA)
```

---

### 🗺️ Route Tables

A **Route Table** contains rules (routes) that determine where network traffic is directed.

```
Public Route Table:
  Destination    Target
  10.0.0.0/16   local            (VPC internal traffic)
  0.0.0.0/0     igw-0abc123      (Internet Gateway)

Private Route Table:
  Destination    Target
  10.0.0.0/16   local
  0.0.0.0/0     nat-0def456      (NAT Gateway — outbound only)
```

---

### 🌐 Internet Gateway (IGW)

An **Internet Gateway** enables communication between your VPC and the internet.

- One IGW per VPC
- Attached to the VPC, not a specific subnet
- Required for public subnets to have internet access

```
Internet → Internet Gateway → Public Subnet → EC2 instance
```

---

### 🔄 NAT Gateway

A **NAT Gateway** allows resources in **private subnets** to access the internet (for updates, package installs) without being accessible from the internet.

```
Private Subnet → NAT Gateway (in Public Subnet) → Internet Gateway → Internet
```

| | NAT Gateway | NAT Instance |
|---|---|---|
| Management | AWS managed | You manage the EC2 |
| Availability | Highly available | Single point of failure |
| Bandwidth | Up to 100 Gbps | Instance type limited |
| Cost | Hourly + data | EC2 instance cost |

---

### 🔒 Security Groups vs Network ACLs

| Feature | Security Group | Network ACL |
|---|---|---|
| Level | Instance level | Subnet level |
| State | **Stateful** | **Stateless** |
| Rules | Allow only | Allow and Deny |
| Rule order | All rules evaluated | Rules evaluated in order |
| Default | Deny all inbound | Allow all |

**Security Group (Stateful):**
```
Inbound: Allow port 80 → response automatically allowed outbound
```

**Network ACL (Stateless):**
```
Inbound:  Rule 100 - Allow port 80
Outbound: Rule 100 - Allow port 1024-65535 (ephemeral ports - must be explicit)
```

---

### 🔑 Public vs Private Subnet

```
                        Internet
                           │
                    Internet Gateway
                           │
              ┌────────────┴────────────┐
         Public Subnet              Public Subnet
         (10.0.1.0/24)             (10.0.2.0/24)
         Web Server / LB           NAT Gateway
              │                           │
              └────────┬──────────────────┘
                  Private Subnet      Private Subnet
                  (10.0.10.0/24)     (10.0.11.0/24)
                  App Server          RDS Database
```

---

## VPC Architecture (Production)

```
VPC: 10.0.0.0/16
│
├── Public Subnets (10.0.1.0/24, 10.0.2.0/24)
│   ├── Application Load Balancer
│   ├── NAT Gateway
│   └── Bastion Host
│
├── Private App Subnets (10.0.10.0/24, 10.0.11.0/24)
│   └── EC2 App Servers (Auto Scaling Group)
│
└── Private DB Subnets (10.0.20.0/24, 10.0.21.0/24)
    └── RDS Multi-AZ Database
```

---

## Key CLI Commands

```bash
# Create a VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region ap-south-1

# Create a subnet
aws ec2 create-subnet --vpc-id vpc-0abc123 --cidr-block 10.0.1.0/24 --availability-zone ap-south-1a

# Create an Internet Gateway
aws ec2 create-internet-gateway

# Attach IGW to VPC
aws ec2 attach-internet-gateway --internet-gateway-id igw-0abc123 --vpc-id vpc-0abc123

# Create a route table
aws ec2 create-route-table --vpc-id vpc-0abc123

# Add route to IGW
aws ec2 create-route --route-table-id rtb-0abc123 --destination-cidr-block 0.0.0.0/0 --gateway-id igw-0abc123

# Describe VPCs
aws ec2 describe-vpcs
```
