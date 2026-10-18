# AWS EC2 (Elastic Compute Cloud) - Compute

Prepared by: Yash Gaikwad (Roll no. 24BCS10100)
Category: Compute

EC2 gives resizable virtual servers in the cloud. Instead of buying hardware, I pick an operating system image, a CPU/RAM size, storage and networking, and AWS boots a virtual machine in a few minutes. It is the building block that most other IaaS ideas (and many Terraform exercises) start with.

---

## What is EC2

- Infrastructure-as-a-Service: virtual machines called **instances**, running on AWS-managed hosts (Nitro-based hypervisor for current generations).
- Instances live inside a **VPC subnet**, which belongs to one **Availability Zone**.
- I get full control of the OS (root / Administrator access), choose what to install, and pay for what I use.
- Pricing / purchase options:
  - **On-Demand** (per-second billing, 60-second minimum for Linux)
  - **Savings Plans / Reserved** (commitment for lower price)
  - **Spot** (spare capacity, can be interrupted)
  - **Dedicated Hosts / Instances** (physical isolation, licence needs)

---

## AMI (Amazon Machine Image)

- A template used to launch an instance: it contains the root volume snapshot (OS + software), launch permissions and a block device mapping.
- Sources: AWS-provided (Amazon Linux, Ubuntu, Windows), AWS Marketplace, community AMIs, or my own custom AMIs created from a running instance.
- An AMI is **regional**. To use it in another region it must be copied.
- Custom AMIs are useful for "golden images" that already have the agents/app baked in, which makes Auto Scaling launches faster.
- AMI IDs look like `ami-0123456789abcdef0` and are different in every region. SSM public parameters can be used to look up the latest Amazon Linux AMI.

```bash
aws ec2 create-image --instance-id i-0123456789abcdef0 --name "web-golden-v1" --no-reboot
aws ec2 copy-image --source-image-id ami-0123456789abcdef0 --source-region us-east-1 --region ap-south-1 --name "web-golden-v1"
```

---

## Instance types

An instance type decides vCPU, memory, network and storage options.

Naming example: **`t3.micro`**

| Part | Meaning |
|---|---|
| `t` | instance family (burstable general purpose) |
| `3` | generation (higher is newer) |
| `micro` | size (`nano`, `micro`, `small`, `medium`, `large`, `xlarge`, `2xlarge` ...) |

Optional letters after the generation describe extras, for example `a` = AMD, `g` = AWS Graviton (ARM), `i` = Intel, `d` = local NVMe disks, `n` = enhanced networking (`m6g`, `c7gn`, `r6id`).

| Family | Optimised for | Typical use |
|---|---|---|
| T (t3, t4g) | Burstable CPU credits | dev/test, small web apps |
| M (m5, m6i, m7g) | Balanced general purpose | app servers, small DBs |
| C (c5, c6i, c7g) | Compute optimised | batch jobs, web tier, encoding |
| R (r5, r6i) / X | Memory optimised | in-memory caches, large DBs, analytics |
| I / D | Storage optimised | NoSQL, data warehousing, high IOPS |
| G / P | Accelerated (GPU) | ML training, graphics |
| Inf / Trn | AWS ML chips | inference / training |

A burstable `t` instance earns CPU credits while idle and spends them under load; once credits run out CPU is throttled (or billed extra in "unlimited" mode). Free-tier eligibility of a size depends on the account and region, so I should check the billing page before launching.

---

## Key pairs

- A key pair is an asymmetric key (RSA or ED25519). AWS stores the **public key** and injects it into the instance; I keep the **private key** (`.pem`).
- The private key can be downloaded **only once** at creation. If it is lost, I cannot recover it (I would have to attach the volume to another instance or use Session Manager).
- Linux: SSH with the private key. Windows: the key is used to decrypt the Administrator password (RSA only).
- Keep permissions strict or SSH will refuse the key.

```bash
aws ec2 create-key-pair --key-name my-keypair --key-type ed25519 \
  --query 'KeyMaterial' --output text > my-keypair.pem
chmod 400 my-keypair.pem
ssh -i my-keypair.pem ec2-user@<PUBLIC_IP>     # ubuntu@<ip> for Ubuntu AMIs
```

