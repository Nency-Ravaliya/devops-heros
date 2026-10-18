# Deployment guide

Run commands from `devops-homework/session-21-capstone/` unless another directory is specified. The executable GitHub Actions workflow is at the repository root: `.github/workflows/session21-capstone.yml`. Tools: AWS CLI v2, Terraform 1.10+, kubectl compatible with your EKS version, Helm 3, OpenSSL, Docker and Git. The committed workflow uses Terraform 1.13.3 and Helm 3.19.0.

## 1. Git and registry

The configured origin is `https://github.com/chinna-328/devops-heros.git`. Push the combined submission branch for review. Deployment is restricted to `main`. Require the test job before merging pull requests. The rubric asks for a history screenshot with at least ten meaningful commits.

On relevant changes, CI tests against a disposable PostgreSQL service, builds React, validates configuration, builds both containers, and runs blocking Trivy HIGH/CRITICAL scans. After tests, SAST, dependency auditing, secret scanning and both image scans pass, trusted non-PR runs in this fork publish:

```text
ghcr.io/chinna-328/devops-heros-queuedesk-backend:<full-git-sha>
ghcr.io/chinna-328/devops-heros-queuedesk-frontend:<full-git-sha>
```

Set the GHCR packages to **public** for this demo so EKS can pull them without a registry credential. For private packages, create a namespace-scoped `ghcr-pull` docker-registry Secret using a read-only package token, then provide `imagePullSecrets: [{name: ghcr-pull}]` in an untracked Helm values file. CI must use that same override. Never put the token in a committed values file or terminal screenshot.

## 2. AWS infrastructure

Authenticate using `aws configure sso` / an existing AWS profile and confirm the account with `aws sts get-caller-identity`. No AWS access keys belong in this repository.

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit the API client CIDR and confirm your region/account/project settings.
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
terraform -chdir=terraform plan -out=queuedesk.tfplan
terraform -chdir=terraform apply queuedesk.tfplan
```

Applying creates billable infrastructure: VPC, two public and two private subnets across two availability zones, one NAT gateway, EKS, a managed node group (two `t3.large` instances), IAM roles, control-plane logs, EBS CSI and Metrics Server add-ons. This is a cost-conscious classroom topology; the single NAT gateway is not resilient to an availability-zone outage. The node group has a configured maximum but no node autoscaler; the backend HPA only changes Pods.

`allowed_api_cidrs` must contain your workstation egress and the CI runner egress. The example uses a documentation address and **must be replaced**. GitHub-hosted runners use changing IPs: use a fixed-egress/self-hosted runner reachable by the private endpoint, or explicitly manage the API CIDRs. If using a self-hosted runner, change the deploy job's `runs-on` accordingly. A broad API CIDR permits reachability but does not grant Kubernetes credentials; use an appropriately restricted range for your environment.

Terraform creates a GitHub OIDC identity provider by default. If one exists already in your account, set `github_oidc_provider_arn` to reuse it. The deployment trust is restricted to `chinna-328/devops-heros` and the `production` environment. If reusing infrastructure from the standalone capstone repository, review and apply the Terraform change to `github_repository` before enabling this workflow; the old repository trust does not authorize this repo. Cluster permissions for that role are scoped to the `queuedesk` namespace. The Terraform caller is the initial cluster administrator and performs bootstrap.

State is local by default and ignored by Git. Retain it securely until destruction. For collaboration, configure an existing encrypted/versioned S3 backend using native S3 locking (`use_lockfile = true`); never commit state or plan files, which can contain sensitive data. Do not run concurrent local applies.

## 3. Bootstrap EKS

Configure access and create the namespace and storage class:

```bash
cluster="$(terraform -chdir=terraform output -raw cluster_name)"
region="$(terraform -chdir=terraform output -raw region)"
vpc="$(terraform -chdir=terraform output -raw vpc_id)"
alb_role="$(terraform -chdir=terraform output -raw load_balancer_controller_role_arn)"
aws eks update-kubeconfig --region "$region" --name "$cluster"
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/storageclass.yaml
```

Install the Ingress controller and monitoring stack:

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system --version 3.6.0 \
  --set clusterName="$cluster" --set region="$region" --set vpcId="$vpc" \
  --set serviceAccount.create=true \
  --set 'serviceAccount.annotations.eks\.amazonaws\.com/role-arn'="$alb_role" \
  --wait --timeout 10m

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace --version 92.10.1 \
  -f monitoring/prometheus-values.yaml -f monitoring/grafana-values.yaml \
  --wait --timeout 15m
kubectl apply -n monitoring -f monitoring/dashboard-configmap.yaml

kubectl get nodes
kubectl get pods -n kube-system
kubectl get storageclass gp3
kubectl top nodes
```

