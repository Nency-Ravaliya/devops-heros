# 03 · S3 — Simple Storage Service (Storage)

## What is S3?

**Amazon S3** is **object storage** with virtually unlimited capacity, accessed over HTTPS through an API.

- Designed for **99.999999999% (11 nines) durability**. Data is stored redundantly across at least 3 Availability Zones (except One Zone classes).
- Pay for what you store, the requests you make, and data transferred out. There is nothing to provision.
- It is **not** a file system or a block device. You `PUT` and `GET` whole objects by key.
- Since December 2020 it has **strong read-after-write consistency** for all operations.

```text
 S3 (regional service)
 └── Bucket: anuskaroy-session18-tf-demo     (globally unique name, lives in one region)
     ├── index.html                          ← object (key = "index.html")
     ├── images/logo.png                     ← object (key = "images/logo.png")
     └── logs/2026/10/07/app.log             ← "folders" are just key prefixes
```

| | S3 (object) | EBS (block) | EFS (file) |
|---|---|---|---|
| Access | HTTP API | attached to 1 EC2 (mostly) | NFS mount, many EC2 |
| Scale | unlimited | up to 64 TiB per volume | elastic |
| Typical use | backups, static assets, data lakes | OS disks, databases | shared file storage |

## Buckets

A **bucket** is a container for objects.

- The name must be **globally unique across all AWS accounts**: 3–63 characters, lowercase letters, numbers, `.` and `-`, and it must start and end with a letter or number.
- A bucket is created in a **specific region** and data stays there unless you replicate it.
- There is a default soft limit of 10,000 buckets per account (it can be raised).
- **Block Public Access** is **on by default** for new buckets, and ACLs are disabled by default (*Bucket owner enforced*).
- Addressed as `https://<bucket>.s3.<region>.amazonaws.com/<key>` or `s3://<bucket>/<key>`.

## Objects

An **object** is the stored data plus metadata.

| Part | Description |
|---|---|
| **Key** | the full name/path, e.g. `images/logo.png` |
| **Value** | the data, from 0 bytes up to **50 TB** (raised from 5 TB in December 2025) |
| **Version ID** | present when versioning is enabled |
| **Metadata** | system (`Content-Type`, `Last-Modified`, `ETag`) and user-defined (`x-amz-meta-*`) |
| **Tags** | up to 10 key/value pairs, used by lifecycle rules, IAM and cost reports |

- A single `PUT` uploads up to 5 GB. Use **multipart upload** for anything over about 100 MB (required above 5 GB). The CLI does this automatically.
- **Pre-signed URLs** grant time-limited access to a private object without sharing credentials.

```bash
aws s3 cp app.log s3://my-bucket/logs/app.log
aws s3 presign s3://my-bucket/logs/app.log --expires-in 3600
```

## Storage classes

| Class | Availability target | AZs | Min. duration | Retrieval | Use for |
|---|---|---|---|---|---|
| **S3 Standard** | 99.99% | ≥3 | – | ms | frequently accessed data (default) |
| **S3 Intelligent-Tiering** | 99.9% | ≥3 | – | ms (archive tiers optional) | unknown or changing access patterns |
| **S3 Standard-IA** | 99.9% | ≥3 | 30 days | ms, per-GB retrieval fee | infrequent but fast access, e.g. backups |
| **S3 One Zone-IA** | 99.5% | **1** | 30 days | ms | re-creatable infrequent data |
| **S3 Express One Zone** | 99.95% | **1** | – | single-digit ms | latency-critical, high-request workloads |
| **S3 Glacier Instant Retrieval** | 99.9% | ≥3 | 90 days | ms | archives accessed about once a quarter |
| **S3 Glacier Flexible Retrieval** | 99.99% | ≥3 | 90 days | minutes to 12 h | archives, backups |
| **S3 Glacier Deep Archive** | 99.99% | ≥3 | 180 days | 12–48 h | compliance retention for 7–10+ years, cheapest |

All classes are designed for the same 11-nines durability, but One Zone-IA and Express One Zone keep data in a single AZ, so it can be lost if that AZ is destroyed. Cost drops and retrieval time grows as you move down the table.

## Versioning

**Versioning** keeps every version of an object in the bucket.

- Bucket states: *Unversioned* (default) → *Enabled* → *Suspended*. Once enabled, versioning **cannot be turned off**, only suspended.
- Overwriting an object creates a new version. **Deleting** an object adds a **delete marker**, and the old versions remain and can be restored.
- It protects against accidental overwrites and deletes, and is **required** for replication (CRR/SRR).
- **MFA Delete** can require MFA to permanently delete a version.
- Every version is billed, so pair versioning with lifecycle rules that expire old versions.

```bash
aws s3api put-bucket-versioning --bucket my-bucket --versioning-configuration Status=Enabled
aws s3api list-object-versions --bucket my-bucket --prefix index.html
```

