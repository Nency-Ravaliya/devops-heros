# Terraform: AWS infrastructure for TaskBoard

This folder provisions the cloud infrastructure that the TaskBoard app (FastAPI + React + Postgres) runs on in AWS:

| Layer | Resources |
|-------|-----------|
| Network | VPC `10.20.0.0/16`; 2 public and 2 private subnets across 2 AZs; Internet Gateway; 1 NAT Gateway + Elastic IP; public and private route tables; VPC Flow Logs to CloudWatch |
| Security | Locked-down default SG; EKS control-plane SG and worker-node SG with explicit least-privilege rules; one KMS key (rotation on) for EKS secrets, ECR and logs |
| Compute | EKS cluster (K8s 1.31, all control-plane logs on, secrets envelope-encrypted, access entries); managed node group (2-4 x `t3.medium`) in the private subnets, using a launch template with IMDSv2 and encrypted gp3 disks |
| IAM | Cluster role, node role (EKS worker, CNI, ECR read-only, SSM), flow-logs role |
| Registry | ECR repos `taskboard-backend` and `taskboard-frontend` (scan on push, immutable tags, KMS, lifecycle policy keeps the last 20 images). These are an AWS-native alternative to GHCR. |

Subnets carry the `kubernetes.io/role/elb` and `kubernetes.io/role/internal-elb` tags, so AWS Load Balancer Controller and `Service type=LoadBalancer` can find them.

## Layout

```text
terraform/
├── versions.tf                 # provider pin (aws ~> 5.0) + default_tags
├── backend.tf                  # S3 + DynamoDB remote state (commented, with bootstrap steps)
├── main.tf                     # real-AWS root: calls the module with EKS fully on
├── variables.tf / outputs.tf   # inputs; outputs incl. kubeconfig + ECR login commands
├── terraform.tfvars.example
├── modules/taskboard-infra/    # ALL resources live here (plain aws_* resources, no 3rd-party modules)
│   ├── main.tf                 # tags, KMS key
│   ├── network.tf              # VPC, subnets, IGW, NAT, routes, flow logs
│   ├── security-groups.tf
│   ├── iam.tf
│   ├── eks.tf                  # cluster, launch template, node group
│   ├── ecr.tf
│   └── variables.tf / outputs.tf / versions.tf
└── environments/local-mock/    # same module, provider pointed at a Moto mock (no AWS account needed)
    ├── main.tf / variables.tf / outputs.tf
    └── verify_moto.py          # boto3 check that the resources really exist in the mock
```

The original files used the community `terraform-aws-modules/vpc` and `eks` modules. They were replaced by one in-repo module made of plain resources. With plain resources every object is visible and can be reviewed. The same code also runs end to end against Moto: the community EKS module calls APIs that the mock does not emulate.

The module has toggles (`enable_eks`, `enable_node_group`, `enable_nat_gateway`, `enable_flow_logs`) so you can do a cheaper partial deploy, for example network + ECR only. With the current Moto image all toggles are left **on**, and the full stack (47 resources) applies against the mock.

## Real AWS usage

> **Cost warning.** This creates billable resources. In `ap-south-1` the approximate cost is: EKS control plane USD 0.10/h (about USD 73/month), NAT Gateway about USD 0.056/h plus data, 2 x t3.medium about USD 0.09/h, plus KMS, logs and EBS. That is roughly **USD 5-6 per day**. Destroy everything when you are done.

```bash
aws configure                                   # or: export AWS_PROFILE=...
cd terraform
cp terraform.tfvars.example terraform.tfvars    # set your IP in cluster_endpoint_public_access_cidrs
terraform init
terraform fmt -check -recursive && terraform validate
terraform plan -out=tfplan
terraform apply tfplan                          # takes about 15 min (EKS control plane + nodes)

# connect kubectl (the exact command is printed as an output)
$(terraform output -raw configure_kubectl)      # aws eks update-kubeconfig --region ap-south-1 --name taskboard-dev-eks
kubectl get nodes

# optional: push images to ECR instead of GHCR
eval "$(terraform output -raw ecr_login)"
terraform output ecr_repository_urls
```

