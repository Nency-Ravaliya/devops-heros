# Amazon EC2

## Overview
Amazon Elastic Compute Cloud (EC2) provides resizable virtual servers in AWS.

## 1. What is EC2?
EC2 instances are virtual machines that can run applications, web servers, APIs, and other workloads.

## 2. AMI
An Amazon Machine Image (AMI) is a template used to launch an EC2 instance. It can contain an operating system, software, and configuration.

Examples include Amazon Linux, Ubuntu, and Windows Server.

## 3. Instance Types
| Category | Purpose |
|---|---|
| T | Burstable general purpose |
| M | General purpose |
| C | Compute optimized |
| R | Memory optimized |

## 4. Key Pairs
Key pairs are used to securely authenticate to EC2 instances. Linux instances commonly use SSH private keys.

```bash
ssh -i my-key.pem ec2-user@PUBLIC_IP
```

Never commit private keys to Git.

## 5. Security Groups
Security Groups act as stateful virtual firewalls for EC2 instances. They control inbound and outbound traffic.

Example rules:
```text
SSH   TCP 22   Trusted IP
HTTP  TCP 80   0.0.0.0/0
HTTPS TCP 443  0.0.0.0/0
```

## 6. EBS
Elastic Block Store (EBS) provides persistent block storage for EC2 instances, including operating system disks and application data.

## 7. Public and Private IPs
EC2 instances can use private IPs for VPC communication and public IPs for Internet communication. Elastic IPs provide persistent public IPv4 addresses.

## 8. Instance Lifecycle
```text
Pending -> Running -> Stopped
                    -> Terminated
```

## 9. Common Use Cases
- Web servers
- Backend APIs
- Application servers
- Development environments
- Batch processing
- CI/CD runners

## 10. Architecture
```text
VPC
 |
Public Subnet
 |
EC2 ---- Security Group
 |
EBS
```

## Summary
| Component | Purpose |
|---|---|
| EC2 | Virtual compute |
| AMI | Instance template |
| Instance Type | CPU/memory configuration |
| Key Pair | Authentication |
| Security Group | Firewall |
| EBS | Persistent storage |

## Conclusion
EC2 provides flexible cloud compute infrastructure with configurable compute, storage, networking, and security.
