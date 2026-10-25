# 05 – DynamoDB & RDS – Database Services

**Name:** Kushal Talati · **Enrollment No:** 24BCS10123

Two managed databases that solve opposite problems. **DynamoDB** is a serverless key-value/document store that scales horizontally and answers single-digit-millisecond lookups by key, with no servers, patches or connection pools to manage. **RDS** runs a normal relational engine (PostgreSQL, MySQL, …) on managed instances, so I keep SQL, joins and transactions and AWS takes over backups, patching, failover and replicas.

Hands-on output below is from LocalStack (raw in [`../../logs/02-aws-services-hands-on.txt`](../../logs/02-aws-services-hands-on.txt) under `05 DynamoDB` / `05 RDS`). DynamoDB works fully in the community edition; the RDS API is a Pro feature, so for RDS I show the call and the error and describe the service from the docs.

---

## DynamoDB

### NoSQL
No fixed schema, no joins, no SQL. I model the data around the *queries* I will run, not around normalised entities. Scale comes from partitioning data across many storage nodes by a hash of the key; the trade-off is that I can only query efficiently by that key (or by a secondary index I define up front).

### Tables, items, attributes

```text
Table  s18-orders                      (≈ a table, but with no fixed columns)
 ├── Item { customer_id: "C001", order_date: "2026-10-01", total: 1250, items: ["keyboard","mouse"] }
 ├── Item { customer_id: "C001", order_date: "2026-10-05", total: 399,  status: "shipped" }
 └── Item { customer_id: "C002", order_date: "2026-10-03", total: 80 }
                ▲                 ▲                 ▲
          partition key        sort key       attributes (any shape per item, up to 400 KB per item)
```

* **Table**: the only mandatory schema is the primary key. Capacity is `PAY_PER_REQUEST` (on-demand) or provisioned RCU/WCU.
* **Item**: one record, max 400 KB, uniquely identified by its primary key.
* **Attribute**: a typed name/value – `S` string, `N` number, `B` binary, `BOOL`, `L` list, `M` map, `SS/NS` sets, `NULL`. Items in the same table can have completely different attributes.

### Partition key and sort key
* **Partition key** (hash key): DynamoDB hashes it to pick the physical partition. A `GetItem` needs it. Good keys have many distinct values with even traffic (customer id, order id); bad keys are things like `status` with 3 values (a "hot partition").
* **Sort key** (range key): optional second part of the primary key. Items with the same partition key are stored **together, sorted by sort key**, so a `Query` can fetch "all orders of C001 in October" with one request using `BETWEEN`, `begins_with`, `<`, `>`. Partition key + sort key together must be unique.
* **Secondary indexes**: a GSI is another partition/sort key over the same data (query by `status` + `order_date`); an LSI is an alternative sort key under the same partition key.

```text
$ awsl dynamodb create-table --table-name s18-orders \
    --attribute-definitions AttributeName=customer_id,AttributeType=S AttributeName=order_date,AttributeType=S \
    --key-schema AttributeName=customer_id,KeyType=HASH AttributeName=order_date,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST
{ "Table": "s18-orders", "Status": "ACTIVE", "Keys": [ {customer_id HASH}, {order_date RANGE} ] }

$ awsl dynamodb put-item --table-name s18-orders --item '{"customer_id":{"S":"C001"},"order_date":{"S":"2026-10-01"},"total":{"N":"1250"},"items":{"L":[{"S":"keyboard"},{"S":"mouse"}]}}'
$ awsl dynamodb put-item ... C001 / 2026-10-05 / total 399 / status shipped
$ awsl dynamodb put-item ... C002 / 2026-10-03 / total 80

$ awsl dynamodb get-item --table-name s18-orders --key '{"customer_id":{"S":"C001"},"order_date":{"S":"2026-10-05"}}'
{ "Item": { "customer_id": {"S": "C001"}, "order_date": {"S": "2026-10-05"}, "total": {"N": "399"}, "status": {"S": "shipped"} } }

$ awsl dynamodb query --table-name s18-orders \
    --key-condition-expression 'customer_id = :c AND order_date BETWEEN :from AND :to' \
    --expression-attribute-values '{":c":{"S":"C001"},":from":{"S":"2026-10-01"},":to":{"S":"2026-10-31"}}'
{ "Count": 2, "Items": [ { "date": "2026-10-01", "total": "1250" }, { "date": "2026-10-05", "total": "399" } ] }

$ awsl dynamodb scan --table-name s18-orders --select COUNT
{ "Count": 3, "ScannedCount": 3 }        <- Scan reads the WHOLE table; fine for 3 items, a bill for 3 million
```

`Query` touched only C001's partition; `Scan` touched everything – that difference is the whole DynamoDB design discipline.

### Other things worth knowing
Streams (change feed → Lambda), TTL attribute (auto-expire items), DAX (in-memory cache), global tables (multi-region active-active), point-in-time recovery, transactions (`TransactWriteItems`), conditional writes for optimistic locking, and a free tier of 25 GB + 25 RCU/WCU.

### Use cases
| Use case | Why DynamoDB fits |
|---|---|
| User sessions, shopping carts, feature flags | key lookup, TTL, millions of small items |
| IoT / clickstream / time series per device | partition = device id, sort = timestamp |
| Serverless APIs (Lambda + API Gateway) | no connection pools, scales to zero and to any load |
| Leaderboards / counters | atomic `ADD` updates |
| Terraform state locking (classic pattern) | one conditional `PutItem` = a lock |

