# 01 - AWS IAM (Identity and Access Management)

- **Student:** Sourabh Srivastva
- **Enrollment No.:** 24BCS10157
- **Session:** 18 - Terraform & IaC (Task 2: AWS core services)

## Checklist

- [x] What is IAM
- [x] Users
- [x] Groups
- [x] Roles
- [x] Policies (with example JSON policy)
- [x] Permissions (how a request is evaluated)
- [x] Least privilege
- [x] Best practices
- [x] Use cases

---

## What is IAM?

IAM is the AWS service that answers two questions for **every** AWS API call:

1. **Authentication** - *who* is making the request? (user, role, federated identity)
2. **Authorization** - *is that identity allowed* to perform this action on this resource?

It is **global** (not tied to a region) and free of charge. Every AWS account starts with a **root user**
(the sign-up email) that has unrestricted access; everything else is built with IAM.

```text
 Principal (user / role)  --->  Request: Action + Resource + Context  --->  IAM policy evaluation  ---> Allow / Deny
```

## Users

- An **IAM user** is a long-lived identity for one person or one application.
- Credentials: a **console password** (+ MFA) and/or up to two **access keys** (`AKIA...` + secret) for CLI/SDK.
- A brand-new user has **no permissions** until policies are attached.
- Modern recommendation: humans sign in through **IAM Identity Center (SSO)** with temporary credentials;
  plain IAM users are kept for break-glass or legacy cases.

## Groups

- A **group** is a collection of users; policies attached to the group apply to all its members.
- Used to manage permissions by job function: `developers`, `admins`, `auditors`.
- Groups cannot be nested and a group is **not** a principal (you can't put a group in a policy's `Principal`).

## Roles

- A **role** is an identity with permissions but **no long-term credentials**. Whoever *assumes* it
  (via STS `AssumeRole`) receives **temporary credentials** (default 1 h).
- A role has two policies:
  - **Trust policy** - *who* may assume the role (an AWS service, another account, a SAML/OIDC provider).
  - **Permissions policy** - *what* the role can do once assumed.
- Typical assumers: EC2 instances (instance profile), Lambda functions, ECS tasks, GitHub Actions via OIDC,
  users from another AWS account.

Example trust policy letting EC2 assume a role:

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

## Policies

A **policy** is a JSON document of one or more statements. Each statement has:

| Element | Meaning |
|---|---|
| `Effect` | `Allow` or `Deny` |
| `Action` | API operations, e.g. `s3:GetObject`, `ec2:*` |
| `Resource` | ARNs the statement applies to |
| `Condition` | optional extra checks (source IP, MFA present, tags, time, ...) |
| `Principal` | only in **resource-based** policies (who the policy grants access to) |

Policy types:

- **Identity-based** - attached to a user, group or role. Either **AWS managed** (e.g. `ReadOnlyAccess`),
  **customer managed** (reusable, versioned, you own it) or **inline** (embedded in one identity).
- **Resource-based** - attached to a resource, e.g. S3 bucket policy, SQS queue policy, KMS key policy.
- **Permission boundaries** - the maximum permissions an identity-based policy can grant.
- **SCPs (Service Control Policies)** - AWS Organizations guardrails for whole accounts.
- **Session policies** - further restrict a temporary session.

