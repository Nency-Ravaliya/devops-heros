# AWS Identity and Access Management (IAM) - Governance

**Name:** Smit Rupani  
**Enrollment:** 24bcs10256  

---

## 1. What is IAM?
AWS IAM is a web service that helps you securely control access to AWS resources. It provides centralized authentication and authorization across your entire AWS cloud estate.

## 2. Core Components
- **Users:** An identity representing a specific human or application (e.g. `smit-admin`). Has long-term credentials (password, access keys).
- **Groups:** A collection of IAM users. Permissions applied to a group are inherited by all group members (e.g. `DevOpsEngineers`).
- **Roles:** An identity that can be assumed by anyone who needs it (users, AWS services like EC2/Lambda, or external federated identities). Uses temporary security credentials.
- **Policies:** JSON documents explicitly stating Allowed or Denied actions on specific resources:
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["s3:GetObject", "s3:ListBucket"],
        "Resource": ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"]
      }
    ]
  }
  ```

## 3. Best Practices
1. **Principle of Least Privilege:** Grant only the exact minimum permissions required to perform the task.
2. **Lock Away Root User:** Never use the root account for daily operational tasks. Enable MFA immediately.
3. **Use Roles for Compute:** Never hardcode AWS API keys inside EC2 instances or Lambda functions; attach an IAM Role (Instance Profile) instead.