## Lifecycle policies

**Lifecycle rules** automatically **transition** objects to cheaper storage classes or **expire** (delete) them based on age. A rule can be filtered by prefix and/or tags.

```text
Day 0 ── Standard ──► Day 30 ── Standard-IA ──► Day 90 ── Glacier Flexible ──► Day 365 ── delete
```

```json
{
  "Rules": [{
    "ID": "logs-tiering",
    "Filter": { "Prefix": "logs/" },
    "Status": "Enabled",
    "Transitions": [
      { "Days": 30, "StorageClass": "STANDARD_IA" },
      { "Days": 90, "StorageClass": "GLACIER" }
    ],
    "Expiration": { "Days": 365 },
    "NoncurrentVersionExpiration": { "NoncurrentDays": 30 },
    "AbortIncompleteMultipartUpload": { "DaysAfterInitiation": 7 }
  }]
}
```

## Encryption

**In transit:** HTTPS (TLS). You can enforce it with a bucket policy condition `aws:SecureTransport = false → Deny`.

**At rest:** all new objects are encrypted automatically (SSE-S3 is the default since January 2023).

| Option | Who manages keys | Notes |
|---|---|---|
| **SSE-S3** | AWS (S3-owned AES-256 keys) | default, no extra cost |
| **SSE-KMS** | AWS KMS (AWS managed or customer managed key) | key policies, CloudTrail audit of key use, enable **Bucket Keys** to cut KMS cost |
| **DSSE-KMS** | KMS, two layers | dual-layer encryption for compliance |
| **SSE-C** | you supply the key with each request | AWS never stores the key. **Blocked by default** on new buckets since April 2026; enable it explicitly if needed |
| **Client-side** | you encrypt before upload | S3 only ever sees ciphertext |

## Bucket policies

A **bucket policy** is a **resource-based** JSON policy attached to the bucket. It controls who can access the bucket and its objects, **including other accounts and anonymous users**.

Within the same account, access is granted if an IAM policy **or** the bucket policy allows it (cross-account access needs **both**), and no explicit `Deny` exists in either. **Block Public Access** overrides any policy that would make data public.

Deny any request that is not over HTTPS:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyInsecureTransport",
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"],
    "Condition": { "Bool": { "aws:SecureTransport": "false" } }
  }]
}
```

Allow a CloudFront distribution (OAC) to read objects:
```json
{
  "Effect": "Allow",
  "Principal": { "Service": "cloudfront.amazonaws.com" },
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::my-bucket/*",
  "Condition": { "StringEquals": { "AWS:SourceArn": "arn:aws:cloudfront::111122223333:distribution/EDFDVBD6EXAMPLE" } }
}
```

## Other notable features

- **Replication** (CRR across regions, SRR within a region) for DR and compliance.
- **Static website hosting**, usually fronted by CloudFront.
- **Event notifications** to Lambda, SQS, SNS or EventBridge on object create or delete.
- **Object Lock** (WORM) in governance or compliance mode for regulatory retention.
- **Access Points** give a separate policy per application on a shared bucket.
- **Athena** queries CSV, JSON or Parquet in place (S3 Select is closed to new customers since July 2024).
- **Transfer Acceleration** speeds up long-distance uploads using edge locations.

## Common use cases

| Use case | Typical setup |
|---|---|
| Backup and restore | versioning + lifecycle to Glacier |
| Static website / SPA | S3 + CloudFront (OAC) + ACM certificate |
| Data lake | raw/processed/curated prefixes, queried with Athena, Glue or EMR |
| Application assets and user uploads | pre-signed URLs, event → Lambda for thumbnails |
| Log archive | ALB, CloudTrail and VPC Flow Logs delivered to S3 |
| **Terraform remote state** | versioned, encrypted bucket with S3-native state locking (`use_lockfile = true`) |
| Disaster recovery | cross-region replication |
| Artifact repository | CI build outputs, Lambda deployment packages |

## Terraform example

```hcl
resource "aws_s3_bucket" "demo" {
  bucket = "anuskaroy-session18-tf-demo"
}

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "aws:kms" }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "demo" {
  bucket                  = aws_s3_bucket.demo.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

The hands-on version is in [../../terraform-s3-demo](../../terraform-s3-demo).

## Useful CLI commands

```bash
aws s3 mb s3://my-bucket --region ap-south-1     # make bucket
aws s3 ls                                        # list buckets
aws s3 ls s3://my-bucket --recursive             # list objects
aws s3 cp file.txt s3://my-bucket/               # upload
aws s3 sync ./site s3://my-bucket/ --delete      # mirror a folder
aws s3 rm s3://my-bucket --recursive             # empty a bucket
aws s3 rb s3://my-bucket                         # remove bucket
```
