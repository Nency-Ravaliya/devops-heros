# 05 · DynamoDB & RDS — Database Services

AWS offers **purpose-built databases**. The two most common are:

| | **DynamoDB** | **RDS** |
|---|---|---|
| Model | NoSQL (key-value and document) | Relational (SQL) |
| Management | fully **serverless**, nothing to patch | **managed** instances, you pick the size |
| Schema | flexible per item, only the key is fixed | fixed tables, columns and types |
| Scaling | horizontal, automatic, near-unlimited | vertical (instance size) + read replicas |
| Queries | by key (Query / GetItem), limited secondary indexes | full SQL: joins, aggregations, ad-hoc queries |
| Latency | single-digit milliseconds at any scale | depends on instance and query |
| Best for | high-scale, known access patterns | complex relationships and transactions, existing SQL apps |

---

# Part A · DynamoDB

## NoSQL

**NoSQL** ("not only SQL") databases drop the rigid relational table model to gain **horizontal scale, flexible schemas and predictable performance**. The main families are key-value, document, wide-column and graph.

**Amazon DynamoDB** is a fully managed, serverless **key-value and document** database:
- no servers, no patching, no version upgrades
- data is replicated automatically across **3 AZs**
- **single-digit-millisecond** reads and writes at any scale, with no limit on table size
- you design the table around your **access patterns** (the queries you will run), not around normalized entities

## Tables

A **table** is a collection of items. You define only the **primary key** when you create it. Every other attribute is schemaless.

**Capacity modes**

| Mode | How you pay | Use when |
|---|---|---|
| **On-demand** | per request | unpredictable or spiky traffic, new apps (default choice) |
| **Provisioned** | per RCU/WCU per hour (+ optional auto scaling) | steady, predictable traffic, cheaper at scale |

- 1 **RCU** = one strongly consistent read per second of up to 4 KB (or two eventually consistent reads).
- 1 **WCU** = one write per second of up to 1 KB.

**Table classes:** *Standard* and *Standard-IA* (cheaper storage for rarely read tables).

## Items

An **item** is a single record, similar to a row. Each item:
- must contain the primary key attributes
- can have a **different set of attributes** from other items in the same table
- can be at most **400 KB**

## Attributes

An **attribute** is a name/value pair, similar to a column but not enforced across items.

| Category | Types |
|---|---|
| Scalar | `S` String, `N` Number, `B` Binary, `BOOL`, `NULL` |
| Document | `M` Map (nested JSON object), `L` List |
| Set | `SS` String set, `NS` Number set, `BS` Binary set |

```json
{
  "UserId":   { "S": "u#1001" },
  "OrderId":  { "S": "2026-10-07#A17" },
  "Total":    { "N": "1499" },
  "Items":    { "L": [ { "S": "keyboard" }, { "S": "mouse" } ] },
  "Shipping": { "M": { "City": { "S": "Bengaluru" }, "Pin": { "S": "560001" } } }
}
```

## Partition key

The **partition key** (also called the *hash key*) is required. DynamoDB hashes its value to decide **which physical partition** stores the item.

- With a **simple primary key** (partition key only), the value must be **unique** for each item, e.g. `UserId`.
- Choose a key with **high cardinality and evenly distributed access**, such as user ID or device ID. A low-cardinality key such as `status = active` creates a **hot partition** that throttles.

```text
PK = "u#1001" ─► hash() ─► Partition 3
PK = "u#1002" ─► hash() ─► Partition 1
PK = "u#1003" ─► hash() ─► Partition 7
```

## Sort key

The **sort key** (also called the *range key*) is optional. With a sort key, the primary key becomes **composite** (partition key + sort key):

- Many items can share a partition key. The **combination** must be unique.
- Items with the same partition key are **stored together, ordered by sort key**.
- This enables range queries: `begins_with`, `between`, `<`, `>`, and sorting with `ScanIndexForward`.

| UserId (PK) | OrderId (SK) | Total |
|---|---|---|
| u#1001 | 2026-09-30#A02 | 799 |
| u#1001 | 2026-10-07#A17 | 1499 |
| u#1002 | 2026-10-01#B11 | 250 |

```bash
# All October 2026 orders for user u#1001, newest first
aws dynamodb query --table-name Orders \
  --key-condition-expression "UserId = :u AND begins_with(OrderId, :m)" \
  --expression-attribute-values '{":u":{"S":"u#1001"},":m":{"S":"2026-10"}}' \
  --no-scan-index-forward
```

**Query vs Scan:** `Query` reads only one partition key's items and is efficient. `Scan` reads the **whole table** and is slow and expensive, so avoid it in hot paths.

