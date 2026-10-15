# AWS EC2 - Elastic Compute Cloud

## 1. What is EC2?
Amazon Elastic Compute Cloud (Amazon EC2) provides scalable computing capacity in the AWS Cloud.

## 2. Core Concepts
- **AMI (Amazon Machine Image)**: Pre-configured template providing OS, application server, and applications.
- **Instance Types**: Varying combinations of CPU, memory, storage, and networking capacity (e.g., t3.micro, c5.large).
- **Key Pairs**: Secure public/private SSH keys used to authenticate into instances.
- **Security Groups**: Virtual firewalls controlling inbound and outbound traffic.
- **EBS (Elastic Block Store)**: Persistent block storage volumes attached to EC2 instances.
- **Public vs Private IP**: Public IPs are reachable from the internet; private IPs operate within the VPC.

## 3. Instance Lifecycle
`Pending` ➔ `Running` ➔ `Stopping` ➔ `Stopped` ➔ `Terminated`
