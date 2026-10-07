# 05 — DynamoDB & RDS (Database Services)

> **NoSQL and Relational Databases on AWS**

---

## Part 1 — DynamoDB (NoSQL)

### What is DynamoDB?

Amazon **DynamoDB** is a fully managed, serverless **NoSQL** database service. It delivers single-digit millisecond performance at any scale.

**Key characteristics:**
- **Serverless** — no servers to manage
- **Scales automatically** — from 1 request/sec to millions
- **Multi-region** (Global Tables)
- **Millisecond latency** at any scale
- **Built-in security** — IAM, encryption at rest

---

### NoSQL vs SQL

| Feature | DynamoDB (NoSQL) | RDS (SQL) |
|---|---|---|
| Schema | Flexible (schemaless) | Fixed schema |
| Scaling | Horizontal (automatic) | Vertical (manual) |
| Queries | Key-based | SQL joins, complex queries |
| Consistency | Eventually consistent (default) | ACID transactions |
| Use Case | High-throughput, simple access patterns | Complex relationships, reporting |

---

### Tables

A **Table** is the top-level container for data in DynamoDB. Each table stores **Items** (equivalent to rows in SQL).

```
Table: Users
  ├── Item: { userId: "u001", name: "Shivansh", email: "s@example.com", age: 22 }
  ├── Item: { userId: "u002", name: "Priya", email: "p@example.com", city: "Mumbai" }
  └── Item: { userId: "u003", name: "Raj", role: "admin" }
```

> Notice: Items can have **different attributes** — no fixed schema!

---

### Items

An **Item** is a single record in a DynamoDB table (like a row in SQL).

- Each item is identified by its **Primary Key**
- Items can have any number of attributes
- Max item size: **400 KB**

---

### Attributes

An **Attribute** is a data element within an item (like a column in SQL).

| DynamoDB Type | Example |
|---|---|
| String (S) | `"Shivansh"` |
| Number (N) | `22` |
| Boolean (BOOL) | `true` |
| List (L) | `["admin", "developer"]` |
| Map (M) | `{ "city": "Pune", "country": "IN" }` |
| Binary (B) | Binary data |

---

### Partition Key (Hash Key)

The **Partition Key** uniquely identifies each item and determines which partition it is stored on.

```
Table: Orders
  Partition Key: orderId (String)

  orderId   │  product     │  price  │  status
  ──────────┼──────────────┼─────────┼──────────
  "ord-001" │  "Laptop"    │  999    │  "shipped"
  "ord-002" │  "Mouse"     │  25     │  "pending"
```

- Must be **unique** for each item (if no sort key)
- Distributes data evenly across partitions

---

### Sort Key (Range Key)

The **Sort Key** (optional) combined with the Partition Key forms a **composite primary key**. Multiple items can share the same partition key but must have different sort keys.

```
Table: UserOrders
  Partition Key: userId
  Sort Key:      orderId

  userId  │  orderId   │  product    │  amount
  ────────┼────────────┼─────────────┼─────────
  "u001"  │  "ord-001" │  "Laptop"   │  999
  "u001"  │  "ord-002" │  "Mouse"    │  25
  "u001"  │  "ord-003" │  "Keyboard" │  75
  "u002"  │  "ord-004" │  "Monitor"  │  350
```

Query: "Get all orders for user u001" → fast, efficient!

---

### DynamoDB Use Cases

| Use Case | Why DynamoDB |
|---|---|
| Session storage | High read/write throughput |
| Shopping cart | Flexible schema, low latency |
| Leaderboards/gaming | Single-digit ms at scale |
| IoT telemetry | High-volume writes |
| User profiles | Schemaless flexibility |
| Real-time notifications | Event-driven with DynamoDB Streams |

---

### DynamoDB CLI Commands

```bash
# Create a table
aws dynamodb create-table \
  --table-name Users \
  --attribute-definitions AttributeName=userId,AttributeType=S \
  --key-schema AttributeName=userId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# Put an item
aws dynamodb put-item \
  --table-name Users \
  --item '{"userId": {"S": "u001"}, "name": {"S": "Shivansh"}, "age": {"N": "22"}}'

# Get an item
aws dynamodb get-item \
  --table-name Users \
  --key '{"userId": {"S": "u001"}}'

# Scan the table
aws dynamodb scan --table-name Users

# Delete a table
aws dynamodb delete-table --table-name Users
```

