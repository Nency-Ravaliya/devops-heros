# 05 - Amazon DynamoDB & Amazon RDS

- **Student:** Ujjawal Prabhat
- **Enrollment No.:** 24BCS10267
- **Session:** 18 - Terraform & IaC (Task 2: AWS core services)

## Checklist

**DynamoDB**
- [x] NoSQL
- [x] Tables
- [x] Items
- [x] Attributes
- [x] Partition key
- [x] Sort key
- [x] Use cases

**RDS**
- [x] Relational database
- [x] Engines
- [x] DB instances
- [x] Security
- [x] Backups
- [x] Multi-AZ
- [x] Read replicas
- [x] Use cases

---

# Part 1 - Amazon DynamoDB

## NoSQL

DynamoDB is a **fully managed, serverless NoSQL key-value and document database**. There are no servers,
patching or storage to manage; it delivers single-digit-millisecond latency at any scale and replicates data
across 3 AZs automatically.

NoSQL vs relational in one line: instead of normalised tables joined at query time, you **design the table
around your access patterns** and fetch data by key - no joins, flexible schema, horizontal scaling.

Capacity modes: **On-demand** (pay per request, no planning) or **Provisioned** (set RCUs/WCUs, optional auto scaling).

## Tables

- A **table** is a collection of items. The only schema you declare up front is the **primary key**.
- Primary key options:
  - **Simple**: partition key only.
  - **Composite**: partition key + sort key.
- Secondary indexes for other access patterns: **GSI** (different partition/sort key, any time) and
  **LSI** (same partition key, different sort key, only at creation).
- Extras: TTL (auto-expire items), Streams (change data capture), point-in-time recovery, global tables (multi-region).

## Items

- An **item** is one record (like a row), max **400 KB**.
- Items in the same table can have **different attributes** (schemaless apart from the key).

## Attributes

- An **attribute** is a name-value pair (like a column, but per item).
- Types: scalar - `S` string, `N` number, `B` binary, `BOOL`, `NULL`; document - `M` map, `L` list;
  sets - `SS`, `NS`, `BS`.

## Partition key

- Also called the **hash key**. DynamoDB hashes its value to decide **which physical partition** stores the item.
- Must be provided for every `GetItem`/`Query`.
- Choose a **high-cardinality** value with evenly spread traffic (`CustomerId`, `UserId`) to avoid
  **hot partitions**; avoid low-cardinality keys like `Status` or `Date`.

## Sort key

- Also called the **range key**. Items with the same partition key are stored together, **sorted** by the sort key.
- Enables range queries: `begins_with`, `between`, `>`, `<` - e.g. "all orders of C001 after 2 Oct".
- Partition key + sort key together must be unique.

```text
Table: Orders  (PK = CustomerId, SK = OrderDate)
+------------+------------+-------+---------+--------+
| CustomerId | OrderDate  | Total | Status  | Coupon |
+------------+------------+-------+---------+--------+
| C001       | 2026-10-01 | 499   | SHIPPED |        |   <- same partition "C001",
| C001       | 2026-10-05 | 1299  |         | DIWALI |      sorted by OrderDate
| C002       | 2026-10-03 | 150   |         |        |
+------------+------------+-------+---------+--------+
```

## Use cases

- Session stores, shopping carts, user profiles.
- Gaming leaderboards and player state.
- IoT/time-series events (PK = device, SK = timestamp) with TTL.
- Serverless backends (API Gateway + Lambda + DynamoDB).
- **Terraform state locking** table (`LockID` partition key) for the S3 backend.

## Hands-on (run against LocalStack, an AWS emulator)

Run against LocalStack 3.8 (`--endpoint-url http://localhost:4566` omitted from displayed commands).
DynamoDB behaves functionally like the real service here; on real AWS the table would start as `CREATING`
for a few seconds before `ACTIVE`.

```text
$ aws dynamodb create-table --table-name Orders \
    --attribute-definitions AttributeName=CustomerId,AttributeType=S AttributeName=OrderDate,AttributeType=S \
    --key-schema AttributeName=CustomerId,KeyType=HASH AttributeName=OrderDate,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST --query "TableDescription.{Table:TableName,Status:TableStatus,Keys:KeySchema}"
{
    "Table": "Orders",
    "Status": "ACTIVE",
    "Keys": [
        {
            "AttributeName": "CustomerId",
            "KeyType": "HASH"
        },
        {
            "AttributeName": "OrderDate",
            "KeyType": "RANGE"
        }
    ]
}

$ aws dynamodb put-item --table-name Orders --item '{"CustomerId":{"S":"C001"},"OrderDate":{"S":"2026-10-01"},"Total":{"N":"499"},"Status":{"S":"SHIPPED"}}'
$ aws dynamodb put-item --table-name Orders --item '{"CustomerId":{"S":"C001"},"OrderDate":{"S":"2026-10-05"},"Total":{"N":"1299"},"Coupon":{"S":"DIWALI"}}'
$ aws dynamodb put-item --table-name Orders --item '{"CustomerId":{"S":"C002"},"OrderDate":{"S":"2026-10-03"},"Total":{"N":"150"}}'

$ aws dynamodb query --table-name Orders \
    --key-condition-expression "CustomerId = :c AND OrderDate >= :d" \
    --expression-attribute-values '{":c":{"S":"C001"},":d":{"S":"2026-10-02"}}'
{
    "Items": [
        {
            "Coupon": {
                "S": "DIWALI"
            },
            "CustomerId": {
                "S": "C001"
            },
            "OrderDate": {
                "S": "2026-10-05"
            },
            "Total": {
                "N": "1299"
            }
        }
    ],
    "Count": 1,
    "ScannedCount": 1,
    "ConsumedCapacity": null
}
```

