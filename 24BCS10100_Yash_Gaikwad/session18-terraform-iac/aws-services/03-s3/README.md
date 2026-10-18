# AWS S3 (Simple Storage Service) - Storage

Prepared by: Yash Gaikwad (Roll no. 24BCS10100)
Category: Storage

S3 is AWS's object storage service. I do not mount it like a disk; I put and get whole objects over HTTPS using an API (console, CLI, SDK, Terraform). It is designed for 11 nines (99.999999999%) of durability and scales without me provisioning capacity, which is why so many other services (CloudTrail, CloudFront, Athena, Terraform remote state) use it as their backing store.

---

## What is S3

- **Object storage**: data is stored as objects inside buckets, not as files in a block device or a hierarchical file system.
- Flat namespace: "folders" in the console are just **key prefixes** (`logs/2026/10/app.log`).
- Accessed via REST API and HTTPS endpoints; every object can have a URL (private unless I allow access).
- Strong read-after-write consistency for all operations.
- Pay for storage used, requests, data retrieval (for some classes) and data transfer out.

---

## Buckets

- A bucket is the top-level container for objects.
- Name rules: **globally unique across all AWS accounts**, 3-63 characters, lowercase letters, numbers, dots and hyphens, must start with a letter or number.
- A bucket is created in one **region** (data stays there unless I replicate it), but the name is global.
- There is no limit on the number of objects per bucket (default quota of 10,000 buckets per account, which can be raised).
- Each bucket has its own settings: versioning, encryption, policy, lifecycle, logging, replication, and so on.

```bash
aws s3 mb s3://my-unique-devops-bucket-24bcs10100 --region ap-south-1
aws s3api create-bucket --bucket my-unique-devops-bucket-24bcs10100 \
  --region ap-south-1 --create-bucket-configuration LocationConstraint=ap-south-1
aws s3 ls
```

(`us-east-1` is the exception: it does not take a `LocationConstraint`.)

---

## Objects

An object consists of:

| Part | Meaning |
|---|---|
| **Key** | the full name inside the bucket, e.g. `images/logo.png` (up to 1,024 bytes) |
| **Value** | the data itself (a sequence of bytes) |
| **Version ID** | present when versioning is on |
| **Metadata** | key/value pairs (system metadata like `Content-Type`, plus user metadata `x-amz-meta-*`) |
| **Tags** | up to 10 key/value tags, useful for lifecycle and access control |

- Maximum object size is **5 TB**. A single PUT can upload up to 5 GB; larger objects must use **multipart upload** (recommended above roughly 100 MB, and the CLI does this automatically).
- Objects are **immutable**: to change one I upload a new object with the same key (a new version if versioning is on).

```bash
aws s3 cp ./report.pdf s3://my-unique-devops-bucket-24bcs10100/reports/report.pdf
aws s3 sync ./site s3://my-unique-devops-bucket-24bcs10100/site --delete
aws s3api head-object --bucket my-unique-devops-bucket-24bcs10100 --key reports/report.pdf
```

---

## Storage classes

| Class | Use when | Retrieval | Minimum storage duration |
|---|---|---|---|
| **Standard** | frequently accessed data | milliseconds | none |
| **Intelligent-Tiering** | unknown or changing access patterns; S3 moves objects between tiers automatically | milliseconds (frequent/infrequent tiers) | none (small monitoring fee per object) |
| **Standard-IA** | infrequent access but needs fast retrieval; stored across multiple AZs | milliseconds, per-GB retrieval fee | 30 days |
| **One Zone-IA** | re-creatable infrequent data; stored in a **single AZ** (lower cost, lost if the AZ is lost) | milliseconds | 30 days |
| **Glacier Instant Retrieval** | archive that is rarely read (about once a quarter) but needs instant access | milliseconds | 90 days |
| **Glacier Flexible Retrieval** | archives read once or twice a year | minutes to hours (expedited / standard / bulk) | 90 days |
| **Glacier Deep Archive** | long-term compliance archives, lowest cost | within about 12 hours (standard) or 48 hours (bulk) | 180 days |

Also exists: S3 Express One Zone (very low latency, single AZ, for performance-critical workloads). Standard-IA and One Zone-IA have a 128 KB minimum billable object size.

Rule of thumb I noted: the colder the class, the cheaper to store but the more it costs (in money or time) to read back.

---

## Versioning

- Keeps **every version** of an object under the same key, which protects against accidental overwrite and delete.
- States: unversioned (default), **enabled**, **suspended**. Once enabled it can only be suspended, never fully switched off.
- A plain `DELETE` on a versioned bucket adds a **delete marker**; the older versions still exist and can be restored by removing the marker or by deleting a specific version ID.
- Every stored version costs storage, so combine versioning with lifecycle rules for noncurrent versions.
- Needed for cross-region replication, and **MFA Delete** can add extra protection for permanent deletes.

```bash
aws s3api put-bucket-versioning --bucket my-unique-devops-bucket-24bcs10100 \
  --versioning-configuration Status=Enabled
aws s3api list-object-versions --bucket my-unique-devops-bucket-24bcs10100 --prefix reports/
```

---

## Lifecycle policies

Lifecycle rules automate **transitions** (move to a cheaper class) and **expiration** (delete) based on object age, prefix or tags.

Useful actions:
- `Transitions` for current objects
- `Expiration` for current objects
- `NoncurrentVersionTransitions` / `NoncurrentVersionExpiration` for old versions
- `AbortIncompleteMultipartUpload` to clean leftover upload parts

Example `lifecycle.json`:

