# 02 – EC2 (Elastic Compute Cloud) – Compute

**Name:** Kushal Talati · **Enrollment No:** 24BCS10123

EC2 is a virtual machine rented by the second. I pick an image, a size, a network location and a firewall, and AWS gives me a Linux/Windows box with a root disk that I can SSH into. Everything else in this session (VPC, security groups, EBS, key pairs, IAM roles) exists to make that VM reachable, persistent and safe.

Hands-on output below is from LocalStack (`aws --endpoint-url=http://localhost:4566 ec2 ...`); raw log in [`../../logs/02-aws-services-hands-on.txt`](../../logs/02-aws-services-hands-on.txt) under `02 EC2`. The full VPC + EC2 build with Terraform is in [session 19](../../../../session19-cloud-terraform/kushal-24bcs10123).

## The pieces of one instance

```text
          ┌─────────────────────────────── VPC / subnet ───────────────────────────────┐
          │   Security Group (stateful firewall around the ENI)                        │
          │   ┌────────────────────────────────────────────────────────────────────┐   │
          │   │  EC2 instance  (instance type = vCPU + RAM + network)              │   │
          │   │   • AMI  → what is on the root disk at first boot                 │   │
          │   │   • key pair → public half injected into ~/.ssh/authorized_keys   │   │
          │   │   • IAM role → temporary AWS credentials via metadata service      │   │
          │   │   • user data → script that runs once at first boot               │   │
          │   │   • ENI: private IP (always), public IP / Elastic IP (optional)   │   │
          │   └──────┬─────────────────────────────────────────┬───────────────────┘   │
          │          │ root EBS volume                         │ extra EBS volume      │
          │          ▼                                         ▼                       │
          │     /dev/xvda  (gp3 8 GiB)                    /dev/sdf  (gp3 8 GiB)        │
          └────────────────────────────────────────────────────────────────────────────┘
```

### AMI – Amazon Machine Image
A template of the root volume: OS + preinstalled software + launch permissions. Amazon Linux 2023, Ubuntu 24.04, Windows Server, Marketplace images, or my own ("golden image") created from a configured instance. AMI ids are **per region** (`ami-0abc...` in ap-south-1 is a different id in us-east-1), which is why Terraform code uses a `data "aws_ami"` lookup by name instead of hard-coding.

```text
$ awsl ec2 describe-images --owners amazon --query 'Images[0:3].{ImageId:ImageId,Name:Name,Arch:Architecture}' --output table
-------------------------------------------------------------------------
|                             DescribeImages                            |
+--------+----------------+--------------------------------------------+
|  Arch  |    ImageId     |                    Name                    |
+--------+----------------+--------------------------------------------+
|  x86_64|  ami-03cf127a |  Windows_Server-2016-English-Nano-Base-2017.10.13                    |
|  x86_64|  ami-12c6146b |  Windows_Server-2008-R2_SP1-English-64Bit-Base-2017.10.13            |
...   (LocalStack ships a fixed catalogue of old Amazon AMIs; on AWS I would filter by name, e.g. al2023-ami-*-arm64)
```

### Instance types
A name like `t3.micro` = family `t` (burstable general purpose), generation `3`, size `micro`. Families: **t/m** general, **c** compute, **r/x** memory, **i/d** storage, **g/p** GPU, and the `g` suffix (`t4g`, `m7g`) means Graviton/ARM, which is cheaper. The free tier is `t2.micro`/`t3.micro` (1 vCPU, 1 GiB).

```text
$ awsl ec2 describe-instance-types --instance-types t2.micro t3.micro m5.large ...
|  MemMiB |  Type     |  vCPU  |
|  1024   |  t2.micro |  1     |
|  1024   |  t3.micro |  2     |
|  8192   |  m5.large |  2     |
```

### Key pairs
An SSH key pair. AWS keeps the **public** key and drops it into the instance at first boot; I keep the `.pem` private key and it can never be downloaded again. Lose it and the fix is a new AMI/instance, not a password reset. Modern alternative: **SSM Session Manager** (no port 22, no key, IAM-controlled shell).

```text
$ awsl ec2 create-key-pair --key-name s18-key --query 'KeyName'
"s18-key"
```

### Security Groups
A **stateful** virtual firewall attached to the instance's network interface. Rules are *allow only* (no deny), inbound and outbound are separate, and "stateful" means the reply to an allowed inbound request is automatically allowed out. Rules can reference other security groups (`allow 5432 from sg-of-the-app-tier`), which is how tiers talk without hard-coding IPs.

```text
$ awsl ec2 create-security-group --group-name s18-web-sg --description 'web sg'
$ awsl ec2 authorize-security-group-ingress --group-name s18-web-sg --protocol tcp --port 22 --cidr 10.0.0.0/8
$ awsl ec2 authorize-security-group-ingress --group-name s18-web-sg --protocol tcp --port 80 --cidr 0.0.0.0/0
|  Cidr        |  Port  |
|  10.0.0.0/8  |  22    |      <- SSH only from inside the private network
|  0.0.0.0/0   |  80    |      <- HTTP from anywhere
```

