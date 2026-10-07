# Amazon VPC

## Overview
Amazon Virtual Private Cloud (VPC) provides an isolated virtual network in AWS with control over IP addressing, subnets, routing, and network security.

## 1. What is a VPC?
A VPC is a virtual network containing CIDR ranges, subnets, route tables, gateways, and security controls.

## 2. CIDR
CIDR defines the IP range of a VPC or subnet.

Example:
```text
VPC: 10.0.0.0/16
Public Subnet: 10.0.1.0/24
Private Subnet: 10.0.2.0/24
```

## 3. Subnets
Subnets divide a VPC into smaller networks and are associated with Availability Zones.

## 4. Route Tables
Route tables determine where traffic is sent.

```text
Destination   Target
10.0.0.0/16   local
0.0.0.0/0     Internet Gateway
```

## 5. Internet Gateway
An Internet Gateway connects a VPC to the Internet. A public subnet normally has a route to an Internet Gateway.

## 6. NAT Gateway
A NAT Gateway allows resources in private subnets to make outbound Internet connections without allowing unsolicited inbound Internet connections.

## 7. Security Groups
Security Groups are stateful virtual firewalls attached to resources such as EC2 instances.

## 8. Network ACLs
Network Access Control Lists operate at subnet level and are stateless rule-based network controls.

## 9. Public vs Private Subnet
| Feature | Public | Private |
|---|---|---|
| Route to IGW | Yes | Usually no direct route |
| Direct Internet access | Possible | No direct access |
| Typical resources | Load balancer/web server | Database/internal services |
| NAT for outbound access | No | Often yes |

## 10. Architecture
```text
VPC 10.0.0.0/16
 |
 +-- Public Subnet 10.0.1.0/24
 |      |
 |     EC2
 |      |
 |   Internet Gateway
 |
 +-- Private Subnet 10.0.2.0/24
        |
       EC2/DB
        |
    NAT Gateway
```

## 11. Main Components
| Component | Purpose |
|---|---|
| VPC | Isolated network |
| CIDR | IP range |
| Subnet | Network division |
| Route Table | Traffic routing |
| Internet Gateway | Internet connectivity |
| NAT Gateway | Private outbound access |
| Security Group | Stateful firewall |
| NACL | Stateless subnet firewall |

## 12. Common Use Cases
- Web applications
- Public/private application tiers
- Database isolation
- Secure cloud networking
- Hybrid networking

## Conclusion
VPC provides the networking foundation for AWS workloads. Correct subnetting, routing, and security controls are essential for secure cloud architectures.
