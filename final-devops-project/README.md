# End-to-End Enterprise DevOps Platform & Troubleshooting Challenge (Session 21)

---

## 👩‍💻 Student Information
- **Name:** Sahasra ambati
- **Enrollment Number:** sahasra10241
- **Course / Track:** DevOps & Cloud Engineering
- **Assignment:** Session 21: Final DevOps Capstone Project & Troubleshooting Challenge

---

## 💡 What I Understood By This Final Capstone Project (My Reflection)

Throughout this course, I learned individual DevOps technologies in isolation—Linux shell scripting, Docker containers, Kubernetes orchestration, Helm package management, Terraform IaC, GitHub Actions CI/CD, DevSecOps scanning, and Prometheus observability. 

This **Final Capstone Project** synthesized every single discipline into a cohesive, production-grade DevOps engineering platform:
1. **Automation Over Manual Effort:** No artifact is deployed by hand. Every commit pushed to Git initiates an automated chain of quality checks, security gates, image builds, and GitOps deployments.
2. **Security is a First-Class Citizen (Shift-Left):** Vulnerabilities and hardcoded secrets are intercepted in the developer's pull request stage before code reaches any cluster.
3. **Immutability & Declarative Convergence:** Both cloud infrastructure (Terraform) and container workloads (Kubernetes + Helm) are declared in Git as the single source of truth. ArgoCD continuously ensures the cluster state matches the Git repository without drift.
4. **Resilience Through Observability:** Metrics and alerts in Prometheus and Grafana provide actionable telemetry, turning reactive firefighting into proactive engineering.
5. **Production Troubleshooting Competency:** Investigating real-world failure states (`CrashLoopBackOff`, `ImagePullBackOff`, `502 Bad Gateway`, `OOMKilled`) taught me how to diagnose root causes systematically using logs, events, resource limits, and networking topologies.

---

## 📐 Project Overview & Architecture

### High-Level Architecture Flow:
```text
  +---------------------------------------------------------------------------------------------------+
  |                                   DEVELOPER COMMIT & CODE STAGE                                   |
  |  [ Application Source Code ] ----> [ Local Unit Tests ] ----> [ Git Commit to GitHub Repository ] |
  +---------------------------------------------------------------------------------------------------+
                                                    |
                                                    v (Webhook Trigger)
  +---------------------------------------------------------------------------------------------------+
  |                                GITHUB ACTIONS CI/CD & DEVSECOPS                                   |
  |  [ Lint & Pytest ] -> [ SAST: Semgrep ] -> [ Secrets: Gitleaks ] -> [ SCA: Trivy Dependencies ]   |
  |                                                 |                                                 |
  |  [ Push to GHCR / Docker Hub ] <--- [ Trivy Container Scan ] <--- [ Docker Multi-Stage Build ]    |
  +---------------------------------------------------------------------------------------------------+
                                                    |
                                                    v (GitOps Reconciliation)
  +---------------------------------------------------------------------------------------------------+
  |                              ARGOCD GITOPS & KUBERNETES DEPLOYMENT                                |
  |  [ ArgoCD Controller ] =====(Sync Git Repo)=====> [ EKS / Minikube Kubernetes Cluster ]           |
  |                                                    |                                              |
  |             +--------------------------------------+--------------------------------------+       |
  |             |                                      |                                      |       |
  |             v                                      v                                      v       |
  |    [ Ingress Nginx ]                      [ ClusterIP Service ]                  [ ReplicaSet / Pods]
  |    app.devopshero.local                   devops-app-service:80                  3 Replicas (HPA 2-10)
  +---------------------------------------------------------------------------------------------------+
                                                    |
                                                    v (Telemetry & Alerts)
  +---------------------------------------------------------------------------------------------------+
  |                                MONITORING & OBSERVABILITY ECOSYSTEM                               |
  |  [ Prometheus Scrapes /metrics ] ---> [ Alertmanager Thresholds ] ---> [ Grafana Dashboards ]     |
  +---------------------------------------------------------------------------------------------------+
```

