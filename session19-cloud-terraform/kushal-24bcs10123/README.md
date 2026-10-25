# Session 19 – Cloud & Terraform in Action

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123  
**Environment:** Terraform v1.16.4 (hashicorp/aws v6.67.0, hashicorp/tls v4), AWS CLI 2.32, Graphviz 16, macOS / Apple Silicon. Target: **LocalStack 4.0.3** (community) in Docker Desktop at `http://localhost:4566`.

> **Why LocalStack.** As in [session 18](../../session18-terraform-iac/kushal-24bcs10123), the AWS key on this laptop is invalid (`InvalidClientTokenId`, logged in [session 18's logs/00](../../session18-terraform-iac/kushal-24bcs10123/logs/00-why-localstack.txt)) and I have no billable AWS account, so the stack was applied against LocalStack's AWS API emulator. The Terraform code is real-AWS code; `localstack.tfvars` only sets the endpoint and an AMI id from LocalStack's catalogue. The section at the end lists exactly what would differ on real AWS.

Every command was really run; raw output is in [`logs/`](logs), the exact commands in [`scripts/`](scripts).

```text
kushal-24bcs10123/
├── README.md
├── terraform-project/
│   ├── versions.tf                 # required_version, aws ~> 6.0, tls ~> 4.0
│   ├── provider.tf                 # provider "aws" + default_tags + LocalStack switch
│   ├── variables.tf                # region, project_name, vpc/subnet CIDRs, instance_type, ssh cidr, bucket suffix, ami_id, endpoint
│   ├── main.tf                     # VPC, subnet, IGW, route table (+assoc), SG, AMI lookup, key pair, EC2, S3 bucket (+block, versioning, object)
│   ├── outputs.tf                  # 13 outputs, one of them sensitive
│   ├── scripts/user_data.sh        # cloud-init: install nginx, write index.html with the instance id
│   ├── terraform.tfvars(.example)  # values (no secrets)   localstack.tfvars  # endpoint + AMI id
│   └── .gitignore                  # .terraform/, *.tfstate*, tfplan
├── diagrams/                       # terraform graph -> graph.dot, terraform-graph.png / .svg
├── scripts/
│   ├── lib.sh                      # x(), hr(), awsl, tf helpers (same as session 18)
│   ├── 01-build-infrastructure.sh  # init -> fmt -> validate -> plan -> apply -> output
│   ├── 02-verify-and-state.sh      # AWS CLI verification, state list/show, state file, graph, drift, sensitive output
│   └── 03-change-and-destroy.sh    # update-in-place plan, forced-replacement plan, destroy
├── logs/                           # one .txt per script
└── screenshots/
```

## Architecture

```text
                                  Internet
                                     │
                          ┌──────────┴───────────┐
                          │  aws_internet_gateway │  igw-381d562a
                          └──────────┬───────────┘
   aws_vpc.main  10.20.0.0/16        │  0.0.0.0/0 -> igw        (aws_route_table.public)
   ┌─────────────────────────────────┼────────────────────────────────────────────┐
   │                                 │                                            │
   │   aws_subnet.public  10.20.1.0/24  ap-south-1a  map_public_ip_on_launch      │
   │   ┌─────────────────────────────┴─────────────────────────────────────────┐  │
   │   │  aws_security_group.web   80/443 from 0.0.0.0/0, 22 from 10.0.0.0/8   │  │
   │   │  ┌─────────────────────────────────────────────────────────────────┐  │  │
   │   │  │  aws_instance.web   t3.micro  ami-03cf127a                      │  │  │
   │   │  │   private 10.20.1.4   public 54.214.155.183                     │  │  │
   │   │  │   key: aws_key_pair.web  (tls_private_key.ssh, ED25519)         │  │  │
   │   │  │   user_data: scripts/user_data.sh  -> nginx                     │  │  │
   │   │  └─────────────────────────────────────────────────────────────────┘  │  │
   │   └───────────────────────────────────────────────────────────────────────┘  │
   └──────────────────────────────────────────────────────────────────────────────┘
                                     │ writes infra/instance.json
                                     ▼
                aws_s3_bucket.assets  s19-kushal-assets-24bcs10123  (private, versioned)
```

Dependency graph as Terraform sees it (`terraform graph | dot -Tpng`, [diagrams/terraform-graph.png](diagrams/terraform-graph.png)):

![terraform graph](diagrams/terraform-graph.png)

## 1. Build: init → fmt → validate → plan → apply

Log: [logs/01-build-infrastructure.txt](logs/01-build-infrastructure.txt) · Screenshot: [screenshots/01-plan-apply.png](screenshots/01-plan-apply.png)

What each requirement of the assignment maps to in the code:

| Requirement | Where |
|---|---|
| Providers | `versions.tf` pins `hashicorp/aws ~> 6.0` and `hashicorp/tls ~> 4.0`; `provider.tf` configures region, `default_tags` (every resource gets `Project/Owner/ManagedBy`) and the LocalStack switch |
| Variables | `variables.tf`: 10 inputs with descriptions and defaults, values in `terraform.tfvars`, overrides via `-var` / `-var-file` |
| Resources | 12 managed resources + 1 data source across network, firewall, compute, storage |
| Outputs | `outputs.tf`: ids, IPs, bucket name/arn, and a `sensitive = true` private key |
| Dependencies | implicit through references (`aws_vpc.main.id` everywhere), explicit `depends_on = [aws_route_table_association.public]` on the instance so it never boots before the internet route exists |
| State | local `terraform.tfstate` (gitignored), inspected in step 2 |

```text
$ terraform init -input=false
- Using hashicorp/aws v6.67.0 from the shared cache directory
- Installing hashicorp/tls v4.1.0...
Terraform has been successfully initialized!

$ terraform fmt -recursive -check -diff; echo "fmt exit code: $?"
fmt exit code: 0
$ terraform validate
Success! The configuration is valid.

$ terraform plan -var-file=localstack.tfvars -out=tfplan
  # aws_instance.web will be created
  # aws_internet_gateway.main will be created
  # aws_key_pair.web will be created
  # aws_route_table.public will be created
  # aws_route_table_association.public will be created
  # aws_s3_bucket.assets will be created
  # aws_s3_bucket_public_access_block.assets will be created
  # aws_s3_bucket_versioning.assets will be created
  # aws_s3_object.instance_info will be created
  # aws_security_group.web will be created
  # aws_subnet.public will be created
  # aws_vpc.main will be created
  # tls_private_key.ssh will be created
Plan: 13 to add, 0 to change, 0 to destroy.
```

The apply order *is* the dependency graph – independent resources run in parallel, dependents wait:

```text
$ terraform apply tfplan
tls_private_key.ssh: Creating...                      ┐
aws_vpc.main: Creating...                             ├ no dependencies -> start together
aws_s3_bucket.assets: Creating...                     ┘
aws_key_pair.web: Creation complete  [id=s19-kushal-key]
aws_vpc.main: Creation complete      [id=vpc-98dac775]
aws_internet_gateway.main: Creating...                ┐
aws_subnet.public: Creating...                        ├ need the VPC id
aws_security_group.web: Creating...                   ┘
aws_route_table.public: Creation complete  [id=rtb-2a430a2f]          <- needs IGW id for the route
aws_subnet.public: Creation complete after 10s [id=subnet-2a044d51]
aws_route_table_association.public: Creation complete [id=rtbassoc-782c89f5]
aws_instance.web: Creating...                                          <- only now: depends_on the association
aws_instance.web: Creation complete after 10s [id=i-3842fe9324347c9fe]
aws_s3_object.instance_info: Creation complete                         <- needs instance id + bucket

Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:
instance_id         = "i-3842fe9324347c9fe"
instance_private_ip = "10.20.1.4"
instance_public_ip  = "54.214.155.183"
internet_gateway_id = "igw-381d562a"
public_subnet_id    = "subnet-2a044d51"
route_table_id      = "rtb-2a430a2f"
security_group_id   = "sg-9e865c56a484cf533"
bucket_name         = "s19-kushal-assets-24bcs10123"
ssh_private_key_pem = <sensitive>
vpc_id              = "vpc-98dac775"
```

## 2. Verify the AWS resources, inspect state, draw the graph

Log: [logs/02-verify-and-state.txt](logs/02-verify-and-state.txt) · Screenshot: [screenshots/02-aws-cli-verification.png](screenshots/02-aws-cli-verification.png)

Everything Terraform reported is visible through the plain AWS CLI (`awsl` = `aws --endpoint-url=http://localhost:4566`):

```text
$ awsl ec2 describe-vpcs --filters Name=tag:Name,Values=s19-kushal-vpc ...
|  10.20.0.0/16 |  available |  vpc-98dac775  |

$ awsl ec2 describe-route-tables --filters Name=tag:Name,Values=s19-kushal-public-rt --query 'RouteTables[0].Routes[]...'
|     Dest      |  State  |    Target      |
|  10.20.0.0/16 |  active |  local         |
|  0.0.0.0/0    |  active |  igw-381d562a  |        <- this route is what makes the subnet public
$ ... Associations
|  Main  |     SubnetId      |
|  False |  subnet-2a044d51  |

$ awsl ec2 describe-security-groups --filters Name=group-name,Values=s19-kushal-web-sg ...
|    Cidr    |            Desc             | From  | Proto  |  To   |
|  0.0.0.0/0 |  HTTP                       |  80   |  tcp   |  80   |
|  10.0.0.0/8|  SSH from admin range only  |  22   |  tcp   |  22   |
|  0.0.0.0/0 |  HTTPS                      |  443  |  tcp   |  443  |

$ awsl ec2 describe-instances --filters Name=tag:Name,Values=s19-kushal-web ...
|  Id        |  i-3842fe9324347c9fe  |
|  State     |  running              |
|  Type      |  t3.micro             |
|  Subnet    |  subnet-2a044d51      |
|  PrivateIp |  10.20.1.4            |        <- from the subnet CIDR, as it should be
|  PublicIp  |  54.214.155.183       |
|  Key       |  s19-kushal-key       |

$ awsl ec2 describe-instance-attribute --instance-id i-3842fe9324347c9fe --attribute userData ... | base64 --decode | head -5
#!/bin/bash
# Runs once at first boot (cloud-init). Installs nginx and serves a page that names the instance.
set -eux
dnf install -y nginx

$ awsl s3 ls
2026-10-07 23:17:54 s19-kushal-assets-24bcs10123
$ awsl s3 cp s3://s19-kushal-assets-24bcs10123/infra/instance.json -
{"instance_id":"i-3842fe9324347c9fe","private_ip":"10.20.1.4","vpc_id":"vpc-98dac775"}   <- one resource's attributes written into another
```

### Terraform state

```text
$ terraform state list
aws_instance.web
aws_internet_gateway.main
aws_key_pair.web
aws_route_table.public
aws_route_table_association.public
aws_s3_bucket.assets
aws_s3_bucket_public_access_block.assets
aws_s3_bucket_versioning.assets
aws_s3_object.instance_info
aws_security_group.web
aws_subnet.public
aws_vpc.main
tls_private_key.ssh

$ terraform state show aws_instance.web | grep -E '^\s+(id|ami|instance_type|subnet_id|private_ip|public_ip|key_name)\s'
    ami           = "ami-03cf127a"
    id            = "i-3842fe9324347c9fe"
    instance_type = "t3.micro"
    key_name      = "s19-kushal-key"
    private_ip    = "10.20.1.4"
    public_ip     = "54.214.155.183"
    subnet_id     = "subnet-2a044d51"
```

The state file itself is JSON; every resource instance records the dependencies it was created with, which is how `destroy` knows the reverse order even if the code has changed since:

```text
$ python3 -c "..."  (reads terraform.tfstate)
terraform 1.16.4 | serial 14 | resources 13
 - aws_instance.web                    -> depends_on [igw, key_pair, route_table, route_table_association, security_group, subnet, vpc, tls_private_key]
 - aws_internet_gateway.main           -> depends_on ['aws_vpc.main']
 - aws_route_table.public              -> depends_on ['aws_internet_gateway.main', 'aws_vpc.main']
 - aws_route_table_association.public  -> depends_on ['aws_internet_gateway.main', 'aws_route_table.public', 'aws_subnet.public', 'aws_vpc.main']
 - aws_s3_object.instance_info         -> depends_on ['aws_instance.web', ..., 'aws_s3_bucket.assets', ...]
 - aws_vpc.main                        -> depends_on []
```

`serial 14` = the state has been written 14 times (one per resource create, roughly). The state contains the SSH private key in clear text – one more reason it is gitignored and, in a team, stored in an encrypted remote backend.

### `terraform graph`

```text
$ terraform graph > diagrams/graph.dot          # 15 edges
aws_instance.web -> aws_key_pair.web
aws_instance.web -> aws_route_table_association.public      <- the explicit depends_on
aws_instance.web -> aws_security_group.web
aws_instance.web -> data.aws_ami.al2023
aws_internet_gateway.main -> aws_vpc.main
aws_key_pair.web -> tls_private_key.ssh
aws_route_table.public -> aws_internet_gateway.main
aws_route_table_association.public -> aws_route_table.public
aws_route_table_association.public -> aws_subnet.public
aws_s3_bucket_public_access_block.assets -> aws_s3_bucket.assets
aws_s3_bucket_versioning.assets -> aws_s3_bucket.assets
aws_s3_object.instance_info -> aws_instance.web
aws_s3_object.instance_info -> aws_s3_bucket.assets
aws_security_group.web -> aws_vpc.main
aws_subnet.public -> aws_vpc.main
$ dot -Tpng diagrams/graph.dot -o diagrams/terraform-graph.png
```

### Drift check and the sensitive output

```text
$ terraform plan -var-file=localstack.tfvars -detailed-exitcode | tail -3
exit code: 2  (0 = no changes, 2 = changes pending)
```

Not 0, and the reason is the same LocalStack limitation seen in session 18: it does not persist the tags sent on `CreateBucket`/`CreateSubnet`, so the refresh sees `tags = {}` and the plan wants to put the `default_tags` back on `aws_s3_bucket.assets` and `aws_subnet.public` (visible in the next log as the two extra `~ tags` blocks). Nothing else drifted. On real AWS this returns 0.

```text
$ terraform output ssh_private_key_pem
<<EOT
-----BEGIN OPENSSH PRIVATE KEY-----
...
$ terraform output -raw ssh_private_key_pem | head -1
-----BEGIN OPENSSH PRIVATE KEY-----
```

`sensitive = true` hides the value in `plan`/`apply` output (`<sensitive>`), but `terraform output <name>` prints it on purpose – marking an output sensitive is a display guard, not encryption.

## 3. Changes and destroy

Log: [logs/03-change-and-destroy.txt](logs/03-change-and-destroy.txt) · Screenshot: [screenshots/03-change-plans-and-destroy.png](screenshots/03-change-plans-and-destroy.png)

**Change 1 – an attribute that can change in place.** A bigger instance type only needs a stop/start:

```text
$ terraform plan -var-file=localstack.tfvars -var instance_type=t3.small
  ~ update in-place
  ~ resource "aws_instance" "web" {
      ~ instance_type = "t3.micro" -> "t3.small"
      ~ public_ip     = "54.214.155.183" -> (known after apply)      <- stop/start releases the public IP (no Elastic IP)
Plan: 0 to add, 3 to change, 0 to destroy.          (the other 2 "changes" are the LocalStack tag re-adds)
```

**Change 2 – an attribute that forces replacement, and the blast radius.** A subnet's CIDR cannot be edited, so the subnet is replaced – and because the instance and the route-table association reference `aws_subnet.public.id`, they must be replaced too; the S3 object changes because it embeds the instance id:

```text
$ terraform plan -var-file=localstack.tfvars -var public_subnet_cidr=10.20.2.0/24
  # aws_instance.web must be replaced
  # aws_route_table_association.public must be replaced
  # aws_s3_object.instance_info will be updated in-place
  # aws_subnet.public must be replaced
Plan: 3 to add, 2 to change, 3 to destroy.
```

This is why reading a plan carefully matters: a one-line variable change would have destroyed the server.

**Destroy** – the graph in reverse, 13 resources, then the API confirms nothing is left:

```text
$ terraform destroy -auto-approve -var-file=localstack.tfvars
Plan: 0 to add, 0 to change, 13 to destroy.
aws_s3_object.instance_info: Destroying...
aws_s3_bucket_versioning.assets: Destroying...
aws_instance.web: Destroying...
...
aws_vpc.main: Destruction complete
Destroy complete! Resources: 13 destroyed.

$ awsl ec2 describe-vpcs ...        -> only LocalStack's default 172.31.0.0/16
$ awsl ec2 describe-instances ...   -> (terminated)
$ awsl s3 ls                        -> (buckets left: 0)
$ terraform state list              -> (state is empty)
```

## What would be different on real AWS

| Item | LocalStack run | Real AWS |
|---|---|---|
| Credentials | `test`/`test`, account `000000000000` | a real IAM user/role; `aws sts get-caller-identity` must succeed first |
| Endpoint | `-var-file=localstack.tfvars` | omit it; the provider talks to `ec2.ap-south-1.amazonaws.com` etc. |
| AMI | `ami-03cf127a` from LocalStack's fixed catalogue | `var.ami_id = null` → `data.aws_ami.al2023` picks the newest Amazon Linux 2023 arm64 image (so `instance_type` should be a Graviton type like `t4g.micro`) |
| user_data | stored but never executed (no VM boots) | cloud-init runs it; `curl http://<public_ip>/` shows the nginx page after ~1 min |
| Public IP | random, not routable | a real public IP, released on stop – use `aws_eip` for a stable one |
| Tags | dropped on bucket/subnet (drift exit 2) | persisted; the drift check returns 0 |
| SSH | key pair exists but nothing to connect to | `terraform output -raw ssh_private_key_pem > key && chmod 600 key && ssh -i key ec2-user@<ip>`, and narrow `ssh_allowed_cidr` to my own /32 |
| Cost | zero | t3.micro ≈ free tier, but IGW is free only until traffic; **`terraform destroy` at the end is not optional** – a forgotten instance + volume bills every hour |
| State | local file | S3 bucket + locking (`backend "s3"` with `use_lockfile = true`), versioned and encrypted, because the state holds the private key |

## What I understood

* The assignment's diagram (VPC → subnet → SG → EC2 → S3) is literally the dependency graph Terraform computes: **references create edges, edges decide ordering and parallelism**, and `depends_on` is only for the one edge the provider cannot see (instance needs the internet route for `user_data`).
* **"Public subnet" is three resources working together** – subnet + IGW + a route table with `0.0.0.0/0 → igw` associated to it – and `map_public_ip_on_launch` on top. Miss any one and the instance is unreachable.
* **Plans distinguish update vs replace**, and replacements cascade: a CIDR change would have recreated the EC2 instance. Always read the `must be replaced` lines before typing `yes`.
* **State is the source of truth for Terraform and a liability for me** – it had the SSH private key in clear text, so remote, encrypted, locked state is a day-one requirement, not an optimisation.
* The provider block is the only place the cloud "lives"; everything else I wrote would run unchanged on real AWS once I have a valid key.

## Checklist

- [x] Terraform project with providers, variables, resources, outputs, implicit + explicit dependencies
- [x] VPC, subnet, Internet Gateway, route table + association, security group, EC2 (user_data, key pair), S3 bucket
- [x] `terraform init / fmt / validate / plan / apply / output / state list / state show / graph / destroy` all run and logged
- [x] Resources verified independently with the AWS CLI
- [x] Architecture diagram (ASCII above + `diagrams/terraform-graph.png` from `terraform graph`)
- [x] Screenshots in `screenshots/`
- [x] Stated plainly that the target was LocalStack and listed what changes on real AWS
