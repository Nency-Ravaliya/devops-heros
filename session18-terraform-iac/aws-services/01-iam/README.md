# 01 · IAM — Identity and Access Management (Governance)

## What is IAM?

**AWS Identity and Access Management (IAM)** is the service that controls **who** can access your AWS account (*authentication*) and **what** they are allowed to do (*authorization*).

- It is a **global** service: IAM users, groups, roles and policies are not tied to a region.
- It is **free**: you pay only for the resources that identities create, not for IAM itself.
- Every AWS API call, whether from the Console, the CLI, an SDK or Terraform, is checked against IAM before it runs.

```text
           ┌──────────────────────── AWS Account ───────────────────────┐
           │                                                            │
 Request ─►│  1. Authenticate: who are you?  (user / role / root)       │
           │  2. Authorize: are you allowed? (evaluate all policies)   │──► Allow / Deny
           │                                                            │
           └────────────────────────────────────────────────────────────┘
```

## Core building blocks

### Root user
This identity is created with the account (the email address and password used to sign up). It has unrestricted access, including billing and account closure.
**Use it only for the few tasks that require it. Enable MFA on it and never create access keys for it.**

### Users
An **IAM user** is an identity for one person or application that needs **long-term credentials**:

| Credential type | Used for |
|---|---|
| Password (+ MFA) | AWS Management Console sign-in |
| Access key ID + secret access key | CLI, SDKs, Terraform |

A new user starts with **no permissions**. You grant permissions explicitly.

```bash
aws iam create-user --user-name dev-alice
aws iam create-access-key --user-name dev-alice
```

### Groups
An **IAM group** is a collection of users. Policies attached to a group apply to every member, so you manage permissions per job function instead of per person.

```text
Group: Developers  ──► policy: PowerUserAccess
   ├── alice
   └── bob
Group: Auditors    ──► policy: ReadOnlyAccess
   └── carol
```

- A user can belong to several groups (up to 10).
- Groups cannot be nested, and a group is **not** an identity: it cannot sign in or be named as a principal.

### Roles
An **IAM role** is an identity with permissions but **no long-term credentials**. A trusted entity *assumes* the role and receives **temporary credentials** from AWS STS, which expire automatically.

A role has two policies:
1. **Trust policy**: *who* may assume the role.
2. **Permissions policy**: *what* the role may do.

Typical principals that assume roles:

| Who | Example |
|---|---|
| AWS service | EC2 instance profile, Lambda execution role, EKS service account (IRSA) |
| Another AWS account | Cross-account access |
| Federated user | SSO through IAM Identity Center, Okta, Google |
| CI/CD | GitHub Actions through OIDC (no stored keys) |

Trust policy that lets EC2 assume the role:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
```

### Policies
A **policy** is a JSON document that defines permissions. Each statement contains:

| Element | Meaning |
|---|---|
| `Effect` | `Allow` or `Deny` |
| `Action` | API operations, e.g. `s3:GetObject`, `ec2:*` |
| `Resource` | ARNs the statement applies to |
| `Condition` | *(optional)* when it applies, e.g. source IP, MFA present, tags |
| `Principal` | *(resource-based policies only)* who the statement applies to |

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOneBucket",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::my-app-bucket",
        "arn:aws:s3:::my-app-bucket/*"
      ]
    }
  ]
}
```

**Policy types**

| Type | Attached to | Notes |
|---|---|---|
| AWS managed | identities | Created and maintained by AWS, e.g. `AmazonS3ReadOnlyAccess` |
| Customer managed | identities | You write them, they are reusable and versioned. **Preferred.** |
| Inline | one identity | Embedded in a single user, group or role. Deleted with it. |
| Resource-based | resources | e.g. S3 bucket policy, SQS queue policy. Has a `Principal`. |
| Permissions boundary | user / role | Sets the **maximum** permissions an identity can ever have |
| SCP (Organizations) | account / OU | Guardrails across accounts in an organization |
| Session policy | STS session | Narrows permissions for one assumed-role session |

