# Homework — all 21 sessions

Student GitHub: [bhanage-viraj](https://github.com/bhanage-viraj)  
Enrollment number: **24BCS10274**. Name: **Viraj Bhanage**.

**Viraj Bhanage, roll 24BCS10274.** The copy a grader should open is the `Viraj-24BCS10274` folder inside each session. This `homework/` tree is the same work with the longer notes.

| Session | Topic | Submission |
|---|---|---|
| 1 | Roadmap | [session-01-roadmap](session-01-roadmap/README.md) |
| 2 | Linux | [session-02-linux](session-02-linux/README.md) |
| 3 | Shell script | [session-03-shell-scripting](session-03-shell-scripting/README.md) |
| 4 | Networking | [session-04-networking](session-04-networking/README.md) |
| 5 | Git | [session-05-git](session-05-git/README.md) |
| 6–7 | Docker Hello World | [session-06-07-docker](session-06-07-docker/README.md) |
| 8 | Docker networks and volumes | [session-08-docker-networking](session-08-docker-networking/README.md) |
| 9 | Kubernetes basics | [session-09-kubernetes](session-09-kubernetes/README.md) |
| 10 | Deployments and Pod lifecycle | [session-10-deployments](session-10-deployments/README.md) |
| 11 | Services, FQDN, CoreDNS | [session-11-services](session-11-services/README.md) |
| 12 | ConfigMap, Secret, Ingress | [session-12-ingress](session-12-ingress/README.md) |
| 13 | Volumes, HPA, mini project | [session-13-storage](session-13-storage/README.md) |
| 14 | Troubleshooting | [session-14-troubleshooting](session-14-troubleshooting/README.md) |
| 15 | Helm | [session-15-helm](session-15-helm/README.md) |
| 16 | GitHub Actions | [session-16-cicd](session-16-cicd/README.md) |
| 17 | DevSecOps | [session-17-devsecops](session-17-devsecops/README.md) |
| 18 | Terraform and AWS notes | [session-18-terraform](session-18-terraform/README.md) |
| 19 | VPC, EC2, S3 | [session-19-cloud](session-19-cloud/README.md) |
| 20 | Monitoring and GitOps | [session-20-observability](session-20-observability/README.md) |
| 21 | TaskBoard capstone | [session-21-capstone](session-21-capstone/README.md) and [`session21-python`](../session21-python) |

GitHub Actions on this fork:

- [Homework CI](../.github/workflows/homework-ci.yml) builds the Hello World images and validates both Terraform projects.
- [TaskBoard CI](../.github/workflows/taskboard-ci.yml) runs pytest, builds images, scans them with Trivy, and pushes to GHCR.

## What you still need to capture

Code, explanations, and the command output that could be collected on this Mac are already in the session READMEs. Docker Desktop was not running, Minikube is not installed, and Terraform was not applied, so there are no live cluster, browser, or AWS console pictures yet. Put each screenshot in the session folder named below and add a one-line link in that session README.

### 1. Enrollment number

Name **Viraj Bhanage** and roll **24BCS10274** are already filled in.

### 2. Git cherry-pick (session 5)

```bash
chmod +x homework/session-05-git/cherry-pick-demo.sh
./homework/session-05-git/cherry-pick-demo.sh
```

Screenshot the terminal. The script writes `homework/session-05-git/cherry-pick-output.txt`. Commit that file.

### 3. Docker Hello World (sessions 6 and 7)

The images were built and curled on this machine. The responses are in `homework/session-06-07-docker/evidence/`. If the form insists on browser pictures, start Docker and run:

```bash
chmod +x homework/session-06-07-docker/build-and-run.sh
./homework/session-06-07-docker/build-and-run.sh
```

Screenshot http://localhost:8080 (the line must be "Hello World from Docker multi-stage build") and `docker ps`. The other ports are 3001, 5001, 8081, 8082, 8083, and 8084.

### 4. Docker networks (session 8)

```bash
chmod +x homework/session-08-docker-networking/run-labs.sh
./homework/session-08-docker-networking/run-labs.sh
```

Screenshot `docker network ls`, a successful ping from `hw-backend` to `hw-database`, a failed ping from `hw-frontend` to `hw-database`, http://localhost (Apache on the host network), and http://localhost:8088 before and after you edit `bind-mount/index.html`.

### 5. Kubernetes (sessions 9–15)

```bash
brew install minikube helm
minikube start --driver=docker
minikube addons enable metrics-server
minikube addons enable ingress
```

Then apply, in order, and screenshot `kubectl get pods,svc` after each:

```bash
kubectl apply -f homework/session-10-deployments/
kubectl apply -f homework/session-11-services/
kubectl apply -f homework/session-12-ingress/
kubectl apply -f homework/session-13-storage/hpa.yaml
kubectl apply -f session-13-storage-hpa-probes/mini-project/
kubectl apply -f session-14-kubernetes-troubleshooting/mini-project/deployment.yaml
kubectl apply -f session-14-kubernetes-troubleshooting/mini-project/service.yaml
kubectl apply -f session-14-kubernetes-troubleshooting/mini-project/broken-pod.yaml
helm install notes session-15-helm/mini-project/notes-chart
helm upgrade notes session-15-helm/mini-project/notes-chart -f session-15-helm/mini-project/notes-chart/values-prod.yaml
helm history notes
helm rollback notes 1
```

For the broken Pod, screenshot `kubectl describe pod project-broken-pod` before you delete it.

### 6. GitHub Actions (sessions 16, 17, 21)

After the push, open https://github.com/bhanage-viraj/devops-heros/actions and screenshot the Homework CI run. Screenshot the TaskBoard run as well, including the Trivy step. If Trivy fails the job, that log is the security-gate evidence. Write two sentences in the session 17 README about what it found.

### 7. AWS (sessions 18, 19, 21)

Only do this if you have an AWS account and you will destroy the stack the same day.

1. `aws configure` with your own keys. Do not put the keys in Git.
2. Change both `bucket_name` values. S3 names are global. The placeholders will be rejected if someone else took them.
3. Session 18: `terraform init && terraform apply` in `homework/session-18-terraform/terraform-s3-demo`, screenshot the plan and the bucket, then `terraform destroy`.
4. Session 19: same in `homework/session-19-cloud`. Screenshot the VPC and the EC2 instance, then destroy.
5. Session 21 EKS is the expensive one. `session21-python/terraform` creates a cluster. Apply only if you can `terraform destroy` immediately after the screenshots in `GRADING.md`. An EKS cluster left running costs real money.

### 8. Capstone UI (session 21)

```bash
cd session21-python
docker compose up --build
```

Screenshot http://localhost:3000 with the TaskBoard UI, and `pytest -v` from `session21-python/backend`.