Alternatives to opening port 22: **EC2 Instance Connect** and **SSM Session Manager** (no inbound ports, access logged through IAM/CloudTrail).

---

## Security Groups (stateful)

- A virtual firewall attached to the instance's network interface (ENI).
- **Stateful**: if an inbound request is allowed, the response traffic is automatically allowed regardless of outbound rules (and vice versa).
- Only **allow** rules exist. Anything not allowed is denied.
- Default for a new SG: no inbound rules, all outbound allowed.
- Source/destination can be a CIDR or **another security group** (nice for "only the app tier can reach the DB").
- Rule changes take effect immediately, and one instance can have several SGs.

```bash
aws ec2 create-security-group --group-name web-sg --description "web tier" --vpc-id vpc-0123456789abcdef0
aws ec2 authorize-security-group-ingress --group-id sg-0123456789abcdef0 --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id sg-0123456789abcdef0 --protocol tcp --port 22 --cidr <MY_IP>/32
```

---

## EBS (Elastic Block Store)

- Network-attached block storage for EC2. It lives in **one AZ** and can only be attached to instances in that AZ (multi-attach is a special case for io1/io2).
- Persists independently of the instance lifecycle (depending on the `DeleteOnTermination` flag).

| Volume type | Medium | Notes |
|---|---|---|
| **gp3** | SSD | default choice; 3,000 IOPS and 125 MiB/s baseline, IOPS/throughput can be raised independently of size |
| gp2 | SSD | older; IOPS tied to size |
| **io2** (io1) | SSD | provisioned IOPS for latency-sensitive databases; highest durability among SSDs |
| st1 | HDD | throughput optimised, big sequential workloads |
| sc1 | HDD | cold, cheapest; st1/sc1 cannot be boot volumes |

**Snapshots**
- Point-in-time backups stored in S3 (managed by AWS, not visible in my buckets).
- **Incremental**: only blocks changed since the previous snapshot are stored.
- Can be copied across regions, shared, and used to create new volumes (or AMIs). Data Lifecycle Manager can automate them.

**Root vs data volume**
- **Root volume** holds the OS and boots the instance. `DeleteOnTermination` is **true** by default, so the volume vanishes with the instance.
- **Data volume** is an extra volume (for example `/dev/sdf`). `DeleteOnTermination` is **false** by default, so it survives termination.
- **Instance store** is different: physically attached, very fast, but the data is lost when the instance stops or terminates.

```bash
aws ec2 create-volume --availability-zone ap-south-1a --size 50 --volume-type gp3 --encrypted
aws ec2 attach-volume --volume-id vol-0123456789abcdef0 --instance-id i-0123456789abcdef0 --device /dev/sdf
aws ec2 create-snapshot --volume-id vol-0123456789abcdef0 --description "before upgrade"
```

---

## Public vs private IP (and Elastic IP)

| | Private IPv4 | Public IPv4 | Elastic IP |
|---|---|---|---|
| Reachable from | inside the VPC / connected networks | the internet | the internet |
| Assigned | always, from subnet CIDR | auto-assigned if subnet enables it | allocated to my account manually |
| After stop/start | **stays the same** | **changes** (released on stop) | **stays the same** |
| Cost | free | charged per hour (all public IPv4 since Feb 2024) | charged per hour |

- An Elastic IP is a static public IPv4 address that I can remap to another instance quickly during failover.
- An Elastic IP that is **not attached** to anything still costs money, so release it when finished.
- Better than a public IP per server: put servers in private subnets behind a load balancer, and use a NAT gateway for outbound access.

```bash
aws ec2 allocate-address --domain vpc
aws ec2 associate-address --instance-id i-0123456789abcdef0 --allocation-id eipalloc-0123456789abcdef0
aws ec2 release-address --allocation-id eipalloc-0123456789abcdef0
```

---

## Instance lifecycle

```
launch --> pending --> running --> stopping --> stopped --start--> pending
                          |                         |
                          |                         +--terminate--> shutting-down --> terminated
                          |
                          +--terminate--> shutting-down --> terminated
                          |
                          +--hibernate--> stopping --> stopped (RAM saved to root EBS)
```

