# S3

S3 is object storage. You store files as objects inside buckets. It is not a disk you mount as the root filesystem of an instance.

## Pieces

- A **bucket** name is global. The lab names in `terraform.tfvars` must be changed before `apply`, or AWS will reject a name someone else already owns.
- An **object** is the file plus its key (the path) and metadata.
- **Storage classes** trade cost and retrieval time: Standard, Intelligent-Tiering, Standard-IA, Glacier Instant / Flexible / Deep Archive. Standard is the lab default.
- **Versioning** keeps old copies when you overwrite or delete. The Session 18 bucket enables it.
- **Lifecycle policies** move or expire objects on a schedule, for example Standard to Glacier after 30 days.
- **Encryption** can be SSE-S3 or SSE-KMS. Block public access is turned on in both Terraform projects.
- A **bucket policy** is a resource policy. It can allow a role from another account. Combine it with IAM, and keep Block Public Access on unless the bucket is a deliberate public website.

## Use cases

Build artifacts, Terraform state (with a lock table), logs, and static website assets. The Session 18 project creates one private bucket. The Session 19 project creates a second private bucket next to the VPC and EC2 instance.
