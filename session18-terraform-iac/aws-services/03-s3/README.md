# S3 - Storage

S3 is object storage. A bucket contains objects identified by keys; it is not a normal mounted filesystem. Storage classes trade access cost and retrieval time, from S3 Standard through infrequent-access and archival classes.

Versioning keeps older object versions. Lifecycle rules can move old versions to cheaper storage or expire them. Encryption can use S3-managed keys or KMS keys. Bucket policies and IAM policies control access, and public-access blocking prevents accidental exposure.

I used S3 in the Terraform demo because it is a clear example of provider configuration, variables, resources, outputs, state, and cleanup. Other common uses are backups, static assets, logs, data lakes, and Terraform remote state.