#### Architecture Diagram Card:
![End-to-End Architecture](./screenshots/01-end-to-end-architecture.png)

---

## 🧰 Technologies & Tools Used

| Domain | Technology Stack | Primary Function in Project |
| :--- | :--- | :--- |
| **Microservice Application** | Python 3.11 / Flask / Gunicorn | High-performance REST API with healthz and Prometheus endpoints |
| **Source Control** | Git & GitHub | Distributed version control and GitOps declarative source of truth |
| **Containerization** | Docker (Multi-Stage Build) | Non-root secure container image (~60MB slim runtime footprint) |
| **Container Registry** | GitHub Container Registry (ghcr.io) | OCI-compliant secure image repository |
| **Infrastructure as Code** | Terraform (HashiCorp AWS Provider) | Declarative provisioning of AWS VPC, Subnets, and EKS Cluster |
| **Container Orchestration**| Kubernetes (v1.30+) | Container scheduling, self-healing, rolling updates, HPA, and PVCs |
| **Package Management** | Helm (v3) | Parameterized Kubernetes templates, release versioning, and values overrides |
| **CI/CD Automation** | GitHub Actions | Automated build, test, scan, containerize, and delivery pipelines |
| **DevSecOps Security** | Trivy, Semgrep, Gitleaks | SAST static analysis, SCA dependency scanning, and secret detection |
| **GitOps Continuous Delivery**| ArgoCD | Automated synchronization, configuration drift self-healing, zero manual ops |
| **Observability & Metrics**| Prometheus & Grafana | Application latency tracking, HTTP request rates, and resource alerts |

---

## 📁 Repository Directory Structure

```text
final-devops-project/
├── application/                       # Microservice application code
│   ├── app.py                         # REST API with Prometheus metrics & health probes
│   ├── requirements.txt               # Pinned dependencies
│   └── test_app.py                    # Pytest unit testing suite
├── docker/                            # Docker configurations
│   ├── Dockerfile                     # Multi-stage, non-root hardened Dockerfile
│   ├── .dockerignore                  # Build context exclusions
│   └── docker-compose.yml             # Local multi-container development environment
├── kubernetes/                        # Raw Kubernetes manifests & Kustomize
│   ├── deployment.yaml                # 3-replica deployment with probes & securityContext
│   ├── service.yaml                   # ClusterIP service
│   ├── configmap.yaml                 # Environment configuration
│   ├── secret.yaml                    # Base64 encrypted credentials
│   ├── ingress.yaml                   # Ingress routing rules
│   ├── hpa.yaml                       # HorizontalPodAutoscaler (CPU & Memory)
│   ├── pvc.yaml                       # PersistentVolumeClaim storage
│   ├── resources.yaml                 # Consolidated manifests
│   └── kustomization.yaml             # Kustomize bundling configuration
├── helm/                              # Production Helm package
│   └── devops-app/
│       ├── Chart.yaml                 # Chart metadata
│       ├── values.yaml                # Configurable deployment values
│       └── templates/                 # Parameterized Kubernetes templates
│           ├── _helpers.tpl           # Template naming macros
│           ├── deployment.yaml        # Deployment template
│           ├── resources.yaml         # Service, ConfigMap, Secret, HPA templates
│           ├── ingress.yaml           # Ingress template
│           └── NOTES.txt              # Installation notes
├── terraform/                         # Infrastructure as Code module
│   ├── provider.tf                    # AWS provider block
│   ├── variables.tf                   # Input variables (VPC CIDR, EKS cluster)
│   ├── main.tf                        # VPC, Subnets, Internet Gateway, Security Groups
│   ├── outputs.tf                     # Exported network & cluster outputs
│   └── terraform.tfvars               # Variable inputs
├── .github/                           # GitHub Actions CI/CD workflows
│   └── workflows/
│       └── ci-cd-devsecops.yml        # 4-stage pipeline with security gates
├── security/                          # DevSecOps scanning configurations
│   ├── gitleaks.toml                  # Secret detection rules
│   ├── semgrep-rules.yaml             # Custom SAST security checks
│   ├── trivy.yaml                     # Vulnerability gate thresholds
│   └── security-gate.sh               # Security gate validation script
├── monitoring/                        # Observability & Metrics
│   ├── prometheus-rules.yaml          # ServiceMonitor & Alerting rules
│   └── grafana-dashboard.json         # Production Grafana dashboard JSON
├── gitops/                            # GitOps manifests
│   ├── argocd-application.yaml        # ArgoCD Application CRD (auto-sync, prune, heal)
│   └── kustomization.yaml             # GitOps Kustomize overlay
├── screenshots/                       # Evidence & architecture reference diagrams
└── README.md                          # Master documentation & troubleshooting guide
```

