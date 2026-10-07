# 02. EC2 Compute

## What is EC2?

****EC2 = Elastic Compute Cloud****

Amazon EC2 provides virtual servers in the AWS cloud.

With EC2 you can:
- Run aaplications
- Host websites
- Run APIs
- Process workloads
- Choose CPU, memory and storage based on requirements

Example:

AWS -> EC2 Instance -> Application

---

## AMI

****AMI = Amazon Machine Image****

An AMI is a template used to create an EC2 instance

It contains:
- Operating System
- Software
- Configuration
- Required files

Example:

Ubuntu AMI -> EC2 Instance -> Ubuntu Server

AWS provides AMIs such as:
- Amazon Linux
- Ubuntu
- Windows Server

You can also create your own custom AMI.

---

## Instance type

****Instance type determines the hardware resources available to an EC2 instance****

Main resources:
- CPU
- Memory
- Network performance
- Storage performance

Example:

t3.micro -> Small workloads
t3.medium -> More CPU/RAM
c7g -> Compute optimized
r7g -> Memory optimized

Common Categories:
- General Purpose
- Compute Optimized
- Memory Optimized
- Storage Optimized
- Accelerated Computing

Choose the instance type based on the workload.

---

## Key Pairs

****A Key Pair is used to securely connect to an EC2 instance****

It contains:

Public Key -> Stored by AWS
Private Key -> Kept by owner

For Linux instances, the private key is commanly used with SSH.

Example:
ssh -i my-key.pen ec2-user@PUBLIC-IP

---

## Security Groups

****A security Group acts as a virtual firewall for an EC2 instance****

It controls:
- Inbound traffic
- Outbound traffic

Example:

Internet -> Security Group -> EC2

Example inbound rules:

SSH -> 22
HTTP -> 80
HTTPS -> 443

Security Groups are stateful

If inbound traffic is allowed, the response traffic is automatically allowed.

---

## EBS

****EBS = Elastic Block Store****

EBS provides persistent block storage for EC2 instance

Example:

EC2 -> EBS Volume -> Application Data

Common uses:

- OS disk
- Application files
- Database storage
- Persistent data

EBS volums persist independently from the lifecycle of an EC2 instance in many cases

---

## Public vs Private IP

### Public IP

****A public IP allows communication with the internet****

Example:

Internet -> Public IP -> EC2

Used for:
- Public websites
- Public APIs
- SSH access

### Private IP

****A private IP is used for communication inside a VPC****

Example:

EC2 -> Private IP -> Other AWS Resources

Private IPs are commonly used for internal communication

---

## Instance Lifecycle

****An EC2 instance can have different states:****

Pending -> Running -> Stopping -> Stopped -> Terminated

**Running: Instance is active and processing workloads**
**Stooped: Instance is powered off bu can usually be started again**
**Terminated: Instance is permanently deleted**

---

## Common Use Cases

### Web Server

Internet -> Security Group -> EC2 -> Web Server

### Backend API

Client -> EC2-> Spring Boot / Node.js / Python API

### Database Server

EC2 can also run database software, although managed services such as RDS are usually preferred when applicable.

EC2 -> Database

### Development Environment

Developer -> EC2 -> Development Tools.