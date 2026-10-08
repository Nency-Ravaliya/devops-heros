# 05. DynamoDB & RDS: Database Services

AWS offers **purpose-built databases**. The two most common are **DynamoDB** (NoSQL key-value/document) and **RDS** (managed relational SQL).

---

## Amazon DynamoDB

### NoSQL

DynamoDB is a **fully managed, serverless NoSQL** key-value and document database:
- No servers, versions or patches to manage; it scales automatically to millions of requests per second.
- **Single-digit millisecond** latency at any scale.
- **Schemaless:** only the primary key is defined up front; every item can have different attributes.
- Data is replicated across **3 AZs** automatically.
- There are no joins, and queries are designed around **access patterns**: you model data for the queries you'll run (often "single-table design").

### Tables

A **table** is a collection of items, for example `Orders`. Settings:
- **Capacity mode:** **On-demand** (pay per request, no planning) or **Provisioned** (set RCU/WCU, optionally with auto scaling, cheaper for steady load).
- **Table class:** Standard or Standard-IA (cheaper storage for rarely read data).
- Encryption at rest (always on; AWS-owned, AWS-managed or customer KMS key).
- **Point-in-time recovery (PITR)** for restoring to any second in the last 35 days, plus on-demand backups.
- **TTL:** automatically delete items after a timestamp attribute (sessions, temporary data).
- **Streams:** an ordered change log of item changes, used to trigger Lambda.
- **Global tables:** multi-region, multi-active replication.

### Items

An **item** is one record, like a row. Maximum size **400 KB**. Example from an `Orders` table:

```json
{
  "customer_id": "C#1001",
  "order_date":  "2026-10-07T10:15:00Z",
  "order_id":    "O#88231",
  "status":      "SHIPPED",
  "total":       1499.00,
  "items":       [{ "sku": "BOOK-42", "qty": 1 }]
}
```

### Attributes

An **attribute** is a named value in an item (`status`, `total`…). Types: scalar (String, Number, Binary, Boolean, Null), document (List, Map), and set (String Set, Number Set, Binary Set). Nested attributes are allowed up to 32 levels.

### Partition key

The **partition key** (hash key) is required. DynamoDB hashes its value to decide which **physical partition** stores the item.
- **Simple primary key** = partition key only; it must be unique per item (e.g. `user_id`).
- Choose a **high-cardinality**, evenly accessed key so traffic spreads across partitions. Avoid "hot keys" such as `status = "ACTIVE"`.
- `GetItem` by partition key is the fastest, cheapest read.

### Sort key

The optional **sort key** (range key) forms a **composite primary key** with the partition key:
- Items with the same partition key are stored together, **sorted** by the sort key.
- The partition + sort combination must be unique.
- Enables range `Query`: `customer_id = "C#1001" AND order_date BETWEEN "2026-10-01" AND "2026-10-31"`, `begins_with(sk, "ORDER#")`, newest first, and so on.

### Indexes and operations

- **GSI (Global Secondary Index):** a different partition/sort key, to query by another attribute (e.g. `status`). Can be added at any time.
- **LSI (Local Secondary Index):** same partition key, different sort key; must be defined at table creation.
- Operations: `PutItem`, `GetItem`, `UpdateItem` (with conditional writes), `DeleteItem`, **`Query`** (efficient, by key), **`Scan`** (reads the whole table; avoid in hot paths), `BatchGet/BatchWrite`, `TransactWriteItems` (ACID across items).
- Reads are eventually consistent by default; strongly consistent reads are optional. **DAX** adds an in-memory cache with microsecond reads.

### Use cases

Shopping carts, user sessions and profiles, gaming leaderboards, IoT and time-series events, serverless backends (API Gateway + Lambda + DynamoDB), metadata stores, idempotency keys, and **Terraform state locking** (the classic `terraform_locks` table with `LockID` as partition key).

---

## Amazon RDS (Relational Database Service)

### Relational database

RDS runs **managed relational (SQL) databases**: tables with a fixed schema, rows and columns, primary/foreign keys, **joins**, **ACID transactions** and SQL. AWS handles provisioning, OS and engine patching, backups, failover and monitoring. You still own the schema, queries, indexes and tuning.

### Supported engines