**Secondary indexes** add more access patterns:
- **GSI (Global Secondary Index)**: a different partition and sort key. Can be added at any time. Eventually consistent.
- **LSI (Local Secondary Index)**: the same partition key with a different sort key. Must be defined when the table is created.

## Other DynamoDB features

- **DynamoDB Streams**: a change-data-capture feed that can trigger Lambda.
- **TTL**: expire items automatically, e.g. sessions (deletes are free).
- **Global Tables**: multi-region, multi-active replication.
- **Transactions**: ACID `TransactWriteItems` / `TransactGetItems` across up to 100 items.
- **PITR**: point-in-time recovery to any second in a configurable window of up to 35 days, plus on-demand backups.
- **DAX**: an in-memory cache for microsecond reads.
- Encryption at rest is always on (AWS-owned, AWS-managed or customer-managed KMS key).

## DynamoDB use cases

- User profiles, sessions and shopping carts
- Gaming leaderboards and player state
- IoT telemetry and time-series events (PK = device, SK = timestamp)
- Serverless backends (API Gateway → Lambda → DynamoDB)
- Real-time bidding and ad tech that needs predictable low latency
- **Terraform state locking** (legacy `dynamodb_table` backend option, now superseded by S3-native locking)
- Metadata and catalog stores for high-traffic apps

## Terraform example

```hcl
resource "aws_dynamodb_table" "orders" {
  name         = "Orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserId"
  range_key    = "OrderId"

  attribute {
    name = "UserId"
    type = "S"
  }
  attribute {
    name = "OrderId"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  ttl {
    attribute_name = "ExpiresAt"
    enabled        = true
  }
}
```

---

# Part B · RDS

## Relational database

A **relational database** stores data in **tables** of rows and columns with a predefined **schema**. **Primary and foreign keys** express relationships between tables, and you query with **SQL**, including joins and aggregations. Relational databases guarantee **ACID** transactions (Atomicity, Consistency, Isolation, Durability).

```text
customers                     orders
┌────┬─────────┐              ┌────┬─────────────┬───────┐
│ id │ name    │◄─────────────│ id │ customer_id │ total │
├────┼─────────┤   FK         ├────┼─────────────┼───────┤
│ 1  │ Anuska  │              │ 10 │ 1           │ 1499  │
└────┴─────────┘              └────┴─────────────┴───────┘
SELECT c.name, SUM(o.total) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.name;
```

**Amazon RDS (Relational Database Service)** runs these databases as a **managed service**. AWS handles provisioning, OS and DB patching, backups, monitoring, failover and storage scaling. You handle schema design, queries, tuning and access control.

## Supported engines

| Engine | Notes |
|---|---|
| **Amazon Aurora** (MySQL- and PostgreSQL-compatible) | AWS-built cloud-native engine with shared storage replicated 6 ways across 3 AZs, up to 15 replicas, and Aurora Serverless v2 |
| **PostgreSQL** | open source |
| **MySQL** | open source |
| **MariaDB** | open source (MySQL fork) |
| **Oracle** | BYOL or license-included |
| **Microsoft SQL Server** | Express, Web, Standard, Enterprise |
| **IBM Db2** | Standard, Advanced |

*RDS Custom* (Oracle, SQL Server) gives OS-level access when an app needs it.

## DB instances

A **DB instance** is an isolated database environment running in the cloud: the basic building block of RDS.

| Setting | Options |
|---|---|
| **Instance class** | `db.t4g.micro` (burstable, Free Tier) · `db.m7g` (general) · `db.r7g` (memory optimized) |
| **Storage** | `gp3` (default), `io2` provisioned IOPS. **Storage autoscaling** grows it automatically. |
| **Network** | placed in a **DB subnet group**, which should be private subnets in at least 2 AZs |
| **Endpoint** | a DNS name, e.g. `mydb.abc123.ap-south-1.rds.amazonaws.com:5432`. It stays the same through failover. |
| **Parameter group** | engine configuration settings (e.g. `max_connections`) |
| **Option group** | engine add-ons (Oracle/SQL Server features) |
| **Maintenance window** | weekly slot for patches |

There is **no SSH access** to the underlying host (except with RDS Custom).

## Security

- **Network isolation:** run in **private subnets**, set `publicly_accessible = false`, and use a **security group** that allows the DB port only from the app's security group.
- **Encryption at rest:** KMS. Enable it at creation; it covers storage, backups, snapshots and replicas.
- **Encryption in transit:** TLS/SSL. Enforce it with `rds.force_ssl` (PostgreSQL) or `require_secure_transport` (MySQL).
- **Authentication:**
  - Native database users and passwords. Store the master password in **AWS Secrets Manager** (`manage_master_user_password = true`) with automatic rotation.
  - **IAM database authentication**: short-lived tokens instead of passwords (MySQL/PostgreSQL).
  - Kerberos / Active Directory (SQL Server, Oracle, MySQL, PostgreSQL).
