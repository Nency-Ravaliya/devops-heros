# Amazon Simple Storage Service (S3) — Object Storage Engineering Guide

**Author:** Durga Prasad  
**Enrollment Number:** 10012  
**Session:** 18 - AWS Cloud & Infrastructure as Code  
**Course:** SST DevOps & Cloud  

---

## 1. What is Amazon S3?

**Amazon Simple Storage Service (Amazon S3)** is an industry-leading object storage service offering 99.999999999% (11 9's) of data durability. Unlike block storage (EBS) or file storage (EFS), S3 stores data as objects within buckets accessible globally over standard HTTP/HTTPS REST APIs.

---

## 2. Core S3 Architectural Concepts

```text
                               AMAZON S3 ARCHITECTURE
                               
     ┌──────────────────────────────────────────────────────────────────┐
     │                      Amazon S3 Global Namespace                  │
     │                      Bucket: devops-heros-dp-prod-10012          │
     │                      Region: us-east-1                           │
     │                                                                  │
     │  ┌───────────────────┐  ┌───────────────────┐  ┌──────────────┐  │
     │  │ Object:           │  │ Object:           │  │ Versioning:  │  │
     │  │ /images/hero.png  │  │ /data/reports.csv │  │ v1: active   │  │
     │  │ Key + Value       │  │ Key + Value       │  │ v0: archive  │  │
     │  │ Metadata + ACL    │  │ Metadata + ACL    │  │ DelMarker    │  │
     │  └───────────────────┘  └───────────────────┘  └──────────────┘  │
     │                                                                  │
     │  ┌────────────────────────────────────────────────────────────┐  │
     │  │ S3 Lifecycle Policies:                                     │  │
     │  │ Day 0: S3 Standard ──► Day 30: Standard-IA ──► Day 90: Glacier│
     │  └────────────────────────────────────────────────────────────┘  │
     │  ┌────────────────────────────────────────────────────────────┐  │
     │  │ Security & Encryption: SSE-S3 / SSE-KMS / Block Public Acc │  │
     │  └────────────────────────────────────────────────────────────┘  │
     └──────────────────────────────────────────────────────────────────┘
```

### 1. Buckets & Objects
* **Bucket:** A top-level logical container for objects. Bucket names are **globally unique across all AWS customers worldwide** (DNS compliant, 3–63 characters).
* **Object:** The fundamental entity stored in S3, composed of:
  - **Key:** The unique string identifier / path (e.g. `logs/2026/app.log`).
  - **Value:** The binary data payload (up to 5 TB per individual object).
  - **Metadata:** Key-value pairs (e.g. `Content-Type: image/png`, user tags).
  - **Version ID:** Unique string when versioning is enabled.

### 2. S3 Storage Classes & Cost Optimization

| Storage Class | Designed For | Availability | Min Storage Duration | Retrieval Fee? |
|---|---|---|---|---|
| **S3 Standard** | Frequently accessed, low latency | 99.99% | None | No |
| **S3 Intelligent-Tiering** | Unknown or changing access patterns | 99.9% | None (Tiering fee) | No |
| **S3 Standard-IA** | Infrequent access, rapid retrieval | 99.9% | 30 days | Yes (per GB) |
| **S3 One Zone-IA** | Non-critical, recreatable backup data | 99.5% (Single AZ) | 30 days | Yes |
| **S3 Glacier Flexible** | Long-term archiving (retrieval: 1m–5h) | 99.99% | 90 days | Yes |
| **S3 Glacier Deep Archive**| Regulatory archives (retrieval: 12h) | 99.99% | 180 days | Yes (Lowest cost) |

### 3. S3 Versioning
Keeps multiple variants of an object in the same bucket.
* Protects against unintended overwrites and accidental deletions.
* A `DELETE` request places a **Delete Marker** on the object instead of permanently erasing data. To permanently delete, the specific Version ID must be targeted.

### 4. S3 Lifecycle Rules
Automated rules that transition objects across storage tiers or expire them after a defined number of days:
```text
Day 0: Upload to S3 Standard
Day 30: Transition to S3 Standard-IA
Day 90: Transition to S3 Glacier Flexible
Day 365: Expire / Delete Permanently
```

### 5. S3 Encryption
* **SSE-S3 (Default):** Server-Side Encryption with Amazon S3-Managed Keys (AES-256).
* **SSE-KMS:** Server-Side Encryption with AWS Key Management Service (offers audit trails and customer-managed keys).
* **SSE-C:** Server-Side Encryption with Customer-Provided Keys.
* **Client-Side Encryption:** Encrypted prior to uploading over TLS.

### 6. Bucket Policies vs ACLs
* **S3 Bucket Policy:** IAM-like JSON document attached directly to the bucket controlling permissions for all objects within it.
* **Block Public Access:** Account-wide and bucket-level master security setting that unconditionally blocks public read/write permissions regardless of bucket policies.

---

## 3. Common Use Cases

1. **Static Website Hosting:** Hosting static Single Page Applications (HTML, CSS, JS) backed by Amazon CloudFront CDN.
2. **Terraform Remote State Backend:** Storing `terraform.tfstate` with versioning enabled and DynamoDB state locking.
3. **Data Lakes & Big Data Analytics:** Raw storage layer for analytics engines (Amazon Athena, AWS Glue, EMR, Snowflake).
4. **Automated Backups & Disaster Recovery:** Nightly database snapshots and system image archiving.