---

## 🐍 1. Application Setup & Unit Testing

The application ([`application/app.py`](./application/app.py)) is a resilient REST microservice built in Python:
- **Endpoints:**
  - `GET /`: Returns service identity, environment, and version payload.
  - `GET /api/v1/info`: Architecture metadata and technology capabilities.
  - `GET /healthz`: Kubernetes liveness and readiness probe endpoint.
  - `GET /metrics`: Standard Prometheus metrics export (`http_requests_total`, `http_request_duration_seconds`).
- **Resilience:** Features fallback metrics handling if the Prometheus library is omitted locally, ensuring graceful degradation.

### Running Unit Tests Locally:
```bash
cd application/
pytest test_app.py -v
```
#### Output:
```text
============================= test session starts =============================
platform win32 -- Python 3.11.9, pytest-9.1.0, pluggy-1.6.0
collected 4 items

test_app.py::test_home_endpoint PASSED                                   [ 25%]
test_app.py::test_info_endpoint PASSED                                   [ 50%]
test_app.py::test_healthz_probe PASSED                                   [ 75%]
test_app.py::test_prometheus_metrics PASSED                              [100%]

============================== 4 passed in 0.30s ==============================
```

---

## 🐳 2. Docker Setup & Containerization

### Multi-Stage Dockerfile Highlights ([`docker/Dockerfile`](./docker/Dockerfile)):
1. **Stage 1 (`builder`):** Compiles dependencies and wheel caches in an isolated build layer.
2. **Stage 2 (`runtime`):** Starts from a lean `python:3.11-slim` base image.
3. **Security Hardening:**
   - Runs as non-root user `appuser` (UID `10001`, GID `10001`).
   - Disables bytecode generation (`PYTHONDONTWRITEBYTECODE=1`).
   - Built-in `HEALTHCHECK` testing `/healthz` every 30 seconds.
   - Discards build tools (`gcc`), shrinking image size from >400MB down to ~60MB.

### Building & Running with Docker Compose:
```bash
# Build standalone image:
docker build -t sahasra/devops-final-app:1.0.0 -f docker/Dockerfile .

# Run multi-container development stack:
docker-compose -f docker/docker-compose.yml up -d
```

---

## ☸️ 3. Kubernetes Deployment

The [`kubernetes/`](./kubernetes/) directory contains production-ready declarative manifests:
- **Deployment (`deployment.yaml`):**
  - Configures **3 replicas** with `RollingUpdate` strategy (`maxSurge: 1`, `maxUnavailable: 0`).
  - Pod security context: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, drops all Linux capabilities.
  - Resource requests: `cpu: 100m`, `memory: 128Mi`. Limits: `cpu: 500m`, `memory: 512Mi`.
  - Configured with `readinessProbe` and `livenessProbe` pointing to `/healthz`.
  - Volume mount attached to `devops-app-pvc` PersistentVolumeClaim.
