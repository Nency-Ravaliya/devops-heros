# 01 — IAM (Identity and Access Management)

> **Governance & Access Control for AWS**

---

## What is IAM?

AWS IAM (Identity and Access Management) is a **free AWS service** that controls who can do what in your AWS account. It is the central **governance** layer for all AWS services.

With IAM you can:
- Create and manage **users**, **groups**, and **roles**
- Define **policies** (what actions are allowed/denied on which resources)
- Apply **least privilege** access
- Enable **multi-factor authentication (MFA)**

---

## Core IAM Concepts

### 👤 Users

An IAM **User** is a permanent identity representing a person or application.

```
Root Account
    │
    ├── IAM User: shivansh (console + programmatic access)
    ├── IAM User: ci-bot  (programmatic only — for GitHub Actions)
    └── IAM User: auditor (read-only)
```

| Type | Use Case |
|------|----------|
| Human user | Developer, admin, auditor |
| Service user | CI/CD bot, Lambda function caller |

**Best practice:** Never use the root account. Create IAM users instead.

---

### 👥 Groups

An IAM **Group** is a collection of users. You attach policies to a group, and all users in that group inherit those permissions.

```
Group: Developers
  ├── Policy: AmazonEC2FullAccess
  ├── Policy: AmazonS3FullAccess
  └── Users: shivansh, john, priya

Group: ReadOnly
  ├── Policy: ReadOnlyAccess
  └── Users: auditor, intern
```

**Best practice:** Assign permissions to groups, not individual users.

---

### 🎭 Roles

An IAM **Role** is a temporary identity that can be assumed by:
- AWS services (EC2, Lambda, ECS)
- External users (cross-account access)
- Federated identities (SSO, GitHub Actions OIDC)

```
EC2 Instance → assumes → IAM Role: EC2-S3-ReadRole
                                    └── Policy: AmazonS3ReadOnlyAccess
```

**Key difference:** Roles are **temporary** (use short-lived credentials), Users are **permanent**.

---

### 📋 Policies

A **Policy** is a JSON document that defines permissions.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

| Policy Type | Description |
|---|---|
| **AWS Managed** | Pre-built by AWS (e.g. `AmazonS3FullAccess`) |
| **Customer Managed** | Custom policies you create |
| **Inline** | Embedded directly in a user/group/role |

---

### 🔐 Permissions

Permissions define **what actions** are allowed or denied on **which resources**.

- **Effect:** `Allow` or `Deny`
- **Action:** API action (e.g. `s3:PutObject`, `ec2:StartInstances`)
- **Resource:** ARN of the resource (e.g. `arn:aws:s3:::my-bucket`)

**Explicit Deny always wins** over Allow.

---

## Principle of Least Privilege

> Grant only the permissions required to perform a task — nothing more.

```
BAD:  Attach AdministratorAccess to a developer
GOOD: Attach only AmazonEC2FullAccess + AmazonS3ReadOnlyAccess
```

---

## IAM Best Practices

| # | Practice |
|---|----------|
| 1 | Enable MFA on the root account and all IAM users |
| 2 | Never share root account credentials |
| 3 | Use roles for EC2, Lambda, and ECS — not access keys |
| 4 | Rotate access keys regularly |
| 5 | Use groups to manage permissions — not individual users |
| 6 | Apply least privilege principle |
| 7 | Use IAM Access Analyzer to review permissions |
| 8 | Enable CloudTrail to audit all IAM activity |

---

## Common Use Cases

| Use Case | IAM Component |
|---|---|
| Developer accesses AWS console | IAM User + MFA |
| EC2 reads from S3 | IAM Role attached to EC2 |
| GitHub Actions deploys to ECS | OIDC Role (no long-lived keys) |
| Audit team reads all logs | IAM Group: ReadOnlyAccess |
| Cross-account access | IAM Role + trust policy |
| Lambda writes to DynamoDB | IAM Role with DynamoDB policy |

---

## Key CLI Commands

```bash
# List all IAM users
aws iam list-users

# Create a user
aws iam create-user --user-name shivansh

# Attach a policy to a user
aws iam attach-user-policy \
  --user-name shivansh \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# List groups
aws iam list-groups

# Create a role
aws iam create-role --role-name EC2-S3-Role \
  --assume-role-policy-document file://trust-policy.json

# Get caller identity
aws sts get-caller-identity
```
