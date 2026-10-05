# EC2 - Compute

EC2 provides virtual machines called instances. An AMI supplies the starting operating system, and the instance type selects CPU, memory, and network capacity. A key pair can be used for SSH, although Session Manager avoids opening SSH to the internet.

Security Groups are stateful instance firewalls. EBS volumes provide persistent block storage. A public IP can be reached through an Internet Gateway when routing and firewall rules allow it; a private IP is used inside the VPC.

An instance normally moves through pending, running, stopping, stopped, shutting-down, and terminated states. Stopping preserves its EBS root volume, while termination normally removes the instance. Common uses include web servers, build agents, legacy applications, and workloads that need operating-system control.