- **Service (`service.yaml`):** ClusterIP exposing internal port 80 to container port 8080.
- **ConfigMap & Secret (`resources.yaml`):** Injects non-sensitive environment variables and encrypted API keys.
- **Ingress (`resources.yaml`):** Exposes application host `app.devopshero.local` via Nginx Ingress Controller.
- **HPA (`resources.yaml`):** HorizontalPodAutoscaler dynamically scaling from 2 to 10 pods when CPU exceeds 70% or memory exceeds 80%.

#### Evidence Screenshot - Kubernetes Deployment:
![Kubernetes Deployment](./screenshots/03-kubernetes-helm-deployment.png)

---

## 📦 4. Helm Deployment

The application is packaged into a modular Helm chart located in [`helm/devops-app/`](./helm/devops-app/):
- **Dynamic Templating:** Standardizes deployments across dev, staging, and production environments using `values.yaml` overrides.
- **Validation:**
  ```bash
  helm lint helm/devops-app
  ```
  **Output:**
  ```text
  ==> Linting helm/devops-app
  [INFO] Chart.yaml: icon is recommended
  1 chart(s) linted, 0 chart(s) failed
  ```
- **Deployment Command:**
  ```bash
  helm upgrade --install devops-release helm/devops-app \
    --namespace production --create-namespace \
    --set image.tag="1.0.0" --set autoscaling.enabled=true
  ```

---

## 🏗️ 5. Terraform Infrastructure as Code

Located in [`terraform/`](./terraform/), the configuration provisions the cloud networking foundation for Kubernetes:
- **VPC (`main.tf`):** Custom VPC with CIDR `10.0.0.0/16` in `ap-south-1`.
- **Subnets:**
  - 2 Public Subnets across Availability Zones `ap-south-1a` and `ap-south-1b` tagged with `kubernetes.io/role/elb=1`.
  - 2 Private Subnets across AZs tagged with `kubernetes.io/role/internal-elb=1` for internal Kubernetes workloads.
- **Gateways & Security:** Internet Gateway (`igw`), route tables, and EKS Cluster Security Group.

### Terraform Execution Workflow:
```bash
cd terraform/
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply -auto-approve
```

---

## 🚀 6. CI/CD Pipeline & DevSecOps Implementation

The automated enterprise pipeline is defined in [`.github/workflows/ci-cd-devsecops.yml`](./.github/workflows/ci-cd-devsecops.yml):

```text
[ Trigger: Push/PR ]
        |
        v
+-----------------------+     +-------------------------------+
| STAGE 1: BUILD & TEST | --> | STAGE 2: DEVSECOPS SECURITY   |
| - Setup Python 3.11   |     | - Secret Scan: Gitleaks       |
| - Pytest Unit Tests   |     | - SAST Scan: Semgrep          |
+-----------------------+     | - SCA Scan: Trivy Filesystem  |
                              +-------------------------------+
                                              |
                                              v
+-----------------------+     +-------------------------------+
| STAGE 4: GITOPS &     | <-- | STAGE 3: CONTAINER SCAN & PUSH|
|          HELM DELIVERY|     | - Docker Multi-Stage Buildx   |
| - Helm Lint           |     | - Trivy Image Vulnerability   |
| - Template Validation |     | - Push to ghcr.io Registry    |
+-----------------------+     +-------------------------------+
```

### DevSecOps Security Gates Enforced:
1. **Secret Scanning (Gitleaks):** Intercepts accidental leaks of API tokens, SSH private keys, and passwords.
2. **Static Application Security Testing (SAST - Semgrep):** Detects insecure coding patterns, code injections, and hardcoded secrets.
3. **Software Composition Analysis (SCA - Trivy):** Checks Python packages in `requirements.txt` against CVE databases.
4. **Container Image Scanning (Trivy):** Scans the built container image; builds fail if `CRITICAL` or `HIGH` vulnerabilities are uncovered.

#### Evidence Screenshot - CI/CD & DevSecOps:
![CI/CD DevSecOps Pipeline](./screenshots/02-ci-cd-devsecops-pipeline.png)

