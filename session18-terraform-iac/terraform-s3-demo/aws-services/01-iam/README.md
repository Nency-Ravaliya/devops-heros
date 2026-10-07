# AWS IAM

## Overview
AWS Identity and Access Management (IAM) securely controls access to AWS resources.

## 1. What is IAM?
IAM provides authentication and authorization for AWS resources.

## 2. IAM Users
An IAM user represents a person or application requiring AWS access. Users may have console passwords or programmatic credentials.

## 3. IAM Groups
Groups organize users so common permissions can be managed centrally.

## 4. IAM Roles
Roles provide temporary permissions to users, AWS services, or applications. They are preferred over long-term credentials for workloads.

## 5. IAM Policies
Policies are JSON documents defining allowed or denied actions.

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "s3:ListBucket",
    "Resource": "arn:aws:s3:::example-bucket"
  }]
}
```

## 6. Permissions
Permissions define which AWS actions an identity can perform, such as `s3:GetObject`, `s3:PutObject`, or `ec2:DescribeInstances`.

## 7. Principle of Least Privilege
Give identities only the permissions required for their tasks. Avoid broad permissions such as `*` when specific permissions are sufficient.

## 8. IAM Best Practices
- Enable MFA for privileged users.
- Avoid using the root user for everyday tasks.
- Prefer IAM roles and temporary credentials.
- Never hard-code credentials in source code.
- Review unused permissions regularly.
- Follow least privilege.

## 9. Common Use Cases
- Developer access management
- Application permissions
- EC2-to-S3 access
- CI/CD permissions
- Administrative access

## 10. Architecture
```text
AWS Account
    |
   IAM
 ┌──┼──────┐
Users Groups Roles
    \   |   /
     Policies
        |
 AWS Resources
```

## Summary
| Component | Purpose |
|---|---|
| User | Identity |
| Group | Organizes users |
| Role | Temporary permissions |
| Policy | Defines permissions |
| Least Privilege | Limits access |

## Conclusion
IAM is a core AWS security service used to control access securely through users, groups, roles, policies, and least privilege.
