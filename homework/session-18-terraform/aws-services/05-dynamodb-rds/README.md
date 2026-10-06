# DynamoDB and RDS

## DynamoDB

DynamoDB is a managed NoSQL key-value and document database.

- Data lives in **tables**.
- A row is an **item**.
- Columns are **attributes**. Not every item needs the same attributes.
- The **partition key** decides which partition stores the item. It must be present on every item.
- A **sort key** is optional. Together with the partition key it is the primary key, and it lets you query a range inside one partition.
- Use it for high-scale lookups by key, session stores, and event data. It is a poor fit when you need arbitrary joins.

## RDS

RDS is managed relational databases. Engines include PostgreSQL, MySQL, MariaDB, Oracle, and SQL Server. Aurora is the AWS-compatible engine in the same family.

- A **DB instance** is the server. You pick a class, storage, and engine version.
- **Security** is a VPC subnet group plus security groups. Do not expose the database port to `0.0.0.0/0`.
- **Backups** are automated snapshots plus a retention window. Point-in-time restore uses those logs.
- **Multi-AZ** keeps a standby in another availability zone and fails over the DNS name.
- **Read replicas** are extra copies for read traffic. They are not a substitute for Multi-AZ failover.

The Session 21 TaskBoard app uses PostgreSQL. Locally that is the Compose service. On AWS the same schema can run on RDS while the app runs on EKS.
