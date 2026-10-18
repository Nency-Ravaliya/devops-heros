# VPC

A VPC is a regional virtual network with a CIDR range. Each subnet is in
one Availability Zone. Route tables choose next hops. A public subnet has an
Internet Gateway route; instances also need public addresses and allowed traffic.
A private subnet has no direct Internet Gateway route. A NAT Gateway allows
outbound IPv4 access without unsolicited inbound access, with additional cost.
Security Groups are stateful resource rules; Network ACLs are stateless subnet
rules and must permit return traffic too. Separate public web and private
database tiers with narrow permissions.

Reference: https://docs.aws.amazon.com/
