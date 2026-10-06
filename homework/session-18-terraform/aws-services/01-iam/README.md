# IAM

IAM is the AWS service that decides who can call which API. It is the governance layer for the account.

## Users, groups, roles, policies

- A **user** is a long-lived identity for a person or an application that cannot assume a role. Prefer roles for workloads.
- A **group** is a list of users. Attach policies to the group so people with the same job share the same permissions.
- A **role** is an identity that is assumed. EC2, EKS, and GitHub Actions use roles. A role has no password. It hands out temporary credentials.
- A **policy** is a JSON document of `Allow` or `Deny` statements: action, resource, and optional condition.
- A **permission** is the effect of those statements. Explicit `Deny` wins over `Allow`.

## Least privilege

Grant only the actions and resource ARNs the job needs. Start from a service-scoped policy, not `AdministratorAccess`. Review unused permissions. Do not share access keys. Rotate keys. Turn on MFA for humans. Prefer IAM Identity Center for people and roles for machines.

## Use cases

- A deploy role that can `eks:DescribeCluster` and pass the node role, and nothing else.
- A CI role that can push to one ECR repository.
- A break-glass admin role that requires MFA.

Do not commit access keys. This repo does not contain any.
