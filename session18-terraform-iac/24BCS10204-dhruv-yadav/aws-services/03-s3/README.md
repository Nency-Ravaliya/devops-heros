# 03 - Amazon S3 (Simple Storage Service)

- **Student:** Dhruv Yadav
- **Enrollment No.:** 24BCS10204
- **Session:** 18 - Terraform & IaC (Task 2: AWS core services)

## Checklist

- [x] What is S3
- [x] Buckets
- [x] Objects
- [x] Storage classes
- [x] Versioning
- [x] Lifecycle policies
- [x] Encryption
- [x] Bucket policies
- [x] Use cases

---

## What is S3?

S3 is AWS's **object storage** service: store any amount of data as objects in buckets and access it over
HTTPS via an API. It is designed for **99.999999999% (11 nines) durability** (data is replicated across at
least 3 AZs for most classes), scales without limits, and you pay for what you store + requests + data out.
It is *not* a filesystem or a block device - you `PUT` and `GET` whole objects.

## Buckets

- A **bucket** is a container for objects. Name rules: 3-63 chars, lowercase, digits, `-`, `.`;
  **globally unique** across all AWS accounts.
- Created in **one region** (data stays there unless you replicate it).
- Bucket-level settings: versioning, default encryption, Block Public Access, policies, lifecycle,
  logging, replication, Object Lock, static website hosting, CORS, tags.
- Default limit 10,000 buckets per account (raisable); unlimited objects per bucket.

## Objects

- An **object** = **key** (full "path", e.g. `logs/2026/10/app.log`) + **data** (0 B - 5 TB) + **metadata**
  (system and user-defined `x-amz-meta-*`) + optional **version ID** and **tags**.
- "Folders" are just key **prefixes**; the namespace is flat.
- Single `PUT` up to 5 GB; use **multipart upload** for large objects (recommended > 100 MB; the CLI does this automatically).
- **Strong read-after-write consistency** for all PUTs, overwrites and deletes.
- URL forms: `https://<bucket>.s3.<region>.amazonaws.com/<key>` (virtual-hosted) - share privately using **pre-signed URLs**.

## Storage classes

| Class | Use for | Notes |
|---|---|---|
| **S3 Standard** | frequently accessed data | default; ms latency; >= 3 AZs |
| **S3 Intelligent-Tiering** | unknown/changing access patterns | auto-moves objects between tiers; small monitoring fee |
| **S3 Standard-IA** | infrequent access, needs fast retrieval | cheaper storage, per-GB retrieval fee, 30-day min |
| **S3 One Zone-IA** | re-creatable infrequent data | single AZ, cheaper, less resilient |
| **S3 Glacier Instant Retrieval** | archive accessed ~quarterly | ms retrieval, 90-day min |
| **S3 Glacier Flexible Retrieval** | archive | minutes to hours retrieval |
| **S3 Glacier Deep Archive** | long-term compliance archive | cheapest; ~12-48 h retrieval, 180-day min |
| **S3 Express One Zone** | ultra-low latency hot data | single AZ, "directory buckets" |

## Versioning

- Keeps **every version** of an object in the same bucket. Bucket states: *Unversioned* -> *Enabled* <-> *Suspended*
  (once enabled it can never return to unversioned).
- Overwrite = new version; delete = a **delete marker** is placed on top (older versions are recoverable).
- Protects against accidental overwrite/delete; required for **replication**; combine with **MFA Delete** /
  **Object Lock** for stronger protection.
- Every version is billed - pair it with lifecycle rules for non-current versions.

## Lifecycle policies

Rules (per prefix/tag) that automatically **transition** objects to cheaper classes or **expire** them:

```json
{
  "Rules": [
    {
      "ID": "logs-tiering",
      "Filter": { "Prefix": "logs/" },
      "Status": "Enabled",
      "Transitions": [
        { "Days": 30, "StorageClass": "STANDARD_IA" },
        { "Days": 90, "StorageClass": "GLACIER" }
      ],
      "Expiration": { "Days": 365 },
      "NoncurrentVersionExpiration": { "NoncurrentDays": 30 }
    }
  ]
}
```

Also commonly used: `AbortIncompleteMultipartUpload` (clean up failed uploads) and expiring delete markers.

## Encryption