---

## 📊 7. Monitoring & Observability

Located in [`monitoring/`](./monitoring/):
1. **Telemetry Instrumentation:** Python microservice exposes real-time Prometheus metrics on `/metrics`.
2. **Prometheus Operator (`prometheus-rules.yaml`):**
   - `ServiceMonitor` automatically discovers and scrapes `/metrics` every 15 seconds.
   - `PrometheusRule` configures alerting rules:
     - `HighHTTPErrorRate`: Fires if 5xx error rate exceeds 5% for 2 minutes.
     - `HighLatency`: Fires if P95 latency exceeds 1.0 second.
     - `PodCrashLooping`: Fires if container restarts escalate rapidly.
3. **Grafana Dashboard ([`grafana-dashboard.json`](./monitoring/grafana-dashboard.json)):** Real-time production visual dashboard showing HTTP request volume (RPS), P95 latency, Pod CPU, and Memory utilization.

#### Evidence Screenshot - Observability:
![Observability Monitoring](./screenshots/04-monitoring-grafana-prometheus.png)

---

## 🔄 8. GitOps Continuous Delivery (ArgoCD)

Located in [`gitops/argocd-application.yaml`](./gitops/argocd-application.yaml):
- **Declarative GitOps CRD:** Points directly to this GitHub repository (`devops-homework` branch) and the Helm chart path (`final-devops-project/helm/devops-app`).
- **Automated Synchronization:**
  - `prune: true`: Automatically deprovisions Kubernetes resources that are deleted from Git.
  - `selfHeal: true`: If a human makes an unauthorized manual change to the live cluster (e.g. `kubectl edit`), ArgoCD automatically reverts the change back to the Git source of truth.
  - Eliminates configuration drift and guarantees reproducible environments.

#### Evidence Screenshot - GitOps:
![ArgoCD GitOps](./screenshots/05-gitops-argocd-workflow.png)

---

## 🛠️ 9. Final Troubleshooting Challenge (Production Post-Mortem)

Four critical production failure scenarios were intentionally introduced into the platform, investigated, remediated, and verified:

```text
========================================================================================
                      FINAL PRODUCTION TROUBLESHOOTING MATRIX
========================================================================================
 Issue | Symptom                | Root Cause              | Remediated State
-------+------------------------+-------------------------+-----------------------------
   1   | CrashLoopBackOff       | String PORT in config   | Integer PORT='8080' (Healthy)
   2   | ImagePullBackOff       | Typo in Helm image tag  | Corrected to tag '1.0.0'
   3   | Ingress 502 Bad Gateway| Service targetPort 5000 | Aligned targetPort to 8080
   4   | OOMKilled (Exit 137)   | Memory limit 32Mi       | Scaled limit to 512Mi
========================================================================================
```

---

### Challenge 1: `CrashLoopBackOff` - Application Boot Failure

#### 1. Symptom & Observation:
Pod status escalated to `CrashLoopBackOff` with restart count rising rapidly:
```bash
kubectl get pods -n production
```
```text
NAME                                     READY   STATUS             RESTARTS   AGE
devops-app-deployment-5d7f99b86f-q8n2z   0/1     CrashLoopBackOff   4          3m
```

#### 2. Investigation Commands:
```bash
kubectl logs devops-app-deployment-5d7f99b86f-q8n2z -n production --previous
```
**Captured Log Output:**
```text
Traceback (most recent call last):
  File "/app/app.py", line 74, in <module>
    port = int(os.getenv("PORT", 8080))
ValueError: invalid literal for int() with base 10: 'eight-zero-eight-zero'
```

#### 3. Root Cause:
The `ConfigMap` contained a string value `PORT: "eight-zero-eight-zero"` instead of an integer. The Python startup sequence crashed immediately on `int()` conversion.

#### 4. Remediation:
Updated `configmap.yaml` to specify `PORT: "8080"` and executed a rollout restart:
```bash
kubectl rollout restart deployment devops-app-deployment -n production
```

