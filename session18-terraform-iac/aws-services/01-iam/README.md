# AWS IAM (Identity and Access Management) - Governance

## 1. What is IAM?
**AWS Identity and Access Management (IAM)** is a global web service that provides centralized access control and authorization across all AWS cloud resources.

---

## 2. Core IAM Building Blocks

* **Users:** An identity representing a specific human or application with long-term security credentials (username/password, access keys).
* **Groups:** A collection of IAM users used to apply batch permissions (e.g., `Developers`, `Admins`).
* **Roles:** An identity with temporary security credentials that can be assumed by trusted entities (e.g., an EC2 instance or Lambda function needing access to S3).
* **Policies:** JSON documents defining formal permissions (Effect, Action, Resource, Condition).

---

## 3. Example IAM Policy (JSON)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-production-bucket",
        "arn:aws:s3:::my-production-bucket/*"
      ]
    }
  ]
}
```

---

## 4. Principle of Least Privilege & Best Practices
1. **Grant Least Privilege:** Start with minimum required permissions and expand only as needed.
2. **Lock Root Account:** Never use the root user for daily operational tasks. Enable MFA immediately.
3. **Use Roles for Compute:** Attach IAM Roles to EC2 instances and ECS tasks instead of baking hardcoded credentials into code or config.
4. **Enforce Strong Password Policies and MFA:** Require multi-factor authentication across all interactive users.
5. **Rotate Access Keys:** Rotate programmatic keys every 90 days.

---

## 5. Common Use Cases
* Granting an EC2 instance read-only access to download application packages from an S3 bucket.
* Delegating cross-account access between Dev, Staging, and Production environments without sharing credentials.
* Enforcing conditional access restricting API calls to corporate IP CIDRs.
