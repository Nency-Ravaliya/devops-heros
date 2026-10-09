# AWS Database Services: DynamoDB & RDS

## Part 1: Amazon DynamoDB (NoSQL)

### 1. What is DynamoDB?
**Amazon DynamoDB** is a fully managed, serverless, key-value and document NoSQL database designed for single-digit millisecond performance at any scale.

### 2. Core Concepts
* **Tables:** Collections of data items (equivalent to tables in SQL).
* **Items:** A single record within a table, composed of attributes (equivalent to rows).
* **Attributes:** Fundamental data element (equivalent to columns, but schema-less per item).
* **Primary Keys:**
  * **Partition Key (Hash Key):** Single attribute used by DynamoDB's internal hash function to distribute items across physical partitions.
  * **Sort Key (Range Key):** Optional second attribute storing items with the same partition key in sorted order.
* **Common Use Cases:**
  * High-concurrency web apps (shopping carts, user session state).
  * Gaming leaderboards and real-time bidding systems.
  * Terraform state locking (`LockID` attribute).

---

## Part 2: Amazon RDS (Relational Database Service)

### 1. What is Amazon RDS?
**Amazon Relational Database Service (Amazon RDS)** makes it easy to set up, operate, and scale a relational database in the cloud with automated provisioning, patching, and backups.

### 2. Core Concepts
* **Supported Engines:** PostgreSQL, MySQL, MariaDB, Oracle Database, Microsoft SQL Server, and Amazon Aurora.
* **DB Instances:** An isolated database environment in the cloud running selected CPU, RAM, and storage configurations.
* **Security:** Deployed inside private subnets, controlled by Security Groups, and encrypted at rest using AWS KMS.
* **Automated Backups:** Point-in-time recovery (PITR) within a configurable retention window (1 to 35 days).
* **Multi-AZ Deployment:** Synchronous replication to a standby instance in a different Availability Zone for high availability and automated failover.
* **Read Replicas:** Asynchronous read-only copies used to offload read-heavy traffic from the primary DB instance.

---

## 3. Comparison Summary

| Feature | Amazon DynamoDB | Amazon RDS |
|---|---|---|
| **Data Model** | NoSQL (Key-Value / Document) | Relational (SQL) |
| **Schema** | Flexible / Dynamic Schema | Rigid Relational Schema |
| **Scalability** | Horizontal (Auto-partitioning) | Vertical (Compute) & Read Replicas |
| **Latency** | Single-digit millisecond | Single-digit millisecond to second |
| **Maintenance** | Serverless (Zero maintenance) | Managed instances (Maintenance windows) |
