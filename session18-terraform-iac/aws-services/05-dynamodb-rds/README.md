# AWS Database Services: DynamoDB (NoSQL) vs RDS (Relational)

**Author:** Durga Prasad  
**Enrollment Number:** 10012  
**Session:** 18 - AWS Cloud & Infrastructure as Code  
**Course:** SST DevOps & Cloud  

---

## 1. Architectural Comparison Overview

Modern cloud architectures select database engines based on data structure, consistency requirements, access patterns, and scaling models:

| Feature | Amazon DynamoDB (NoSQL) | Amazon RDS (Relational) |
|---|---|---|
| **Data Model** | Key-Value & Document (JSON) | Relational (SQL Tables, Schemas, Foreign Keys) |
| **Scalability** | Horizontal (Automatic partitioning, infinite scale) | Vertical (Compute instance scaling) + Read Replicas |
| **Latency** | Single-digit millisecond latency at any scale | Low millisecond (Dependent on query complexity & joins) |
| **Maintenance** | Fully Serverless (Zero patching, zero provisioning) | Managed (AWS handles OS/DB patching, backups, Multi-AZ) |
| **Query Mechanism**| Key lookups, Queries on Partition/Sort key, Scans | Complex SQL queries, Multi-table JOINs, Aggregations |
| **High Availability**| Built-in across 3 AZs natively | Multi-AZ standby replica with automated failover |

---

## 2. Amazon DynamoDB Deep Dive

**Amazon DynamoDB** is a fully managed, serverless, key-value NoSQL database designed to run high-performance applications at any scale.

### Core Data Modeling Concepts:
* **Tables:** Collections of items (analogous to SQL tables).
* **Items:** A collection of attributes. Each item is uniquely identified by its primary key (analogous to rows).
* **Attributes:** Fundamental data element (analogous to columns). Schema-less: items in the same table can have different attributes.
* **Primary Key Types:**
  1. **Partition Key (Hash Key):** A single attribute used to distribute items across physical partitions.
  2. **Composite Primary Key (Partition Key + Sort Key / Range Key):** Allows multiple items to share the same partition key while ordered by sort key (e.g., `UserId` [Partition] + `Timestamp` [Sort]).
* **Secondary Indexes:**
  - **Global Secondary Index (GSI):** An index with a partition key and sort key that can be different from those on the table.
  - **Local Secondary Index (LSI):** An index that has the same partition key as the table, but a different sort key.
* **Capacity Modes:**
  - **On-Demand:** Automatically handles spiky workloads without capacity planning (pay-per-request).
  - **Provisioned:** Specify Read Capacity Units (RCUs) and Write Capacity Units (WCUs) for predictable traffic.

### Best Use Cases:
* Session stores, shopping carts, gaming leaderboards, real-time IoT telemetry, mobile app user profiles.

---

## 3. Amazon Relational Database Service (RDS) Deep Dive

**Amazon RDS** simplifies the setup, operation, and scaling of relational databases in the cloud.

### Supported Database Engines:
1. **Amazon Aurora** (AWS-engineered high-throughput MySQL/PostgreSQL compatible)
2. **PostgreSQL**
3. **MySQL**
4. **MariaDB**
5. **Oracle**
6. **Microsoft SQL Server**

### High Availability: Multi-AZ Deployments
* Synchronously replicates data to a standby instance in a different Availability Zone.
* If the primary instance fails, AWS automatically triggers DNS failover to the standby in ~60–120 seconds with zero data loss.

```text
              PRIMARY AZ                              STANDBY AZ
      ┌─────────────────────────┐             ┌─────────────────────────┐
      │   Primary DB Instance   │             │   Standby DB Instance   │
      │   (Read / Write)        │             │   (Hot Standby)         │
      │   IP: 10.0.10.50        ├────────────►│   (Automatic Failover)  │
      └─────────────────────────┘ Synchronous └─────────────────────────┘
                                  Replication
```

### Read Scaling: Read Replicas
* Asynchronously replicates updates from primary to up to 15 read replicas.
* Offloads read-heavy analytical and reporting queries from the primary write instance.

### Automated Backups & Point-In-Time Recovery (PITR)
* Daily automated snapshot storage in S3 + continuous transaction log capture.
* Restores database state to any specific second within retention period (1 to 35 days).

### Best Use Cases:
* Financial transactions, ERP/CRM platforms, applications requiring complex SQL joins and strict ACID compliance.
