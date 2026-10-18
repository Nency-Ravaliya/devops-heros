# Terraform: AWS VPC + EKS

Infrastructure as Code for StockPilot. Instead of clicking through the AWS console (VPC, subnets, NAT, EKS, node
group...), this folder describes the desired state and Terraform makes AWS match it.

```text
AWS (ap-south-1)
 `-- VPC 10.0.0.0/16
      |-- 2 public subnets   (one per AZ)  -> internet gateway, NAT gateway, load balancers
      |-- 2 private subnets  (one per AZ)  -> worker nodes
      `-- EKS cluster (Kubernetes 1.35)
           |-- add-ons: coredns, kube-proxy, vpc-cni, aws-ebs-csi-driver
           `-- managed node group: 3 x t3.medium (min 2, max 4), Amazon Linux 2023
```

The configuration uses the community modules `terraform-aws-modules/vpc/aws` and `terraform-aws-modules/eks/aws`,
so the code stays short and focused on the Terraform concepts: providers, variables, modules, outputs, state and the
plan/apply/destroy cycle.

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform and provider versions, the AWS provider and default tags |
| `variables.tf` | inputs (region, cluster name, Kubernetes version, node sizes...) with defaults |
| `main.tf` | the VPC module and the EKS module |
| `outputs.tf` | VPC/subnet IDs, cluster name and endpoint, the `kubectl` configuration command |
| `terraform.tfvars.example` | copy to `terraform.tfvars` to override defaults (the real file is git-ignored) |

## Prerequisites

- Terraform >= 1.6, AWS CLI v2, kubectl, Helm
- AWS credentials in your shell (`aws configure`, SSO or environment variables). **Never put keys in these files or in Git.**
- Permissions to create VPC, EC2, IAM and EKS resources

## Use

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply                  # EKS takes roughly 15-20 minutes
aws eks update-kubeconfig --region ap-south-1 --name stockpilot-eks     # also printed as an output
kubectl get nodes
```

Then continue with `scripts/install-cluster-addons.sh` and the Helm deployment (see the root README).

## Cost warning

While it exists this stack costs roughly 0.35 USD per hour: the EKS control plane (about 0.10), the NAT gateway
(about 0.05 plus data), and three `t3.medium` nodes (about 0.12) plus EBS volumes and the load balancer. Prices differ by
region; check the AWS pricing pages. **Destroy it as soon as you have your screenshots.**

## Destroy (order matters)

Kubernetes creates things Terraform does not know about: an AWS load balancer for ingress-nginx and EBS volumes for
the PersistentVolumeClaims. They sit inside the VPC and block its deletion, so remove them first:

```bash
helm uninstall stockpilot -n stockpilot
helm uninstall monitoring -n monitoring
helm uninstall ingress-nginx -n ingress-nginx      # deletes the load balancer
kubectl delete pvc --all -n stockpilot             # deletes the EBS volume
kubectl delete pvc --all -n monitoring

terraform destroy
```

Afterwards check the AWS console (EC2 > Load Balancers, EC2 > Volumes, VPC, EKS) to confirm nothing is left running.
