# AWS VPC (Virtual Private Cloud) - Networking

Prepared by: Yash Gaikwad (Roll no. 24BCS10100)
Category: Networking

A VPC is my own logically isolated virtual network inside AWS. I choose the IP range, split it into subnets, decide which subnets can talk to the internet, and control traffic with security groups and network ACLs. Almost every resource I launch (EC2, RDS, EKS nodes, load balancers) lives inside a VPC, so this is the networking foundation for the Terraform work as well.

---

## What is VPC

- A VPC is **regional** and spans all Availability Zones in that region.
- Each account gets a **default VPC** in every region (CIDR `172.31.0.0/16`, one public subnet per AZ). For real projects I create a custom VPC.
- Core components: CIDR block, subnets, route tables, internet gateway, NAT gateway, security groups, network ACLs. Optional: VPC endpoints, peering, Transit Gateway, VPN / Direct Connect, flow logs.
- Traffic inside a VPC between subnets works out of the box through the implicit `local` route.

---

## CIDR

CIDR (Classless Inter-Domain Routing) writes a network as `address/prefix-length`. The prefix tells how many leading bits are the network part; the rest (32 - prefix) are host bits.

Number of addresses = 2^(32 - prefix).

**VPC example: `10.0.0.0/16`**
- Host bits = 32 - 16 = 16, so 2^16 = **65,536** addresses.
- Range: `10.0.0.0` to `10.0.255.255`.
- A VPC CIDR can be between **/16 (largest) and /28 (smallest)** and should come from the private ranges (RFC 1918): `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`. It must not overlap networks I want to peer with.

**Subnet example: `10.0.1.0/24` carved from that VPC**
- Host bits = 8, so 2^8 = **256** addresses in the block.
- AWS reserves **5 addresses in every subnet**, so usable = 256 - 5 = **251**.

| Address | Reserved for |
|---|---|
| `10.0.1.0` | network address |
| `10.0.1.1` | VPC router |
| `10.0.1.2` | Amazon DNS resolver (VPC base + 2) |
| `10.0.1.3` | reserved for future use |
| `10.0.1.255` | network broadcast (not supported in a VPC, but still reserved) |

Usable host addresses: `10.0.1.4` to `10.0.1.254`.

A /16 can be split into 2^(24-16) = 256 non-overlapping /24 subnets (`10.0.0.0/24`, `10.0.1.0/24`, ... `10.0.255.0/24`).

| Prefix | Total addresses | Usable in an AWS subnet |
|---|---|---|
| /16 | 65,536 | 65,531 |
| /20 | 4,096 | 4,091 |
| /24 | 256 | 251 |
| /26 | 64 | 59 |
| /28 | 16 | 11 (smallest allowed) |

---

## Subnets

- A subnet is a range of IPs from the VPC CIDR and lives in **exactly one AZ**. It cannot span AZs.
- Subnet CIDRs inside one VPC cannot overlap.
- What makes a subnet "public" or "private" is its **route table**, not its name.
- For high availability, create the same layout of subnets in at least two AZs.

---

## Route tables

- A route table is a list of rules (destination CIDR -> target) deciding where subnet traffic goes.
- Every VPC has a **main route table**; a subnet uses it unless explicitly associated with a custom one. Each subnet is associated with exactly one route table; one route table can serve many subnets.
- Every table has an automatic `local` route (VPC CIDR -> local) that cannot be removed.
- Most specific route wins (**longest prefix match**).

| Destination | Target | Meaning |
|---|---|---|
| `10.0.0.0/16` | local | traffic inside the VPC |
| `0.0.0.0/0` | `igw-xxxx` | everything else goes to the internet (public subnet) |
| `0.0.0.0/0` | `nat-xxxx` | everything else goes through NAT (private subnet) |

---

## Internet Gateway

