# 03 – S3 (Simple Storage Service) – Storage

**Name:** Kushal Talati · **Enrollment No:** 24BCS10123

S3 is object storage: I `PUT` a blob under a key in a bucket and `GET` it back by that key over HTTPS. There is no filesystem, no mounting, no partial writes – just objects (up to 5 TB each) in a flat namespace, with eleven 9s of durability because every object is copied across at least three facilities in the region.

Task 1 of this session ([`../../terraform-s3-demo/`](../../terraform-s3-demo)) creates a bucket with Terraform; this note covers the concepts and a few extra API calls run against LocalStack (raw output in [`../../logs/02-aws-services-hands-on.txt`](../../logs/02-aws-services-hands-on.txt) under `03 S3`).

## Buckets and objects

```text
s3://kushal-24bcs10123-s18-demo/               <- bucket: globally unique name, lives in ONE region
    hello/README.txt                           <- object key (the "/" is just a character; "folders" are a UI illusion)
    hello/note.txt   (version 1, version 2)    <- with versioning every PUT keeps the old copy
    logs/2026/10/07/app.log
```

* **Bucket**: the container and the unit for policies, versioning, encryption, lifecycle and logging settings. Names are DNS names (3–63 chars, lowercase) and shared across *all* AWS accounts – hence the roll number in mine.
* **Object**: key + data + metadata (Content-Type, custom `x-amz-meta-*`, storage class, ETag/MD5, version id). Max 5 TB, >5 GB must use multipart upload.
* Access paths: `https://<bucket>.s3.<region>.amazonaws.com/<key>` (virtual-hosted) or `https://s3.<region>.amazonaws.com/<bucket>/<key>` (path style – what LocalStack needs, hence `s3_use_path_style = true` in my provider).

## Storage classes – same API, different price per GB vs per request

| Class | For | Min storage / retrieval |
|---|---|---|
| **STANDARD** | hot data, frequently read | none |
| **INTELLIGENT_TIERING** | unknown access pattern; S3 moves objects between tiers itself | small monitoring fee |
| **STANDARD_IA** / **ONEZONE_IA** | backups, older files read a few times a year (One-Zone = one AZ, cheaper, less durable) | 30 days, per-GB retrieval fee |
| **GLACIER_IR / GLACIER (Flexible) / DEEP_ARCHIVE** | archives; retrieval from milliseconds (IR) to minutes–hours (Flexible) to 12 h (Deep) | 90 / 90 / 180 days |
| **EXPRESS_ONEZONE** | single-digit ms latency for ML / analytics scratch data | directory buckets only |

```text
$ awsl s3 cp a.txt s3://s18-notes-kushal/a.txt --storage-class STANDARD
$ awsl s3 cp a.txt s3://s18-notes-kushal/b.txt --storage-class STANDARD_IA
$ awsl s3 cp a.txt s3://s18-notes-kushal/c.txt --storage-class GLACIER
$ awsl s3api list-objects-v2 --bucket s18-notes-kushal --query 'Contents[].{Key:Key,StorageClass:StorageClass}' --output table
|  a.txt  |  STANDARD     |
|  b.txt  |  STANDARD_IA  |
|  c.txt  |  GLACIER      |
```

## Versioning
Once enabled (it can be suspended but never turned off), every overwrite creates a new version id and every delete only adds a *delete marker*. Protects against the two classic accidents – overwriting and deleting – at the cost of paying for every version until a lifecycle rule expires the old ones. In the Terraform demo I uploaded `hello/note.txt` twice and `list-object-versions` showed two versions with `IsLatest` true on only one:

```text
$ awsl s3api list-object-versions --bucket kushal-24bcs10123-s18-demo --prefix hello/note.txt ...
|  IsLatest  |      Key        |  Size  |  VersionId  |
|  True      |  hello/note.txt |  54    |  <id-2>     |
|  False     |  hello/note.txt |  54    |  <id-1>     |
```

## Lifecycle policies
Rules per bucket (optionally per prefix/tag) that *transition* objects to a cheaper class after N days and/or *expire* them. This is how "keep logs 30 days hot, 90 days cold, delete after a year" becomes zero operational work:

```json
{ "Rules": [ { "ID": "logs-cool-down-then-expire", "Status": "Enabled", "Filter": { "Prefix": "" },
   "Transitions": [ { "Days": 30, "StorageClass": "STANDARD_IA" }, { "Days": 90, "StorageClass": "GLACIER" } ],
   "Expiration": { "Days": 365 } } ] }
```