### EBS – Elastic Block Store
Network-attached block storage that is the instance's disks. Lives in one AZ, survives a stop/start and (unless `DeleteOnTermination`) survives termination; snapshots go to S3 and are the backup/clone mechanism. Types: **gp3** (default SSD, 3000 IOPS baseline), **io2** (provisioned IOPS for databases), **st1/sc1** (cheap HDD for logs/cold data). Instance-store volumes are the opposite: physically on the host, fast, lost on stop.

```text
$ awsl ec2 create-volume --size 8 --volume-type gp3 --availability-zone ap-south-1a
{ "VolumeId": "vol-f3122976", "Size": 8, "Type": "gp3", "State": "creating" }
$ awsl ec2 attach-volume --volume-id vol-f3122976 --instance-id i-e6f3f17a525e385ce --device /dev/sdf
{ "Device": "/dev/sdf", "State": "attaching" }
$ awsl ec2 detach-volume --volume-id vol-f3122976 --instance-id i-e6f3f17a525e385ce --device /dev/sdf
{ "Device": "/dev/sdf", "State": "detaching" }
```

### Public vs private IP
Every instance gets a **private IP** from its subnet CIDR; it is stable for the life of the instance and is what other instances in the VPC use. A **public IP** is only assigned if the subnet (or launch) says so, is *not* stable (changes on stop/start), and is really a NAT mapping on the Internet Gateway – the OS never sees it. For a stable public address you allocate an **Elastic IP**.

```text
$ awsl ec2 run-instances --image-id ami-... --instance-type t3.micro --key-name s18-key --security-groups s18-web-sg ...
{ "InstanceId": "i-e6f3f17a525e385ce", "State": "pending", "Type": "t3.micro", "PrivateIp": "10.36.104.169", "PublicIp": "54.214.57.67" }
$ awsl ec2 describe-instances --instance-ids i-e6f3f17a525e385ce ...
{ "State": "running", "Private": "10.145.138.101", "Public": null, "RootDevice": "/dev/sda1" }
  (LocalStack's EC2 is a mock: it hands out random private/public IPs and even changed them between calls;
   on AWS the private IP comes from the subnet CIDR and stays fixed for the instance's life)
```

### Instance lifecycle

```text
pending ──▶ running ──▶ stopping ──▶ stopped ──▶ (start) ──▶ pending ──▶ running
                 │                        │
                 │                        └──▶ terminated  (EBS root deleted unless DeleteOnTermination=false)
                 └──▶ shutting-down ──▶ terminated
                 └──▶ rebooting (same host, same IPs)
```

* **stop**: no compute charge, EBS still billed, public IP released, private IP kept, may move to another host on start.
* **hibernate**: RAM written to EBS, resumes where it was.
* **terminate**: gone; `DisableApiTermination` protects against doing it by accident.

```text
$ awsl ec2 stop-instances  --instance-ids i-...   → { "Prev": "running", "Now": "stopping" }
$ awsl ec2 start-instances --instance-ids i-...   → { "Prev": "stopped", "Now": "pending" }
$ awsl ec2 terminate-instances --instance-ids i-...
An error occurred (InvalidVolume.NotFound) ... The volume 'vol-e3c18d97' does not exist.
  (a LocalStack mock bug after detach-volume; on AWS this returns { "Prev": "running", "Now": "shutting-down" }
   and the first run of this script, before I added the detach step, did return exactly that)
```

### Pricing models (worth knowing even though this was emulated)
On-Demand (pay per second), **Reserved / Savings Plans** (1–3 year commitment, up to ~70 % off), **Spot** (spare capacity, up to 90 % off, can be reclaimed with 2 min notice – perfect for CI runners and batch), **Dedicated Hosts** (licensing). The capstone's EKS worker nodes would be Spot in a real budget.

## Common use cases

| Use case | Typical setup |
|---|---|
| Web/app server | t3/m7g in a public subnet behind an ALB, SG allows 80/443 from the ALB only, Auto Scaling Group |
| Database or stateful service you manage yourself | r-family in a private subnet, io2 volumes, snapshots nightly |
| CI/CD runners (GitHub Actions self-hosted) | Spot instances launched by an ASG, IAM role instead of keys |
| Batch / ML training | c/g/p instances, Spot, data staged on S3 |
| Bastion / jump host | Tiny instance, SG allows 22 from office IP only – or replace with SSM Session Manager |
| Kubernetes worker nodes | EKS managed node group = an ASG of EC2 instances with the node IAM role |

## What I understood

* An EC2 instance is **ephemeral compute + persistent EBS**; design so the instance can die (data on EBS/S3/RDS, config via user data or an AMI, IAM role for credentials).
* The **security group is the real perimeter** for an instance, and referencing other SGs instead of IPs is what keeps multi-tier setups maintainable.
* Public IPs are a NAT trick at the IGW; the instance itself only ever has a private IP, which is why `ip addr` inside an EC2 never shows the public address.
