# AWS DynamoDB and RDS - Databases

Prepared by: Yash Gaikwad (Roll no. 24BCS10100)
Category: Database

AWS offers many database services; the two I studied are **DynamoDB** (a serverless NoSQL key-value / document database) and **RDS** (managed relational databases). The main thing I learned is that they solve different problems: DynamoDB is for predictable, key-based access at huge scale, RDS is for relational data with joins and transactions.

---

# Part 1: Amazon DynamoDB

## NoSQL

- NoSQL means the data is not stored as rows in rigid tables joined with SQL. DynamoDB stores **key-value and document** data with a flexible schema (only the key attributes are fixed).
- It is **fully managed and serverless**: no servers, patching or capacity planning of instances. Data is replicated across multiple AZs in a region automatically.
- Typical latency is single-digit milliseconds at any scale.
- Access is through an API (SDK / CLI / PartiQL), not a connection to a database server.
- Trade-off: no joins, and queries must be designed around the key structure. I model the table from the access patterns, not from the entities.

## Tables

- A **table** is the top-level container, created in one region. Table names are unique per account per region.
- The only thing declared up front is the **primary key**; all other attributes are schemaless.
- Billing/capacity mode is chosen per table (see below).

## Items

- An **item** is one record in a table (like a row), identified uniquely by its primary key.
- Maximum item size is **400 KB**.
- Different items in the same table can have different attributes.

## Attributes

- An **attribute** is a single piece of data in an item (like a column value).
- Types: scalar (String `S`, Number `N`, Binary `B`, Boolean, Null), set (SS, NS, BS) and document (List `L`, Map `M`).

## Partition key

- Every table needs a **partition key** (also called the hash key). DynamoDB hashes its value to decide which internal partition stores the item.
- With only a partition key, it must be unique per item (a *simple primary key*).
- Pick a key with **high cardinality** and evenly spread access (for example `userId`, `orderId`). A low-cardinality key (like `status`) creates a "hot partition" that throttles.

## Sort key

- An optional second key (range key). Partition key + sort key together form a **composite primary key**, which must be unique as a pair.
- Items with the same partition key are stored together and sorted by the sort key, which enables range queries such as "all orders of customer C101 in October" (`begins_with`, `between`, `>`, `<`).

| Example table `Orders` | |
|---|---|
| Partition key | `CustomerId` (String) |
| Sort key | `OrderDate` (String, ISO date) |
| Other attributes | `Total`, `Items`, `Status` |

## Secondary indexes (brief)

- **GSI (Global Secondary Index)**: a different partition key and optional sort key, so I can query by another attribute. Can be added any time, has its own capacity, and is eventually consistent.
- **LSI (Local Secondary Index)**: same partition key as the table but a different sort key. Must be created **when the table is created**.

## Capacity modes (brief)

| Mode | How it works | Good for |
|---|---|---|
| **On-demand** | pay per read/write request, no planning, scales instantly | new or unpredictable workloads |
| **Provisioned** | set read/write capacity units (RCU/WCU), optionally with auto scaling | steady, predictable traffic, lower cost at scale |

- 1 RCU = one strongly consistent read per second of up to 4 KB (an eventually consistent read costs half).
- 1 WCU = one write per second of up to 1 KB.
- Other features worth knowing: TTL (auto-expire items), Streams (change events, for example to trigger Lambda), DAX (in-memory cache), Global Tables (multi-region), point-in-time recovery and on-demand backups.

## Example: create a table and use it

```bash
aws dynamodb create-table \
  --table-name Orders \
  --attribute-definitions AttributeName=CustomerId,AttributeType=S AttributeName=OrderDate,AttributeType=S \
  --key-schema AttributeName=CustomerId,KeyType=HASH AttributeName=OrderDate,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST

aws dynamodb put-item --table-name Orders --item '{
  "CustomerId": {"S": "C101"},
  "OrderDate":  {"S": "2026-10-05"},
  "Total":      {"N": "1499"}
}'

aws dynamodb query --table-name Orders \
  --key-condition-expression "CustomerId = :c AND begins_with(OrderDate, :m)" \
  --expression-attribute-values '{":c":{"S":"C101"},":m":{"S":"2026-10"}}'
```

