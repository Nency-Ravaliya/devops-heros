# AWS VPC - Virtual Private Cloud

## 1. What is VPC?
Amazon Virtual Private Cloud (Amazon VPC) lets you provision a logically isolated section of the AWS Cloud where you can launch AWS resources in a virtual network.

## 2. Core Components
- **CIDR (Classless Inter-Domain Routing)**: IP address range allocation (e.g., `10.0.0.0/16`).
- **Subnets**: Subdivisions of a VPC IP address range (Public vs Private subnets).
- **Route Tables**: Rules determining network traffic direction.
- **Internet Gateway (IGW)**: Allows communication between resources in public subnets and the internet.
- **NAT Gateway**: Enables instances in private subnets to connect to the internet while preventing external connections.
- **Security Groups**: Stateful firewall at the EC2 instance level.
- **Network ACLs (NACLs)**: Stateless firewall at the subnet level.
