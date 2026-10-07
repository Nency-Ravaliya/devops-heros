# 01. IAM – Identity and Access Management (Governance)

## What is IAM?
AWS IAM is the free, global service that controls **who** (authentication) can do **what** (authorization) on **which AWS resources**. Every AWS API call is checked against IAM policies. If nothing explicitly allows it, it's denied (**implicit deny**), and an explicit `Deny` always wins.

## Users
- A long-term identity for **one person or application**, with credentials: a console password and/or access keys (`AKIA...`).
- New users have **no permissions** until a policy is attached.
- Best practice: humans sign in through **IAM Identity Center (SSO)** or federation rather than IAM users. Avoid long-lived access keys.

## Groups
- A collection of users (`Developers`, `Admins`, `ReadOnly`). Policies attached to the group apply to every member.
- Groups can't be nested and can't be used as a principal in a resource policy.

## Roles
- An identity with permissions but **no long-term credentials**. Whoever is trusted to **assume** it gets **temporary credentials** from STS (15 min to 12 h).
- A role has two policies: a **trust policy** (who may assume it, e.g. `ec2.amazonaws.com`, another account, a GitHub OIDC provider) and a **permissions policy** (what it can do).
- Used for EC2 instance profiles, Lambda execution roles, EKS IRSA / Pod Identity, cross-account access, and CI/CD (GitHub Actions OIDC → no stored keys).

## Policies
JSON documents made of statements: `Effect`, `Action`, `Resource`, optional `Condition`.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOnlyOneBucket",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::tejas-devops-heros-demo",
        "arn:aws:s3:::tejas-devops-heros-demo/*"
      ],
      "Condition": { "Bool": { "aws:SecureTransport": "true" } }
    }
  ]
}
```

| Type | Notes |
|---|---|
| **AWS managed** | Pre-made by AWS (`ReadOnlyAccess`, `AmazonS3FullAccess`). Easy but usually too broad. |
| **Customer managed** | Your own reusable, versioned policies. |
| **Inline** | Embedded in one user/group/role; deleted with it. |
| **Resource-based** | Attached to the resource (S3 bucket policy, KMS key policy, SQS policy) and names a `Principal`. |
| **Permissions boundary** | Maximum permissions an identity can ever get. |
| **SCP** (AWS Organizations) | Guardrails for whole accounts; they don't grant anything themselves. |

## Permissions – how a request is evaluated
1. Explicit **Deny** anywhere → **denied**.
2. SCP / permissions boundary / session policy must allow it.
3. An identity-based **or** resource-based policy must **Allow** it.
4. Otherwise → implicit deny.

## Least privilege
Grant only the **actions** and **resources** needed, for only as long as needed:
- Start from nothing and add permissions, instead of starting from `*` and removing them.
- Scope `Resource` to specific ARNs and use `Condition` keys (source IP, MFA, tags, `aws:RequestedRegion`).
- Use **IAM Access Analyzer** to generate policies from CloudTrail activity and to find unused permissions or public/cross-account access.

## IAM best practices
- **Lock away the root user:** enable MFA on it, delete its access keys, and use it only for the few root-only tasks.
- **MFA** for every human.
- Prefer **roles + temporary credentials** (SSO, OIDC, instance profiles) over access keys. If keys are unavoidable, **rotate** them and never commit them (see Session 17: secret scanning).
- Manage permissions through **groups/roles**, not per user.
- Use a strong password policy, and review the **credential report** and "last accessed" data regularly.
- Enable **CloudTrail** in all regions to audit every API call.
- Separate environments into **separate accounts** under AWS Organizations, with SCPs.

## Common use cases
| Use case | IAM feature |
|---|---|
| Developers get read-only prod and full dev access | Groups + SSO permission sets per account |
| EC2 app reads from an S3 bucket | IAM role + instance profile (no keys on the server) |
| GitHub Actions deploys with Terraform | OIDC identity provider + role with a trust condition on `repo:TejasVarshney/*` |
| Pods in EKS call DynamoDB | IRSA / EKS Pod Identity |
| Partner account reads a bucket | Cross-account role or bucket policy with their account as `Principal` |
| Prevent anyone disabling CloudTrail | SCP with an explicit `Deny cloudtrail:StopLogging` |