```text
$ awsl s3api put-bucket-lifecycle-configuration --bucket s18-notes-kushal --lifecycle-configuration file://lifecycle.json
$ awsl s3api get-bucket-lifecycle-configuration --bucket s18-notes-kushal ... --output table
|  Days  |  Expire  |             ID               |     To       |
|  30    |  365     |  logs-cool-down-then-expire  |  STANDARD_IA |
```

Lifecycle rules also clean up *noncurrent versions* and *incomplete multipart uploads*, which otherwise silently cost money forever.

## Encryption
* **At rest** – every new object is encrypted by default since 2023 with **SSE-S3** (`AES256`, keys managed by S3). **SSE-KMS** uses a KMS key I control (audit trail in CloudTrail, cross-account grants, key rotation); `aws:kms:dsse` double-encrypts. **SSE-C** means I send the key with each request. Client-side encryption means S3 only ever sees ciphertext.
* **In transit** – HTTPS; the bucket policy below *denies* anything over plain HTTP (`aws:SecureTransport = false`), which is the standard way to force TLS.

Terraform demo: `aws_s3_bucket_server_side_encryption_configuration` with `sse_algorithm = "AES256"`, confirmed by `get-bucket-encryption` in [`../../logs/01-terraform-s3-workflow.txt`](../../logs/01-terraform-s3-workflow.txt).

## Bucket policies (and the other access controls)
Order of evaluation for an S3 request: **Block Public Access** settings → IAM identity policy → bucket policy → (legacy) ACLs. Explicit deny anywhere wins.

* **Block Public Access** (account- and bucket-level) – four switches that make it impossible to accidentally expose a bucket. On by default for new buckets; my Terraform turns all four on.
* **Bucket policy** – resource-based JSON on the bucket. Used for: force TLS, allow a specific role/account, allow CloudFront OAC, restrict by VPC endpoint or source IP.
* **IAM policies** – identity-based, see [01-iam](../01-iam/README.md).
* **ACLs** – legacy per-object grants; disabled by `BucketOwnerEnforced` object ownership on new buckets.
* **Presigned URLs** – a time-limited URL signed with my credentials that lets someone without AWS access download/upload one object. Used for "download your invoice" links.

```json
{ "Version": "2012-10-17", "Statement": [
   { "Sid": "DenyPlainHttp", "Effect": "Deny", "Principal": "*", "Action": "s3:*",
     "Resource": ["arn:aws:s3:::s18-notes-kushal", "arn:aws:s3:::s18-notes-kushal/*"],
     "Condition": { "Bool": { "aws:SecureTransport": "false" } } },
   { "Sid": "AllowReadToDevGroupRole", "Effect": "Allow",
     "Principal": { "AWS": "arn:aws:iam::000000000000:role/s18-ec2-app-role" },
     "Action": ["s3:GetObject"], "Resource": "arn:aws:s3:::s18-notes-kushal/*" } ] }
```

```text
$ awsl s3api put-bucket-policy --bucket s18-notes-kushal --policy file://bucket-policy.json
$ awsl s3 presign s3://s18-notes-kushal/a.txt --expires-in 60
http://localhost:4566/s18-notes-kushal/a.txt?X-Amz-Algorithm=AWS4-HMAC-SHA256&...&X-Amz-Expires=60&...&X-Amz-Signature=...
```

## Common use cases

| Use case | S3 features that matter |
|---|---|
| Static website / SPA hosting | website endpoint or (better) private bucket + CloudFront with OAC |
| Backups and snapshots | versioning + lifecycle to Glacier + Object Lock (WORM) for ransomware protection |
| Data lake (Athena, Spark, Redshift Spectrum) | partitioned keys `year=/month=/`, Parquet, Intelligent-Tiering |
| Log archive (CloudTrail, ALB, VPC flow logs) | lifecycle expiry, bucket policy allowing the log service principal |
| Terraform remote state | versioning (rollback), SSE-KMS, native S3 state locking (`use_lockfile = true` in Terraform ≥ 1.10) |
| Container image layers / artifacts | ECR and GHCR store layers in S3-style object storage underneath |
| Sharing files with users | presigned URLs, never a public bucket |

## What I understood

* S3 is a **key → blob** store with HTTP semantics; "folders" and "mounting" are illusions, which is why it scales and why it is not a database or a POSIX disk.
* Durability is solved for me; **cost and access control are my job** – lifecycle rules for the former, Block Public Access + bucket policy + IAM for the latter.
* Versioning + lifecycle + encryption-by-default are the three switches I would turn on for every bucket that holds anything I care about, which is exactly what the Terraform demo does.
