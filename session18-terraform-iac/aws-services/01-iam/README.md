# AWS Identity and Access Management (IAM) — Deep Dive & Best Practices

**Author:** Durga Prasad  
**Enrollment Number:** 10012  
**Session:** 18 - AWS Cloud & Infrastructure as Code  
**Course:** SST DevOps & Cloud  

---

## 1. What is AWS IAM?

**AWS Identity and Access Management (IAM)** is a foundational web service that helps you securely control access to AWS resources. IAM enables you to specify who is authenticated (signed in) and authorized (has permissions) to use resources.

IAM is **global** (not region-specific) and comes at **no additional charge**.

---

## 2. Core IAM Building Blocks

```text
                           IAM IDENTITY HIERARCHY
                           
                         ┌───────────────────────┐
                         │   AWS Root Account    │ (Break-glass only, MFA enforced)
                         └───────────┬───────────┘
                                     │
                 ┌───────────────────┴───────────────────┐
                 ▼                                       ▼
     ┌───────────────────────┐               ┌───────────────────────┐
     │      IAM Users        │               │       IAM Roles       │
     │  (People or Systems)  │               │   (Assumable Identity)│
     └───────────┬───────────┘               └───────────┬───────────┘
                 │                                       │
                 ▼                                       ▼
     ┌───────────────────────┐               ┌───────────────────────┐
     │      IAM Groups       │               │ Temporary Credentials │
     │  (Collections of Users)               │   (STS: 15m to 12h)   │
     └───────────┬───────────┘               └───────────────────────┘
                 │
                 ▼
     ┌───────────────────────┐
     │     IAM Policies      │ (JSON Documents defining Allow/Deny)
     └───────────────────────┘
```

### 1. IAM Users
An entity representing a person or service that interacts with AWS.
* **Credentials:** Console password (for AWS Management Console) and Access Key ID + Secret Access Key (for AWS CLI / SDK).
* **Best Practice:** Do NOT create access keys for people; use IAM Identity Center (SSO).

### 2. IAM Groups
A collection of IAM users. Permissions applied to a group apply automatically to all members.
* A user can belong to multiple groups.
* Groups cannot be nested (groups cannot contain other groups).

### 3. IAM Roles
An identity with permission policies that determine what the identity can and cannot do in AWS. Unlike users, roles do **not** have permanent credentials (no password or long-term access keys).
* Dynamically assumed by:
  - AWS Services (e.g., an EC2 instance or Lambda function accessing S3).
  - Cross-account access.
  - Federated users (e.g., Google, Okta, Active Directory via OIDC / SAML 2.0).
* Generates temporary security credentials via **AWS STS (Security Token Service)** valid from 15 minutes to 12 hours.

### 4. IAM Policies
JSON documents that explicitly define authorization rules.

#### JSON Policy Structure:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ReadOnlySpecificBucket",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-company-assets",
        "arn:aws:s3:::my-company-assets/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    }
  ]
}
```

* **Effect:** `Allow` or `Deny` (Explicit Deny always overrides any Allow).
* **Action:** List of API operations (e.g., `s3:GetObject`, `ec2:DescribeInstances`).
* **Resource:** Amazon Resource Name (ARN) of the targeted objects.
* **Condition:** Contextual constraints (e.g., require TLS/HTTPS, require MFA, restrict by source IP range).

---

## 3. The Principle of Least Privilege

> *"Grant only the permissions required to perform a specific task, for only the time needed, and nothing more."*

Never grant `AdministratorAccess` or wildcard `*` permissions to application roles or developers. Start with minimal read-only permissions and expand deliberately as application specifications require.

---

## 4. IAM Security Best Practices Checklist

1. **Lock Away the AWS Root User:** Enable hardware MFA, generate no access keys, and use root only for billing changes or account closure.
2. **Enforce Multi-Factor Authentication (MFA):** Require MFA for every human console identity.
3. **Use Roles for Applications and EC2:** Never bake access keys into code, config files, or Docker images. Attach an IAM Instance Profile to EC2.
4. **Rotate Credentials Regularly:** Automatically expire access keys older than 90 days.
5. **Use AWS IAM Access Analyzer:** Continuously analyze policies to identify external or unintended public access.

---

## 5. Common Use Cases

* **EC2 to S3 Data Access:** Attach an IAM Role with `AmazonS3ReadOnlyAccess` to an EC2 instance profile so applications call `aws s3 cp` without hardcoding credentials.
* **GitHub Actions CI/CD to AWS:** Use GitHub's OpenID Connect (OIDC) identity provider to assume an AWS IAM Role securely without storing static AWS access keys in GitHub Secrets.
* **Cross-Account Staging/Production Isolation:** Developers in the `Dev` AWS account assume a scoped IAM role in the `Production` account to trigger releases.
