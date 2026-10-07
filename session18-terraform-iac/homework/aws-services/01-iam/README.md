# IAM — Identity and Access Management

**What:** Global AWS service that controls **who** (authentication) can do **what** on **which resources** (authorization). Free of charge.

## Core Concepts
| Concept | Description |
|---|---|
| **Root user** | Email used to create the account; full access. Lock it with MFA, never use day-to-day. |
| **User** | Identity for one person/app with long-term credentials (password and/or access keys). |
| **Group** | Collection of users; attach policies once, all members inherit them (e.g. `Developers`, `Admins`). Groups can't be nested. |
| **Role** | Identity with **temporary** credentials (via STS) that is *assumed* by AWS services (EC2, Lambda), other accounts, or federated users. No password/keys. |
| **Policy** | JSON document of permissions attached to a user, group or role. |

## Policies & Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject", "s3:PutObject"],
    "Resource": "arn:aws:s3:::my-bucket/*"
  }]
}
```
- **Effect** Allow/Deny · **Action** API calls · **Resource** ARNs · optional **Condition** (IP, MFA, tags).
- Types: **AWS-managed** (e.g. `ReadOnlyAccess`), **customer-managed** (reusable, versioned), **inline** (embedded in one identity), **resource-based** (on the resource, e.g. S3 bucket policy, role trust policy).
- Evaluation: everything is **denied by default** → an explicit **Allow** grants → an explicit **Deny always wins**.
- Permission boundaries and SCPs (AWS Organizations) cap the maximum permissions.

## Least Privilege
Grant only the actions and resources needed for the task, nothing more. Start narrow and add as required; use IAM Access Analyzer / "last accessed" data to trim unused permissions.

## Best Practices
- Enable **MFA** on root and all human users; delete root access keys.
- Use **roles** (not access keys) for EC2, Lambda, CI/CD (GitHub OIDC → role).
- Manage permissions through **groups**, not individual users.
- Prefer IAM Identity Center (SSO) for humans.
- Rotate any access keys; never commit them to git.
- Strong password policy; audit with **CloudTrail** and the credential report.

## Use Cases
- Separate admin / developer / read-only access for a team.
- EC2 instance role to read from S3 without storing keys.
- Cross-account access (e.g. prod account assumes a role in a logging account).
- Terraform / GitHub Actions deploying with a scoped role.