---
---

## Part 2 — RDS (Relational Database Service)

### What is RDS?

Amazon **RDS** is a fully managed **relational database** service. It automates database administration tasks like provisioning, patching, backups, and recovery.

---

### Supported Engines

| Engine | Version |
|---|---|
| **MySQL** | 5.7, 8.0 |
| **PostgreSQL** | 12, 13, 14, 15 |
| **MariaDB** | 10.x |
| **Oracle** | 12c, 19c |
| **SQL Server** | 2019, 2022 |
| **Amazon Aurora** | MySQL/PostgreSQL compatible |

---

### DB Instances

A **DB Instance** is an isolated database environment running in the cloud.

```
DB Instance: my-prod-db
  Engine:     PostgreSQL 15.3
  Class:      db.t3.medium
  Storage:    100 GB gp3 SSD
  Multi-AZ:   Yes
  Region:     ap-south-1
```

| Instance Class | Use Case |
|---|---|
| `db.t3.micro` | Dev/test (free tier) |
| `db.t3.medium` | Small production |
| `db.r6g.large` | Memory-optimised production |
| `db.m6i.4xlarge` | High-traffic production |

---

### Security

| Security Layer | Mechanism |
|---|---|
| Network | VPC private subnet, Security Groups |
| Authentication | Username/password or IAM DB authentication |
| Encryption at rest | AWS KMS |
| Encryption in transit | SSL/TLS |
| Audit logs | CloudWatch Logs |

**Best practice:** Always place RDS in a **private subnet** — never expose it directly to the internet.

---

### Backups

| Type | Description | Retention |
|---|---|---|
| **Automated Backups** | Daily full backup + transaction logs | 1–35 days |
| **DB Snapshots** | Manual, point-in-time backups | Indefinitely |
| **Point-in-time Recovery** | Restore to any second in retention window | Within retention period |

```bash
# Create a manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier my-prod-db \
  --db-snapshot-identifier my-prod-db-snapshot-20240101
```

---

### Multi-AZ (High Availability)

**Multi-AZ** creates a synchronous **standby replica** in a different Availability Zone.

```
Primary DB (ap-south-1a)
       │ sync replication
Standby DB (ap-south-1b)  ← automatic failover if primary fails
```

- Automatic failover (60–120 seconds)
- No manual intervention needed
- Used for **high availability**, not read scaling

---

### Read Replicas (Scalability)

**Read Replicas** are asynchronous read-only copies of the primary DB.

```
Primary DB (writes) → Read Replica 1 (reads — Asia)
                    → Read Replica 2 (reads — Europe)
                    → Read Replica 3 (reads — US)
```

- Up to 5 read replicas per primary
- Used for **read scaling**, not high availability
- Can be promoted to standalone DB

---

### RDS Use Cases

| Use Case | Why RDS |
|---|---|
| E-commerce platform | Complex SQL queries, ACID transactions |
| CMS/Blog | MySQL/PostgreSQL + managed backups |
| Analytics | Read replicas for reporting queries |
| Financial systems | Multi-AZ + encryption + audit logs |
| SaaS applications | Aurora (auto-scaling, serverless option) |

---

### RDS CLI Commands

```bash
# Create a PostgreSQL RDS instance
aws rds create-db-instance \
  --db-instance-identifier my-prod-db \
  --db-instance-class db.t3.medium \
  --engine postgres \
  --master-username admin \
  --master-user-password SecurePassword123 \
  --allocated-storage 20

# List all DB instances
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]' \
  --output table

# Create a snapshot
aws rds create-db-snapshot \
  --db-instance-identifier my-prod-db \
  --db-snapshot-identifier my-snapshot

# Delete a DB instance (with final snapshot)
aws rds delete-db-instance \
  --db-instance-identifier my-prod-db \
  --final-db-snapshot-identifier my-final-snapshot
```

---

## DynamoDB vs RDS — When to Use Which

| Scenario | Use |
|---|---|
| Need SQL queries and JOINs | ✅ RDS |
| Need ACID compliance | ✅ RDS |
| Need horizontal auto-scaling | ✅ DynamoDB |
| Schema changes frequently | ✅ DynamoDB |
| Need ms latency at massive scale | ✅ DynamoDB |
| Complex reporting/analytics | ✅ RDS |
| Simple key-value access pattern | ✅ DynamoDB |
| Legacy application migration | ✅ RDS |
