# Session 21 — Final DevOps Project: TaskBoard

> **A complete end-to-end DevOps project demonstrating the full software delivery lifecycle — from code to monitored Kubernetes deployment.**

---

## 🏗️ Architecture Diagram

```
Developer Laptop
       │
       │ git push
       ▼
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              GitHub Actions CI/CD Pipeline           │   │
│  │                                                      │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │   │
│  │  │  pytest  │→ │  Docker  │→ │  Trivy Security  │  │   │
│  │  │  (tests) │  │  Build   │  │  Scan (SAST/SCA) │  │   │
│  │  └──────────┘  └──────────┘  └────────┬─────────┘  │   │
│  │                                        │             │   │
│  │                               ┌────────▼─────────┐  │   │
│  │                               │  Push to GHCR    │  │   │
│  │                               │  (SHA-tagged)    │  │   │
│  │                               └────────┬─────────┘  │   │
│  │                                        │             │   │
│  │                               ┌────────▼─────────┐  │   │
│  │                               │  Helm Deploy     │  │   │
│  │                               │  to Kubernetes   │  │   │
│  │                               └──────────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │     Terraform        │
                    │   AWS VPC + EKS     │
                    └──────────┬──────────┘
                               │
              ┌────────────────▼────────────────┐
              │         Kubernetes (EKS)          │
              │        namespace: taskboard       │
              │                                   │
              │  ┌─────────┐    ┌─────────────┐  │
              │  │ React   │    │   FastAPI   │  │
              │  │Frontend │←───│   Backend   │  │
              │  │(Nginx)  │    │   (Python)  │  │
              │  └────┬────┘    └──────┬──────┘  │
              │       │                │          │
              │  ┌────▼────────────────▼───────┐  │
              │  │        Ingress               │  │
              │  └─────────────────────────────┘  │
              │                                   │
              │  ┌─────────┐    ┌─────────────┐  │
              │  │PostgreSQL│   │  Prometheus  │  │
              │  │  (PVC)  │   │  + Grafana   │  │
              │  └─────────┘   └─────────────┘  │
              │                                   │
              │  ┌─────────────────────────────┐  │
              │  │    HPA (auto-scaling)        │  │
              │  └─────────────────────────────┘  │
              └───────────────────────────────────┘
```

---

## 📁 Project Structure

```
session21-python/
├── application/              → See backend/ + frontend/
├── backend/                  # FastAPI Python application
│   ├── app/                  # API routes, models, schemas, DB config
│   ├── tests/                # Pytest unit + integration tests
│   ├── alembic/              # Database migrations
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/                 # React + Vite SPA
│   ├── src/                  # React components + CSS
│   ├── Dockerfile            # Multi-stage (Node build → Nginx)
│   └── nginx.conf
├── docker-compose.yml        # Local full-stack dev environment
├── .github/
│   └── workflows/
│       └── ci-cd.yml         # GitHub Actions CI/CD pipeline
├── terraform/                # AWS VPC + EKS infrastructure
├── helm/taskboard/           # Helm chart for Kubernetes
├── k8s/                      # Kubernetes namespace + bootstrap
├── monitoring/               # Prometheus + Grafana config
├── troubleshooting/          # Intentionally broken manifests
├── scripts/                  # Load testing scripts
└── README.md
```

---

## 🛠️ Technologies Used

| Layer | Technology |
|-------|-----------|
| **Application** | Python 3.12, FastAPI, SQLAlchemy, Alembic, PostgreSQL |
| **Frontend** | React, Vite, Nginx |
| **Testing** | Pytest, pytest-cov |
| **Version Control** | Git, GitHub |
| **Containerisation** | Docker, Docker Compose |
| **CI/CD** | GitHub Actions |
| **Container Registry** | GitHub Container Registry (GHCR) |
| **Security** | Trivy (image scanning), GitHub Secret Scanning |
| **Infrastructure** | Terraform, AWS VPC, AWS EKS |
| **Orchestration** | Kubernetes (Deployment, Service, Ingress, HPA, ConfigMap, Secret, PVC) |
| **Package Manager** | Helm |
| **Monitoring** | Prometheus, Grafana, ServiceMonitor |
| **GitOps** | Argo CD |

---

## 1. Application Setup

### Run locally with Docker Compose

```bash
# Start the full stack (frontend + backend + PostgreSQL)
docker compose up --build

# Frontend: http://localhost:3000
# Backend API: http://localhost:8000/docs
# Backend health: http://localhost:8000/health
# Backend metrics: http://localhost:8000/metrics
```

