# 01. IAM: Identity and Access Management (Governance)

## What is IAM?

**AWS Identity and Access Management (IAM)** controls **who** (authentication) can do **what** (authorisation) on **which AWS resources**, and under what conditions. It is a global service (not tied to a region), and it's free.

Every API call to AWS (console click, CLI command, Terraform apply, SDK call from an app) is signed with credentials. IAM evaluates the policies attached to that identity and returns **Allow** or **Deny**.

```text
Principal (who)  ──request──▶  IAM policy evaluation  ──▶  Allow / Deny
user / role / service            identity policies
                                 + resource policies
                                 + permission boundaries
                                 + SCPs (AWS Organizations)
                                 + session policies
```

## Root user

The account's **root user** (the e-mail used to create the account) has unrestricted access and can't be limited by IAM policies. Best practice: enable MFA on it, delete its access keys, and use it only for the few tasks that require it (billing settings, closing the account).

## Users

An **IAM user** is a long-lived identity for a person or application, with:
- a **console password** (optionally with MFA), and/or
- **access keys** (access key ID + secret access key) for the CLI/SDK.

Today AWS recommends using as few IAM users as possible: humans should sign in through **IAM Identity Center (SSO)** and get temporary credentials, and workloads should use **roles**.

## Groups

A **group** is a collection of users. Policies are attached to the group, and every member inherits them. For example: `Developers` (read/write to dev resources), `Admins`, `ReadOnly`. Groups can't be nested and aren't principals themselves (you can't reference a group in a resource policy).

## Roles

A **role** is an identity with permissions but **no long-term credentials**. Someone or something **assumes** it via AWS STS and receives **temporary credentials** (default 1 hour). A role has two policies:
- **Trust policy:** *who* may assume the role (an AWS service such as `ec2.amazonaws.com`, another account, a federated identity such as GitHub Actions OIDC).
- **Permission policy:** *what* the role can do.

Typical uses:
- **EC2 instance profile:** an app on EC2 reads S3 without storing keys.
- **Lambda execution role**, **ECS task role**, **EKS IRSA / Pod Identity:** per-workload permissions.
- **Cross-account access:** a role in the prod account trusted by the tooling account.
- **CI/CD via OIDC:** GitHub Actions assumes a role with `AssumeRoleWithWebIdentity`, so no AWS keys are stored in GitHub secrets.

## Policies

Policies are **JSON documents** made of statements:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOneBucket",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::session18-tf-demo-*",
        "arn:aws:s3:::session18-tf-demo-*/*"
      ],
      "Condition": { "Bool": { "aws:SecureTransport": "true" } }
    }
  ]
}
```

| Element | Meaning |
|---|---|
| `Effect` | `Allow` or `Deny` |
| `Action` | API operations, e.g. `s3:GetObject`, `ec2:StartInstances` (wildcards allowed) |
| `Resource` | ARNs the statement applies to |
| `Condition` | Extra checks: source IP, MFA present, tags, TLS, time, VPC endpoint… |
| `Principal` | Only in resource-based policies: who the policy applies to |

Policy types:
- **AWS managed** (e.g. `ReadOnlyAccess`, `AmazonS3ReadOnlyAccess`): convenient but usually too broad.
- **Customer managed:** your own reusable policies; preferred.
- **Inline:** embedded in a single user, group or role; use rarely.
- **Resource-based:** attached to the resource (S3 bucket policy, KMS key policy, SQS queue policy) and name a `Principal`.
- **Permission boundaries:** the *maximum* permissions an identity can ever get.
- **Service Control Policies (SCPs):** guardrails across accounts in AWS Organizations.

## Permissions: how a request is evaluated

1. By default everything is **implicitly denied**.
2. An **explicit Deny** in any applicable policy always wins.
3. Otherwise, the request is allowed only if some policy **Allows** it, *and* it is within any SCP, permission boundary and session policy that applies.

```text
explicit Deny anywhere? ── yes ──▶ DENY
        │ no
Allowed by SCP / boundary / session (if present)? ── no ──▶ DENY
        │ yes
Allowed by an identity or resource policy? ── no ──▶ DENY (implicit)
        │ yes
      ALLOW
```

## Least privilege

Give every identity **only the permissions it needs, for only as long as it needs them**:
- Start from zero and add specific actions on specific resource ARNs, not `"Action": "*"` / `"Resource": "*"`.
- Use **conditions** (tags, source VPC, MFA) to narrow further.
- Use **IAM Access Analyzer** to generate policies from CloudTrail activity and to find unused permissions and external access.
- Review regularly; remove unused users, keys and roles (credential report, "last accessed" data).

## IAM best practices

1. Lock away the **root user**: MFA, no access keys.
2. **MFA** for every human.
3. Prefer **temporary credentials**: IAM Identity Center for people, roles for workloads, OIDC for CI/CD. Avoid long-lived access keys; if you must use them, rotate them and never commit them to Git.
4. **Least privilege**, using customer-managed policies attached to **groups/roles**, not to individual users.
5. Use **conditions** and **permission boundaries** for delegated administration.
6. Separate environments into **separate accounts** (AWS Organizations) with SCP guardrails.
7. Turn on **CloudTrail** in all regions to audit every API call.
8. Use **Access Analyzer**, credential reports and "last accessed" information to clean up.
9. Strong password policy for any remaining IAM users.

## Common use cases

- A developer team gets read/write to dev and read-only to prod (groups + policies, or Identity Center permission sets).
- An application on EC2/ECS/Lambda/EKS reads a specific S3 bucket and DynamoDB table (role with a scoped policy).
- GitHub Actions deploys with Terraform (OIDC role trusted only for one repo and branch).
- An auditor gets read-only access across all accounts (cross-account role + `SecurityAudit`).
- An S3 bucket allows uploads only from one account's role (bucket policy with `Principal`).

## In this course

In Session 18 Terraform authenticates with the credentials of my AWS CLI profile. In a real setup that profile would be an Identity Center user or a role with only the S3/EC2/VPC permissions the project needs. CI would use OIDC instead of stored keys, as the GitHub Actions projects in Sessions 16–17 do with `GITHUB_TOKEN`.
