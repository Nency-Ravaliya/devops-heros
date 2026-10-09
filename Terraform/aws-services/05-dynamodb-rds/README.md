# 05. DynamoDB & RDS – Database Services

| | **DynamoDB** | **RDS** |
|---|---|---|
| Model | NoSQL key-value / document | Relational (SQL) |
| Management | Serverless, no instances | Managed DB **instances** you size |
| Scaling | Automatic, virtually unlimited | Vertical (bigger instance) + read replicas |
| Schema | Schemaless (only the key is defined) | Fixed tables, columns, foreign keys |
| Queries | By key, with indexes; no joins | Full SQL: joins, aggregations, transactions |
| Latency | Single-digit ms at any scale | Depends on instance and query |

---

# DynamoDB

## NoSQL
DynamoDB is a fully managed, serverless **NoSQL** database. It doesn't use tables of fixed columns joined together. Each item is a flexible set of attributes accessed by its **key**. Data is spread across partitions automatically, which gives consistent millisecond performance from a few requests to millions per second. You design the table around your **access patterns** (often a single table for a whole app), not around normalization.

## Tables
- A collection of items, with no fixed schema apart from the **primary key**.
- **Capacity modes:** *On-demand* (pay per request, no planning) or *Provisioned* (set RCU/WCU, optionally with auto scaling; cheaper for steady load).
- **Table classes:** Standard and Standard-IA (cheaper storage for rarely-read tables).

## Items
- One "row", up to **400 KB**. Each item can have different attributes.
```json
{ "UserId": "u#1001", "OrderDate": "2026-10-07", "Total": 499, "Status": "SHIPPED", "Items": ["book", "pen"] }
```

## Attributes
- Name/value pairs. Types: scalar (`S` string, `N` number, `B` binary, `BOOL`, `NULL`), document (`M` map, `L` list), and sets (`SS`, `NS`, `BS`).
- **TTL attribute:** an epoch timestamp after which DynamoDB deletes the item for free (sessions, temporary data).

## Partition key
- **Required**, part of the primary key. DynamoDB hashes it to decide **which partition** stores the item.
- Choose a **high-cardinality** key (`UserId`, `OrderId`) so traffic spreads evenly and avoids "hot partitions".
- Simple primary key = partition key only: `GetItem(UserId="u#1001")`.

## Sort key
- **Optional** second part of a *composite* primary key. Items with the same partition key are stored together, **ordered by the sort key**.
- Enables range queries: `Query(UserId="u#1001" AND OrderDate BETWEEN "2026-01-01" AND "2026-12-31")`, `begins_with`.
- **Secondary indexes** for other access patterns: **GSI** (different partition and sort key, can be added any time) and **LSI** (same partition key, different sort key, only at table creation).

Other features: **DynamoDB Streams** (change data capture → Lambda), **Global Tables** (multi-region active-active), PITR backups (35 days), **DAX** (in-memory cache, microseconds), transactions, and encryption at rest by default.

## Use cases
- User profiles, sessions and shopping carts in web/mobile apps
- Gaming leaderboards and player state; IoT telemetry at massive scale
- Serverless backends (API Gateway + Lambda + DynamoDB)
- **Terraform state locking** (the classic `dynamodb_table` lock for the S3 backend; newer Terraform versions can use S3-native locking instead)
- Event-driven architectures using Streams

---

# RDS (Relational Database Service)

## Relational database
RDS runs and manages relational databases for you. AWS handles provisioning, OS and DB patching, backups, monitoring and failover. You still choose the instance size, and you own the schema, queries and tuning. Data lives in **tables with rows and columns**, related through keys and queried with **SQL**, with full **ACID** transactions.

## Supported engines
- **Amazon Aurora** (MySQL- and PostgreSQL-compatible): AWS's cloud-native engine with storage replicated 6 ways across 3 AZs, up to 15 low-lag replicas, and Aurora Serverless v2
- **PostgreSQL**
- **MySQL**
- **MariaDB**
- **Oracle** (license included or BYOL)
- **Microsoft SQL Server**
- **IBM Db2**

## DB instances
- The compute part: an instance class like `db.t4g.micro` (burstable, free-tier eligible), `db.m7g.large` (general), or `db.r7g.xlarge` (memory-optimized).
- **Storage:** gp3 or io2 EBS, with optional **storage autoscaling**.
- Lives in a **DB subnet group** (private subnets in at least 2 AZs). You connect through an **endpoint** DNS name, never an IP.
- Configured with **parameter groups** (engine settings) and **option groups**.

## Security
- Put it in **private subnets** with `publicly_accessible = false`, and allow its **security group** only from the app's SG on the DB port (5432/3306).
- **Encryption at rest** with KMS (must be chosen at creation; it covers snapshots and replicas). **TLS in transit** (`rds.force_ssl`).
- Credentials in **AWS Secrets Manager** with automatic rotation (`manage_master_user_password`), or **IAM database authentication** (short-lived tokens).
- Audit with CloudTrail (API calls), engine audit logs, and Database Activity Streams.

## Backups
- **Automated backups:** daily snapshot + transaction logs, retained 1–35 days, which enables **point-in-time restore** to any second in that window (the restore creates a new instance).
- **Manual snapshots:** kept until you delete them, and can be copied cross-region or shared cross-account.
- AWS Backup gives centralized policies across services.

## Multi-AZ
- **High availability, not scaling.** RDS keeps a **synchronous standby** in another AZ. On failure (or patching), the DNS endpoint fails over automatically in about 60–120 s, with no data loss.
- The standby **can't serve reads** (classic Multi-AZ instance). A *Multi-AZ DB cluster* (2 readable standbys) or Aurora gives readable replicas plus faster failover.

## Read replicas
- **Asynchronous** copies for **scaling reads** (reports, analytics, read-heavy APIs). Up to 15 per source, can be in another region (also useful for DR), and each has its own endpoint.
- Can be **promoted** to a standalone primary. Replication lag means reads may be slightly stale.

| | Multi-AZ | Read replica |
|---|---|---|
| Purpose | Availability / failover | Read scaling (+ DR) |
| Replication | Synchronous | Asynchronous |
| Serves traffic? | No (standby) | Yes (reads) |
| Failover | Automatic | Manual promotion |

## Use cases
- Transactional apps (e-commerce orders, banking, ERP/CRM) that need joins, constraints and ACID
- Backends for WordPress, Django, Rails and Spring apps
- Reporting on read replicas
- Lift-and-shift of existing MySQL/PostgreSQL/Oracle/SQL Server databases without managing servers

**Choosing:** relational data, complex queries and transactions → **RDS/Aurora**. Known key-based access at huge scale, serverless, single-digit ms → **DynamoDB**.