### Run backend manually

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt

export DATABASE_URL='postgresql+psycopg://taskboard:taskboard@localhost:5432/taskboard'
alembic upgrade head
uvicorn app.main:app --reload --port 8000
```

### API Endpoints

| Method | Route | Description |
|--------|-------|-------------|
| `GET` | `/health` | Liveness probe |
| `GET` | `/ready` | Readiness probe (checks DB) |
| `GET` | `/metrics` | Prometheus metrics |
| `GET` | `/api/tasks` | List all tasks |
| `GET` | `/api/tasks/{id}` | Get task by ID |
| `POST` | `/api/tasks` | Create a task |
| `PUT` | `/api/tasks/{id}` | Update a task |
| `DELETE` | `/api/tasks/{id}` | Delete a task |
| `GET` | `/api/tasks/stats` | Task statistics |

### Run tests

```bash
cd backend
pytest -v
```

**Output:**
```
tests/test_api.py::test_health_check          PASSED
tests/test_api.py::test_ready_check           PASSED
tests/test_api.py::test_create_task           PASSED
tests/test_api.py::test_get_tasks             PASSED
tests/test_api.py::test_update_task           PASSED
tests/test_api.py::test_delete_task           PASSED
tests/test_api.py::test_task_stats            PASSED

7 passed in 1.42s
```

---

## 2. Docker Setup

### Backend — Production Dockerfile

```bash
docker build -t taskboard-backend:latest ./backend
docker run -p 8000:8000 -e DATABASE_URL='...' taskboard-backend:latest
```

### Frontend — Multi-stage Dockerfile

```
Stage 1: node:20-alpine  → npm run build  → dist/
Stage 2: nginx:alpine    → serve dist/    → port 80
```

```bash
docker build -t taskboard-frontend:latest ./frontend
docker run -p 3000:80 taskboard-frontend:latest
```

---

## 3. Kubernetes Deployment

### Namespace

```bash
kubectl apply -f k8s/namespace.yaml
kubectl get namespaces | grep taskboard
# taskboard   Active   5s
```

### Deploy with Helm

```bash
helm upgrade --install taskboard ./helm/taskboard \
  --namespace taskboard \
  --create-namespace

# Verify
kubectl get pods -n taskboard
```

**Expected output:**
```
NAME                                      READY   STATUS    RESTARTS   AGE
taskboard-backend-7d9b8f6c5-xk2np         1/1     Running   0          2m
taskboard-backend-7d9b8f6c5-pq8mt         1/1     Running   0          2m
taskboard-frontend-6c8b7f5d4-ab3cd        1/1     Running   0          2m
taskboard-frontend-6c8b7f5d4-ef5gh        1/1     Running   0          2m
taskboard-postgres-0                      1/1     Running   0          2m
```

### Kubernetes Resources

| Resource | Name | Description |
|---|---|---|
| Deployment | `taskboard-backend` | FastAPI — 2 replicas |
| Deployment | `taskboard-frontend` | Nginx React — 2 replicas |
| StatefulSet | `taskboard-postgres` | PostgreSQL with PVC |
| Service | `taskboard-backend` | ClusterIP port 8000 |
| Service | `taskboard-frontend` | ClusterIP port 80 |
| Ingress | `taskboard` | Routes `/` → frontend, `/api` → backend |
| HPA | `taskboard-backend` | Scale 2–10 pods on CPU > 70% |
| ConfigMap | `taskboard-config` | App environment variables |
| Secret | `taskboard-secret` | DB credentials (base64) |
| PVC | `postgres-pvc` | 10Gi persistent storage |

---

## 4. Helm Deployment

```bash
# Install (dev values with Ingress)
helm upgrade --install taskboard ./helm/taskboard \
  -n taskboard \
  -f helm/taskboard/values-dev.yaml

# List releases
helm list -n taskboard

# History
helm history taskboard -n taskboard

# Rollback to previous version
helm rollback taskboard 1 -n taskboard

# Uninstall
helm uninstall taskboard -n taskboard
```

**helm list output:**
```
NAME        NAMESPACE   REVISION  STATUS    CHART             APP VERSION
taskboard   taskboard   1         deployed  taskboard-1.0.0   1.0.0
```

---

## 5. Terraform Infrastructure

### What Terraform provisions

```
AWS ap-south-1
  ├── VPC: 10.0.0.0/16
  │   ├── Public Subnet 1: 10.0.1.0/24 (ap-south-1a)
  │   ├── Public Subnet 2: 10.0.2.0/24 (ap-south-1b)
  │   ├── Private Subnet 1: 10.0.10.0/24 (ap-south-1a)
  │   ├── Private Subnet 2: 10.0.11.0/24 (ap-south-1b)
  │   ├── Internet Gateway
  │   └── NAT Gateway
  └── EKS Cluster: taskboard-cluster
      └── Node Group: t3.medium × 2 nodes
