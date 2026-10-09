# 03. S3 – Simple Storage Service (Storage)

## What is S3?
Amazon S3 is **object storage** with virtually unlimited capacity, designed for **11 nines (99.999999999%) durability**: data is stored redundantly across at least 3 AZs. You store files (objects) in containers (buckets) and access them over HTTPS through an API. There is no file system, so it can't be mounted like a disk. It's regional and pay-per-use (GB stored + requests + data out).

## Buckets
- Top-level container. The name is **globally unique** across all AWS accounts, DNS-compatible (3–63 chars, lowercase), and can't be renamed.
- Created in **one region**. A bucket holds an unlimited number of objects.
- Since April 2023, new buckets have **Block Public Access ON** and **ACLs disabled** (Bucket owner enforced) by default.
- In my Terraform demo the bucket name is `tejas-devops-heros-<random hex>` because names must be globally unique.

## Objects
- An object = **key** (full "path", e.g. `logs/2026/10/app.log`) + **data** (0 B to 5 TB) + **metadata** (content-type, user metadata) + optional **tags** (up to 10).
- The "folders" in the console are just key prefixes; the namespace is flat.
- Uploads over 100 MB should use **multipart upload**, which is required above 5 GB.
- **Strong read-after-write consistency** for all PUT/DELETE operations.
- Access: `https://<bucket>.s3.<region>.amazonaws.com/<key>`, `aws s3 cp`, SDKs, or **pre-signed URLs** for temporary access.

## Storage classes
| Class | Use | Retrieval |
|---|---|---|
| **S3 Standard** | Frequently accessed data | ms |
| **S3 Intelligent-Tiering** | Unknown/changing access patterns; moves objects between tiers automatically | ms |
| **Standard-IA** | Infrequent access, multi-AZ (min 30 days, retrieval fee) | ms |
| **One Zone-IA** | Re-creatable infrequent data, single AZ (cheaper, less resilient) | ms |
| **Glacier Instant Retrieval** | Archives accessed ~quarterly | ms |
| **Glacier Flexible Retrieval** | Archives, retrieval in minutes to hours | 1 min–12 h |
| **Glacier Deep Archive** | Long-term compliance archives (cheapest, min 180 days) | 12–48 h |
| **S3 Express One Zone** | Single-digit-ms latency for hot data (directory buckets) | <10 ms |

## Versioning
- A bucket-level setting: **Unversioned → Enabled → Suspended** (it can never go back to unversioned).
- Every overwrite creates a new **version ID**. A delete only adds a **delete marker**, so previous versions can be restored. This protects against accidental deletes and overwrites (and ransomware).
- Required for **replication** (CRR/SRR) and **Object Lock**. Every version is billed, so pair it with lifecycle rules for noncurrent versions.
- My Terraform demo enables it with `aws_s3_bucket_versioning`.

## Lifecycle policies
Rules (filtered by prefix or tag) that act automatically as objects age:
- **Transition** current or noncurrent versions to cheaper classes
- **Expire** (delete) objects or noncurrent versions
- Abort incomplete multipart uploads (saves hidden storage cost)

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.demo.id
  rule {
    id     = "logs-retention"
    status = "Enabled"
    filter { prefix = "logs/" }
    transition { days = 30  storage_class = "STANDARD_IA" }
    transition { days = 90  storage_class = "GLACIER" }
    expiration { days = 365 }
    noncurrent_version_expiration { noncurrent_days = 30 }
  }
}
```

## Encryption
- **In transit:** HTTPS/TLS. Enforce it with a bucket policy denying `aws:SecureTransport = false`.
- **At rest:** all new objects are encrypted automatically (since January 2023).
  - **SSE-S3** (AES-256, keys managed by S3). This is the default and what my demo sets explicitly.
  - **SSE-KMS:** your AWS KMS key, which adds key policies, CloudTrail audit of key use and rotation. Use an S3 Bucket Key to cut KMS cost.
  - **DSSE-KMS:** dual-layer, for strict compliance.
  - **SSE-C:** you supply the key with every request.
  - **Client-side encryption:** encrypt before uploading.

## Bucket policies
A resource-based JSON policy on the bucket, the main way to grant cross-account or public access and to enforce rules:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"],
      "Condition": { "Bool": { "aws:SecureTransport": "false" } }
    },
    {
      "Sid": "CloudFrontReadOnly",
      "Effect": "Allow",
      "Principal": { "Service": "cloudfront.amazonaws.com" },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": { "StringEquals": { "AWS:SourceArn": "arn:aws:cloudfront::123456789012:distribution/EDFDVBD6EXAMPLE" } }
    }
  ]
}
```

Access to an object = IAM policy **and/or** bucket policy allow it, no explicit deny exists, and **Block Public Access** permits it. My demo turns all four Block Public Access settings on (`aws_s3_bucket_public_access_block`).

## Common use cases
- **Static website hosting** (React/Vue builds) behind CloudFront
- **Backups and disaster recovery** (EBS/RDS exports, Velero backups of Kubernetes)
- **Data lake** for analytics (Athena, Glue, EMR, Redshift Spectrum)
- **Log storage**: CloudTrail, ALB/CloudFront access logs, VPC Flow Logs
- **Terraform remote state**: S3 backend with versioning + encryption (+ lock file)
- **CI/CD artifacts** and media/user uploads via pre-signed URLs
