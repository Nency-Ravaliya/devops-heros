# IAM

IAM controls who can perform which actions on which AWS resources. Users
represent identities; groups collect users and policies. Roles provide temporary
credentials to services or federated people. Policies define allowed/denied
actions, resources and conditions; explicit deny overrides allow. Apply least
privilege, MFA and short-lived role/SSO sessions. Avoid daily root use and keys
in source. Example: an EC2 role can read one S3 bucket without embedding a user key.

Reference: https://docs.aws.amazon.com/