Prefer `query` (uses the key, efficient) over `scan` (reads the whole table, slow and costly).

## DynamoDB use cases

- Session stores, user profiles, shopping carts.
- Gaming leaderboards and player state.
- IoT and time-series style event data keyed by device and timestamp.
- Serverless backends with Lambda and API Gateway.
- Terraform state lock table (older S3 backend setups).

---

# Part 2: Amazon RDS

## Relational database

- A relational database stores data in tables of rows and columns, enforces a schema, and uses **SQL** with joins and **ACID transactions**.
- **RDS (Relational Database Service)** is the managed version: AWS handles provisioning, OS and engine patching, backups, replication and failover, while I handle schema, queries and tuning. I do **not** get OS-level (SSH) access.

## Supported engines

| Engine | Note |
|---|---|
| MySQL | open source, very common |
| PostgreSQL | open source, rich features |
| MariaDB | MySQL fork |
| Oracle | licence-included or bring your own licence |
| SQL Server | Microsoft, licence-included |
| IBM Db2 | newer addition |
| **Amazon Aurora** | AWS-built, MySQL- and PostgreSQL-compatible; storage is a shared distributed cluster volume across 3 AZs, up to 15 low-lag replicas |

## DB instances

- The building block is a **DB instance**: an isolated database environment with an instance class (for example `db.t3.micro`, `db.m6g.large`), allocated storage (gp3 / io1 / io2) and an engine version.
- Lives in a **DB subnet group** (subnets in at least two AZs) inside a VPC.
- Configuration is tuned using **parameter groups** (engine settings) and option groups (engine add-ons).
- Each instance exposes an **endpoint** (DNS name) and a port (3306 MySQL/MariaDB, 5432 PostgreSQL, 1433 SQL Server, 1521 Oracle).

```bash
aws rds create-db-instance \
  --db-instance-identifier demo-mysql \
  --engine mysql \
  --db-instance-class db.t3.micro \
  --allocated-storage 20 --storage-type gp3 \
  --master-username admin \
  --manage-master-user-password \
  --db-subnet-group-name demo-db-subnets \
  --vpc-security-group-ids sg-0123456789abcdef0 \
  --storage-encrypted \
  --backup-retention-period 7 \
  --no-publicly-accessible
```

`--manage-master-user-password` lets RDS keep the password in Secrets Manager so I never write it on the command line.

## Security

- **Network**: run in private subnets of a VPC, `--no-publicly-accessible`, and restrict the **security group** so only the application's SG can reach the DB port.
- **Encryption at rest**: AWS **KMS** keys encrypt storage, automated backups, snapshots and read replicas. It must be chosen **at creation**; to encrypt an existing DB, copy a snapshot with encryption and restore from it.
- **Encryption in transit**: use **SSL/TLS** connections (RDS CA certificate bundle) and can enforce it with parameters (for example `rds.force_ssl` on PostgreSQL).
- **IAM database authentication** (MySQL, MariaDB, PostgreSQL, Aurora): connect with a short-lived (15-minute) token instead of a stored password.
- Use Secrets Manager rotation, least-privilege DB users, and turn on deletion protection for production.

## Backups

- **Automated backups**: daily snapshot during the backup window plus continuous transaction logs. Retention can be **0-35 days** (0 disables them; the console default is 7).
- **Point-in-time recovery (PITR)**: restore to any second inside the retention window; the result is always a **new DB instance** with a new endpoint.
- **Manual snapshots**: taken on demand, kept until I delete them (they survive deleting the instance), can be copied or shared across regions/accounts.
- Automated backups are deleted with the instance unless I keep them explicitly; take a final snapshot before deleting.

