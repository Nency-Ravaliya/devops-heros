# AWS Virtual Private Cloud (VPC) - Networking

**Name:** Smit Rupani  
**Enrollment:** 24bcs10256  

---

## 1. What is a VPC?
A Virtual Private Cloud (VPC) lets you provision a logically isolated section of the AWS cloud where you can launch AWS resources in a virtual network that you define.

## 2. Core Components
- **CIDR Block:** Classless Inter-Domain Routing IP address range for your VPC (e.g. `10.0.0.0/16` = 65,536 IPs).
- **Subnets:** Subsections of the VPC CIDR tied to specific Availability Zones:
  - *Public Subnet:* Route table routes `0.0.0.0/0` traffic to an Internet Gateway (IGW). Instances can have public IPs.
  - *Private Subnet:* Isolated from direct internet access. Outbound internet is routed through a NAT Gateway in a public subnet.
- **Internet Gateway (IGW):** Horizontally scaled, redundant VPC component that enables communication between VPC resources and the public internet.
- **NAT Gateway:** Enables instances in a private subnet to connect to the internet (for OS updates/packages) while preventing external connections initiated from the internet.
- **Security Groups vs Network ACLs:**
  - *Security Group:* Stateful, instance-level firewall. Evaluates allow rules only.
  - *Network ACL (NACL):* Stateless, subnet-level firewall. Supports explicit allow and deny rules.
