# Amazon VPC

## What is VPC?
Amazon Virtual Private Cloud (VPC) provides a logically isolated network in AWS where resources can be launched.

## CIDR
CIDR notation defines the IP address range of a VPC or subnet, such as 10.0.0.0/16.

## Public Subnet
A public subnet has a route to an Internet Gateway and can contain resources that need internet connectivity.

## Private Subnet
A private subnet does not have a direct route to an Internet Gateway and is commonly used for internal resources.

## Internet Gateway
An Internet Gateway allows resources in a VPC to communicate with the internet when appropriate routing and public addressing are configured.

## NAT Gateway
A NAT Gateway allows resources in private subnets to make outbound internet connections without allowing direct inbound internet connections.

## Route Tables
Route tables contain rules that determine where network traffic is directed.

## Security Groups
Security groups act as stateful virtual firewalls for resources such as EC2 instances.

## Network ACLs
Network Access Control Lists (NACLs) control traffic at the subnet level and are stateless.