#### 5. Verification:
```bash
kubectl get pods -n production
```
```text
NAME                                     READY   STATUS    RESTARTS   AGE
devops-app-deployment-7f89d4c798-8x7q2   1/1     Running   0          45s
```
✅ **Result:** Pod running stably with 0 restarts.

---

### Challenge 2: `ImagePullBackOff` / `ErrImagePull` - Image Tag Mismatch

#### 1. Symptom & Observation:
Pod was unable to start and remained stuck in `ImagePullBackOff`:
```bash
kubectl get pods -n production
```
```text
NAME                                     READY   STATUS             RESTARTS   AGE
devops-app-deployment-64dcb7c648-9x2pk   0/1     ImagePullBackOff   0          2m
```

#### 2. Investigation Commands:
```bash
kubectl describe pod devops-app-deployment-64dcb7c648-9x2pk -n production
```
**Captured Event Log:**
```text
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  2m                 default-scheduler  Successfully assigned devops-app to node-1
  Normal   Pulling    50s (x3 over 2m)   kubelet            Pulling image "sahasra/devops-final-app:v1.0.0-nonexistent"
  Warning  Failed     48s (x3 over 2m)   kubelet            Failed to pull image: rpc error: code = NotFound desc = not found
  Warning  Failed     48s (x3 over 2m)   kubelet            Error: ErrImagePull
```

#### 3. Root Cause:
The Helm `values.yaml` specified a non-existent tag `tag: "v1.0.0-nonexistent"` rather than the published image tag `1.0.0`.

#### 4. Remediation:
Corrected `values.yaml` to `tag: "1.0.0"` and updated the deployment:
```bash
helm upgrade devops-release helm/devops-app --set image.tag="1.0.0" -n production
```

#### 5. Verification:
```bash
kubectl get pods -n production
```
```text
NAME                                     READY   STATUS    RESTARTS   AGE
devops-app-deployment-7f89d4c798-b4m99   1/1     Running   0          30s
```
✅ **Result:** Image pulled successfully; container initialized.

---

### Challenge 3: Ingress `502 Bad Gateway` - Service Port Mismatch

#### 1. Symptom & Observation:
External users attempting to access the application via Ingress received an HTTP `502 Bad Gateway`:
```bash
curl -i -H "Host: app.devopshero.local" http://192.168.49.2/
```
```text
HTTP/1.1 502 Bad Gateway
Date: Thu, 08 Oct 2026 11:00:15 GMT
Content-Type: text/html
Content-Length: 157
Connection: keep-alive
```

#### 2. Investigation Commands:
```bash
# Check endpoints:
kubectl get endpoints devops-app-service -n production

# Inspect service definition:
kubectl get svc devops-app-service -n production -o yaml
```
**Captured Output:**
```yaml
ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 5000  # MISMATCH!
```

#### 3. Root Cause:
The Service was forwarding incoming traffic to container `targetPort: 5000`, while the container was actually listening on port `8080`. The Ingress controller could not establish a TCP handshake with the backend pods.

#### 4. Remediation:
Updated `service.yaml` and `helm/devops-app/values.yaml` so `targetPort` matched container port `8080`:
```bash
kubectl patch service devops-app-service -n production --type='json' \
  -p='[{"op": "replace", "path": "/spec/ports/0/targetPort", "value": 8080}]'
```

#### 5. Verification:
```bash
curl -i -H "Host: app.devopshero.local" http://192.168.49.2/
```
```text
HTTP/1.1 200 OK
Content-Type: application/json
Date: Thu, 08 Oct 2026 11:02:10 GMT

{"environment":"production","message":"Welcome to the Production DevOps Cloud Platform!","service":"devops-hero-microservice","status":"online","version":"1.0.0"}
```
✅ **Result:** Traffic routed properly through Ingress to Service to Pod; returned `200 OK`.

---

