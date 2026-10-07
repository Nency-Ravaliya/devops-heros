# Session 21: Final DevOps Project & Troubleshooting

## 1. Project Overview
This project represents a complete, end-to-end production-grade DevOps deployment for a microservices taskboard application. It integrates containerization, cloud infrastructure provisioning via Terraform, Kubernetes orchestration, Helm package management, automated CI/CD with GitHub Actions, DevSecOps security scanning, Prometheus/Grafana monitoring, GitOps with ArgoCD, and root-cause troubleshooting.

---

## 2. Architecture Diagram

```text
                             +-------------------+
                             |   GitHub Repo     |
                             +---------+---------+
                                       |
                                       v
                             +-------------------+
                             |  GitHub Actions   |
                             |  CI/CD & DevSecOps|
                             +---------+---------+
                                       |
                        +--------------+--------------+
                        |                             |
                        v                             v
             +--------------------+        +--------------------+
             |  Docker Registry   |        |  Terraform AWS/K8s |
             |  Image Push        |        |  Infra Provision   |
             +----------+---------+        +----------+---------+
                        |                             |
                        +--------------+--------------+
                                       |
                                       v
                             +-------------------+
                             | Kubernetes Cluster|
                             | (Helm & ArgoCD)   |
                             +---------+---------+
                                       |
                     +-----------------+-----------------+
                     |                                   |
                     v                                   v
          +--------------------+               +--------------------+
          | Frontend & Backend |               | Prometheus/Grafana |
          | Pods, HPA & SVC    |               | Monitoring & Logs  |
          +--------------------+               +--------------------+
```

---

## 3. Technologies Used
- **Application**: Python Flask API & React Frontend
- **Database**: PostgreSQL
- **Containerization**: Docker & Docker Compose
- **Orchestration**: Kubernetes (Kind / Minikube)
- **Package Manager**: Helm 3
- **IaC**: Terraform 1.10
- **CI/CD & DevSecOps**: GitHub Actions, Pytest, Bandit, Safety, Gitleaks, Trivy
- **GitOps & Monitoring**: ArgoCD, Prometheus, Grafana

---

## 4. Application & Docker Setup
The application is structured into decoupled frontend and backend containers using multi-stage Docker builds.

### Docker Run Commands:
```bash
cd final-devops-project
docker-compose up --build -d
docker-compose ps
```

---

## 5. Kubernetes & Helm Deployment
The application is deployed using custom Helm charts featuring Deployments, Services, ConfigMaps, Secrets, Ingress, HorizontalPodAutoscaler (HPA), and Health Probes (Liveness & Readiness).

```bash
cd final-devops-project/helm
helm install final-devops-app ./chart
kubectl get pods,svc,hpa -A
```

---

## 6. Terraform Infrastructure Provisioning
Cloud resources (VPC, Subnets, Internet Gateway, Security Groups, S3 Buckets) are declaratively provisioned:

```bash
cd final-devops-project/terraform
terraform init
terraform validate
terraform plan
terraform apply
```

---

## 7. CI/CD & DevSecOps Pipeline
The automated workflow executes:
1. **Unit Testing**: `pytest`
2. **SAST**: Code analysis via `bandit`
3. **SCA**: Dependency vulnerability scan via `safety` / `pip-audit`
4. **Secret Scanning**: Credentials check via `gitleaks`
5. **Container Image Scan**: Vulnerability scan via `trivy`
6. **Deploy**: Continuous deployment to Kubernetes upon merge to `main`.

---

## 8. Monitoring & GitOps
- **Prometheus & Grafana**: Monitors cluster CPU, memory utilization, and HTTP request rate.
- **ArgoCD**: Continuously reconciles cluster state against Git declarations.

---

## 9. Final Troubleshooting Challenge & Root Cause Analysis (RCA)

### Problem 1: Pod CrashLoopBackOff
- **Symptom**: Backend pod stuck in `CrashLoopBackOff`.
- **Investigation**: `kubectl logs <backend-pod> -n default` revealed `psycopg2.OperationalError: could not connect to server: Connection refused`.
- **Root Cause**: Database hostname in ConfigMap was misconfigured to `localhost` instead of the PostgreSQL service DNS `postgres`.
- **Fix**: Updated `DATABASE_URL` in ConfigMap to `postgresql://taskboard:taskboard@postgres:5432/taskboard`.
- **Verification**: `kubectl get pods` confirmed backend status `1/1 Running`.

---

## 10. Screenshots & Verification
![Architecture & Infrastructure Output](./screenshots/01-architecture-infrastructure.png)
![CI/CD & Kubernetes Output](./screenshots/02-cicd-kubernetes.png)
![Troubleshooting RCA Output](./screenshots/03-troubleshooting.png)

---

## 11. Lessons Learned
- **Automation & Security**: Embedding SAST and container image scanning directly into GitHub Actions prevents vulnerable images from reaching production.
- **Infrastructure as Code**: Terraform enables idempotent, version-controlled cloud infrastructure provisioning.
- **GitOps Reconciliation**: ArgoCD ensures zero drift between desired Git declarations and active Kubernetes cluster state.
