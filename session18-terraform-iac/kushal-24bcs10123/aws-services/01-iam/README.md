# 01 – IAM (Identity and Access Management) – Governance

**Name:** Kushal Talati · **Enrollment No:** 24BCS10123

IAM is the AWS service that answers one question for every single API call: *"is this caller allowed to do this action on this resource?"* It is global (not per region), free, and every other service depends on it. Nothing in AWS happens without an IAM decision first.

The hands-on part of these notes was run against LocalStack (`aws --endpoint-url=http://localhost:4566 iam ...`), raw output in [`../../logs/02-aws-services-hands-on.txt`](../../logs/02-aws-services-hands-on.txt) under the `01 IAM` header. The policy JSON files used are in this folder.

## The building blocks

```text
            who is calling?                        what are they allowed to do?
   ┌───────────────────────────┐             ┌──────────────────────────────────┐
   │  User   (a person / CLI)  │──member of──│  Group   (just a bag of users)    │
   │  Role   (assumed, temp)   │             │                                  │
   └───────────┬───────────────┘             └───────────────┬──────────────────┘
               │   policies attach to users, groups and roles │
               ▼                                             ▼
          ┌──────────────────────────────────────────────────────────┐
          │  Policy = JSON document: Effect / Action / Resource / Condition │
          └──────────────────────────────────────────────────────────┘
```

| Concept | What it is | One-liner I use to remember it |
|---|---|---|
| **User** | A permanent identity for a person or an application that needs long-lived access keys or a console password. | "A login". Should be rare; humans should federate (SSO), apps should use roles. |
| **Group** | A collection of users. Policies attached to the group apply to every member. Groups cannot be nested and cannot be a principal in a policy. | "A job title": `developers`, `billing`, `read-only`. |
| **Role** | An identity with permissions but **no** long-term credentials. Something *assumes* it (an EC2 instance, a Lambda, a user from another account, a CI runner) and gets temporary STS credentials (15 min – 12 h). | "A hat anyone trusted can put on for a while". |
| **Policy** | A JSON document listing statements of `Effect` (Allow/Deny), `Action` (`s3:GetObject`), `Resource` (ARN) and optional `Condition`. Managed (reusable, has its own ARN) or inline (glued to one identity). | "The rule book". |
| **Permission** | The result of evaluating all policies that apply: explicit **Deny** always wins → otherwise any **Allow** → otherwise implicit deny. | "Deny beats allow, silence means no". |

### Identity-based vs resource-based policies

* **Identity-based** policies are attached to a user/group/role and say what *that identity* may do (my `least-privilege-policy.json`).
* **Resource-based** policies are attached to the resource (S3 bucket policy, SQS queue policy, KMS key policy) and name the *principals* allowed in. They are how cross-account access works without creating users.
* A **trust policy** is the special resource-based policy on a role that says *who may assume it* (`ec2-trust-policy.json` below).

## What I actually ran

Create a user, a group, add the user to the group:

```text
$ awsl iam create-user --user-name s18-dev-kushal
{ "UserName": "s18-dev-kushal", "Arn": "arn:aws:iam::000000000000:user/s18-dev-kushal" }
$ awsl iam create-group --group-name s18-developers
$ awsl iam add-user-to-group --user-name s18-dev-kushal --group-name s18-developers
```

A least-privilege managed policy – read one bucket and nothing else (two statements because `ListBucket` is a *bucket* action and `GetObject` is an *object* action, so their Resource ARNs differ):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Sid": "ListOnlyThisBucket",        "Effect": "Allow", "Action": ["s3:ListBucket"], "Resource": "arn:aws:s3:::s18-notes-kushal" },
    { "Sid": "ReadObjectsOnlyThisBucket", "Effect": "Allow", "Action": ["s3:GetObject"],  "Resource": "arn:aws:s3:::s18-notes-kushal/*" }
  ]
}
```

```text
$ awsl iam create-policy --policy-name s18-readonly-one-bucket --policy-document file://least-privilege-policy.json
{ "PolicyName": "s18-readonly-one-bucket", "Arn": "arn:aws:iam::000000000000:policy/s18-readonly-one-bucket" }
$ awsl iam attach-group-policy --group-name s18-developers --policy-arn arn:aws:iam::000000000000:policy/s18-readonly-one-bucket
$ awsl iam list-attached-group-policies --group-name s18-developers
{ "AttachedPolicies": [ { "PolicyName": "s18-readonly-one-bucket", "PolicyArn": "arn:aws:iam::000000000000:policy/s18-readonly-one-bucket" } ] }
```

A role for EC2: the trust policy names the EC2 service as the principal, then the same permissions policy is attached. An instance launched with this role gets rotating credentials from the instance metadata service and never needs an access key on disk.

```json
{ "Version": "2012-10-17",
  "Statement": [ { "Effect": "Allow", "Principal": { "Service": "ec2.amazonaws.com" }, "Action": "sts:AssumeRole" } ] }
