# AWS Simple Storage Service (S3) - Storage

**Name:** Smit Rupani  
**Enrollment:** 24bcs10256  

---

## 1. What is S3?
Amazon S3 is an object storage service offering industry-leading scalability, data availability, security, and performance (99.999999999% - 11 9's durability).

## 2. Core Concepts
- **Buckets:** Top-level containers for data with globally unique names across all AWS accounts.
- **Objects:** Fundamental entities stored in S3 consisting of file data and metadata.
- **Storage Classes:**
  - *S3 Standard:* High throughput, low latency for frequent access.
  - *S3 Intelligent-Tiering:* Automatically shifts data between tiers based on changing access patterns.
  - *S3 Standard-IA / One Zone-IA:* Infrequently accessed data requiring rapid retrieval.
  - *S3 Glacier / Glacier Deep Archive:* Ultra low-cost archival storage for compliance and audit logs.
- **Versioning:** Keeps multiple variants of an object in the same bucket to prevent accidental deletions or overwrites.
- **Lifecycle Policies:** Automated rules to transition objects to cheaper storage classes or expire them after N days.
- **Security & Encryption:** Server-Side Encryption (SSE-S3, SSE-KMS) and S3 Bucket Policies to control public/IAM access.
