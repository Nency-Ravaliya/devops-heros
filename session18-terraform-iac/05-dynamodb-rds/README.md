# Amazon DynamoDB and Amazon RDS

## DynamoDB

### What is DynamoDB?
Amazon DynamoDB is a fully managed NoSQL database service designed for fast and predictable performance.

### Tables
A DynamoDB table stores items and does not require a fixed relational schema.

### Items
Items are individual records stored in a DynamoDB table.

### Attributes
Attributes are data elements within an item.

### Partition Key
The partition key uniquely identifies an item when used as the table's primary key and determines how data is distributed.

### Sort Key
A sort key can be combined with a partition key to create a composite primary key and organize related items.

## RDS

### What is RDS?
Amazon Relational Database Service (RDS) is a managed service for running relational databases in AWS.

### Database Engines
RDS supports database engines such as Amazon Aurora, PostgreSQL, MySQL, MariaDB, Oracle, and SQL Server.

### DB Instances
A DB instance provides the compute and memory resources required to run a relational database.

### Security
RDS security can be controlled using VPC networking, security groups, IAM, encryption, and database authentication.

### Backups
RDS supports automated backups and database snapshots to help recover data.

### Multi-AZ
Multi-AZ deployments provide high availability by maintaining a standby database instance in another Availability Zone.

### Read Replicas
Read replicas provide additional read capacity by replicating data from a source database.

### Common Uses
DynamoDB is commonly used for high-scale applications requiring low-latency NoSQL access. RDS is commonly used for applications that require relational databases and SQL.
