# IAM - Governance

IAM controls who can access AWS and what they can do. A **user** represents a person or long-lived workload, while a **group** collects users that need the same permissions. A **role** is assumed temporarily by a user, AWS service, or federated identity.

Policies are JSON documents containing effects, actions, resources, and optional conditions. I would start with no permissions and add only the actions needed for the task. This is least privilege. I would also prefer roles and short-lived credentials over access keys, require MFA for humans, review unused permissions, and avoid routine use of the root account.

Common examples are an EC2 role that reads one S3 bucket, a CI role assumed through GitHub OIDC, and separate developer and read-only groups.
