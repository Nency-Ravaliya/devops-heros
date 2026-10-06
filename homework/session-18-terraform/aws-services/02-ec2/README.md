# EC2

EC2 is the AWS virtual machine service. You rent compute by the second and attach storage and network rules yourself.

## Pieces

- An **AMI** is the disk image: operating system plus anything baked in. Amazon Linux 2023 is the AMI the Session 19 project looks up.
- An **instance type** is the size. `t3.micro` is a small burstable general-purpose type used in the lab.
- A **key pair** is the SSH public key AWS puts on the instance. The private key stays with you. The Session 19 lab boots from user data and does not require a key pair to create the instance.
- A **security group** is a stateful virtual firewall on the instance. The lab allows TCP 80 in and all egress out.
- **EBS** is the network disk. The root volume is usually `gp3`. It lives in one availability zone with the instance.
- A **public IP** is reachable from the internet if a route and security group allow it. A **private IP** is the address inside the VPC. Instances should use private IPs for east-west traffic.
- **Lifecycle:** pending, running, stopping, stopped, shutting-down, terminated. Stop keeps the EBS volume. Terminate deletes the instance. A stop/start can change the public IP unless you attached an Elastic IP.

## Use cases

Web servers, CI runners, bastion hosts, and anything that needs a full OS. Prefer managed services when you do not need the OS.
