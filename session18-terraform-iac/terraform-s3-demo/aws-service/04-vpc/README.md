# 04. VPC Networking

## What is VPC?

***A VPC is a logically isolated network inside AWS where you can launch and control AWS resources.****

A VPC controls:
- IP addresses
- Subnets
- Routing
- Internet access
- Network security

Basic flow:

VPC -> Subnets -> AWS Resources

---

## CIDR

****CIDR defines the IP address range of a VPC or subnet****

Example:

10.0.0.0/16

This gives the VPC a range of private IP addresses

Example:

VPC: 10.0.0.0/16

Subnet 1: 10.0.1.0/24
Subnet 2: 10.0.2.0/24

The subnet CIDR must be within VPC CIDR

---

## Subnets

****A Subnet is a smaller network inside a VPC****

Subnets are associated with an Availability Zone.

Example:

```
VPC
├── Public Subnet
│     └── EC2
│
└── Private Subnet
      └── Database
```
Subnets are mainly divided into:
- Public Subnet
- Private Subnet

---

## Route Tables

****A route Table controls where network traffic goes****

Example:

Private Subnet -> Route Table -> NAT Gateway -> Internet

Example route:

0.0.0.0/0 -> Internet Gateway

This means traffic to destinations outside the VPC is sent to the Internet Gateway

---

## Internet Gateway

****An Internet Gateway (IGW) allows resources in a VPC to communicate with the internet****

Basic Flow:

EC2 -> Route Table -> Internet Gateway -> Internet

A public subnet normally has a route to an Internet Gateway

---

## NAT Gateway

****NAT = Network Address Translation****

***A NAT Gateway allows resources in a private subnet to access the internet without allowing the internet to directly initiate connections to them***

Example:

Private EC2 -> NAT Gateway -> Internet

Common Use:

Private EC2 -> Download updates/packages -> Internet

The private instance does not need a public IP.

---

## Security Groups

****A Security Group acts as a virtual firewall for AWS resources such as EC2****

It controls:
- Inbound traffic
- Outbound traffic

Example:

Internet -> Security Group -> EC2

Security Groups are stateful

They allow traffic based on rules such as:

SSH -> 22
HTTP -> 80
HTTPS -> 443

---

## Network ACLs

****NACL = Network Access Control Links****

***A NACL controls traffic at the subnet level***

It supports:
- Allow rules
- Deny rules

NACLs are stateless, so inbound and outbound traffic must be configured separately.

Basic difference:

Security Group -> Instance level
NACL -> Subnet level

---

## Public vs Private Subnet

### Public Subnet

****A subnet is considered public when its route table has a route to an Internet Gateway****

Example:

Internet -> Internet Gateway -> Public Subnet -> EC2

Usually used for:

- Web servers
- Load Balancers
- Bastion hosts

### Private Subnet

****A private subnet does not have a direct route to an Internet Gateway****

Usually used for:

- Databases
- Backed services
- Internal applications

---

## Common Architecture

A common AWS architecture looks like:

                 Internet
                    ↓
            Internet Gateway
                    ↓
             Public Subnet
                    ↓
               Load Balancer
                    ↓
             Private Subnet
                    ↓
              Application
                    ↓
             Private Subnet
                    ↓
                Database

This keeps databases and internal services away from direct internet access