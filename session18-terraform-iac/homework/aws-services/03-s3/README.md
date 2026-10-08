# 03. S3: Simple Storage Service (Storage)

## What is S3?

**Amazon S3** is object storage with effectively unlimited capacity and 99.999999999% (11 nines) durability. Data is stored as **objects** inside **buckets** and accessed over HTTPS through an API, not mounted like a disk. It's regional (data stays in the region you choose) and replicated across at least 3 Availability Zones (for most storage classes).

```text
Bucket (globally unique name, in one region)
 └── Object  key = "reports/2026/october.csv"
             value = bytes (0 B … 5 TB)
             metadata, tags, version ID, storage class, encryption info
```

## Buckets

- A **container** for objects. The name is **globally unique** across all AWS accounts, 3–63 characters, lowercase, DNS-compatible. That's why my Terraform demo appends a random suffix.
- Created in **one region**; default soft limit 10,000 buckets per account.
- Bucket-level settings: Block Public Access, versioning, default encryption, lifecycle rules, bucket policy, CORS, logging, replication, Object Lock, static website hosting.
- **Object Ownership "bucket owner enforced"** (the default) disables ACLs, so access is controlled only with policies.

## Objects

- **Key:** the full "path" (`images/cat.png`). S3 is flat; "folders" are just key prefixes shown with `/`.
- **Value:** up to **5 TB**. Use **multipart upload** above ~100 MB (required above 5 GB).
- **Metadata** (system: content-type, size; user-defined: `x-amz-meta-*`) and up to 10 **tags**.
- **Strong read-after-write consistency** for all operations.
- Access: `s3://bucket/key`, `https://bucket.s3.region.amazonaws.com/key`, **pre-signed URLs** for temporary access to private objects.

## Storage classes

| Class | Use for | Availability | Min storage duration | Retrieval |
|---|---|---|---|---|
| **S3 Standard** | Frequently accessed data | 99.99% | none | instant |
| **S3 Intelligent-Tiering** | Unknown/changing access patterns; moves objects between tiers automatically | 99.9% | none | instant (archive tiers optional) |
| **S3 Standard-IA** | Infrequent access, needs fast retrieval | 99.9% | 30 days | instant, per-GB fee |
| **S3 One Zone-IA** | Re-creatable infrequent data (single AZ) | 99.5% | 30 days | instant |
| **S3 Glacier Instant Retrieval** | Archive accessed ~quarterly | 99.9% | 90 days | milliseconds |
| **S3 Glacier Flexible Retrieval** | Archive | 99.99% | 90 days | minutes to 12 h |
| **S3 Glacier Deep Archive** | Long-term compliance archive, cheapest | 99.99% | 180 days | 12–48 h |
| **S3 Express One Zone** | Single-digit ms latency, high request rates | 99.95% | none | instant |

## Versioning

When enabled, S3 keeps **every version** of every object:
- Each PUT creates a new **version ID**; overwrites don't destroy older data.
- A DELETE adds a **delete marker**; the object "disappears" but old versions can be restored.
- Protects against accidental deletes/overwrites and ransomware (especially with **MFA Delete** or **Object Lock**).
- Bucket states: *unversioned → enabled → suspended* (it can't go back to unversioned).
- Every version is billed, so combine it with a lifecycle rule that expires noncurrent versions. My Terraform demo deletes noncurrent versions after 30 days.
- Required for **replication** (CRR/SRR).

## Lifecycle policies

Rules that act on objects automatically, filtered by prefix or tags:
- **Transition actions:** e.g. Standard → Standard-IA after 30 days → Glacier Flexible Retrieval after 90 → Deep Archive after 365.
- **Expiration actions:** delete objects after N days, delete **noncurrent versions** after N days, remove expired delete markers, **abort incomplete multipart uploads** (a common hidden cost).

```json
{ "Rules": [{
  "ID": "logs-archive",
  "Filter": { "Prefix": "logs/" },
  "Status": "Enabled",
  "Transitions": [
    { "Days": 30, "StorageClass": "STANDARD_IA" },
    { "Days": 90, "StorageClass": "GLACIER" }
  ],
  "Expiration": { "Days": 365 },
  "AbortIncompleteMultipartUpload": { "DaysAfterInitiation": 7 }
}]}
```

## Encryption

- **In transit:** HTTPS/TLS. Enforce it with a bucket policy condition `aws:SecureTransport = false → Deny`.
- **At rest (server-side).** Since January 2023 every new object is encrypted by default:
  - **SSE-S3** (`AES256`): S3-managed keys, no extra cost (used in my Terraform demo).
  - **SSE-KMS** (`aws:kms`): keys in AWS KMS, with key policies, CloudTrail audit of key use and rotation; use **S3 Bucket Keys** to cut KMS request costs.
  - **DSSE-KMS:** dual-layer encryption for compliance.
  - **SSE-C:** you supply the key with every request.
- **Client-side encryption:** encrypt before upload (the AWS Encryption SDK).

## Bucket policies

**Resource-based JSON policies** attached to the bucket, with a `Principal`. Used for cross-account access, forcing TLS or encryption, allowing a CloudFront distribution (Origin Access Control), or restricting access to a VPC endpoint.

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
      "Sid": "AllowAppRoleRead",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::111122223333:role/app-role" },
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

Access to an object requires that IAM (identity policy) **and** the bucket policy allow it, with no explicit Deny anywhere. **Block Public Access** (account and bucket level, on by default) overrides any policy or ACL that would make data public. My demo turns on all four settings.

## Other features

Static website hosting (usually behind CloudFront), event notifications (Lambda/SQS/SNS/EventBridge), cross-region and same-region replication, Object Lock (WORM compliance), S3 Inventory and Storage Lens, access points, Transfer Acceleration, server access logs, and querying in place with Athena / S3 Select.

## Common use cases

- Backups and disaster recovery, data lakes and analytics (Athena, EMR, Redshift Spectrum).
- Static websites and assets for web/mobile apps (with CloudFront).
- Application uploads (images, documents) via pre-signed URLs.
- Log storage (ALB, CloudTrail, VPC flow logs) with lifecycle to Glacier.
- Artifact storage for CI/CD and **Terraform remote state** (with DynamoDB or S3-native state locking).
- ML training datasets and model artifacts.

The [Session 18 Terraform demo](../../terraform-s3-demo/README.md) creates a bucket with versioning, SSE-S3 encryption, Block Public Access, a lifecycle rule and a sample object.