```

```text
$ awsl iam create-role --role-name s18-ec2-app-role --assume-role-policy-document file://ec2-trust-policy.json
{ "RoleName": "s18-ec2-app-role", "Arn": "arn:aws:iam::000000000000:role/s18-ec2-app-role" }
$ awsl iam attach-role-policy --role-name s18-ec2-app-role --policy-arn arn:aws:iam::000000000000:policy/s18-readonly-one-bucket
```

And the thing to avoid – a long-lived access key on a user (this is exactly the kind of key that leaks into git):

```text
$ awsl iam create-access-key --user-name s18-dev-kushal
{ "UserName": "s18-dev-kushal", "AccessKeyId": "LKIAQAAAAAAAJDQS2PPA", "Status": "Active"   (LocalStack fake key, deleted again in the cleanup step) }
```

## Least privilege

Give every identity the *minimum* set of actions, on the *narrowest* resources, for the *shortest* time. Practically:

1. Start from zero (implicit deny) and add actions as the application fails with `AccessDenied`, instead of starting from `AdministratorAccess` and trimming.
2. Scope `Resource` to ARNs, not `"*"`; use `Condition` (`aws:SourceIp`, `aws:MultiFactorAuthPresent`, `s3:prefix`) to narrow further.
3. Prefer **roles with temporary credentials** over users with access keys.
4. Use **IAM Access Analyzer** / last-accessed data to remove permissions that are never used.

## IAM best practices (the checklist I would apply to a new account)

* Lock the **root user** away: strong password, hardware MFA, no access keys, use it only for the handful of tasks that need it.
* **MFA for every human**, and humans sign in through IAM Identity Center / SSO instead of IAM users.
* **Roles for workloads** (EC2 instance profile, EKS IRSA / Pod Identity, Lambda execution role, GitHub Actions OIDC) – no static keys in config files, Docker images or CI secrets where a role could be used.
* **Groups, not per-user policies**; managed policies, not inline, so they are reusable and reviewable.
* **Rotate** any key that must exist, and set up a credential report to catch unused ones.
* **Permission boundaries** and **Service Control Policies** (in Organizations) as guard rails so that even an admin cannot exceed them.
* Enable **CloudTrail** – every IAM decision is logged, which is how a leaked key is detected.

## Common use cases

| Scenario | IAM piece used |
|---|---|
| Developer needs CLI access to a dev account | IAM Identity Center user in a `developers` permission set (or an IAM user in a group, with MFA) |
| App on EC2 reads from S3 | Role + instance profile (`s18-ec2-app-role` pattern) |
| Kubernetes pod reads a secret | IRSA / Pod Identity – a role trusted by the cluster OIDC provider |
| GitHub Actions deploys to AWS | Role trusted by `token.actions.githubusercontent.com`, no secrets stored in GitHub |
| Another AWS account needs read access to a bucket | Bucket policy naming their role + a role in my account they assume |
| Temporary elevated access for an incident | `sts:AssumeRole` into a break-glass role with a 1 h session and MFA condition |

## What I understood

* IAM is **deny by default**; the whole job is writing the smallest Allow that still lets the work happen. An explicit Deny anywhere (identity policy, SCP, bucket policy) ends the discussion.
* **Roles are the answer to "where do I put the credentials?"** – you don't. The service that assumes the role gets short-lived keys automatically.
* Users and groups are for *people*; roles are for *everything else* and for people from other accounts.
