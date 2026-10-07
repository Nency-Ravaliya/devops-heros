# Amazon S3

## Overview
Amazon Simple Storage Service (S3) is AWS object storage for storing and retrieving data at scale.

## 1. What is S3?
S3 stores objects inside buckets.

```text
S3 -> Bucket -> Objects
```

## 2. Buckets
A bucket is a container for objects. Bucket names must be globally unique. Buckets should normally remain private unless public access is explicitly required.

## 3. Objects
An object contains data, an object key, and metadata.

Examples:
```text
images/logo.png
documents/report.pdf
data/train.csv
```

## 4. Storage Classes
| Storage Class | Typical Use |
|---|---|
| Standard | Frequently accessed data |
| Intelligent-Tiering | Changing/unknown access patterns |
| Standard-IA | Infrequent access |
| One Zone-IA | Infrequent, recreatable data |
| Glacier Instant Retrieval | Archive with fast retrieval |
| Glacier Flexible Retrieval | Long-term archive |
| Glacier Deep Archive | Lowest-cost long-term archive |

## 5. Versioning
Versioning keeps multiple versions of objects and helps recover from accidental deletion or overwriting.

## 6. Lifecycle Rules
Lifecycle rules automatically transition or delete objects.

```text
Day 0   -> Standard
Day 30  -> Standard-IA
Day 90  -> Glacier
Day 365 -> Delete
```

## 7. Encryption
S3 supports encryption at rest including SSE-S3, SSE-KMS, and client-side encryption.

## 8. Bucket Policies
Bucket policies are resource-based JSON policies controlling access to buckets and objects. Public access should only be enabled intentionally.

## 9. Common Use Cases
- Backups
- Static website assets
- Images and videos
- Data lakes
- Application uploads
- Logs
- ML datasets
- Archives

## 10. Terraform Example
```hcl
resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name

  tags = {
    Name      = "Terraform S3 Demo"
    ManagedBy = "Terraform"
  }
}
```

## Summary
| Feature | Purpose |
|---|---|
| Bucket | Object container |
| Object | Stored data |
| Storage Class | Storage/access optimization |
| Versioning | Object recovery |
| Lifecycle | Automated transitions/deletion |
| Encryption | Data protection |
| Bucket Policy | Access control |

## Conclusion
S3 is highly scalable object storage suitable for backups, application files, datasets, logs, and archival workloads.