Create the database Secret once, before installing the application:

```bash
db_password="$(openssl rand -hex 24)"
kubectl create secret generic queuedesk-database -n queuedesk \
  --from-literal=POSTGRES_PASSWORD="$db_password" \
  --from-literal=DATABASE_URL="postgresql+psycopg://queuedesk:$db_password@queuedesk-postgres:5432/queuedesk"
unset db_password
```

If the Secret already exists, keep it. PostgreSQL retains its initialized password on the PVC; replacing the Secret alone does not rotate the database password. Credentials stay outside Helm values and Git.

The [AWS controller IAM policy](../terraform/policies/load-balancer-controller.json) comes from the [official controller policy](https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/install/iam_policy.json). The controller creates the ALB from the Ingress. EBS CSI uses its own service-account IAM role; worker nodes run in private subnets and reach GHCR through NAT.

## 4. First application release

After CI publishes the images, use the exact SHA of the successful run:

```bash
release_sha="$(git rev-parse HEAD)"
image_prefix=ghcr.io/chinna-328/devops-heros-queuedesk
helm upgrade --install queuedesk ./helm/queuedesk \
  --namespace queuedesk -f helm/queuedesk/values-aws.yaml \
  --set-string backend.image.repository="$image_prefix-backend" \
  --set-string frontend.image.repository="$image_prefix-frontend" \
  --set-string backend.image.tag="$release_sha" \
  --set-string frontend.image.tag="$release_sha" \
  --atomic --wait --wait-for-jobs --timeout 15m
kubectl get pods,svc,ingress,hpa -n queuedesk
helm list -n queuedesk
```

Use the Ingress `ADDRESS` as the browser hostname. No host rule is set in AWS values so the ALB hostname works immediately. `/api` routes to the backend; `/` routes to the frontend. The frontend also proxies `/api` so port forwarding remains usable. Backend `/health`, `/ready`, `/metrics`, `/docs`, and `/openapi.json` are available via an internal Service or port-forward rather than public Ingress routes:

```bash
kubectl port-forward -n queuedesk svc/queuedesk-backend 8000:8000
```

For HTTPS, supply a real domain plus an ACM certificate annotation and HTTPS listener/redirect annotations in an untracked override. Do not send real customer data to the classroom HTTP endpoint.

## 5. Enable continuous deployment

Create a GitHub environment named **production**. Restrict it to `main` and configure repository/environment variables:

| Variable | Value |
|---|---|
| `DEPLOY_ENABLED` | Repository variable `true`; checked before environment jobs start |
| `AWS_ROLE_ARN` | `terraform output -raw github_role_arn` |
| `AWS_REGION` | `ap-south-1` or the configured region |
| `EKS_CLUSTER_NAME` | `terraform output -raw cluster_name` |

The three AWS variables can be set on the production environment. No long-lived AWS secret is needed. Until `DEPLOY_ENABLED=true`, CI still tests, scans, and publishes; the deploy job is explicitly skipped. Verify bootstrap, package visibility and network reachability first. A push then deploys the two images from that same SHA using `helm upgrade --install --atomic --wait --wait-for-jobs`. For a demo, change visible UI text, commit, push, watch the pipeline, and verify the new Deployment image tags.

Inspect and roll back:

```bash
helm history queuedesk -n queuedesk
helm rollback queuedesk <successful-revision> -n queuedesk --wait --wait-for-jobs --timeout 15m
```

Database migrations must remain compatible with both old and new application versions. Helm rollback does not reverse a migration; plan any schema reversal and backup recovery separately.

## 6. Cleanup after evaluation

Keep the ALB controller running while the application Ingress is deleted, so it can remove AWS load balancers and security groups. Back up any data you intend to retain first.

```bash
helm uninstall queuedesk -n queuedesk --wait
# Confirm the app ALB/target groups have disappeared in AWS before continuing.
kubectl get ingress -n queuedesk
helm uninstall monitoring -n monitoring --wait
helm uninstall aws-load-balancer-controller -n kube-system --wait
# StatefulSet/monitoring PVCs can survive uninstall. The next commands delete demo data.
kubectl delete pvc --all -n queuedesk
kubectl delete pvc --all -n monitoring
terraform -chdir=terraform plan -destroy
terraform -chdir=terraform destroy
```

Wait for EBS volume deletion and any load-balancer ENI cleanup before destroying the VPC. If Terraform reports dependencies, inspect the controller-created resources, finish Kubernetes cleanup while the cluster is still accessible, then retry. Capture the destroy completion screenshot. Confirm that no project load balancers, NAT gateways, EBS volumes or EC2 instances remain. Retained CloudWatch groups or manually created resources must also be checked. Disable `DEPLOY_ENABLED` when the cluster is gone.