## Permissions: how AWS evaluates a request

```text
                 ┌─────────────────────────┐
  request ─────► │ Explicit DENY anywhere? │── yes ──► DENY
                 └───────────┬─────────────┘
                             no
                 ┌───────────▼─────────────┐
                 │ SCP / boundary allows?  │── no ───► DENY
                 └───────────┬─────────────┘
                             yes
                 ┌───────────▼─────────────┐
                 │ Any explicit ALLOW?     │── no ───► DENY  (implicit deny)
                 └───────────┬─────────────┘
                             yes
                             ▼
                           ALLOW
```

Three rules to remember:
1. **Everything is denied by default** (implicit deny).
2. An **explicit `Allow`** overrides the implicit deny.
3. An **explicit `Deny`** always wins over any `Allow`.

Use the **IAM Policy Simulator** or `aws iam simulate-principal-policy` to test policies before you attach them.

## Least privilege

Grant **only the permissions required to perform a task, and nothing more**.

| Instead of… | Use… |
|---|---|
| `"Action": "*"` and `"Resource": "*"` | specific actions on specific ARNs |
| `AdministratorAccess` for a CI pipeline | a custom policy scoped to the pipeline's resources |
| a long-lived access key on an EC2 instance | an **instance role** |
| permanent admin rights | a role that is assumed only when needed |

Tools that help:
- **IAM Access Analyzer** generates a least-privilege policy from CloudTrail activity and flags resources shared outside your account.
- **Last accessed information** shows services a principal never uses, so you can remove those permissions.

## IAM best practices

1. **Lock down the root user.** Enable MFA, create no access keys, and use it only for root-only tasks.
2. **Use federation and IAM Identity Center** for human users instead of individual IAM users where possible.
3. **Prefer roles and temporary credentials** for workloads such as EC2, Lambda, ECS and GitHub Actions OIDC.
4. **Require MFA** for all console users.
5. **Apply least privilege**, then tighten it over time with Access Analyzer.
6. **Manage permissions through groups**, not on individual users.
7. **Use customer-managed policies** rather than inline policies.
8. **Rotate credentials** and remove unused users, keys and roles. Check the *credential report*.
9. **Set a strong password policy.**
10. **Use conditions** such as `aws:MultiFactorAuthPresent`, `aws:SourceIp` and `aws:PrincipalTag` for extra guardrails.
11. **Use permissions boundaries and SCPs** to cap what delegated admins can grant.
12. **Turn on CloudTrail** so every API call is logged and auditable.
13. **Never commit access keys** to Git. Use `aws configure`, environment variables or a secrets manager.

## Common use cases

| Scenario | IAM solution |
|---|---|
| A team of developers needs console and CLI access | IAM Identity Center or IAM users in a `Developers` group |
| An EC2 app reads from S3 | Instance profile (role) with `s3:GetObject` on that bucket |
| A Lambda function writes to DynamoDB | Lambda execution role |
| GitHub Actions deploys with Terraform | OIDC identity provider + role assumed by the workflow |
| An auditor needs read-only access | Group or role with `ReadOnlyAccess` / `SecurityAudit` |
| Account B needs access to a bucket in Account A | Cross-account role, or a bucket policy that names Account B |
| Pods in EKS need AWS access | IRSA / EKS Pod Identity |
| Stop anyone from disabling CloudTrail | SCP with an explicit `Deny` on `cloudtrail:StopLogging` |

## Terraform example

```hcl
resource "aws_iam_group" "developers" {
  name = "developers"
}

resource "aws_iam_group_policy_attachment" "dev_readonly" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role" "ec2_s3_reader" {
  name = "ec2-s3-reader"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
```

## Useful CLI commands

```bash
aws sts get-caller-identity              # which identity am I using?
aws iam list-users
aws iam list-groups-for-user --user-name alice
aws iam list-attached-role-policies --role-name ec2-s3-reader
aws iam generate-credential-report && aws iam get-credential-report
```
