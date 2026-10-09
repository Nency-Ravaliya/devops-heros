# AWS S3 (Simple Storage Service) - Storage

## 1. What is S3?
**Amazon Simple Storage Service (Amazon S3)** is an object storage service offering industry-leading scalability, data availability, security, and 99.999999999% (11 9s) of data durability.

---

## 2. Core S3 Concepts

* **Buckets:** Top-level containers for objects. Bucket names must be **globally unique** across all AWS accounts worldwide.
* **Objects:** Fundamental entities stored in S3 consisting of data bytes, a key (filename/path), and metadata (tags, headers).
* **Storage Classes:**
  * **S3 Standard:** High frequency access, low latency.
  * **S3 Standard-IA (Infrequent Access):** Lower storage cost, small retrieval fee.
  * **S3 Intelligent-Tiering:** Automatically moves objects across tiers based on access patterns.
  * **S3 Glacier & Glacier Deep Archive:** Extremely cheap long-term cold storage for compliance backups.
* **Versioning:** Preserves, retrieves, and restores every version of every object, protecting against accidental deletes or overwrites.
* **Lifecycle Policies:** Automated rules transitioning objects across tiers (e.g. Standard to Glacier after 90 days) or expiring old versions.
* **Encryption:** Server-Side Encryption using Amazon S3 managed keys (SSE-S3) or AWS KMS keys (SSE-KMS).
* **Bucket Policies:** JSON-based access policies attached directly to the bucket controlling permissions for cross-account users or public access.

---

## 3. Common Use Cases
* Static website hosting (HTML, CSS, JS assets).
* Centralized backup and disaster recovery target for database snapshots.
* Data lake storage for analytics pipelines (Athena, EMR, Snowflake).
* Hosting Terraform remote state files with state locking via DynamoDB.
