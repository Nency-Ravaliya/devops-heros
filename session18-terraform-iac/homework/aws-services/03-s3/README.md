# S3 — Simple Storage Service

**What:** Object storage with virtually unlimited capacity and 99.999999999% (11 nines) durability. Accessed over HTTP APIs, not mounted like a disk.

## Buckets & Objects
| Concept | Description |
|---|---|
| **Bucket** | Container for objects; name is **globally unique**, 3–63 lowercase chars; created in one region. |
| **Object** | File + metadata, up to 5 TB; addressed by a **key** (`logs/2026/app.log`). Folders are just key prefixes. |
| **URL** | `https://<bucket>.s3.<region>.amazonaws.com/<key>` |

## Storage Classes
| Class | Use for |
|---|---|
| S3 Standard | Frequently accessed data |
| Intelligent-Tiering | Unknown/changing access; auto-moves between tiers |
| Standard-IA / One Zone-IA | Infrequent access, retrieval fee (One Zone = 1 AZ, cheaper) |
| Glacier Instant / Flexible / Deep Archive | Archives; retrieval from ms → minutes/hours → 12 h |

## Versioning
- Keeps every version of an object; protects from overwrite and accidental delete (delete = **delete marker**).
- States: Unversioned → Enabled → Suspended (can't go back to unversioned).
- Combine with MFA Delete for extra protection.

## Lifecycle Rules
Automate cost savings, e.g.:
- Move to Standard-IA after 30 days → Glacier after 90 days.
- Expire objects / noncurrent versions after 365 days.
- Abort incomplete multipart uploads after 7 days.

## Encryption
- **At rest:** SSE-S3 (AES-256, default for all new objects), SSE-KMS (KMS keys, audit trail), SSE-C (customer-provided keys), or client-side.
- **In transit:** HTTPS/TLS; enforce with a policy denying `aws:SecureTransport = false`.

## Access Control & Bucket Policies
- **Block Public Access** is on by default — keep it on unless hosting public content.
- **Bucket policy** = resource-based JSON policy, e.g. allow one role read access:
```json
{
  "Effect": "Allow",
  "Principal": {"AWS": "arn:aws:iam::123456789012:role/app-role"},
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::my-bucket/*"
}
```
- IAM policies control what identities can do; ACLs are legacy (disabled by default).
- Presigned URLs give temporary access to a single object.

## Use Cases
- Backups, logs, data lake, ML datasets.
- Static website hosting (with CloudFront).
- Terraform remote state backend (with versioning + locking).
- Artifact/storage for CI/CD pipelines.
