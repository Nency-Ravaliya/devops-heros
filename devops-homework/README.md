# DevOps homework

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

This folder contains the assignments for Sessions 2–21. Each session has its
application/configuration files, commands, notes and available execution output.
Session 1 is excluded. Session 21 is the full QueueDesk capstone project.

| Session | Assignment | Files |
|---|---|---|
| 2 | Linux fundamentals | [session-02-linux/](session-02-linux/README.md) |
| 3 | Shell scripting | [session-03-shell-scripting/](session-03-shell-scripting/README.md) |
| 4 | Networking | [session-04-networking/](session-04-networking/README.md) |
| 5 | Git and GitHub | [session-05-git-github/](session-05-git-github/README.md) |
| 6 | Docker applications | [session-06-docker/](session-06-docker/README.md) |
| 7 | Docker multi-stage builds | [session-07-docker-multi-stage/](session-07-docker-multi-stage/README.md) |
| 8 | Docker networking and volumes | [session-08-docker-networking-volumes/](session-08-docker-networking-volumes/README.md) |
| 9 | Kubernetes fundamentals | [session-09-kubernetes/](session-09-kubernetes/README.md) |
| 10 | Deployment strategies and Pod lifecycle | [session-10-deployments-pod-lifecycle/](session-10-deployments-pod-lifecycle/README.md) |
| 11 | Services and DNS | [session-11-services-dns/](session-11-services-dns/README.md) |
| 12 | Ingress, ConfigMaps and Secrets | [session-12-ingress-configmaps-secrets/](session-12-ingress-configmaps-secrets/README.md) |
| 13 | Storage, HPA and probes | [session-13-storage-hpa-probes/](session-13-storage-hpa-probes/README.md) |
| 14 | Kubernetes troubleshooting | [session-14-kubernetes-troubleshooting/](session-14-kubernetes-troubleshooting/README.md) |
| 15 | Helm | [session-15-helm/](session-15-helm/README.md) |
| 16 | CI/CD | [session-16-ci-cd/](session-16-ci-cd/README.md) |
| 17 | DevSecOps | [session-17-devsecops/](session-17-devsecops/README.md) |
| 18 | Terraform and AWS services | [session-18-terraform-aws/](session-18-terraform-aws/README.md) |
| 19 | Cloud infrastructure | [session-19-cloud-infrastructure/](session-19-cloud-infrastructure/README.md) |
| 20 | Monitoring and GitOps | [session-20-monitoring-gitops/](session-20-monitoring-gitops/README.md) |
| 21 | QueueDesk capstone | [session-21-capstone/](session-21-capstone/README.md) |

## CI/CD

GitHub Actions workflows are in the repository root:

- `session16-cicd.yml`: tests, image build/publication and manual practice-cluster deployment.
- `session17-devsecops.yml`: tests, SAST, dependency/secret/image checks and gated deployment.
- `session21-capstone.yml`: PostgreSQL tests/migrations, frontend build, infrastructure checks,
  security gates, both container images and optional EKS deployment through AWS OIDC.

The workflows run on relevant changes to `main`, the all-assignments branch and
pull requests. Registry publication is restricted to trusted runs in this fork.
Practice deployment needs the `practice` environment's `KUBE_CONFIG` secret.
QueueDesk deployment requires the configured `production` environment and
`DEPLOY_ENABLED=true` on `main`; see the capstone deployment guide.
Terraform validation does not apply cloud infrastructure.

## Verification

The session READMEs distinguish completed local checks from cluster, cloud and
Actions runs that still need an available environment. Available execution output
is in the corresponding session's `evidence/` folder. QueueDesk also keeps its standalone-project
verification record; the workflow in this repository needs a fresh Actions run.
