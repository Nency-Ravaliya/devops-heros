# 04 — VPC (Virtual Private Cloud): Networking

**Submitted by:** Piyush Bansal

## What is VPC?

A VPC is **your own logically isolated private network inside an AWS region**. You
choose its IP range, split it into subnets across Availability Zones, and control
routing and firewalls. EC2, RDS, EKS nodes, Lambda-in-VPC and load balancers all live in
a VPC. Every region has a **default VPC** (`172.31.0.0/16`) with public subnets, handy
for testing but not what you use in production.

A VPC spans all AZs of one region; a subnet lives in exactly one AZ.

## CIDR

CIDR (Classless Inter-Domain Routing) notation describes an IP range as
`base-address/prefix-length`. The prefix is how many leading bits are fixed; the rest
are host addresses.

| CIDR | Addresses | Typical use |
|---|---|---|
| `10.0.0.0/16` | 65,536 | Whole VPC (AWS allows /16 to /28) |
| `10.0.1.0/24` | 256 (251 usable in AWS) | One subnet |
| `10.0.1.0/28` | 16 (11 usable) | Smallest subnet allowed |

- Use private RFC 1918 ranges: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.
- AWS reserves **5 addresses** per subnet: network address, `.1` VPC router, `.2` DNS,
  `.3` future use, and the broadcast address.
- Plan ranges so VPCs you might **peer** or connect over VPN/Transit Gateway don't overlap.

## Subnets

- A subnet is a slice of the VPC CIDR **in one AZ**, e.g. `10.0.1.0/24` in `ap-south-1a`.
- Whether it is "public" or "private" is decided only by its **route table** (see below).
- Best practice: at least one public and one private subnet in each of 2–3 AZs for high
  availability.
- `map_public_ip_on_launch = true` makes instances in that subnet get a public IP automatically.

## Route tables

- A set of rules: **destination CIDR → target**. The most specific match wins.
- Every route table has the implicit `local` route (VPC CIDR → local) so all subnets in
  the VPC can talk to each other.
- Each subnet is associated with exactly one route table (the **main** route table if
  you don't associate one explicitly).

```text
Public route table               Private route table
10.0.0.0/16  -> local            10.0.0.0/16  -> local
0.0.0.0/0    -> igw-xxxx         0.0.0.0/0    -> nat-xxxx
```

## Internet Gateway (IGW)

- A horizontally scaled, highly available VPC component that connects the VPC to the
  internet. One IGW per VPC, no bandwidth limit, no extra charge.
- It allows **both** inbound and outbound traffic for resources that have a public IP,
  and does the 1:1 NAT between public and private IP.
- Needs: IGW attached to VPC + route `0.0.0.0/0 → igw` + public IP on the instance +
  SG/NACL allowing the traffic.

## NAT Gateway

- Lets instances in **private subnets** reach the internet (OS updates, calling APIs)
  **without** being reachable from the internet. Outbound-only.
- Lives in a **public subnet**, has an Elastic IP, and the private route table sends
  `0.0.0.0/0 → nat-gw`.
- Managed by AWS, zonal: for HA put one NAT Gateway per AZ.
- Costs money per hour plus per GB processed, often a surprise on the bill. Alternatives:
  VPC endpoints for S3/DynamoDB (free gateway endpoints), or a NAT instance for labs.

## Security Groups

- **Stateful**, attached to an ENI (instance level), **allow rules only**.
- All rules are evaluated together (no order).
- Can reference other security groups as source.
- First line of defence for a specific resource.

## Network ACLs

- **Stateless** firewall at the **subnet** level.
- Has both **allow and deny** rules, evaluated **in order by rule number**, first match wins.
- Because it is stateless you must allow return traffic explicitly, usually the
  **ephemeral ports 1024–65535**.
- Default NACL allows everything; a custom NACL denies everything until you add rules.
- Good for blocking a specific bad IP range for a whole subnet.

| | Security Group | Network ACL |
|---|---|---|
| Level | Instance / ENI | Subnet |
| State | Stateful | Stateless |
| Rules | Allow only | Allow and Deny |
| Evaluation | All rules | In number order, first match |
| Default | Deny in, allow out | Default NACL allows all |

## Public vs private subnet

| | Public subnet | Private subnet |
|---|---|---|
| Route `0.0.0.0/0` | → Internet Gateway | → NAT Gateway (or none) |
| Instances get public IP | Usually yes | No |
| Reachable from internet | Yes (if SG allows) | No |
| Typical resources | Load balancers, NAT Gateway, bastion | App servers, databases, EKS nodes |

Typical 3-tier design: ALB in public subnets → app servers in private subnets →
RDS in private (isolated) subnets with no internet route at all.

```text
                    Internet
                       |
                 [Internet Gateway]
                       |
  +---------------- VPC 10.0.0.0/16 ----------------+
  |  Public subnet 10.0.1.0/24 (AZ a)               |
  |     ALB, NAT Gateway                            |
  |            |                                    |
  |  Private subnet 10.0.11.0/24 (AZ a)             |
  |     App EC2 (outbound via NAT only)             |
  |            |                                    |
  |  DB subnet 10.0.21.0/24 (AZ a)                  |
  |     RDS (no internet route)                     |
  +-------------------------------------------------+
```

## Quick check on LocalStack

Created a VPC, a public subnet, an IGW and a route on **LocalStack** (a local AWS
emulator, not a real AWS account). The API objects are created, but there is no real
network behind them. Session 19's homework builds the same thing with Terraform.

```text
$ VPC_ID=$(aws --endpoint-url=http://localhost:4566 ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text); echo $VPC_ID
vpc-3814b73f
$ SUBNET_ID=$(aws --endpoint-url=http://localhost:4566 ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone ap-south-1a --query Subnet.SubnetId --output text); echo $SUBNET_ID
subnet-a50ce5f2
$ IGW_ID=$(aws --endpoint-url=http://localhost:4566 ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text); echo $IGW_ID
igw-e578d34a
$ aws --endpoint-url=http://localhost:4566 ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
$ RT_ID=$(aws --endpoint-url=http://localhost:4566 ec2 create-route-table --vpc-id $VPC_ID --query RouteTable.RouteTableId --output text); echo $RT_ID
rtb-4136633d
$ aws --endpoint-url=http://localhost:4566 ec2 create-route --route-table-id $RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
{
    "Return": true
}
$ aws --endpoint-url=http://localhost:4566 ec2 associate-route-table --route-table-id $RT_ID --subnet-id $SUBNET_ID --query AssociationState.State --output text
None
$ aws --endpoint-url=http://localhost:4566 ec2 describe-route-tables --route-table-ids $RT_ID --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId]" --output table
---------------------------------
|      DescribeRouteTables      |
+--------------+----------------+
|  10.0.0.0/16 |  local         |
|  0.0.0.0/0   |  igw-e578d34a  |
+--------------+----------------+
```

The route table shows exactly the two routes that make a subnet public: the implicit
`local` route for the VPC CIDR and `0.0.0.0/0 → igw`. (`None` for the association state
is a LocalStack quirk; real AWS returns `associated`.) I deleted everything afterwards.

## What I learned

- "Public subnet" is not a setting, it's just a subnet whose route table points
  `0.0.0.0/0` at an Internet Gateway.
- NAT Gateway = outbound only for private subnets, and it isn't free.
- Security groups are stateful at the instance; NACLs are stateless at the subnet.
