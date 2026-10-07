# DynamoDB & RDS — AWS Databases

## DynamoDB (NoSQL)
**What:** Fully managed, serverless **key-value / document** database with single-digit-millisecond latency at any scale. No servers, no schema except the key.

| Concept | Description |
|---|---|
| **Table** | Collection of items (no fixed columns). |
| **Item** | One record (like a row), max 400 KB. |
| **Attribute** | Field of an item (String, Number, Boolean, List, Map…); items can have different attributes. |
| **Partition key** | Required; hashed to choose the storage partition. Must be unique if it's the only key. Pick high-cardinality values (`user_id`). |
| **Sort key** | Optional; with the partition key forms a **composite primary key**; enables range queries (`order_date BETWEEN …`). |
| **Indexes** | GSI (different partition/sort key) and LSI (same partition key, different sort key) for other access patterns. |

- Capacity: **On-Demand** (pay per request) or **Provisioned** (RCU/WCU + auto scaling).
- Features: Streams (change events → Lambda), TTL, point-in-time recovery, Global Tables (multi-region), encryption at rest by default.
- `Query` uses keys (fast); `Scan` reads the whole table (slow, expensive).

**Use cases:** session stores, shopping carts, gaming leaderboards, IoT data, serverless APIs, Terraform state locking table.

## RDS (Relational)
**What:** Managed **relational SQL** database. AWS handles provisioning, patching, backups and failover; you manage schema and queries.

| Topic | Details |
|---|---|
| **Engines** | MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, IBM Db2, **Aurora** (AWS-built, MySQL/PostgreSQL-compatible, up to 5× faster). |
| **Instances** | DB instance classes like `db.t4g.micro`, `db.r7g.large`; storage on EBS (`gp3`, `io2`), auto-scaling storage. |
| **Security** | Run in **private subnets** (DB subnet group); Security Group allows port 3306/5432 only from the app SG; encryption at rest (KMS) and in transit (SSL); IAM DB auth; password in Secrets Manager. |
| **Backups** | Automated daily snapshots + transaction logs (retention 1–35 days) → **point-in-time restore**; manual snapshots kept until deleted. |
| **Multi-AZ** | Synchronous standby in another AZ; **automatic failover** (~60–120 s) for **high availability**. Standby does not serve reads. |
| **Read replicas** | **Asynchronous** copies (same or cross-region) for **read scaling**; can be promoted to standalone. |

**Use cases:** web/e-commerce backends, ERP/CRM, financial transactions, any app needing joins, ACID transactions and a fixed schema.

## DynamoDB vs RDS
| | DynamoDB | RDS |
|---|---|---|
| Model | NoSQL key-value/document | Relational tables (SQL) |
| Schema | Flexible | Fixed |
| Scaling | Horizontal, automatic | Vertical + read replicas |
| Queries | By key / index only | Rich SQL, joins |
| Management | Serverless | Instance-based (managed) |
| Best for | Massive scale, known access patterns | Complex queries, relationships |