- A horizontally scaled, highly available gateway attached to a VPC. It allows two-way traffic between the VPC and the internet and does one-to-one NAT for instances that have a public IPv4/Elastic IP.
- No bandwidth constraint and no hourly charge for the IGW itself.
- To make a subnet public I need all of: IGW attached, route `0.0.0.0/0 -> igw`, a public/Elastic IP on the instance, and security group / NACL rules that allow the traffic.

---

## NAT Gateway

- Lets instances in a **private subnet** start outbound connections (OS updates, pulling container images, calling external APIs) while blocking unsolicited inbound connections from the internet.
- A public NAT gateway sits in a **public subnet**, needs an **Elastic IP**, and private route tables point `0.0.0.0/0` at it.
- It is AZ-specific; for resilience deploy one per AZ and route each private subnet to the NAT in its own AZ.
- Billed per hour plus per GB processed, so it is one of the more expensive items in a small lab. Delete it after practising.
- A NAT *instance* is the old do-it-yourself alternative.

---

## Security Groups

- Instance/ENI-level firewall. **Stateful**, **allow rules only**, all rules evaluated together. Default: deny all inbound, allow all outbound.
- Can reference other security groups as sources (example: DB SG allows port 5432 only from the app SG).

---

## Network ACLs

- Subnet-level firewall. Each subnet has exactly one NACL; the **default NACL allows all** traffic, a custom one denies all until rules are added.
- **Stateless**: return traffic must be allowed explicitly in the other direction.
- Rules have **rule numbers** (1-32766), evaluated from lowest to highest; the first match wins and processing stops. The last rule `*` is an implicit deny that cannot be edited.
- Supports both **allow and deny**, so it can block a specific malicious IP, which a security group cannot do.
- **Ephemeral ports**: a client picks a random high port for the reply, so the outbound/inbound rule for return traffic must allow roughly **1024-65535** (Linux commonly uses 32768-60999, Windows 49152-65535). Forgetting this is the classic reason a NACL "breaks" an otherwise working app.

Example inbound/outbound rules for a public web subnet:

| Direction | Rule # | Protocol / port | Source / destination | Action |
|---|---|---|---|---|
| Inbound | 100 | TCP 443 | 0.0.0.0/0 | ALLOW |
| Inbound | 110 | TCP 1024-65535 | 0.0.0.0/0 | ALLOW (replies to outbound calls) |
| Inbound | * | all | 0.0.0.0/0 | DENY |
| Outbound | 100 | TCP 443 | 0.0.0.0/0 | ALLOW |
| Outbound | 110 | TCP 1024-65535 | 0.0.0.0/0 | ALLOW (replies to clients) |
| Outbound | * | all | 0.0.0.0/0 | DENY |

### Security Group vs NACL

| Feature | Security Group | Network ACL |
|---|---|---|
| Level | instance / network interface | subnet |
| State | **Stateful** | **Stateless** |
| Rule types | allow only | allow and deny |
| Rule evaluation | all rules evaluated | in number order, first match wins |
| Default | inbound denied, outbound allowed | default NACL allows all |
| Return traffic | automatic | must be allowed explicitly (ephemeral ports) |
| Applies to | only instances the SG is attached to | every instance in the subnet |
| Can reference other SGs | yes | no (CIDR only) |

---

## Public vs private subnet

| | Public subnet | Private subnet |
|---|---|---|
| Route to internet | `0.0.0.0/0 -> IGW` | no IGW route; optional `0.0.0.0/0 -> NAT` |
| Instances get public IP | usually yes | no |
| Reachable from internet | yes (if SG/NACL allow) | no |
| Typical resources | load balancers, bastion host, NAT gateway | app servers, databases, caches |

### Architecture diagram

