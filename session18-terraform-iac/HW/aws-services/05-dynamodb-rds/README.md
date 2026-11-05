# AWS Database Services: DynamoDB & RDS

**Name:** Smit Rupani  
**Enrollment:** 24bcs10256  

---

## 1. Amazon DynamoDB (NoSQL)
DynamoDB is a fully managed, serverless, key-value and document database that delivers single-digit millisecond performance at any scale.
- **Data Model:** Tables contain Items (rows); Items contain Attributes (columns). Schema is dynamic per item.
- **Primary Keys:**
  - *Partition Key (Hash):* Determines the internal partition where data is stored.
  - *Sort Key (Range):* Stores items with the same partition key close together in sorted order.
- **Use Cases:** Mobile backends, gaming leaderboards, IoT sensor streams, e-commerce shopping carts.

---

## 2. Amazon Relational Database Service (RDS)
Amazon RDS simplifies the setup, operation, and scaling of relational databases in the cloud.
- **Supported Engines:** PostgreSQL, MySQL, MariaDB, Oracle, Microsoft SQL Server, and Amazon Aurora.
- **Multi-AZ Deployments:** High availability via synchronous standby replica in a different Availability Zone with automated failover.
- **Read Replicas:** Asynchronous read copies used to offload read-heavy reporting workloads.
- **Automated Backups:** Daily snapshots and point-in-time recovery down to the second.
- **Use Cases:** Traditional enterprise apps, transactional accounting systems, ERPs, CRM platforms.