After this, deploy the app with the Helm chart or manifests from `../helm` and `../kubernetes`. Set the image repository to the ECR URL if you use ECR.

**Destroy:**

```bash
terraform destroy          # removes everything, including ECR repos (force_delete = true)
```

Delete any `LoadBalancer` Services or Ingresses first (`kubectl delete svc,ingress --all -A`). If you skip this, the ELBs created by Kubernetes keep the VPC from being deleted.

### Remote state (team / CI)

`backend.tf` contains the commented `backend "s3"` block and the one-time commands that create a versioned, encrypted, private S3 bucket and a DynamoDB lock table. Create them, uncomment the block, then run `terraform init -migrate-state`. On Terraform 1.10 or later you can use `use_lockfile = true` instead of DynamoDB.

## Local mock workflow (no AWS account, no cost)

[Moto](https://github.com/getmoto/moto) emulates the AWS APIs locally. `environments/local-mock` calls the **same module** with fake credentials (`test`/`test`). Its provider `endpoints {}` sends ec2, eks, ecr, iam, kms, logs, sts and s3 to `http://localhost:4577`.

```bash
# Moto must preload AWS-managed IAM policies (AmazonEKSClusterPolicy, ...)
docker run -d --name moto-aws -p 4577:5000 -e MOTO_IAM_LOAD_MANAGED_POLICIES=true motoserver/moto:latest

cd terraform/environments/local-mock
terraform init
terraform validate
terraform plan -out=tfplan          # Plan: 47 to add
terraform apply tfplan
terraform output
terraform state list
pip install boto3 && python3 verify_moto.py   # lists VPC, subnets, IGW/NAT, SGs, EKS, node group, ECR
terraform destroy -auto-approve
```

Notes on the mock:
- All IDs, the EKS endpoint, the NAT IP (`127.x.x.x`) and the account `123456789012` come from Moto. Nothing is reachable, and `aws eks update-kubeconfig` cannot produce a working kubeconfig for it.
- Without `MOTO_IAM_LOAD_MANAGED_POLICIES=true`, every `aws_iam_role_policy_attachment` fails with `NoSuchEntity`.
- A second `terraform plan` after apply shows drift: `2 to add, 6 to change, 2 to destroy`. Moto does not return the EKS `access_config`, it returns a fake `remote_access` block on the node group, and it does not fully echo back SG rules or launch template attributes. This is emulation drift only. Against real AWS the plan is clean.

## Security scan (Checkov)

```bash
cd terraform
docker run --rm -v "$PWD":/tf -w /tf bridgecrew/checkov -d /tf --framework terraform --quiet --compact --skip-path .terraform
# Passed checks: 146, Failed checks: 0, Skipped checks: 17
```

The first scan reported 5 failures:

- **Fixed:** the node SG was not attached to anything (CKV2_AWS_5). A managed node group without a launch template ignores custom SGs. A launch template was added. It attaches the node SG and the EKS cluster SG, enforces IMDSv2 and encrypts the root volume.
- **Skipped with an inline reason (`#checkov:skip=...`):**
  - The public EKS endpoint (CKV_AWS_38/39) is restricted through `cluster_endpoint_public_access_cidrs`. Set your `/32`.
  - Hop limit 2 (CKV_AWS_341) is the value AWS recommends for EKS.
  - The EIP belongs to the NAT gateway, not an EC2 instance (CKV2_AWS_19).
  - The SG port range 1025-65535 comes from the control-plane SG, not from `0.0.0.0/0`, so CKV_AWS_25 is a false positive.
  - The KMS root key-policy statements (CKV_AWS_109/111/356) are AWS's standard default.
  - Node egress to `0.0.0.0/0` through the NAT (CKV_AWS_382) is needed to pull images and call AWS APIs.