The query used the **partition key** (`C001`) plus a **sort-key range** (`>= 2026-10-02`), and the items show
different attribute sets (`Status` vs `Coupon`). The table was deleted afterwards.

Terraform equivalent:

```hcl
resource "aws_dynamodb_table" "orders" {
  name         = "Orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "CustomerId"
  range_key    = "OrderDate"

  attribute {
    name = "CustomerId"
    type = "S"
  }
  attribute {
    name = "OrderDate"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}
```

---

# Part 2 - Amazon RDS (Relational Database Service)

## Relational database

RDS is a **managed relational (SQL) database** service. Data lives in tables with a fixed schema, rows
linked by foreign keys, queried with SQL joins, with full **ACID transactions**. AWS handles provisioning,
OS/DB patching, backups, failover and monitoring; you handle schema, queries, indexes and tuning.
You do **not** get OS/SSH access to the host.

## Engines

- **Amazon Aurora** (MySQL- and PostgreSQL-compatible; cloud-native storage replicated 6 ways across 3 AZs; Aurora Serverless v2)
- **PostgreSQL**
- **MySQL**
- **MariaDB**
- **Oracle** (license included or BYOL)
- **Microsoft SQL Server**
- **IBM Db2**

## DB instances

- A **DB instance** is an isolated database environment = instance class (CPU/RAM) + storage + engine version.
- Instance classes: `db.t4g.micro` (burstable, free tier), `db.m7g.*` (general), `db.r7g.*` (memory-optimised).
- Storage: `gp3` (general SSD) or `io1/io2` (provisioned IOPS); **storage auto scaling** can grow it.
- Placed into a **DB subnet group** (subnets in >= 2 AZs, normally private) and reached via a DNS **endpoint**
  like `mydb.abc123.ap-south-1.rds.amazonaws.com:5432`.
- Configured via **parameter groups** (engine settings) and **option groups**.

## Security

- **Network**: run in **private subnets**, `publicly_accessible = false`; security group allows the DB port
  (e.g. 5432) **only from the app's security group**.
- **Encryption at rest** with KMS (must be chosen at creation; covers storage, snapshots, replicas, logs).
- **Encryption in transit** with TLS (force it, e.g. `rds.force_ssl = 1` for PostgreSQL).
- **Authentication**: master user password stored/rotated in **Secrets Manager** (`manage_master_user_password`),
  or **IAM database authentication** (short-lived tokens).
- IAM policies control who can *manage* RDS (create/delete/modify); CloudTrail audits it.

## Backups

- **Automated backups**: daily snapshot + transaction logs, retention **1-35 days**, enabling
  **point-in-time restore (PITR)** to any second within the window (restores create a *new* instance).
- **Manual snapshots**: kept until you delete them; can be copied cross-region / shared cross-account.
- **AWS Backup** for central backup policies. Set `deletion_protection = true` and take a final snapshot on delete.

## Multi-AZ

- **High availability**, not scaling: RDS keeps a **synchronous standby** in another AZ.
- On failure (instance/AZ outage, patching) RDS **automatically fails over** - the DNS endpoint flips to the
  standby, typically within 60-120 s. The standby does **not** serve reads.
- **Multi-AZ DB cluster** variant (MySQL/PostgreSQL): one writer + two *readable* standbys, faster failover.

## Read replicas

- **Scaling reads**: **asynchronous** copies of the primary with their **own endpoint** for read-only queries
  (reports, analytics, read-heavy APIs).
- Up to 15 per primary (engine-dependent); can be in the same region, another AZ or **cross-region** (also useful for DR).
- Can be **promoted** to a standalone writable DB. Replication lag means reads can be slightly stale.

| | Multi-AZ | Read replica |
|---|---|---|
| Purpose | availability / failover | read scaling |
| Replication | synchronous | asynchronous |
| Readable? | no (classic Multi-AZ) | yes |
| Failover | automatic | manual promote |

## Use cases

- Transactional business apps: e-commerce orders, banking, ERP, CRM.
- Backends of web/mobile apps needing joins, constraints and transactions.
- Lift-and-shift of existing MySQL/PostgreSQL/Oracle/SQL Server databases.
- Reporting with read replicas.

## When to choose which

| Need | Pick |
|---|---|
| Complex queries, joins, strict relational integrity, transactions across many tables | **RDS / Aurora** |
| Known key-based access patterns, massive scale, serverless, single-digit ms | **DynamoDB** |

## Terraform snippet (RDS)

```hcl
resource "aws_db_subnet_group" "db" {
  name       = "app-db-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_instance" "postgres" {
  identifier                  = "app-db"
  engine                      = "postgres"
  engine_version              = "16"
  instance_class              = "db.t4g.micro"
  allocated_storage           = 20
  storage_type                = "gp3"
  storage_encrypted           = true
  username                    = "appadmin"
  manage_master_user_password = true # password kept in Secrets Manager
  db_subnet_group_name        = aws_db_subnet_group.db.name
  vpc_security_group_ids      = [aws_security_group.db.id]
  publicly_accessible         = false
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
}
```

> RDS was **not** run hands-on: RDS is not part of LocalStack's free community edition (it is a Pro feature),
> and no real AWS account was used. The snippet above was not applied.