- **Amazon Aurora** (MySQL- and PostgreSQL-compatible; AWS's cloud-native engine with shared distributed storage, up to 15 low-latency read replicas, and **Aurora Serverless v2** autoscaling)
- **PostgreSQL**
- **MySQL**
- **MariaDB**
- **Oracle** (license included or bring your own licence)
- **Microsoft SQL Server**
- **IBM Db2**

### DB instances

A **DB instance** is the isolated database environment:
- **Instance class:** e.g. `db.t4g.micro` (burstable, free-tier eligible), `db.m7g.large` (general), `db.r7g.xlarge` (memory optimised).
- **Storage:** gp3 / io2 EBS-based, with **storage autoscaling**. Aurora uses its own cluster volume.
- Lives in a **DB subnet group** (private subnets in ≥2 AZs) inside your VPC.
- **Parameter groups** (engine settings) and **option groups**.
- Connect via the **endpoint** DNS name (never the IP, which changes on failover).
- Maintenance windows for patching; **Performance Insights** and Enhanced Monitoring for tuning.

### Security

- **Network:** place it in **private subnets** with `publicly_accessible = false`, and allow the DB port only from the app's **security group**.
- **Encryption at rest** with KMS (must be chosen at creation; it also covers snapshots, replicas and logs). **TLS** in transit (enforce with the `rds.force_ssl` / `require_secure_transport` parameter).
- **Credentials:** let RDS manage the master password in **AWS Secrets Manager** (with rotation) instead of writing it in Terraform variables.
- **IAM database authentication** for MySQL/PostgreSQL (short-lived tokens instead of passwords).
- Audit logs exported to CloudWatch Logs; deletion protection; CloudTrail for API calls.

### Backups

- **Automated backups:** a daily snapshot plus transaction logs every ~5 minutes give **point-in-time restore** to any second within the retention period (1–35 days).
- **Manual snapshots:** kept until you delete them; can be copied to other regions/accounts and shared.
- A restore always creates a **new** DB instance (new endpoint).
- **AWS Backup** can manage policies centrally.

### Multi-AZ

High availability for failures:
- **Multi-AZ DB instance:** a **synchronous standby** in another AZ. It isn't readable; automatic failover takes ~60–120s and the endpoint DNS switches to the standby. It covers AZ outages, instance failure and maintenance.
- **Multi-AZ DB cluster** (MySQL/PostgreSQL): 1 writer + 2 **readable** standbys in 3 AZs, failover usually under 35s.
- **Aurora:** storage is always replicated 6 ways across 3 AZs; any replica can be promoted to writer.

### Read replicas

For **scaling reads**, not primarily for HA:
- **Asynchronous** replication from the primary, so they can lag slightly.
- Up to 15 per instance (MySQL/MariaDB/PostgreSQL), in the same region or **cross-region** (also useful for disaster recovery).
- The application sends reporting and read queries to the replica endpoint(s).
- A replica can be **promoted** to a standalone database.

| | Multi-AZ | Read replica |
|---|---|---|
| Purpose | availability / failover | read scaling (and DR if cross-region) |
| Replication | synchronous | asynchronous |
| Readable | no (instance) / yes (cluster) | yes |
| Failover | automatic | manual promotion |

### Use cases

Transactional applications with relationships and constraints: e-commerce orders and payments, banking/ERP/CRM systems, CMS (WordPress), SaaS backends, reporting with complex joins, and lift-and-shift of existing MySQL/PostgreSQL/Oracle/SQL Server databases.

---

## DynamoDB vs RDS: when to choose which

| | DynamoDB | RDS / Aurora |
|---|---|---|
| Model | key-value / document, schemaless | relational tables, fixed schema |
| Queries | by key and indexes; no joins; access patterns designed up front | flexible ad-hoc SQL, joins, aggregations |
| Scaling | automatic, virtually unlimited, horizontal | vertical (instance size) + read replicas; Aurora Serverless v2 |
| Operations | serverless, nothing to patch | managed, but you choose size, maintenance and parameters |
| Transactions | supported (TransactWriteItems), limited scope | full ACID across tables |
| Pricing | per request (on-demand) or capacity + storage | per instance-hour + storage + I/O |
| Best for | massive scale, predictable access patterns, serverless | complex relationships, reporting, existing SQL apps |

Many systems use both: RDS for core transactional data, DynamoDB for sessions, carts, events and high-traffic lookups.
