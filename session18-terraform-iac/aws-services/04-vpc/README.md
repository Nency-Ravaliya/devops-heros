# VPC - Networking

A VPC is an isolated AWS network defined by a CIDR range. Subnets divide that range, usually across Availability Zones. Route tables decide where traffic goes. A subnet with a route to an Internet Gateway can be public; a private subnet normally reaches the internet through a NAT Gateway without accepting unsolicited inbound connections.

Security Groups are stateful and attach to resources. Network ACLs are stateless subnet-level rules. I would place load balancers in public subnets and application or database workloads in private subnets, then allow only the required paths between their security groups.

The Session 19 project turns these pieces into Terraform resources.