```json
{
  "Rules": [
    {
      "ID": "logs-tiering-and-expiry",
      "Status": "Enabled",
      "Filter": { "Prefix": "logs/" },
      "Transitions": [
        { "Days": 30, "StorageClass": "STANDARD_IA" },
        { "Days": 90, "StorageClass": "GLACIER" }
      ],
      "Expiration": { "Days": 365 },
      "NoncurrentVersionExpiration": { "NoncurrentDays": 30 },
      "AbortIncompleteMultipartUpload": { "DaysAfterInitiation": 7 }
    }
  ]
}
```

```bash
aws s3api put-bucket-lifecycle-configuration \
  --bucket my-unique-devops-bucket-24bcs10100 \
  --lifecycle-configuration file://lifecycle.json
```

`GLACIER` in the API means Glacier Flexible Retrieval; the other values are `GLACIER_IR`, `DEEP_ARCHIVE`, `INTELLIGENT_TIERING`, `ONEZONE_IA`. There are minimum-age rules between transitions (for example, objects must be in Standard for at least 30 days before moving to Standard-IA).

---

## Encryption

**At rest** (server-side encryption):

| Option | Keys managed by | Notes |
|---|---|---|
| **SSE-S3** | S3 (AES-256) | default; no extra setup or cost |
| **SSE-KMS** | AWS KMS key (AWS managed or my own CMK) | audit trail in CloudTrail, key policies, per-request KMS cost |
| **SSE-C** | me, key supplied on every request | AWS does not store the key; requests must use HTTPS. Since April 2026 SSE-C is **disabled by default on new buckets** (you must opt in with `BlockedEncryptionTypes` set to `NONE` in the bucket's default encryption configuration), so prefer SSE-S3 or SSE-KMS |
| DSSE-KMS | KMS, two layers | for strict compliance needs |
| Client-side | me, before upload | S3 only ever sees ciphertext |

- **Default encryption**: since January 2023 all new objects are automatically encrypted with SSE-S3 even if I do nothing. I can change a bucket's default to SSE-KMS.
- **In transit**: use HTTPS (TLS). I can force it with a bucket policy that denies requests where `aws:SecureTransport` is `false` (see below).

```bash
aws s3api put-bucket-encryption --bucket my-unique-devops-bucket-24bcs10100 \
  --server-side-encryption-configuration '{
    "Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"alias/my-s3-key"},"BucketKeyEnabled":true}]
  }'
```

`BucketKeyEnabled` lowers KMS request costs.

---

## Bucket policies

- A **resource-based** JSON policy on the bucket. Good for cross-account access, forcing TLS or encryption, and restricting by VPC endpoint or IP.
- Works together with IAM identity policies: access is allowed if either allows (within the same account) and nothing explicitly denies.

Example `bucket-policy.json`: deny non-TLS requests and allow one role to read:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::my-unique-devops-bucket-24bcs10100",
        "arn:aws:s3:::my-unique-devops-bucket-24bcs10100/*"
      ],
      "Condition": { "Bool": { "aws:SecureTransport": "false" } }
    },
    {
      "Sid": "AllowReportsRoleRead",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::<ACCOUNT_ID>:role/ec2-reports-reader" },
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::my-unique-devops-bucket-24bcs10100/reports/*"
    }
  ]
}
```

```bash
aws s3api put-bucket-policy --bucket my-unique-devops-bucket-24bcs10100 --policy file://bucket-policy.json
```

**Block Public Access**
- Four settings (block public ACLs, ignore public ACLs, block public policies, restrict public buckets) available per bucket and per account.
- Enabled by default on new buckets. I should turn them off only for a deliberate static website or public dataset.

```bash
aws s3api put-public-access-block --bucket my-unique-devops-bucket-24bcs10100 \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

**ACLs**
- Legacy per-object/bucket access lists. Since April 2023 new buckets use **Object Ownership = Bucket owner enforced**, which **disables ACLs**, so access is controlled with IAM and bucket policies instead.

---

## Common use cases

- Static website and asset hosting (often behind CloudFront).
- Backup, disaster recovery and long-term archive (with Glacier classes).
- Data lake storage queried by Athena, EMR or Redshift Spectrum.
- Application logs and audit trails (CloudTrail, ALB logs, VPC flow logs).
- Build artifacts, container/Helm chart storage, ML datasets.
- **Terraform remote state**: store `terraform.tfstate` in an S3 bucket with versioning and encryption. Older setups use a DynamoDB table for state locking; newer Terraform versions support S3-native locking (`use_lockfile`), and the DynamoDB option is on its way out.

---

## Interview quick points

- S3 is object storage, regional service with globally unique bucket names; max object size 5 TB, single PUT 5 GB, use multipart beyond that.
- Durability 11 nines; availability depends on the class (Standard 99.99%).
- Flat structure: prefixes are not real folders.
- Strong consistency for reads after writes and deletes.
- Know the classes: Standard, Intelligent-Tiering, Standard-IA, One Zone-IA, Glacier Instant / Flexible / Deep Archive; the minimum durations are 30 / 30 / 90 / 90 / 180 days.
- Versioning protects from accidental delete; once on it can only be suspended; delete adds a delete marker.
- Lifecycle rules automate transitions and expiry, including noncurrent versions and incomplete multipart uploads.
- Encryption: SSE-S3 (default), SSE-KMS, SSE-C, client-side; TLS in transit.
- Block Public Access is on by default for new buckets; ACLs are disabled by default for new buckets.
- Bucket policy = resource-based; IAM policy = identity-based; an explicit deny always wins.
- Other features worth naming: replication (CRR/SRR), pre-signed URLs, event notifications, Object Lock (WORM), access points, static website hosting.
