# AWS IAM

## What is IAM?
AWS Identity and Access Management (IAM) controls who can access AWS resources and what actions they can perform.

## Users
IAM users represent individual identities that need access to AWS resources.

## Groups
Groups are collections of IAM users. Permissions can be assigned to a group instead of configuring each user separately.

## Roles
IAM roles provide temporary permissions that can be assumed by users, applications, or AWS services.

## Policies
Policies are JSON documents that define permissions. They specify which actions are allowed or denied on which resources.

## Permissions
Permissions determine what actions an identity can perform on AWS resources.

## Least Privilege
Least privilege means giving users and applications only the permissions they need to perform their tasks.

## Best Practices
- Use least-privilege permissions.
- Enable MFA for users.
- Avoid using the root account for daily tasks.
- Use roles for applications and AWS services.
- Regularly review permissions.

## Common Uses
IAM is commonly used to control access to AWS services, manage users and groups, provide permissions to applications, and secure AWS resources.