```bash
aws rds create-db-snapshot --db-instance-identifier demo-mysql --db-snapshot-identifier demo-mysql-before-upgrade
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier demo-mysql \
  --target-db-instance-identifier demo-mysql-restored \
  --use-latest-restorable-time
```

## Multi-AZ vs Read replicas

| | Multi-AZ | Read replica |
|---|---|---|
| Purpose | **high availability / durability** | **read scaling** (and DR with cross-region) |
| Replication | **synchronous** to a standby in another AZ | **asynchronous** (small replica lag) |
| Serves traffic | standby is not used for reads (classic Multi-AZ instance deployment) | yes, it has its **own endpoint** and serves reads |
| Failover | **automatic** (DNS endpoint switches to the standby, typically about a minute or two) | manual **promotion** to a standalone DB |
| Region | same region | same region, cross-AZ or **cross-region** |
| Application change | none, same endpoint | app must send read queries to the replica endpoint |
| Cost | roughly double the instance | one extra instance per replica |
| Typical use | production uptime, maintenance with minimal downtime | reporting, read-heavy apps |

Notes: a Multi-AZ **DB cluster** (MySQL/PostgreSQL) has two readable standbys, which blends both ideas. MySQL, MariaDB and PostgreSQL support up to 15 read replicas (limits vary by engine); Aurora supports up to 15 replicas that can also act as failover targets.

```bash
aws rds modify-db-instance --db-instance-identifier demo-mysql --multi-az --apply-immediately
aws rds create-db-instance-read-replica --db-instance-identifier demo-mysql-replica --source-db-instance-identifier demo-mysql
```

## RDS use cases

- Traditional business apps, ERP/CRM, e-commerce with orders and payments.
- Web applications needing joins, constraints and transactions (WordPress, Django, Spring apps).
- Reporting on structured data (via read replicas).
- Lift-and-shift of existing MySQL/PostgreSQL/Oracle/SQL Server databases.

---

# DynamoDB vs RDS decision table

| Question | Choose DynamoDB | Choose RDS |
|---|---|---|
| Data model | key-value / document, flexible | relational tables with schema |
| Query style | by primary key / index, known access patterns | ad-hoc SQL, joins, aggregations |
| Transactions | supported but limited in scope | full ACID across many tables |
| Scaling | automatic horizontal scaling, huge throughput | vertical scale + read replicas (Aurora scales further) |
| Management | serverless, no instances | managed instances, I pick size and engine |
| Availability | multi-AZ by default | enable Multi-AZ explicitly |
| Latency | single-digit ms at any scale | depends on instance, query and indexes |
| Pricing | per request or provisioned capacity | per instance hour + storage + I/O |
| Network | accessed through public endpoint / VPC gateway endpoint | lives inside my VPC subnets |
| Example | shopping cart, sessions, IoT events | orders and invoices, banking-like data |

---

## Interview quick points

- DynamoDB: serverless NoSQL, primary key = partition key (+ optional sort key), item limit 400 KB, single-digit ms latency.
- Pick a high-cardinality partition key to avoid hot partitions; use `Query` not `Scan`.
- GSI can be added any time and has its own throughput; LSI only at table creation and shares the partition key.
- On-demand for unpredictable load, provisioned (with auto scaling) for steady load.
- RDS: managed relational DB; engines are MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, Db2 and Aurora. No OS access.
- Multi-AZ = HA with synchronous standby and automatic failover; Read replica = asynchronous copy for scaling reads and can be promoted.
- Multi-AZ is not a performance feature (classic mode), and read replicas are not a backup/HA substitute on their own.
- Automated backups: retention 0-35 days with PITR; restore always creates a new instance. Manual snapshots stay until deleted.
- Encryption at rest with KMS must be set at creation; IAM auth uses 15-minute tokens; keep DBs in private subnets with SG restricted to the app tier.
- Aurora = AWS-built, storage replicated 6 ways across 3 AZs, up to 15 replicas, fast failover.
