# 05. DynamoDB & RDS Database Services

---

# DynamoDB

## What is DynamoDB?

****DynammoDB is a fully managed NoSQL database service provided by AWS****

It is:
- Serverless
- Highly scalable
- Low Latency
- Fully managed by AWS

Unlike relational databases, DynamoDB does not use tables with fixed rows and columns in the traditional SQL way.

---

## Tables

****A DynamoDB Table stores data****

Example:

Users Table -> Items

Example:

```
Users 
├── User 1 
├── User 2 
└── User 3
```

---

## Items

****An Item is a single record in a DynamoDB table****

Example:

{
  "userId":"101",
  "name": "Abhijit",
  "email": "abhijit.24bcs10175@sst.scaler.com"
}

An item is similar to a row in relational database

---

## Attributes

****Attributes are the individual data fields inside an item****

Example:

userId
name
email

Unlike traditional relational databases, different items can have different attributes

---

## Partition Key

****A Partition Key uniquely identifies where an item is stored****

Example:

userId = 101

DynameDB uses the partition key to distribute data across partitions

A good partition key should distribute requests evenly

---

## Sort Key

****A Sort Key allows multiple items with the same partition key to be stored and organized****

A Sort Key is optional

Example:

```
UserID OrderID 
101     001 
101     002 
101     003
```

Here:

Partition Key = UserID
Sort Key - OrderID

Together they form a composite primary key

---

## Common Use Cases

DynamoDB is commonly used for:
- High-scale applications
- User sessions
- Shopping carts
- Gaming applications
- IoT applications
- Real-Time applications

Basic flow:

```
  Application 
      ↓ 
  DynamoDB 
      ↓ 
    Items
```

---

# RDS

## What is RDS?

****RDS = Relational Database Service****

Amazon RDS is a managed service for running relational database in AWS

RDS handles many administrative tasks such as:
- Database setup
- Backups
- Patching
- Maintenance

---

## Relational Database

****A relational database stores data in tables with rows and columns****

Examples:

```
Users
------------------- 
id | name | email
1 | John | ... 
2 | Alex | ...
```

Relational databases use SQL and support relationships between tables

---

## Supported Engines

Amazon RDS supports database engines such as:
- Amazon Aurora
- PostgreSQL
- MySQL
- MariaDB
- Oracle
- SQL Server

Choose the engine based on application requirements

---

## DB Instances

****A DB Instance is the compute environment used to run an RDS database****

It determines resources such as:

- CPU
- Memory
- Network performance
- Storage

Example:

```
  Application 
      ↓ 
  RDS DB Instance 
      ↓ 
  PostgreSQL
```

---

## Security

RDS security can be controlled using:
- VPC
- Security Groups
- IAM
- Encryption
- Database authentication

A common setup is to place RDS inside a private subnet

Application -> Private RDS

The database should generally not be directly accessible from the public internet

---

## Backups

****RDS provides automated backups and supports manual snapshots****

Backups can be used to:
- Recover from failuers
- Restore databases
- Recover deleted or corrupted data

Example:

```
      RDS 
       ↓ 
  Automated Backup 
       ↓ 
    Restore
```

---

## Multi-AZ

****Multi-AZ provides high availability by maintaining a standby database in another Availability Zone****

Example:

```
Availability Zone A 
      ↓ 
  Primary RDS 
      ↓ 
Availability Zone B 
      ↓ 
  Standby RDS
```

If the primary database fails, RDA can fail over to the standby.

Multi-AZ is mainly for high availability, not for scaling read traffic.

---

## Read Replicas

****A Read Replica is a copy of a database used mainly for read operations****

Example:

```
Application 
    ↓ 
Primary RDS 
    ↓ 
Read Replica 
    ↓ 
Read Traffic
```

Read replicas can help scale applications with heavy read workloads.

---
## Common RDS Use Cases

- Web applications
- Backend APIs
- E-commerce applications
- Busimess applications
- Applications requiring SQL and relationships

Example:

```
Application 
    ↓ 
RDS PostgreSQL 
    ↓ 
Users / Orders / Products
```

---
# DynamoDB vs RDS

| DynamoDB              | RDS                                             |
|-----------------------|-------------------------------------------------|
| NoSQL                 | Relational                                      |
| Key-value/document    | Tables and relationships                        |
| Serverless            | Managed DB instances                            |
| No SQL required       | Uses SQL                                        |
| Highly scalable       | Scales based on instance/storage configuration  |
| Low-latency workloads | Traditional relational workloads                |

---
