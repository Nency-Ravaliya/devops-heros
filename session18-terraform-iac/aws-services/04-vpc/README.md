# AWS VPC (Virtual Private Cloud) - Networking

## 1. What is VPC?
**Amazon Virtual Private Cloud (Amazon VPC)** enables you to provision a logically isolated section of the AWS Cloud where you can launch AWS resources in a virtual network that you define.

---

## 2. Core VPC Networking Components

* **CIDR (Classless Inter-Domain Routing):** The IP address range assigned to the VPC (e.g., `10.0.0.0/16` provides 65,536 private IP addresses).
* **Subnets:** Subsections of the VPC CIDR tied to a specific Availability Zone (e.g., `10.0.1.0/24`).
* **Public vs Private Subnet:**
  * **Public Subnet:** Associated with a Route Table pointing `0.0.0.0/0` to an **Internet Gateway (IGW)**. Instances can have public IPs.
  * **Private Subnet:** Does not have a direct route to the Internet Gateway. Outbound internet access requires a **NAT Gateway**.
* **Internet Gateway (IGW):** Horizontally scaled VPC component allowing bidirectional communication between VPC resources and the internet.
* **NAT Gateway:** Network Address Translation service located in a public subnet allowing private instances to initiate outbound connections (e.g. software patches) while blocking inbound connections.
* **Route Tables:** Set of rules (routes) that determine where network traffic from your subnet or gateway is directed.
* **Security Groups vs Network ACLs (NACLs):**
  * **Security Groups:** Stateful firewalls applied at the **instance/ENI level**. Return traffic is automatically allowed.
  * **Network ACLs:** Stateless firewalls applied at the **subnet boundary**. Explicit allow/deny rules required for both inbound and outbound.

---

## 3. Architecture Overview

```text
[ AWS VPC: 10.0.0.0/16 ]
       │
       ├─ [ Internet Gateway (IGW) ]
       │
       ├─ [ Public Subnet: 10.0.1.0/24 ]
       │        ├── Route Table: 0.0.0.0/0 -> IGW
       │        ├── Public EC2 Instance (Web Server)
       │        └── [ NAT Gateway ]
       │
       └─ [ Private Subnet: 10.0.2.0/24 ]
                ├── Route Table: 0.0.0.0/0 -> NAT Gateway
                └── Private EC2 Instance (Backend/Database)
```