```
                              Internet
                                 |
                       +---------+---------+
                       |  Internet Gateway |
                       +---------+---------+
                                 |
+--------------------------------+---------------------------------+
| VPC  10.0.0.0/16                                                 |
|                                                                  |
|  +------------------------------------------------------------+  |
|  | PUBLIC subnet 10.0.1.0/24 (AZ a)                           |  |
|  | Route table public-rt                                      |  |
|  |    10.0.0.0/16  -> local                                   |  |
|  |    0.0.0.0/0    -> igw-xxxx                                |  |
|  |                                                            |  |
|  |    [ Web / Bastion EC2 ]          [ NAT Gateway + EIP ]    |  |
|  +-----------------------------------------------+------------+  |
|                                                  ^               |
|              private egress: 0.0.0.0/0 -> NAT                    |
|                                                  |               |
|  +------------------------------------------------------------+  |
|  | PRIVATE subnet 10.0.2.0/24 (AZ a)                          |  |
|  | Route table private-rt                                     |  |
|  |    10.0.0.0/16  -> local                                   |  |
|  |    0.0.0.0/0    -> nat-xxxx                                |  |
|  |                                                            |  |
|  |    [ App EC2 ]                    [ RDS database ]         |  |
|  +------------------------------------------------------------+  |
|                                                                  |
|  NACL on each subnet (stateless)   SG on each instance (stateful)|
+------------------------------------------------------------------+
```

Flow: a private instance calls the internet -> private-rt sends it to the NAT gateway -> NAT gateway (in the public subnet, using its EIP) goes out through public-rt to the IGW. Internet users cannot start a connection to the private instance.

---

## Example: build a small VPC with the CLI

Ids are placeholders; I note each returned id and use it in the next command.

```bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=demo-vpc}]'

aws ec2 create-subnet --vpc-id vpc-0123456789abcdef0 --cidr-block 10.0.1.0/24 --availability-zone ap-south-1a
aws ec2 create-subnet --vpc-id vpc-0123456789abcdef0 --cidr-block 10.0.2.0/24 --availability-zone ap-south-1a

aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --vpc-id vpc-0123456789abcdef0 --internet-gateway-id igw-0123456789abcdef0

aws ec2 create-route-table --vpc-id vpc-0123456789abcdef0
aws ec2 create-route --route-table-id rtb-0123456789abcdef0 --destination-cidr-block 0.0.0.0/0 --gateway-id igw-0123456789abcdef0
aws ec2 associate-route-table --route-table-id rtb-0123456789abcdef0 --subnet-id subnet-0aaaaaaaaaaaaaaaa
aws ec2 modify-subnet-attribute --subnet-id subnet-0aaaaaaaaaaaaaaaa --map-public-ip-on-launch

aws ec2 allocate-address --domain vpc
aws ec2 create-nat-gateway --subnet-id subnet-0aaaaaaaaaaaaaaaa --allocation-id eipalloc-0123456789abcdef0
# then: create a second route table for the private subnet with 0.0.0.0/0 -> nat-xxxx
```

---

## Interview quick points

- VPC is a regional, isolated virtual network; subnets are AZ-scoped.
- VPC CIDR size ranges from /16 to /28; /16 gives 65,536 addresses; each subnet loses 5 addresses (network, router, DNS, future, broadcast), so a /24 has 251 usable.
- A subnet is public only because its route table has a route to an Internet Gateway.
- IGW = two-way internet access; NAT gateway = outbound-only for private subnets, lives in a public subnet and needs an EIP.
- Route tables use longest prefix match; the `local` route is always present.
- Security groups: stateful, allow-only, instance level. NACLs: stateless, allow and deny, numbered rules, subnet level, need ephemeral ports for return traffic.
- Block a single bad IP -> use a NACL deny rule (SGs cannot deny).
- Make NAT highly available with one NAT gateway per AZ.
- Other connectivity options: VPC peering (non-transitive), Transit Gateway, VPN, Direct Connect, and VPC endpoints (gateway endpoints for S3/DynamoDB, interface endpoints for PrivateLink).
- VPC Flow Logs capture accepted/rejected traffic metadata for troubleshooting.
- Overlapping CIDRs cannot be peered, so plan address space up front.