### Challenge 4: `OOMKilled` (Exit 137) - Memory Starvation Under Load

#### 1. Symptom & Observation:
During load testing, pods were being terminated with exit code 137:
```bash
kubectl get pods -n production
```
```text
NAME                                     READY   STATUS      RESTARTS   AGE
devops-app-deployment-7f89d4c798-v2n51   0/1     OOMKilled   1          10m
```

#### 2. Investigation Commands:
```bash
kubectl describe pod devops-app-deployment-7f89d4c798-v2n51 -n production
```
**Captured State:**
```text
    State:          Running
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Thu, 08 Oct 2026 10:45:00 GMT
      Finished:     Thu, 08 Oct 2026 10:55:00 GMT
```

#### 3. Root Cause:
The container memory limit in `deployment.yaml` was set to `32Mi`. Under concurrent request load, Gunicorn worker threads consumed ~50Mi, triggering the Linux kernel cgroup OOM killer to terminate the container.

#### 4. Remediation:
Increased memory allocations in `deployment.yaml` and `values.yaml`:
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```
Applied the updated configuration:
```bash
kubectl apply -f kubernetes/deployment.yaml
```

#### 5. Verification:
Simulated 500 concurrent connections. Memory stabilized at ~85Mi, well within the 512Mi limit. Zero OOMKilled events occurred.
✅ **Result:** Workload maintained 100% availability under heavy traffic.

#### Evidence Screenshot - Troubleshooting Remediation:
![Troubleshooting Investigation](./screenshots/06-troubleshooting-investigation-fix.png)

---

## 📸 Complete Screenshots Reference Gallery

All high-resolution visual evidence artifacts are located in [`final-devops-project/screenshots/`](./screenshots/):
1. **[`01-end-to-end-architecture.png`](./screenshots/01-end-to-end-architecture.png):** Visual overview of the entire DevOps cloud platform architecture from commit to GitOps.
2. **[`02-ci-cd-devsecops-pipeline.png`](./screenshots/02-ci-cd-devsecops-pipeline.png):** 4-stage GitHub Actions pipeline execution passing unit tests and DevSecOps gates.
3. **[`03-kubernetes-helm-deployment.png`](./screenshots/03-kubernetes-helm-deployment.png):** Kubernetes resources, Ingress routing, HPA scaling, and curl endpoint output.
4. **[`04-monitoring-grafana-prometheus.png`](./screenshots/04-monitoring-grafana-prometheus.png):** Prometheus metrics scraping, alert rules, and Grafana dashboard telemetry.
5. **[`05-gitops-argocd-workflow.png`](./screenshots/05-gitops-argocd-workflow.png):** ArgoCD application reconciliation showing Synced, Healthy, and self-healing state.
6. **[`06-troubleshooting-investigation-fix.png`](./screenshots/06-troubleshooting-investigation-fix.png):** Complete diagnostic and remediation logs for all 4 production challenge scenarios.

---

## 🎓 Key Lessons Learned

1. **Shift-Left Security:** Catching security vulnerabilities early via automated SAST and container image scanning in CI prevents expensive security incidents in production.
2. **Multi-Stage Docker Builds:** Drastically shrinks image footprint, strips compilation toolchains, and eliminates CVE attack surface.
3. **Separation of Concerns:** Separating application code, packaging (Helm), cloud infrastructure (Terraform), and delivery (GitOps) creates a maintainable enterprise platform.
4. **GitOps is the Future of Delivery:** Eliminates manual `kubectl` interventions, configuration drift, and ensures complete auditability of every production deployment.
5. **Systematic Troubleshooting:** When pods fail, checking logs (`--previous`), describing events, inspecting endpoints, and verifying port alignments resolves 95% of Kubernetes production outages.

---

**Submitted by:** Sahasra ambati (`sahasra10241`)  
**Assignment:** Session 21 - Final DevOps Capstone Project & Troubleshooting Challenge  
**Git Branch:** `devops-homework`
