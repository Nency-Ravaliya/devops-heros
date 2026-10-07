# 03 — S3 (Simple Storage Service)

> **Object Storage at Any Scale**

---

## What is S3?

Amazon S3 (Simple Storage Service) is AWS's **object storage** service. It stores any type of data — images, videos, backups, logs, Terraform state files, static websites — at virtually unlimited scale.

**Key characteristics:**
- **99.999999999% (11 9s) durability**
- **99.99% availability**
- Globally unique bucket names
- Pay for what you store

---

## Core S3 Concepts

### 🪣 Buckets

A **Bucket** is a top-level container for objects. Think of it like a folder in the cloud.

```
Bucket: devops553-session18-terraform-demo
  ├── logs/app-2024-01-01.log
  ├── uploads/profile.jpg
  └── backups/db-backup-20240101.sql.gz
```

- Bucket names must be **globally unique** across all AWS accounts
- Created in a specific AWS region
- Can hold unlimited objects

---

### 📦 Objects

An **Object** is a file stored in a bucket. Each object has:
- **Key** — the full path/name of the object (e.g. `logs/app.log`)
- **Value** — the actual data (up to 5TB per object)
- **Metadata** — key-value pairs (content-type, custom tags)
- **Version ID** — if versioning is enabled

```bash
# Upload an object
aws s3 cp app.log s3://my-bucket/logs/app.log

# Download an object
aws s3 cp s3://my-bucket/logs/app.log ./app.log

# List objects
aws s3 ls s3://my-bucket/logs/
```

---

### 🗃️ Storage Classes

| Storage Class | Use Case | Retrieval | Cost |
|---|---|---|---|
| **S3 Standard** | Frequently accessed data | Instant | Highest |
| **S3 Standard-IA** | Infrequently accessed | Instant | Lower |
| **S3 One Zone-IA** | Non-critical, infrequent | Instant | Lower |
| **S3 Glacier Instant** | Archives, fast retrieval | Milliseconds | Low |
| **S3 Glacier Flexible** | Archives, minutes retrieval | Minutes–Hours | Very Low |
| **S3 Glacier Deep Archive** | Long-term archives (7+ years) | Up to 12 hours | Lowest |
| **S3 Intelligent-Tiering** | Unknown access patterns | Instant | Auto-optimised |

---

### 🔄 Versioning

**Versioning** keeps multiple versions of an object, protecting against accidental deletion or overwrites.

```bash
# Enable versioning
aws s3api put-bucket-versioning \
  --bucket my-bucket \
  --versioning-configuration Status=Enabled

# List all versions
aws s3api list-object-versions --bucket my-bucket
```

With versioning enabled:
- Deleted objects get a **delete marker** (not permanently deleted)
- Previous versions can be restored
- Storage costs increase (multiple versions stored)

---

### ♻️ Lifecycle Policies

**Lifecycle policies** automatically transition objects between storage classes or expire them.

```json
{
  "Rules": [
    {
      "ID": "MoveToGlacierAfter90Days",
      "Status": "Enabled",
      "Transitions": [
        { "Days": 30,  "StorageClass": "STANDARD_IA" },
        { "Days": 90,  "StorageClass": "GLACIER" }
      ],
      "Expiration": { "Days": 365 }
    }
  ]
}
```

**Typical lifecycle:**
```
Day 0   → S3 Standard    (active use)
Day 30  → S3 Standard-IA (access drops)
Day 90  → S3 Glacier     (archival)
Day 365 → Delete         (expired)
```

---

### 🔐 Encryption

| Type | Description |
|---|---|
| **SSE-S3** | AWS manages keys (default) |
| **SSE-KMS** | AWS KMS manages keys (audit trail) |
| **SSE-C** | You provide and manage your own keys |
| **Client-side** | Encrypt before uploading |

```bash
# Upload with SSE-KMS encryption
aws s3 cp file.txt s3://my-bucket/ --sse aws:kms
```

---

### 📜 Bucket Policies

**Bucket policies** are JSON documents that control access to the bucket and its objects.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-public-bucket/*"
    }
  ]
}
```

| Policy Use Case | Effect |
|---|---|
| Public read (static website) | Allow `s3:GetObject` to `*` |
| Block all public access | Deny `s3:*` to `*` |
| Allow specific IAM role only | Allow specific `Principal` ARN |
| Cross-account access | Trust another account's users |

---

## Common Use Cases

| Use Case | S3 Feature |
|---|---|
| Static website hosting | Public bucket + website config |
| Terraform remote state | Private bucket + versioning |
| Application backups | Lifecycle to Glacier |
| CI/CD artifact storage | Private bucket + IAM role access |
| Log archiving | Lifecycle to Glacier Deep Archive |
| Media storage (images/video) | S3 Standard + CloudFront CDN |

---

## Key CLI Commands

```bash
# Create a bucket
aws s3 mb s3://my-unique-bucket-name --region ap-south-1

# Upload a file
aws s3 cp file.txt s3://my-bucket/

# Sync a directory
aws s3 sync ./dist s3://my-bucket/

# List buckets
aws s3 ls

# List objects in a bucket
aws s3 ls s3://my-bucket/ --recursive

# Delete an object
aws s3 rm s3://my-bucket/file.txt

# Delete a bucket (must be empty first)
aws s3 rb s3://my-bucket --force
```
