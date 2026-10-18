# S3

S3 stores objects in buckets. An object has a key, content and metadata.
Storage classes trade access patterns, latency and cost: Standard,
Intelligent-Tiering and archive classes are examples. Versioning retains older
versions; lifecycle policies can expire or transition them. Encryption can use
S3-managed or KMS-managed keys. Bucket policies grant resource permissions and
Block Public Access helps prevent accidental exposure. Use S3 for backups,
static assets, logs or data lakes. It is not a POSIX filesystem.

Reference: https://docs.aws.amazon.com/