---

## RDS (Relational Database Service)

### Relational database
Tables with fixed columns, rows, primary/foreign keys, SQL, joins, ACID transactions. The right choice whenever data has relationships and I need ad-hoc queries, reporting, or the integrity guarantees of a schema – which is most business applications (the capstone's FastAPI + PostgreSQL + Alembic stack is exactly this).

### Supported engines
PostgreSQL, MySQL, MariaDB, Oracle, SQL Server, IBM Db2, and **Aurora** (AWS's own MySQL/PostgreSQL-compatible engine with a distributed storage layer, 6 copies across 3 AZs, up to 15 read replicas, Aurora Serverless v2 scales in ACUs).

### DB instances
A DB instance = engine + instance class (`db.t3.micro` … `db.r6g.16xlarge`) + storage (gp3/io1, autoscaling) + a subnet group (which private subnets it may use) + parameter/option groups (engine config). I connect to an **endpoint DNS name**, never an IP, so failover does not change my connection string. The call I tried (LocalStack community does not implement RDS):

```text
$ awsl rds create-db-instance --db-instance-identifier s18-pg --db-instance-class db.t3.micro --engine postgres \
    --master-username admin1 --master-user-password '<placeholder>' --allocated-storage 20
An error occurred (InternalFailure) when calling the CreateDBInstance operation: API for service 'rds' not yet implemented or pro feature
```

On real AWS the same call returns a `DBInstance` in status `creating`, then `available` after ~5–10 minutes, with `Endpoint.Address = s18-pg.xxxx.ap-south-1.rds.amazonaws.com:5432`.

### Security
* **Network**: instance in private subnets (DB subnet group), `PubliclyAccessible = false`, security group that allows the engine port **only from the application's security group**.
* **Auth**: master password in Secrets Manager with automatic rotation, or **IAM database authentication** (15-minute tokens instead of passwords).
* **Encryption**: at rest with KMS (must be chosen at creation; snapshots and replicas inherit it), in transit with TLS (`rds.force_ssl=1` on PostgreSQL).
* **Audit**: engine logs to CloudWatch, CloudTrail for API calls.

### Backups
* **Automated backups**: daily snapshot + transaction logs, retention 1–35 days, enabling **point-in-time restore** to any second in the window.
* **Manual snapshots**: kept until I delete them, can be copied across regions/accounts and shared.
* A restore always creates a **new instance**; there is no in-place restore – plan the DNS switch.

### Multi-AZ
A synchronous standby copy in another Availability Zone. Writes are committed on both before being acknowledged; on failure of the primary (or AZ, or during patching) RDS flips the endpoint DNS to the standby in ~60–120 s. The standby is **not readable** (except in the newer "Multi-AZ DB cluster" mode with two readable standbys). It is for **availability**, not for scaling.

### Read replicas
Asynchronous copies (same region or cross-region, up to 15 for Aurora, 5 for others) with **their own endpoints** that serve `SELECT` traffic. They are for **read scaling** and reporting; they lag by milliseconds to seconds, and a replica can be promoted to a standalone primary for disaster recovery or migrations.

```text
                     writes                              reads
   application ───────────────▶ primary (AZ a) ──sync──▶ standby (AZ b)      Multi-AZ: availability
                                   │
                                   └──async──▶ read replica 1 ◀──── reporting / dashboards
                                   └──async──▶ read replica 2 ◀──── API read traffic
```

### Use cases
| Use case | Why RDS fits |
|---|---|
| Transactional web apps (orders, users, bookings) | SQL + ACID + ORMs/migrations (SQLAlchemy + Alembic) |
| Reporting / BI over relational data | read replicas, joins, aggregates |
| Lift-and-shift of an on-prem Oracle/SQL Server | same engine, managed |
| Multi-tenant SaaS | schemas per tenant, row-level security in PostgreSQL |
| Anything needing complex queries you cannot predict up front | the opposite of DynamoDB's "know your access pattern" rule |

---

## DynamoDB vs RDS – how I decide

| | DynamoDB | RDS |
|---|---|---|
| Model | key-value / document, schema per item | relational, fixed schema |
| Query | by key / index only; no joins | arbitrary SQL, joins, aggregates |
| Scaling | automatic, horizontal, effectively unlimited | vertical (bigger instance) + read replicas |
| Ops | zero (serverless) | low (managed), but instances, maintenance windows, storage still exist |
| Latency | single-digit ms at any scale | ms, depends on query and instance |
| Consistency | eventual by default, strong on request, transactions available | ACID always |
| Cost shape | per request + storage; scales to zero | per instance-hour even when idle |
| Pick when | access patterns are known and key-based, huge scale or serverless | relationships, ad-hoc queries, existing SQL app |

## What I understood

* DynamoDB's **partition key + sort key** is the entire design: get it right and every query is one cheap `Query`; get it wrong and I am doing `Scan`s or redesigning the table.
* RDS gives me PostgreSQL **without being a DBA**: Multi-AZ answers "what if the server dies", read replicas answer "what if reads outgrow one box", automated backups answer "what if I drop a table", and none of those required me to install anything.
* The two are not competitors so much as answers to different questions, and a real system (like the capstone) often uses RDS for the core data and DynamoDB for sessions/counters/events next to it.
