# AWS IAM (Identity and Access Management) - Governance

Prepared by: Yash Gaikwad (Roll no. 24BCS10100)
Category: Security / Governance

IAM is the service that decides **who** can do **what** on **which** AWS resources. Every API call in AWS, whether it comes from the console, the CLI, Terraform or an application, is authenticated and then authorised by IAM. Because Terraform in this course creates real AWS resources, understanding IAM is the first thing I need before running `terraform apply` safely.

IAM is a global service (not tied to one region) and it is free to use; you only pay for the resources the identities create.

---

## What is IAM

- A web service for managing identities (authentication) and permissions (authorisation) inside one AWS account.
- **Authentication** = proving who you are (password + MFA, access keys, temporary role credentials).
- **Authorisation** = what you are allowed to do once authenticated (policies).
- The very first identity in an account is the **root user** (email + password). It has unrestricted access and should only be used for the few tasks that require it, with MFA enabled and no access keys.

How a request is evaluated (this is the part I want to remember):

1. Everything is **implicitly denied** by default.
2. An explicit **Allow** in an applicable policy can override that default.
3. An explicit **Deny** anywhere always wins over any Allow.

Organisation-level guardrails (Service Control Policies) and permission boundaries can only *limit* what is allowed; they never grant permissions on their own.

---

## Users

- An IAM **user** represents one person or one application that needs long-term credentials.
- Credentials a user can have: a console password, and up to two access key pairs (`AKIA...` access key ID + secret access key).
- A new user has **no permissions** until a policy is attached (directly or through a group).
- Today AWS recommends human users sign in through **IAM Identity Center** (SSO) rather than creating many IAM users. IAM users with access keys are mostly legacy or for third-party tools that cannot assume roles.

```bash
aws iam create-user --user-name dev-yash
aws iam create-login-profile --user-name dev-yash --password-reset-required --password '<TEMP_PASSWORD>'
aws iam create-access-key --user-name dev-yash
```

---

## Groups

- A **group** is a collection of users. Permissions attached to the group are inherited by every member.
- A user can be in several groups (up to 10); groups cannot be nested and a group cannot be a principal in a trust/resource policy.
- Best used to model job functions: `developers`, `auditors`, `devops-admins`.

```bash
aws iam create-group --group-name developers
aws iam attach-group-policy --group-name developers --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
aws iam add-user-to-group --group-name developers --user-name dev-yash
```

---

## Roles

- A **role** is an identity with permissions but **no long-term credentials**. Whoever (or whatever) assumes it gets **temporary credentials** from AWS STS (default 1 hour).
- Every role has two kinds of policy:
  - **Trust policy** (who may assume the role)
  - **Permissions policy** (what the role can do after being assumed)
- Typical principals that assume roles: AWS services (EC2, Lambda, ECS tasks), other AWS accounts, federated identities (SAML/OIDC, for example GitHub Actions OIDC), and IAM users.
- For EC2 the role is delivered through an **instance profile**; the application reads temporary keys from the instance metadata service, so no keys are stored on disk.

---

## Policies

- A policy is a JSON document that lists permissions. Main elements: `Effect`, `Action`, `Resource`, optional `Condition`, and `Principal` (only in resource-based policies).
- Types I need to know:

| Policy type | Attached to | Example |
|---|---|---|
| AWS managed | users, groups, roles | `AmazonS3ReadOnlyAccess` |
| Customer managed | users, groups, roles | my own reusable JSON |
| Inline | exactly one user/group/role | one-off exception |
| Resource-based | a resource | S3 bucket policy, role trust policy |
| Permissions boundary | user or role | sets the maximum permissions |
| SCP (Organizations) | account / OU | org-wide guardrail |

---

## Permissions

- Permissions are expressed as `service:Action` pairs, for example `s3:GetObject`, `ec2:RunInstances`, `iam:PassRole`.
- `Resource` uses ARNs (`arn:aws:s3:::bucket-name/*`). The bucket ARN and the object ARN are different, which is why S3 policies usually need two statements.
- `Condition` narrows when a statement applies (source IP, MFA present, tag value, region, and so on).
- `NotAction`, wildcards (`*`) and `"Resource": "*"` should be used sparingly because they widen access quickly.

---

## Least privilege

Least privilege means granting only the permissions required for the task and nothing more.

Practical approach I would follow:

1. Start with zero permissions and add what the workload actually needs.
2. Scope `Resource` to specific ARNs instead of `*`.
3. Add `Condition` keys where possible.
4. Review unused permissions with IAM Access Analyzer / "last accessed" data and remove them.
5. Test with the policy simulator before rolling out.

### Example 1: read-only access to a single S3 bucket

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListTheBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket", "s3:GetBucketLocation"],
      "Resource": "arn:aws:s3:::my-app-reports-bucket"
    },
    {
      "Sid": "ReadObjects",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:GetObjectVersion"],
      "Resource": "arn:aws:s3:::my-app-reports-bucket/*"
    }
  ]
}
```

`ListBucket` acts on the bucket itself, `GetObject` acts on objects inside it. There is no write or delete action, and no other bucket is reachable.

### Example 2: trust policy so EC2 can assume a role

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Putting both together with the CLI

```bash
aws iam create-policy \
  --policy-name S3ReadOnlyReportsBucket \
  --policy-document file://s3-read-only.json

aws iam create-role \
  --role-name ec2-reports-reader \
  --assume-role-policy-document file://ec2-trust.json

aws iam attach-role-policy \
  --role-name ec2-reports-reader \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/S3ReadOnlyReportsBucket

# The console creates an instance profile automatically; the CLI does not.
aws iam create-instance-profile --instance-profile-name ec2-reports-reader
aws iam add-role-to-instance-profile \
  --instance-profile-name ec2-reports-reader \
  --role-name ec2-reports-reader

# Check who I am at any time
aws sts get-caller-identity
```

### Same idea in Terraform

```hcl
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "reports_reader" {
  name               = "ec2-reports-reader"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_instance_profile" "reports_reader" {
  name = "ec2-reports-reader"
  role = aws_iam_role.reports_reader.name
}
```

---

## IAM best practices

- Turn on **MFA** for the root user and for all human users; do not create root access keys.
- Use **roles and temporary credentials** instead of long-term access keys wherever possible.
- Prefer **groups / roles** for permissions rather than attaching policies to individual users.
- Apply **least privilege**, and use customer managed policies for anything reused.
- Never hard-code or commit access keys to Git (this ties in with the DevSecOps session). Use secret scanners and rotate any key that leaks.
- **Rotate** or delete unused credentials; check the credential report regularly.
- Use **conditions** (MFA, source IP, region, tags) for sensitive actions.
- Use **permissions boundaries** when delegating the ability to create roles.
- Enable **CloudTrail** so every IAM and API action is auditable.
- Use **IAM Access Analyzer** to find resources shared outside the account and to generate policies from activity.
- Use separate AWS accounts (AWS Organizations) for dev / prod and use SCPs as guardrails.

---

## Common use cases

| Scenario | IAM building block |
|---|---|
| EC2 app reading from S3 | EC2 instance profile with a role |
| Lambda writing to DynamoDB | Lambda execution role |
| CI/CD pipeline deploying to AWS | GitHub Actions OIDC provider + role (no stored keys) |
| Developer team with shared permissions | Group + managed policy |
| Cross-account access (prod account reads from shared account) | Role with trust policy for the other account |
| Pods in EKS accessing AWS APIs | IRSA / EKS Pod Identity role |
| Temporary elevated access for an engineer | Role assumed with MFA condition |
| Terraform running from a laptop | SSO profile or assumed role, not a root key |

---

## Interview quick points

- IAM is global, free, and is the AWS authentication + authorisation service.
- Default is implicit deny; explicit deny always overrides allow.
- User = long-term credentials for a person/app; Group = set of users; Role = temporary credentials assumed by someone/something.
- A role has a **trust policy** (who can assume) and **permissions policies** (what it can do).
- Groups cannot be nested and cannot be principals.
- Identity-based policies attach to identities; resource-based policies attach to resources and include a `Principal`.
- Permissions boundary and SCP set a ceiling but do not grant anything by themselves.
- Roles for EC2 are passed using an instance profile; credentials are rotated automatically via IMDS.
- `iam:PassRole` is required to give a role to a service, and it is a common privilege-escalation path if granted with `Resource: "*"`.
- Root user: enable MFA, do not use daily, no access keys.
- Access keys are for programmatic access; max 2 per user; rotate them.
- The policy simulator and Access Analyzer help to verify and tighten permissions.