### Example: least-privilege read-only policy for one bucket

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListOneBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::sourabh-reports"
    },
    {
      "Sid": "ReadObjectsInBucket",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::sourabh-reports/*"
    }
  ]
}
```

Note the two ARNs: `ListBucket` acts on the **bucket** ARN, `GetObject` on **object** ARNs (`/*`).

## Permissions - how a request is evaluated

```text
1. Explicit Deny anywhere (SCP, boundary, identity or resource policy)?  ---> DENY
2. Allowed by SCPs / permission boundary / session policy (if present)?   ---> otherwise DENY
3. Explicit Allow in an identity policy or resource policy?               ---> ALLOW
4. Nothing matched                                                         ---> implicit DENY (default)
```

Key rule: **everything is denied by default; an explicit Deny always wins over any Allow.**

## Least privilege

Grant only the actions, on only the resources, under only the conditions that a task actually needs - nothing more.

- Start from zero and add permissions as needed (not `"Action": "*"`).
- Scope `Resource` to specific ARNs instead of `*`.
- Use `Condition` keys (e.g. `aws:SourceIp`, `aws:MultiFactorAuthPresent`, `aws:ResourceTag/...`).
- Use **IAM Access Analyzer** to generate policies from CloudTrail activity and find unused permissions.
- Review regularly using *last accessed* information and remove what isn't used.

## Best practices

1. **Lock away the root user**: enable MFA, delete root access keys, use it only for the few root-only tasks.
2. Use **IAM Identity Center / federation** for humans -> temporary credentials, no long-lived keys.
3. Use **roles** for workloads (EC2 instance profiles, Lambda execution roles, OIDC for CI) - never hard-code keys.
4. Enforce **MFA** for all human users.
5. Manage permissions through **groups** (or permission sets), not per-user.
6. Apply **least privilege**; prefer customer-managed policies over broad AWS-managed ones.
7. **Rotate** any access keys that must exist; remove unused users, keys and roles.
8. Use **permission boundaries** and **SCPs** as guardrails.
9. Turn on **CloudTrail** to audit who did what.
10. Strong password policy for any console users.

## Use cases

| Use case | IAM feature |
|---|---|
| Team of developers needs read-only prod access | Group `developers` + `ReadOnlyAccess` (or a scoped custom policy) |
| EC2 app must read from an S3 bucket | Role + instance profile, permissions policy like the one above |
| GitHub Actions deploys with Terraform | IAM OIDC provider + role trusted for `token.actions.githubusercontent.com` |
| Auditor from another company | Cross-account role with `SecurityAudit`, assumed with an external ID |
| Prevent anyone from leaving a region | SCP with `Deny` + `aws:RequestedRegion` condition |

---

## Hands-on (run against LocalStack, an AWS emulator)

The commands below were run against LocalStack 3.8 (`--endpoint-url http://localhost:4566` omitted from the
displayed commands for readability). Account ID `000000000000` is LocalStack's default; on real AWS you would
see your 12-digit account ID. **LocalStack community does not enforce IAM policies by default**, so this
demonstrates the API/resource model, not real permission enforcement.

```text
$ aws iam create-group --group-name developers
{
    "Group": {
        "Path": "/",
        "GroupName": "developers",
        "GroupId": "apvklzixzxgzf127pmix",
        "Arn": "arn:aws:iam::000000000000:group/developers",
        "CreateDate": "2026-10-06T11:18:23.940000+00:00"
    }
}

$ aws iam create-user --user-name sourabh-dev
{
    "User": {
        "Path": "/",
        "UserName": "sourabh-dev",
        "UserId": "ou3x3v3g9udh8wc4rhhn",
        "Arn": "arn:aws:iam::000000000000:user/sourabh-dev",
        "CreateDate": "2026-10-06T11:18:24.210000+00:00"
    }
}

$ aws iam add-user-to-group --group-name developers --user-name sourabh-dev

$ aws iam create-policy --policy-name ReportsReadOnly --policy-document file://readonly-s3.json
{
    "Policy": {
        "PolicyName": "ReportsReadOnly",
        "PolicyId": "AXMH8PVC7J6L8WBKGWNBS",
        "Arn": "arn:aws:iam::000000000000:policy/ReportsReadOnly",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        ...
    }
}

$ aws iam attach-group-policy --group-name developers --policy-arn arn:aws:iam::000000000000:policy/ReportsReadOnly

$ aws iam list-attached-group-policies --group-name developers
{
    "AttachedPolicies": [
        {
            "PolicyName": "ReportsReadOnly",
            "PolicyArn": "arn:aws:iam::000000000000:policy/ReportsReadOnly"
        }
    ]
}

$ aws iam get-group --group-name developers --query "Users[].UserName"
[
    "sourabh-dev"
]
```

(`readonly-s3.json` is the example policy shown above. All resources were deleted afterwards.)

### Same thing in Terraform

```hcl
resource "aws_iam_group" "developers" {
  name = "developers"
}

resource "aws_iam_user" "dev" {
  name = "sourabh-dev"
}

resource "aws_iam_user_group_membership" "dev" {
  user   = aws_iam_user.dev.name
  groups = [aws_iam_group.developers.name]
}

data "aws_iam_policy_document" "reports_ro" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::sourabh-reports"]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::sourabh-reports/*"]
  }
}

resource "aws_iam_policy" "reports_ro" {
  name   = "ReportsReadOnly"
  policy = data.aws_iam_policy_document.reports_ro.json
}

resource "aws_iam_group_policy_attachment" "dev_reports" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.reports_ro.arn
}
```
