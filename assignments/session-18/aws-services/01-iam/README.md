# AWS IAM - Identity and Access Management

## 1. What is IAM?
AWS Identity and Access Management (IAM) is a web service that helps you securely control access to AWS resources. You use IAM to control who is authenticated (signed in) and authorized (has permissions) to use resources.

## 2. Core Concepts
- **Users**: Individuals or applications needing access to AWS.
- **Groups**: Collections of IAM users sharing permissions.
- **Roles**: Identity with specific permission policies attached, assumable by users, applications, or services.
- **Policies**: JSON documents defining allowed or denied actions on AWS resources.
- **Permissions**: Declarative rules specifying granted actions (e.g., `s3:GetObject`).

## 3. Principle of Least Privilege
Always grant only the permissions required to perform a specific task and no more.

## 4. Best Practices
- Enable Multi-Factor Authentication (MFA) on root and all IAM users.
- Never use the root account for daily operational tasks.
- Rotate credentials and access keys regularly.
- Use IAM Roles for EC2 instances and AWS services instead of long-lived access keys.
