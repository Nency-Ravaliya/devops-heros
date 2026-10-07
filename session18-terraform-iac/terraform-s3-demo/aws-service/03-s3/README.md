# 03. S3 Storage

## What is S3?

****S3 = Simple Storage Service****

Amazon S3 is an object storage service sued to store and retrieve data

Common examples:
- Images
- Videos
- Documents
- Backups
- Logs
- Application Files

S3 is highly durable and scalable

Basic Flow:

Application -> S3 Bucker -> Objects

----

## Buckets

****A Bucket is a container used to store objects.****

Example:

my-app-bucket -> Images
                 Documents
                 Backups

Bucket names must be globally unique.

A bucket belongs to an AWS Region.

---

## Objects

****An Object is the actual data stored in S3.****

An object contains:
- Data
- Key
- Metadata

Example:

my-bucket -> images/profile,jpg

Here:

Bucket = my-bucket
Key = images/profile.jpg
Object = profile.jpg

---

## Storage Classes

****S3 provides different storage classes based on how frequently data is accessed****

Common classes:

- S3 Standard
- S3 Intelligent-Tiering
- S3 Standard=IA
- S3 One Zone-IA
- S3 Glacier Instant Retrieval
- S3 Glacier Flexible Retrieval
- S3 Glacier Depp Archive

Simple Idea:

Frequently accessed -> S3 Standard

Rarely accessed -> S3 Standard-IA

Long-term archive -> S3 Glacier

Choose the storage class based on access frequency and cost.

---

## Versioning

****Versioning keeps multiple versions of an object****

Example:

config.json -> Version 1, Version 2, Version 3

If an object is accidentally deleted or overwritten, an older version can be recovered.

Enable versioning when data recovery is important

---

## Lifecycle Policies

****Lifecycle policices automatically manage objects over time****

Example:

S3 Standard -> After 30 days -> S3 Standard-IA -> After 90 days -> S3 Glacier

They can also automatically delete old objects.

Useful for:

- Logs
- Backups
- Old files
- Archived data

---

## Encryption

****Encryption protects data stored in S3****

S3 supports server side encryption such as:

- SSE-S3
- SSE-KMS
- SSE-C

Example:

Application -> Encrypted Object -> S3

---

## Bucket Policies

****A bucket Policy is a JSON-based resource policy attached to an S3 bucket****

It controls who can access the bucket and what they can do.

Example:

User -> Bucket Policy -> S3 Bucket

A policy can allow or deny actions such as:

s3:GetObject
s3:PutObject
s3:DeleteObject

Avoid making buckets publicly accessible unelss it is actually required.

---

## Common Use Cases

**Static Website : User -> S3 -> HTML/CSS/JS**
**Application -> S3 -> Images/Documents**
**Backups: Application -> S3 -> Backup Files**
**Logs: AWS Services -> S3 -> Log Storage**