| State | What it means | Instance usage billed? |
|---|---|---|
| pending | being provisioned on a host | No |
| running | ready to use | **Yes** |
| stopping | shutting down before stop | No (if heading to stop) |
| stopping (hibernate) | saving RAM contents to root EBS | **Yes** while preparing to hibernate |
| stopped | powered off, EBS volumes kept | No instance charge, but **EBS storage and Elastic IPs still billed** |
| shutting-down | being terminated | No |
| terminated | gone permanently | No (volumes with DeleteOnTermination=false remain and are billed) |

Other points:
- **Reboot** keeps the instance on the same host, same IPs, and does not change the state to stopped.
- **Hibernate** saves RAM to the (encrypted) root EBS volume so the instance resumes with processes intact. It must be enabled at launch and has RAM size and AMI limits.
- **Termination protection** (`DisableApiTermination`) stops accidental terminates.

```bash
aws ec2 stop-instances      --instance-ids i-0123456789abcdef0
aws ec2 start-instances     --instance-ids i-0123456789abcdef0
aws ec2 stop-instances      --instance-ids i-0123456789abcdef0 --hibernate
aws ec2 terminate-instances --instance-ids i-0123456789abcdef0
```

---

## Example: launch an instance with the CLI

All ids below are placeholders; replace them with ids from my own account and region.

```bash
aws ec2 run-instances \
  --image-id ami-0123456789abcdef0 \
  --instance-type t3.micro \
  --key-name my-keypair \
  --security-group-ids sg-0123456789abcdef0 \
  --subnet-id subnet-0123456789abcdef0 \
  --iam-instance-profile Name=ec2-reports-reader \
  --metadata-options "HttpTokens=required,HttpEndpoint=enabled" \
  --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=20,VolumeType=gp3,DeleteOnTermination=true}' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=devops-demo}]' \
  --count 1

# find it again
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=devops-demo" \
  --query "Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]" \
  --output table
```

Notes: the root device name depends on the AMI (`/dev/xvda` for Amazon Linux, `/dev/sda1` for Ubuntu). `HttpTokens=required` enforces IMDSv2, which is safer against SSRF-style credential theft.

A user-data script can bootstrap software at first boot (it runs once as root by default):

```bash
#!/bin/bash
dnf install -y nginx
systemctl enable --now nginx
```

---

## Common use cases

- Hosting web and application servers behind a load balancer and Auto Scaling group.
- Running self-managed databases or caches when a managed service does not fit.
- Build agents / CI runners (for example self-hosted GitHub Actions runners).
- Batch processing and data crunching, often on cheap Spot capacity.
- Bastion or jump hosts, VPN endpoints, and lab/dev environments.
- GPU instances for ML training and rendering.
- Worker nodes for Kubernetes (EKS managed node groups are EC2 instances).

---

## Interview quick points

- Instance = virtual server; AMI = template; EBS = persistent disk; Security Group = stateful firewall; Key pair = SSH credentials.
- Naming: `t3.micro` = family `t`, generation 3, size micro. T family is burstable; M balanced; C compute; R memory.
- Security groups are **stateful**, allow-only, attached to ENIs. NACLs are stateless and sit on subnets.
- Private IP survives stop/start; the auto-assigned public IP does not; an Elastic IP does.
- A stopped instance is not billed for compute but its EBS volumes and Elastic IPs are.
- Root volume is deleted on termination by default; additional data volumes are not.
- EBS is AZ-scoped; copy a snapshot to move data to another AZ or region.
- gp3 is the usual default; io2 for high, consistent IOPS; HDD (st1/sc1) cannot be a boot volume.
- Instance store data is lost on stop/terminate; EBS data is not.
- Prefer IAM roles (instance profile) over putting access keys on an instance; enforce IMDSv2.
- Use Session Manager or EC2 Instance Connect to avoid exposing SSH publicly.
- Hibernate stores RAM on an encrypted root volume; billing is for the EBS storage while hibernated.
