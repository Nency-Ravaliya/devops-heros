# Amazon DynamoDB and Amazon RDS

## Overview
Amazon DynamoDB is a managed NoSQL database, while Amazon RDS is a managed relational database service.

# 1. Amazon DynamoDB

DynamoDB is a managed NoSQL database designed for high-scale, low-latency applications.

## Tables
A DynamoDB table stores related items.

## Items
An item is a single record.

```json
{
  "UserId": "U101",
  "Name": "Example User",
  "City": "Bengaluru"
}
```

## Attributes
Attributes are individual fields within an item, such as `UserId`, `Name`, and `City`.

## Partition Key
The partition key determines how DynamoDB distributes data. It should provide good distribution of data and traffic.

## Sort Key
A sort key can be combined with a partition key to create a composite primary key.

Example:
```text
Partition Key: UserId
Sort Key: OrderDate
```

## DynamoDB Use Cases
- Serverless applications
- Gaming
- IoT
- Shopping carts
- Session management
- High-traffic APIs

# 2. Amazon RDS

Amazon Relational Database Service (RDS) is a managed service for relational databases.

## Supported Database Engines
- PostgreSQL
- MySQL
- MariaDB
- Oracle
- Microsoft SQL Server
- Amazon Aurora

## DB Instances
An RDS DB instance provides compute and storage for a relational database. Configuration includes engine, instance class, storage, networking, and security.

## Security
RDS can use:
- VPC networking
- Security Groups
- Encryption at rest
- Encryption in transit
- Database credentials
- IAM authentication where supported

Databases should generally be placed in private subnets unless public access is specifically required.

## Backups
RDS supports automated backups and manual snapshots for recovery from failures or accidental data changes.

## Multi-AZ
Multi-AZ deployments maintain a standby database in another Availability Zone for high availability and failover.

```text
Application
    |
RDS Primary
    |
Standby - Another AZ
```

## Read Replicas
Read replicas provide additional database instances for read traffic and can help scale read-heavy workloads.

```text
RDS Primary
 /       \\
Read     Read
Replica  Replica
```

# 3. DynamoDB vs RDS

| Feature | DynamoDB | RDS |
|---|---|---|
| Type | NoSQL | Relational |
| Data model | Key-value/document | Tables/relationships |
| Schema | Flexible | Structured |
| Query model | Key-based/document APIs | SQL |
| Scaling | Designed for high-scale workloads | Depends on engine/configuration |
| Best for | Low-latency, scalable NoSQL | Relational applications |

# 4. Architecture

```text
             Application
              /       \\
             v         v
        DynamoDB       RDS
         NoSQL       Relational
           |             |
         Items       Tables/Rows
```

# 5. When to Use DynamoDB
Choose DynamoDB when:
- Very low latency is required.
- The application uses key-value/document data.
- Large-scale traffic is expected.
- Serverless architecture is preferred.

# 6. When to Use RDS
Choose RDS when:
- SQL is required.
- Data has strong relationships.
- Complex joins are required.
- Traditional relational database capabilities are needed.

# 7. Common Use Cases
### DynamoDB
- Shopping carts
- Gaming
- IoT
- Serverless applications
- Session stores

### RDS
- E-commerce databases
- Enterprise applications
- Banking/transactional systems
- Content management systems

## Conclusion
DynamoDB is suitable for highly scalable NoSQL workloads, while RDS is appropriate for applications requiring relational database capabilities, SQL, relationships, and complex queries.
