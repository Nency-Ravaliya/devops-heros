# DevOps Homework: Sessions 1 to 21

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

This repository contains my solutions to the DevOps course homework (Linux, shell scripting, networking, Git, Docker, Kubernetes, Helm, CI/CD, DevSecOps, Terraform, AWS, monitoring, GitOps and the final project). Every session has its own folder with a `README.md` that holds the explanation, the **real command output** and the screenshots, plus the code and manifests.

## Sessions

| Session | Topic | README |
|---|---|---|
| 1 and 2 | Linux: soft and hard links, `adduser` vs `useradd`, `journalctl`, command cheat sheet | [session1-2-linux](session1-2-linux/README.md) |
| 3 | Shell scripting: system information script | [session3-shell-scripting](session3-shell-scripting/README.md) |
| 4 | Networking commands | [session4-networking](session4-networking/README.md) |
| 5 | Git: `commit -a -m`, cherry-pick | [session5-git-github](session5-git-github/README.md) |
| 6 | Docker: Hello World apps (Node.js, Python, Java, Apache, React, Nginx) | [session6-docker-hello-world](session6-docker-hello-world/README.md) |
| 7 | Docker: multi-stage build, three application types | [session7-docker-multistage](session7-docker-multistage/README.md) |
| 8 | Docker: networking, host network, bind mount, overlay | [session8-docker-networking-volume](session8-docker-networking-volume/README.md) |
| 9 | Kubernetes fundamentals: Minikube, architecture, basics tutorial | [session9-kubernetes-fundamentals](session9-kubernetes-fundamentals/README.md) |
| 10 | Deployment strategies (rolling, blue-green, canary, recreate) and Pod lifecycle | [session10-k8s-pods-replicasets-deployments](session10-k8s-pods-replicasets-deployments/README.md) |
| 11 | Services (5 types), object comparison, FQDN, CoreDNS | [session11-kubernetes-services](session11-kubernetes-services/README.md) |
| 12 | ConfigMap, Secret, Ingress, troubleshooting | [session12-ingress-configmaps-secrets](session12-ingress-configmaps-secrets/README.md) |
| 13 | Volumes, HPA, probes, mini project | [session13-storage-hpa-probes](session13-storage-hpa-probes/README.md) |
| 14 | Kubernetes troubleshooting (commands, 9 issues, mini project) | [session14-kubernetes-troubleshooting](session14-kubernetes-troubleshooting/README.md) |
| 15 | Helm: commands, rollback workflow, mini project | [session15-helm](session15-helm/README.md) |
| 16 | CI/CD and GitHub Actions | [session16-github-actions](session16-github-actions/README.md) |
| 17 | Complete CI/CD and DevSecOps | [session17-devsecops](session17-devsecops/README.md) |
| 18 | Terraform and Infrastructure as Code, AWS services | [session18-terraform-iac](session18-terraform-iac/README.md) |
| 19 | Cloud and Terraform in action (VPC, subnet, security group, EC2, S3) | [session19-cloud-terraform](session19-cloud-terraform/README.md) |
| 20 | Monitoring, observability and GitOps | [session20-monitoring-observability-gitops](session20-monitoring-observability-gitops/README.md) |
| 21 | Final DevOps project (StockPilot) and troubleshooting challenge | [session21-final-devops-project/final-devops-project](session21-final-devops-project/final-devops-project/README.md) |

## How this was produced

- **Real output only.** Each block under a command is what the terminal printed when I ran it. Where a command failed or behaved unexpectedly, the README says so and shows what I did about it (for example the DNS test image named in the course's file that does not exist, and the HPA test in the Session 13 mini project where one load generator stayed just under the threshold until I added more).
- **Screenshots** are taken from a real (headless) Microsoft Edge browser pointed at the running service, or are text output of the terminal.
- **Environment:** Windows 11, Docker Desktop (Docker 29), WSL2 Ubuntu 26.04, Minikube v1.39 (Docker driver) with Kubernetes v1.37, Helm v4, Terraform v1.16, GitHub CLI.
- **Course files used unchanged** are marked as such in the READMEs (for example the Pod lifecycle manifests, the HPA files and the mini projects); everything else is my own work.

## What could not be executed (and how it is handled)

| Item | Why | What I did instead |
|---|---|---|
| GitHub Actions run of the new workflows (`ci-cd-with-artifacts.yml`, `devsecops.yml`) | GitHub only runs workflows from the root `.github/workflows` of a repository; here they sit inside session folders | linted with `actionlint`, every tool they call was run locally; the existing `ci-cd.yml` ran on GitHub (4 green runs, shown in Session 16) |
| Terraform `plan/apply/destroy` against real AWS | needs a real, billable AWS account | `fmt`, `init`, `validate`, and a **real apply and destroy against a local AWS emulator** (Sessions 18 and 19) |
| EKS and a container registry in the cloud | cost and accounts | Minikube with locally loaded images (final project) |
| Traces (third pillar of observability) | a single-service demo has nothing to trace across | explained in the notes (Session 20) |