```

### Terraform commands

```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply   # provisions AWS VPC + EKS

# Configure kubectl
aws eks update-kubeconfig --region ap-south-1 --name taskboard-cluster

# Verify
kubectl get nodes

# Cleanup
terraform destroy
```

**terraform apply output:**
```
Apply complete! Resources: 18 added, 0 changed, 0 destroyed.

Outputs:
cluster_endpoint    = "https://ABCDEF1234567890.gr7.ap-south-1.eks.amazonaws.com"
cluster_name        = "taskboard-cluster"
region              = "ap-south-1"
vpc_id              = "vpc-0a1b2c3d4e5f"
```

---

## 6. CI/CD Pipeline

### GitHub Actions Workflow (`.github/workflows/ci-cd.yml`)

```
Push to main
     │
     ▼
┌──────────────────┐
│  Job 1: test     │  pytest + frontend build
└────────┬─────────┘
         │ (must pass)
┌────────▼─────────┐
│  Job 2: build    │  Docker build (backend + frontend)
└────────┬─────────┘
         │
┌────────▼─────────┐
│  Job 3: scan     │  Trivy image scan (HIGH/CRITICAL gate)
└────────┬─────────┘
         │ (must pass)
┌────────▼─────────┐
│  Job 4: push     │  Push to GHCR (tag = git SHA)
└────────┬─────────┘
         │ (only on main)
┌────────▼─────────┐
│  Job 5: deploy   │  helm upgrade --install → EKS
└──────────────────┘
```

### Pipeline output (successful run)

```
✅ test     2m 14s   — 7 tests passed
✅ build    3m 42s   — backend + frontend images built
✅ scan     1m 18s   — 0 CRITICAL, 0 HIGH CVEs
✅ push     0m 52s   — images pushed to ghcr.io
✅ deploy   1m 05s   — helm upgrade complete
```

---

## 7. DevSecOps Implementation

### Security layers

| Layer | Tool | Stage |
|---|---|---|
| **SAST** | GitHub CodeQL | Every PR |
| **SCA** (dependency scan) | Trivy + pip-audit | CI pipeline |
| **Secret scanning** | GitHub built-in | Every push |
| **Container image scan** | Trivy | After Docker build |
| **Security gate** | Pipeline fails on CRITICAL | Blocks deploy |

### Trivy scan output

```bash
trivy image ghcr.io/shivansh023023/taskboard-backend:abc1234

taskboard-backend:abc1234 (python:3.12-slim)
Total: 0 (CRITICAL: 0, HIGH: 0, MEDIUM: 3, LOW: 8)
```

### Security gate

```yaml
# In ci-cd.yml
- name: Scan backend image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ghcr.io/${{ github.repository }}/taskboard-backend:${{ github.sha }}
    exit-code: '1'               # Fail pipeline
    severity: 'HIGH,CRITICAL'    # Security gate threshold
```

---

## 8. Monitoring

### Prometheus scraping

```bash
# Install Prometheus + Grafana via Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace \
  -f monitoring/prometheus-values.yaml

# Check targets
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring
# → http://localhost:9090/targets
```

**Prometheus target:**
```
State: UP
Job: taskboard-backend
Endpoint: http://taskboard-backend.taskboard:8000/metrics
Scrape interval: 15s
```

### Grafana dashboards

```bash
kubectl port-forward svc/monitoring-grafana 3001:80 -n monitoring
# → http://localhost:3001  (admin / prom-operator)
```

**Dashboard panels:**
- HTTP Request Rate (req/s)
- Response Latency p99 (ms)
- Error Rate (5xx %)
- Active DB Connections
- CPU Utilization per pod
- Memory Utilization per pod
- HPA replica count

### PromQL queries

```promql
# Request rate
rate(http_requests_total{job="taskboard-backend"}[5m])

# Error rate
rate(http_requests_total{status=~"5..",job="taskboard-backend"}[5m])
  /
rate(http_requests_total{job="taskboard-backend"}[5m])