| Where | Option | Who manages the key |
|---|---|---|
| At rest (server side) | **SSE-S3** (`AES256`) | AWS/S3 - **default for all new objects since Jan 2023** |
| | **SSE-KMS** (`aws:kms`) | AWS KMS key (AWS-managed or customer-managed CMK), auditable in CloudTrail; use **bucket keys** to cut KMS cost |
| | **DSSE-KMS** | dual-layer KMS encryption for compliance |
| | **SSE-C** | you send the key with every request |
| Client side | encrypt before upload | entirely you |
| In transit | HTTPS/TLS | enforce with a bucket policy `aws:SecureTransport = false -> Deny` |

## Bucket policies

A **resource-based IAM policy** attached to the bucket (it has a `Principal`). Used for cross-account access,
enforcing TLS/encryption, restricting to a VPC endpoint, or allowing CloudFront. **Block Public Access**
(on by default) overrides any policy that would make the bucket public.

Example - deny any request that is not over HTTPS:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyInsecureTransport",
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": [
      "arn:aws:s3:::Dhruv-24BCS10204-tf-demo",
      "arn:aws:s3:::Dhruv-24BCS10204-tf-demo/*"
    ],
    "Condition": { "Bool": { "aws:SecureTransport": "false" } }
  }]
}
```

Access to S3 is allowed if (IAM policy **or** bucket policy allows) **and** nothing explicitly denies it.
ACLs are legacy - new buckets have ACLs disabled (*Bucket owner enforced*).

## Use cases

- Static website hosting / SPA assets behind **CloudFront**.
- Backups, disaster recovery, and long-term archive (Glacier).
- Data lakes for analytics (Athena, EMR, Redshift Spectrum).
- Application file uploads (images, documents) via pre-signed URLs.
- Log storage (CloudTrail, ALB, VPC Flow Logs).
- **Terraform remote state** backend (with versioning + locking).
- Artifact storage for CI/CD pipelines.

---

## Hands-on (run against LocalStack, an AWS emulator)

Run against LocalStack 3.8 (`--endpoint-url http://localhost:4566` omitted from displayed commands).
The Terraform version (bucket + versioning + encryption + public access block) is in
[`../../terraform-s3-demo`](../../terraform-s3-demo/README.md).

```text
$ aws s3 mb s3://Dhruv-s3-notes
make_bucket: Dhruv-s3-notes

$ aws s3api put-bucket-versioning --bucket Dhruv-s3-notes --versioning-configuration Status=Enabled

$ aws s3api put-bucket-lifecycle-configuration --bucket Dhruv-s3-notes --lifecycle-configuration file://lifecycle.json

$ aws s3api get-bucket-lifecycle-configuration --bucket Dhruv-s3-notes --query "Rules[0].Transitions"
[
    {
        "Days": 30,
        "StorageClass": "STANDARD_IA"
    },
    {
        "Days": 90,
        "StorageClass": "GLACIER"
    }
]

$ aws s3 cp app.log s3://Dhruv-s3-notes/logs/app.log --storage-class STANDARD_IA
upload: ./app.log to s3://Dhruv-s3-notes/logs/app.log
$ aws s3 cp app.log s3://Dhruv-s3-notes/logs/app.log --storage-class STANDARD_IA
upload: ./app.log to s3://Dhruv-s3-notes/logs/app.log

$ aws s3api list-object-versions --bucket Dhruv-s3-notes --prefix logs/ --query "Versions[].{Key:Key,VersionId:VersionId,IsLatest:IsLatest,StorageClass:StorageClass}" --output table
----------------------------------------------------------------------------------
|                               ListObjectVersions                               |
+----------+---------------+---------------+-------------------------------------+
| IsLatest |      Key      | StorageClass  |              VersionId              |
+----------+---------------+---------------+-------------------------------------+
|  True    |  logs/app.log |  STANDARD     |  pSQvDlYAtlkAJHnFinphR8gP1EaDl82E   |
|  False   |  logs/app.log |  STANDARD     |  gcxWVtbq_A9.5XY0OWXe042kh6.ciL_4   |
+----------+---------------+---------------+-------------------------------------+
```

`lifecycle.json` is the policy shown above. Uploading the same key twice produced **two versions** (versioning works).
Honest note: LocalStack reported `STANDARD` even though `--storage-class STANDARD_IA` was requested - the emulator
does not model storage classes for `ListObjectVersions`; real S3 would show `STANDARD_IA`. Lifecycle
transitions are also not actually executed by LocalStack (real S3 runs them asynchronously, once a day).
The bucket and all versions were deleted afterwards.
