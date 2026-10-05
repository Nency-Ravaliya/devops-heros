# DynamoDB and RDS

## DynamoDB

DynamoDB is a managed NoSQL database. Tables contain items made from attributes. Every item has a partition key, and a table can also use a sort key to group and order related items. It suits key-value access, high-scale serverless applications, sessions, carts, and event metadata when access patterns are known in advance.

## RDS

RDS manages relational engines such as PostgreSQL, MySQL, MariaDB, Oracle, and SQL Server. A DB instance has compute and storage settings and runs inside a VPC. Security Groups control network access. Automated backups support point-in-time recovery, Multi-AZ improves availability, and read replicas can serve read-heavy workloads.

I would choose DynamoDB for predictable key-based access and horizontal scale. I would choose RDS when I need SQL, joins, transactions, and a relational schema.