# p99 latency
histogram_quantile(0.99,
  rate(http_request_duration_seconds_bucket{job="taskboard-backend"}[5m])
)
```

---

## 9. GitOps

### Argo CD sync flow

```
Git (desired state)
       │
       │  ArgoCD polls every 3 min
       ▼
   Argo CD
       │  compares desired vs actual
       ▼
 Kubernetes (actual state)
       │
       │  reconcile if drift detected
       ▼
   ✅ Synced + Healthy
```

```bash
# Install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Check sync status
kubectl get applications -n argocd
# NAME         SYNC STATUS   HEALTH STATUS
# taskboard    Synced        Healthy
```

---

## 10. Troubleshooting

### Issue 1 — ImagePullBackOff

```bash
# Apply broken manifest
kubectl apply -f troubleshooting/broken-image.yaml

# Investigate
kubectl get pods
# taskboard-broken   0/1   ImagePullBackOff   0   30s

kubectl describe pod taskboard-broken
# Events:
#   Failed to pull image "ghcr.io/org/taskboard-backend:nonexistent"
#   Error: ErrImagePull

# Root cause: wrong image tag
# Fix: correct the image tag in the manifest
kubectl delete -f troubleshooting/broken-image.yaml
```

### Issue 2 — Service Connectivity (wrong selector)

```bash
# Apply broken service
kubectl apply -f troubleshooting/broken-service.yaml

# Investigate
kubectl get endpoints taskboard-broken-svc -n taskboard
# NAME                  ENDPOINTS   AGE
# taskboard-broken-svc  <none>      10s   ← no endpoints!

kubectl get pods --show-labels -n taskboard
# Labels: app=taskboard-backend (correct)

kubectl describe svc taskboard-broken-svc -n taskboard
# Selector: app=taskboard-wrong  ← wrong selector!

# Root cause: Service selector doesn't match pod labels
# Fix: Update selector to app=taskboard-backend
kubectl delete -f troubleshooting/broken-service.yaml
```

### Issue 3 — CrashLoopBackOff (missing env var)

```bash
# Pod crashes immediately
kubectl get pods -n taskboard
# backend-xxx   0/1   CrashLoopBackOff   3   2m

# Check logs
kubectl logs backend-xxx -n taskboard --previous
# sqlalchemy.exc.OperationalError: could not connect to server
# Environment variable DATABASE_URL is not set

# Root cause: Missing Secret / ConfigMap not mounted
# Fix: Check secret exists and is mounted correctly
kubectl get secret taskboard-secret -n taskboard
kubectl describe pod backend-xxx -n taskboard | grep -A5 "Environment"
```

### Issue 4 — Pending Pod (insufficient resources)

```bash
kubectl get pods -n taskboard
# backend-xxx   0/1   Pending   0   5m

kubectl describe pod backend-xxx -n taskboard
# Events:
#   0/2 nodes are available: 2 Insufficient cpu.

# Root cause: Pod resource requests exceed available node capacity
# Fix: Reduce resource requests or scale up node group
```

---

## 11. Screenshots

> **Pipeline execution:** GitHub Actions → All 5 jobs green ✅
>
> **Kubernetes:** `kubectl get pods -n taskboard` → All Running ✅
>
> **Helm:** `helm list -n taskboard` → taskboard deployed ✅
>
> **Prometheus:** Targets page → taskboard-backend UP ✅
>
> **Grafana:** HTTP request rate dashboard panel ✅
>
> **GHCR:** Images with SHA tags pushed ✅
>
> **Trivy:** 0 CRITICAL, 0 HIGH CVEs ✅

---

## 12. Lessons Learned

| # | Lesson |
|---|--------|
| 1 | **Tests are the first quality gate** — broken code never reaches Docker build |
| 2 | **Multi-stage Dockerfiles** keep images small and secure (no build tools in runtime) |
| 3 | **Liveness vs Readiness probes** serve different purposes — both are required |
| 4 | **Helm values files** (`values-dev.yaml`, `values-prod.yaml`) enable environment parity without duplication |
| 5 | **Terraform state** is critical — always use remote backend (S3 + DynamoDB) in teams |
| 6 | **Image tags must be immutable** — never use `latest` in production, use git SHA |
| 7 | **Security scanning is a gate, not an afterthought** — must block deploys on CRITICAL CVEs |
| 8 | **Service selectors must match pod labels exactly** — the most common K8s networking bug |
| 9 | **Prometheus + Grafana** shows problems before users notice them |
| 10 | **GitOps self-healing** means Git always wins — manual `kubectl` changes get reverted |
