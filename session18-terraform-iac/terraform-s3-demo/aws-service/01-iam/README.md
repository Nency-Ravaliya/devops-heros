# 01. IAM Governance

## What is IAM?

****IAM = Identity and Access Management****

AWS IAM controls:
- Who can access AWS resources
- What they can access
- What actions they can perform
- Under what conditions they can perform them

IAM is a global aws service

Main components are:
1. Users
2. Groups
3. Roles
4. Policies
5. Permissions

---

## Users:

An IAM user represents a person or application that needs long term AWS access.

A user can have:
- Console password
- Access Keys
- Permissions

Example:

Developer -> IAM User -> AWS Resources

Use IAM users when a specific identity needs long-term credentials

For human users (also known as workforce identities or human identities) AWS generally recommends using termporary credentials via IAM Identity Center instead of long-lived IAM users.

---

## Groups:

A Group is a collection of IAM users.

Instead of giving permission to every user individually, you can assign permissions to the group and all users in the group will get those permissions.


Example:

Developers -> S3 ReadOnly EC2 ReadOnly

Adding a user to the group gives then the group's permissions.

***Why use groups?***

- Easier permission management.
- Avoids repeating policies.
- Easier to manage multiple users.

Groups cannot contain other groups.

---

## Roles:

A Role is an identity that provides temporary permissions.

Unlike a user, a role does not normally have permanent credentials.

A role can be assumed by:
- IAM users
- AWS services
- Applications
- Other AWS accounts

Example:

EC2 -> IAM Role -> S3 permissions

The EC2 instance can access S3 without storing AWS access keys inside the application.

### Common example

An EC2 application needs to read files from S3

Bad approach:

EC2 -> Access Key + Secret Key -> S3

Better approach:

EC2 -> IAM Role -> S3

The role provides temporary credentials

---

## Policies:

A Policy is a JSON document that defines permissions.

Example:

{ 
  "Version": "2012-10-17", 
  "Statement": [ 
    { 
      "Effect": "Allow",
       "Action": "s3:GetObject", 
       "Resource": "arn:aws:s3:::my-bucket/*" 
    } 
  ] 
}

This means:

Allow -> s3:GetObject -> Objects inside my-bucket

### Main policy elements:

- Effect : Defines whether an action is allowed or denied
- Action : Defines what operation is allowed
- Resource : Defines which AWS resource the permission applies to
- Condition : Adds additional rules to a permission.
- Principal : Determine what an identity can do

### Least Previlege:

- Give only the permissions required to perform the task

Example:

Bad:

User -> AdministratorAccess , When the user only needs to read one S3 bucket.

Better:

User -> s3:GetObject -> Specific S3 bucket


***Benefits:***

- Reduces security risk
- Limits damage if credentials are compromised
- Reduces accidental changes
- Makes permissions easier to manage

---

## IAM Best Practices:

- Do not use the root user for normal work
- Enable MFA
- Follow least privilege
- Use IAM roles instead of hardcoded access keys
- Remove unused user and access keys
- Use groups to manage permission for multiple users.
- User temporary credentials where possible.
- Monitor access using CloudTrail and IAM Access Analyzer

---

## Common Use Cases:

**Developer access:**

Developer -> IAM Group -> AWS Resources

EC2 accessing S3:

EC2 -> IAM Role -> S3

**Lambda accessing DynamoDB:**

Lambda -> Execution Role -> DynamoDB

**Cross-account access:**

Account A -> Assume Role -> Account B