- **IAM** controls who can manage the instance (create, delete, modify, snapshot).
- **Auditing:** CloudTrail for API calls, database audit logs exported to CloudWatch Logs, and **Database Activity Streams** (Aurora).
- **Deletion protection** prevents accidental deletes.

## Backups

| Type | How | Retention | Restore |
|---|---|---|---|
| **Automated backups** | daily snapshot + transaction logs (every 5 minutes) | 1–35 days (0 disables) | **Point-in-time recovery** to any second in the retention window |
| **Manual snapshots** | taken on demand | **kept until you delete them** | to the snapshot moment |

- A restore always creates a **new** DB instance with a new endpoint.
- Snapshots can be **copied across regions and accounts** for DR, and shared.
- **AWS Backup** can centralize backup policies.
- Take a final snapshot when deleting (`skip_final_snapshot = false`).

## Multi-AZ

**Multi-AZ** gives **high availability and durability**. It is **not** a way to scale reads.

```text
          App ──► mydb.xxxx.rds.amazonaws.com  (DNS endpoint)
                         │
          ┌──────────────┴───────────────┐
   AZ-a   ▼                              │  AZ-b
   ┌─────────────┐  synchronous    ┌─────────────┐
   │  PRIMARY    │ ──replication─► │  STANDBY    │  (cannot serve reads)
   └─────────────┘                 └─────────────┘
   Failure / patching ─► automatic failover (~60–120 s): DNS now points to the standby
```

| Deployment | What you get |
|---|---|
| **Multi-AZ DB instance** | 1 primary + 1 **synchronous standby** that does not serve reads |
| **Multi-AZ DB cluster** (MySQL/PostgreSQL) | 1 writer + **2 readable standbys** in 3 AZs, failover usually under 35 s |
| **Aurora** | storage is always multi-AZ, and any replica can be promoted |

Failover triggers include AZ outage, primary failure, instance class change, OS patching and manual reboot with failover. The application reconnects to the **same endpoint**.

## Read replicas

**Read replicas** improve **read scalability**.

- **Asynchronous** replication from the primary, so replicas are *eventually consistent* (replica lag).
- Up to **15** read replicas for MySQL, MariaDB and PostgreSQL (Aurora: 15).
- Each replica has **its own endpoint**. The application must send reads to it.
- Replicas can be in the **same AZ, another AZ, or another region** (cross-region also gives DR).
- A replica can be **promoted** to a standalone database (manual, used for DR or migration).
- A replica can itself be Multi-AZ.

| | Multi-AZ | Read replica |
|---|---|---|
| Purpose | high availability / failover | read scaling (and DR if cross-region) |
| Replication | synchronous | asynchronous |
| Serves reads? | no (except Multi-AZ cluster) | **yes** |
| Failover | automatic | manual promotion |
| Endpoint | same as primary | separate |

## RDS use cases

- Web and mobile backends that need relational data and transactions: e-commerce orders, banking, ERP, CRM
- Content management systems (WordPress, Drupal) on MySQL or MariaDB
- Lift-and-shift of existing Oracle or SQL Server applications
- SaaS multi-tenant applications on PostgreSQL
- Reporting and analytics on read replicas without loading the primary
- Microservices that each own a small Postgres instance

## Terraform example

```hcl
resource "aws_db_subnet_group" "db" {
  name       = "app-db-subnets"
  subnet_ids = [aws_subnet.db_a.id, aws_subnet.db_b.id]
}

resource "aws_db_instance" "postgres" {
  identifier                  = "app-db"
  engine                      = "postgres"
  engine_version              = "16"
  instance_class              = "db.t4g.micro"
  allocated_storage           = 20
  max_allocated_storage       = 100
  db_name                     = "appdb"
  username                    = "appadmin"
  manage_master_user_password = true # password stored in Secrets Manager
  db_subnet_group_name        = aws_db_subnet_group.db.name
  vpc_security_group_ids      = [aws_security_group.db.id]
  publicly_accessible         = false
  storage_encrypted           = true
  multi_az                    = true
  backup_retention_period     = 7
  deletion_protection         = true
  skip_final_snapshot         = false
  final_snapshot_identifier   = "app-db-final"
}

resource "aws_db_instance" "replica" {
  identifier          = "app-db-replica"
  replicate_source_db = aws_db_instance.postgres.identifier
  instance_class      = "db.t4g.micro"
  skip_final_snapshot = true # replicas cannot take a final snapshot
}
```

---

## Choosing between them

```text
Need joins, complex ad-hoc queries, strict relational integrity, or an existing SQL app?  ─► RDS / Aurora
Known access patterns, massive scale, serverless, single-digit-ms latency at any load?   ─► DynamoDB
```
