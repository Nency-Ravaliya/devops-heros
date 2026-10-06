# VPC

A VPC is your private network inside one AWS region.

## Pieces

- **CIDR** is the address range, for example `10.40.0.0/16` in the Session 19 project.
- **Subnets** are slices of that range in one availability zone. `10.40.1.0/24` is public A and `10.40.2.0/24` is public B.
- A **route table** decides the next hop. The public table sends `0.0.0.0/0` to the internet gateway.
- An **internet gateway** is the horizontally scaled door to the public internet. A subnet is public when its route table points default traffic at an IGW and instances get public IPs.
- A **NAT gateway** lets private subnets open outbound connections without accepting inbound ones. The lab uses public subnets only, so it does not create a NAT gateway.
- A **security group** is stateful and attached to an ENI. A **network ACL** is stateless and attached to a subnet. Prefer security groups.
- A **public subnet** has a route to an IGW. A **private subnet** does not. Workloads that should not be reachable from the internet go in private subnets and use NAT for updates.

The Session 19 Terraform file builds this layout and places one EC2 instance in the first public subnet.
