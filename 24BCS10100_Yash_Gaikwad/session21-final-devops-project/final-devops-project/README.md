# StockPilot: from a laptop to monitored Kubernetes (Final DevOps Project)

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

This is the final project of the course: one real application taken through **Git, GitHub, CI, build and test, security scanning, Docker, a registry, Kubernetes, Helm, Terraform, monitoring and GitOps**, followed by a **troubleshooting challenge** in which I break the running system on purpose and repair it.

The application and the DevOps layer are my own project (it also lives in my GitHub repository <https://github.com/Yash-1706/devops-assgn>, where its CI pipeline has run on GitHub). Here it is reorganised into the folder layout the homework asks for, extended with a ConfigMap, a DevSecOps pipeline, GitOps, and re-verified end to end: **every output and screenshot in this file was produced during this submission**, on my laptop, and nothing is copied from elsewhere.

| Required item | Where |
|---|---|
| `application/` | [`application/`](application): FastAPI backend (with tests and migrations) and React frontend |
| `docker/` | [`docker/`](docker): the two Dockerfiles and the Compose file |
| `kubernetes/` | [`kubernetes/`](kubernetes): namespace, storage class, troubleshooting manifests (the objects themselves are in the chart) |
| `helm/` | [`helm/stockpilot/`](helm/stockpilot): the chart with `values-dev.yaml` and `values-eks.yaml` |
| `terraform/` | [`terraform/`](terraform): AWS VPC + EKS |
| `.github/workflows/` | [`ci-cd.yml`](.github/workflows/ci-cd.yml) (ran on GitHub) and [`devsecops.yml`](.github/workflows/devsecops.yml) (full DevSecOps flow) |
| `security/` | [`security/`](security): scanner configuration and policy |
| `monitoring/` | [`monitoring/`](monitoring): Prometheus, Grafana, alert rules, dashboard |
| `gitops/` | [`gitops/`](gitops): the Argo CD `Application` |
| `README.md` | this file |

## Contents

1. [Project overview](#1-project-overview)
2. [Architecture diagram](#2-architecture-diagram)
3. [Technologies used](#3-technologies-used)
4. [Application setup](#4-application-setup)
5. [Docker setup](#5-docker-setup)
6. [Kubernetes deployment](#6-kubernetes-deployment)
7. [Helm deployment](#7-helm-deployment)
8. [Terraform infrastructure](#8-terraform-infrastructure)
9. [CI/CD pipeline](#9-cicd-pipeline)
10. [DevSecOps implementation](#10-devsecops-implementation)
11. [Monitoring](#11-monitoring)
12. [GitOps](#12-gitops)
13. [Troubleshooting](#13-troubleshooting)
14. [Screenshots](#14-screenshots)
15. [Lessons learned](#15-lessons-learned)

### What was executed, and what was not

| Area | Status in this submission |
|---|---|
| Unit tests (48), Docker build, Compose stack, smoke tests | **run** (section 5) |
| Image scans (Trivy), SAST, SCA, secret scan | **run** locally (sections 5 and 10, details in Session 17) |
| Kubernetes + Helm on a real cluster (Minikube): install, probes, storage, Ingress, HPA under load, `helm test` | **run** (sections 6 and 7) |
| Troubleshooting challenge (4 faults, fixed) | **run** (section 13) |
| Monitoring (Prometheus, Grafana, alert firing and resolving) | **run** against the real backend (section 11) |
| GitOps (Argo CD sync, self-heal, change through Git) | **run** (section 12) |
| GitHub Actions `ci-cd.yml` | **ran on GitHub** earlier (4 green runs, Session 16); both workflows lint clean with `actionlint` |
| `devsecops.yml` | linted, every tool in it run locally; **not run on GitHub** (in this homework repository the workflow files sit inside a session folder, and GitHub only runs workflows from the root `.github/workflows`) |
| Terraform | `fmt`, `init`, `validate` **run**; `plan/apply/destroy` against AWS **not run** (needs a real, billable AWS account); Terraform apply/destroy was demonstrated against a local AWS emulator in Sessions 18 and 19 |
| Push to a container registry, EKS | **not run** (Minikube with locally loaded images stands in for the registry and the cluster) |

---

## 1. Project overview

StockPilot is a small, realistic inventory-management web application for a warehouse team. It tracks what is in stock, warns when an item drops below its reorder level, and keeps a ledger of every stock movement (goods received, goods shipped).

- Dashboard with KPI cards: total SKUs, units in stock, stock value, items that need attention
- Item table with stock-level bars, status badges (in stock / low stock / out of stock), search and category filters
- Create, edit and delete items; **receive** or **issue** stock with a reason
- Reorder list: everything at or below its reorder level
- Stock-movement ledger: an auditable history of every change, newest first
- Responsive UI and clear loading and error states

## 2. Architecture diagram

```text
Developer -> Git/GitHub -> GitHub Actions (ci-cd.yml, devsecops.yml)
                              |-- unit tests (pytest) + frontend build
                              |-- SAST (Semgrep)  SCA (pip-audit, npm audit)  secret scan (gitleaks)
                              |-- Docker build (backend + frontend)
                              |-- container image scan (Trivy, fails on HIGH/CRITICAL)
                              |-- SECURITY GATE (all scans must pass)
                              `-- push to the registry (GHCR), tagged with the commit SHA
                                        |
   Terraform -> AWS VPC + EKS           v
                    |              Helm chart  <---- Argo CD (GitOps): Git is the source of truth,
                    v                   |                          sync + self-heal + prune
              Kubernetes  <-------------+
        +-----------+-----------+
     Frontend    Backend      PostgreSQL (PVC)
     (React +    (FastAPI)
      Nginx)        |  /metrics, /health, /ready
        ^           v
     Ingress    Prometheus -> Grafana (+ alert rules)        HPA scales the backend on CPU
```

## 3. Technologies used

| Layer | Technology |
|---|---|
| Frontend | React 19, Vite, plain CSS, served by Nginx (unprivileged) |
| Backend | Python 3.12, FastAPI, SQLAlchemy 2, Alembic, Pydantic |
| Database | PostgreSQL 16 |
| Tests | pytest (FastAPI TestClient, in-memory SQLite) |
| Containers | Docker, Docker Compose, multi-stage builds, non-root users |
| CI/CD | GitHub Actions, GitHub Container Registry (GHCR) |
| Security | Semgrep (SAST), pip-audit and npm audit (SCA), gitleaks (secrets), Trivy (images) |
| Infrastructure | Terraform (AWS VPC + EKS) |
| Orchestration | Kubernetes, Helm, Ingress (ingress-nginx), HPA, probes, PVC |
| Observability | Prometheus, Grafana, alert rules, health/readiness endpoints |
| GitOps | Argo CD |

### Repository layout

```text
final-devops-project/
├── application/
│   ├── backend/            FastAPI app (app/), Alembic migrations (alembic/), tests (tests/)
│   └── frontend/           React + Vite app (src/), nginx.conf.template
├── docker/                 backend.Dockerfile, frontend.Dockerfile, docker-compose.yml
├── kubernetes/             namespace, storage class, troubleshooting manifests
├── helm/stockpilot/        the chart (templates/, values.yaml, values-dev.yaml, values-eks.yaml)
├── terraform/              AWS VPC + EKS
├── .github/workflows/      ci-cd.yml, devsecops.yml
├── security/               .gitleaks.toml, trivy.yaml, .trivyignore, semgrep-rules.yml, run-security-scans.sh, policy
├── monitoring/             local/ (Prometheus + Grafana in Docker) and kube-prometheus-stack values
├── gitops/                 argocd-application.yaml
├── scripts/                load-test.sh (HPA), install-cluster-addons.sh
├── docs/screenshots/       the screenshots used in this README
└── README.md
```

## 4. Application setup

### With Docker Compose (fastest)

```bash
cd docker
docker compose up --build
```

| URL | What |
|---|---|
| http://localhost:3000 | the application |
| http://localhost:8000/docs | Swagger UI of the API |
| http://localhost:8000/health | liveness probe |
| http://localhost:8000/ready | readiness probe (checks the database) |
| http://localhost:8000/metrics | Prometheus metrics |

On the first start the backend container runs the Alembic migrations (which also load a few demo items). No password is stored in the repository: the Compose database is only reachable on the private Compose network, so it uses `trust` authentication; Kubernetes uses a generated password instead.

### Backend only

```bash
docker run -d --name stockpilot-pg -p 5432:5432 -e POSTGRES_HOST_AUTH_METHOD=trust \
  -e POSTGRES_DB=stockpilot postgres:16-alpine

cd application/backend
python -m venv .venv && source .venv/bin/activate       # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt
export DATABASE_URL='postgresql+psycopg://postgres@localhost:5432/stockpilot'
alembic upgrade head
uvicorn app.main:app --reload --port 8000
```

### Frontend only (hot reload)

```bash
cd application/frontend
npm ci
npm run dev        # http://localhost:5173, /api is proxied to http://localhost:8000
```

### API

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/items` | list items; filters `?stock=low_stock`, `?category=`, `?q=` (name/SKU search) |
| GET | `/api/items/stats` | KPI numbers (totals, stock value, low / out of stock) |
| GET | `/api/items/{id}` | one item |
| POST | `/api/items` | create (409 if the SKU exists) |
| PUT | `/api/items/{id}` | update (only the fields sent change) |
| DELETE | `/api/items/{id}` | delete an item and its ledger |
| POST | `/api/items/{id}/adjust` | receive (`delta` > 0) or issue (`delta` < 0) stock; 409 if it would go below zero |
| GET | `/api/movements?limit=10` | latest stock-ledger entries |
| GET | `/`, `/health`, `/ready`, `/metrics` | service info, liveness, readiness, Prometheus |

`/health` only says "the process is alive" (no database access). `/ready` runs `SELECT 1` and returns `503` if the database is unreachable, which is what tells Kubernetes to stop sending traffic to a Pod. The test run is in the next section.

## 5. Docker setup

- [`docker/backend.Dockerfile`](docker/backend.Dockerfile): `python:3.12-slim`, dependencies installed first (layer cache), numeric non-root user (uid 10001), `HEALTHCHECK`, and a start command that runs `alembic upgrade head` and then `exec uvicorn`. A PostgreSQL advisory lock in `alembic/env.py` makes replicas that start at the same time take turns migrating.
- [`docker/frontend.Dockerfile`](docker/frontend.Dockerfile): multi-stage. Stage 1 (`node:22-alpine`) runs `npm ci && npm run build`; stage 2 (`nginxinc/nginx-unprivileged`, uid 101) contains only the static files and the nginx config. nginx forwards `/api` to the backend (`BACKEND_URL`), so the browser never needs the backend host name.
- [`docker/docker-compose.yml`](docker/docker-compose.yml): PostgreSQL (with a named volume and a health check), the backend (waits for a healthy database) and the frontend (waits for a healthy backend).

### Unit tests (the CI "test" gate), run in a clean container

_The backend test suite (pytest) runs against a throw-away SQLite database. This is exactly the step the pipeline runs before anything is built._

```console
$ docker run --rm -e PYTHONDONTWRITEBYTECODE=1 -v "$PWD/application/backend:/app" -w /app python:3.12-slim sh -c 'pip install -q -r requirements-dev.txt 2>&1 | grep -v WARNING | tail -n 2; python -m pytest -q -p no:cacheprovider 2>&1 | tail -n 12'
[notice] A new release of pip is available: 25.0.1 -> 26.2.1
[notice] To update, run: pip install --upgrade pip
................................................                         [100%]
48 passed in 2.75s
```

### Build and run the whole stack with Docker Compose

_Builds both images from `docker/*.Dockerfile` (contexts in `application/`) and starts PostgreSQL, the backend and the frontend._

```console
$ cd docker && docker compose -p stockpilot-final up -d --build 2>&1 | tail -n 14
 Container stockpilot-final-backend-1 Creating 
 Container stockpilot-final-backend-1 Created 
 Container stockpilot-final-frontend-1 Creating 
 Container stockpilot-final-frontend-1 Created 
 Container stockpilot-final-db-1 Starting 
 Container stockpilot-final-db-1 Started 
 Container stockpilot-final-db-1 Waiting 
 Container stockpilot-final-db-1 Healthy 
 Container stockpilot-final-backend-1 Starting 
 Container stockpilot-final-backend-1 Started 
 Container stockpilot-final-backend-1 Waiting 
 Container stockpilot-final-backend-1 Healthy 
 Container stockpilot-final-frontend-1 Starting 
 Container stockpilot-final-frontend-1 Started 
```

_Three services; the backend and the frontend wait for the health checks of the layer below._

```console
$ cd docker && docker compose -p stockpilot-final ps --format 'table {{.Service}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
SERVICE    IMAGE                       STATUS                   PORTS
backend    stockpilot-final-backend    Up 2 minutes (healthy)   0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp
db         postgres:16-alpine          Up 2 minutes (healthy)   5432/tcp
frontend   stockpilot-final-frontend   Up 2 minutes (healthy)   0.0.0.0:3000->8080/tcp, [::]:3000->8080/tcp
```

_Smoke test: liveness, readiness (checks the database), the frontend health endpoint and a real API call (inventory statistics from PostgreSQL)._

```console
$ curl -s localhost:8000/health; echo; curl -s localhost:8000/ready; echo; curl -s localhost:3000/healthz; echo; curl -s localhost:8000/api/items/stats
{"status":"OK"}
{"status":"READY"}
ok

{"total_items":10,"total_units":1175,"total_value":8020.3,"low_stock":3,"out_of_stock":2,"categories":4}
```

_The first items of the seeded inventory, and the same API reached **through the frontend nginx proxy** on port 3000._

```console
$ curl -s "localhost:8000/api/items?limit=3" | head -c 600; echo; echo ...; curl -s localhost:3000/api/items/stats
[{"id":4,"sku":"OF-2001","name":"A4 copier paper (500 sheets)","description":"","category":"Office","quantity":320,"reorder_level":100,"unit_price":4.25,"supplier":"PaperPlus","location":"B-07","created_at":"2026-10-18T14:35:19.429401Z","updated_at":"2026-10-18T14:35:19.429401Z","stock_status":"in_stock"},{"id":5,"sku":"OF-2002","name":"Ballpoint pens (box of 50)","description":"","category":"Office","quantity":12,"reorder_level":20,"unit_price":7.8,"supplier":"PaperPlus","location":"B-08","created_at":"2026-10-18T14:35:19.429401Z","updated_at":"2026-10-18T14:35:19.429401Z","stock_status":"low
...
{"total_items":10,"total_units":1175,"total_value":8020.3,"low_stock":3,"out_of_stock":2,"categories":4}
```

_The backend exposes Prometheus metrics at `/metrics` (request counts, latency, memory): this is what the monitoring section scrapes._

```console
$ curl -s localhost:8000/metrics | grep -E "^http_requests_total|^process_resident_memory_bytes|^http_request_duration_seconds_count" | head -n 6
process_resident_memory_bytes 8.7314432e+07
http_requests_total{handler="/api/items/stats",method="GET",status="2xx"} 2.0
http_requests_total{handler="/api/items",method="GET",status="2xx"} 1.0
http_request_duration_seconds_count{handler="/api/items/stats",method="GET"} 2.0
http_request_duration_seconds_count{handler="/api/items",method="GET"} 1.0
```

![StockPilot frontend](docs/screenshots/app-frontend.png)

![StockPilot API documentation (FastAPI /docs)](docs/screenshots/app-api-docs.png)

### Image security scan (the CI "container image scan" gate)
_Trivy scans the backend image for HIGH and CRITICAL vulnerabilities that already have a fix (`--ignore-unfixed`) and exits with code 1 if it finds any. Zero findings and exit code 0 means the security gate is open._

```console
$ OUT=$(docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --quiet --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --format json stockpilot-final-backend:latest 2>/dev/null); RC=$?; echo "image: stockpilot-final-backend:latest"; echo "scanned targets: $(echo "$OUT" | grep -c '"Target"')"; echo "HIGH/CRITICAL vulnerabilities that have a fix: $(echo "$OUT" | grep -c '"VulnerabilityID"')"; echo "trivy exit code: $RC  (0 = gate open, 1 = gate closed)"
image: stockpilot-final-backend:latest
scanned targets: 2
HIGH/CRITICAL vulnerabilities that have a fix: 0
trivy exit code: 0  (0 = gate open, 1 = gate closed)
```

_Trivy scans the frontend image for HIGH and CRITICAL vulnerabilities that already have a fix (`--ignore-unfixed`) and exits with code 1 if it finds any. Zero findings and exit code 0 means the security gate is open._

```console
$ OUT=$(docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --quiet --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --format json stockpilot-final-frontend:latest 2>/dev/null); RC=$?; echo "image: stockpilot-final-frontend:latest"; echo "scanned targets: $(echo "$OUT" | grep -c '"Target"')"; echo "HIGH/CRITICAL vulnerabilities that have a fix: $(echo "$OUT" | grep -c '"VulnerabilityID"')"; echo "trivy exit code: $RC  (0 = gate open, 1 = gate closed)"
image: stockpilot-final-frontend:latest
scanned targets: 1
HIGH/CRITICAL vulnerabilities that have a fix: 0
trivy exit code: 0  (0 = gate open, 1 = gate closed)
```

_Final image sizes (the frontend is a multi-stage build: Node builds the static files, nginx serves them)._

```console
$ docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | grep -E 'REPOSITORY|stockpilot-final'
REPOSITORY                    TAG         SIZE
stockpilot-final-frontend     latest      95.3MB
stockpilot-final-backend      latest      302MB
```

_Both images run as a non-root numeric user._

```console
$ docker inspect -f '{{.Config.User}}' stockpilot-final-backend:latest stockpilot-final-frontend:latest
10001
101
```

## 6. Kubernetes deployment

### Make the images available to the cluster

Minikube has its own image store, so the two images built by Docker Compose are tagged with the names used in `values-dev.yaml` and loaded into the cluster (no registry needed for the local run).

_Tag and load both images into Minikube._

```console
$ docker tag stockpilot-final-backend:latest stockpilot-backend:local && docker tag stockpilot-final-frontend:latest stockpilot-frontend:local && minikube image load stockpilot-backend:local && minikube image load stockpilot-frontend:local && minikube image ls | grep -E "stockpilot-(backend|frontend):local"
docker.io/library/stockpilot-frontend:local
docker.io/library/stockpilot-backend:local
```

### Kubernetes objects: plain manifests and Helm

All Kubernetes objects of the application are defined once, as templates, in the Helm chart. I check them first **without installing**:

_The namespace manifest (plain Kubernetes YAML)._

```console
$ kubectl apply -f kubernetes/namespace.yaml && cat kubernetes/namespace.yaml
namespace/stockpilot created
apiVersion: v1
kind: Namespace
metadata:
  name: stockpilot
  labels:
    app.kubernetes.io/part-of: stockpilot
    # Pod Security Admission: reject pods that run as root or escalate privileges
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/warn: restricted
```

_Static check of the chart._

```console
$ helm lint helm/stockpilot
==> Linting helm/stockpilot
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

_Render the chart locally: these are the Kubernetes kinds it produces (Deployments, StatefulSet, Services, ConfigMap, Secret, Ingress, HPA, PodDisruptionBudgets, a test Pod)._

```console
$ helm template stockpilot helm/stockpilot -n stockpilot -f helm/stockpilot/values-dev.yaml | grep -E "^kind:" | sort | uniq -c
      1 kind: ConfigMap
      2 kind: Deployment
      1 kind: HorizontalPodAutoscaler
      1 kind: Ingress
      1 kind: Pod
      2 kind: PodDisruptionBudget
      1 kind: Secret
      3 kind: Service
      1 kind: StatefulSet
```

_The rendered manifests validated by the real API server (`--dry-run=server`): every object is accepted without creating anything._

```console
$ helm template stockpilot helm/stockpilot -n stockpilot -f helm/stockpilot/values-dev.yaml | kubectl apply --dry-run=server -f - 2>&1 | head -n 20
poddisruptionbudget.policy/stockpilot-backend created (server dry run)
poddisruptionbudget.policy/stockpilot-frontend created (server dry run)
secret/stockpilot-db created (server dry run)
configmap/stockpilot-frontend-config created (server dry run)
service/stockpilot-backend created (server dry run)
service/stockpilot-frontend created (server dry run)
service/stockpilot-postgres created (server dry run)
deployment.apps/stockpilot-backend created (server dry run)
deployment.apps/stockpilot-frontend created (server dry run)
horizontalpodautoscaler.autoscaling/stockpilot-backend created (server dry run)
statefulset.apps/stockpilot-postgres created (server dry run)
ingress.networking.k8s.io/stockpilot created (server dry run)
pod/stockpilot-test created (server dry run)
```

## 7. Helm deployment

### Install with Helm

_**Helm deployment:** one command creates the whole application. `--wait` returns when everything is ready. The NOTES at the end are printed by the chart._

```console
$ helm install stockpilot helm/stockpilot -n stockpilot -f helm/stockpilot/values-dev.yaml --wait --timeout 8m
NAME: stockpilot
LAST DEPLOYED: Sun Oct 18 20:36:18 2026
NAMESPACE: stockpilot
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
NOTES:
StockPilot 1.0.0 was deployed as release "stockpilot" in namespace "stockpilot".

See what is running:
  kubectl get pods,svc,hpa -n stockpilot

Smoke test (backend + database + frontend proxy):
  helm test stockpilot -n stockpilot

The Ingress routes "/" to the frontend and "/api" to the backend:
  kubectl get ingress -n stockpilot
  Open http://stockpilot.local  (add the Ingress address to your hosts file if needed)
```

_The release, its status and the values I supplied._

```console
$ helm list -n stockpilot; helm status stockpilot -n stockpilot | head -n 8; helm get values stockpilot -n stockpilot
NAME      	NAMESPACE 	REVISION	UPDATED                              	STATUS  	CHART           	APP VERSION
stockpilot	stockpilot	1       	2026-10-18 20:36:18.8135831 +0530 IST	deployed	stockpilot-1.0.0	1.0.0      
NAME: stockpilot
LAST DEPLOYED: Sun Oct 18 20:36:18 2026
NAMESPACE: stockpilot
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
RESOURCES:
==> v1/PodDisruptionBudget
USER-SUPPLIED VALUES:
backend:
  image:
    pullPolicy: IfNotPresent
    repository: stockpilot-backend
    tag: local
  replicaCount: 2
frontend:
  image:
    pullPolicy: IfNotPresent
    repository: stockpilot-frontend
    tag: local
ingress:
  className: nginx
  enabled: true
  host: stockpilot.local
postgres:
  persistence:
    size: 1Gi
```

_**Everything the release created:** Deployments (2 backend + 2 frontend Pods), the PostgreSQL StatefulSet with its PVC, Services, the Ingress, the HPA, the ConfigMap and the PodDisruptionBudgets._

```console
$ kubectl get deploy,statefulset,pods,svc,ingress,hpa,pvc,configmap,pdb -n stockpilot
NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/stockpilot-backend    2/2     2            2           60s
deployment.apps/stockpilot-frontend   2/2     2            2           60s

NAME                                   READY   AGE
statefulset.apps/stockpilot-postgres   1/1     60s

NAME                                       READY   STATUS    RESTARTS   AGE
pod/stockpilot-backend-7fbd656b85-44l2r    1/1     Running   0          60s
pod/stockpilot-backend-7fbd656b85-wdpxr    1/1     Running   0          60s
pod/stockpilot-frontend-6699c58bd7-2zr4b   1/1     Running   0          60s
pod/stockpilot-frontend-6699c58bd7-ckdp2   1/1     Running   0          60s
pod/stockpilot-postgres-0                  1/1     Running   0          60s

NAME                          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/stockpilot-backend    ClusterIP   10.99.160.70   <none>        8000/TCP   60s
service/stockpilot-frontend   ClusterIP   10.102.9.41    <none>        80/TCP     60s
service/stockpilot-postgres   ClusterIP   None           <none>        5432/TCP   60s

NAME                                   CLASS   HOSTS              ADDRESS        PORTS   AGE
ingress.networking.k8s.io/stockpilot   nginx   stockpilot.local   192.168.49.2   80      60s

NAME                                                     REFERENCE                       TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/stockpilot-backend   Deployment/stockpilot-backend   cpu: <unknown>/50%   2         6         2          60s

NAME                                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/data-stockpilot-postgres-0   Bound    pvc-4d467740-2fc5-40e1-a45d-be069a253407   1Gi        RWO            standard       <unset>                 60s

NAME                                   DATA   AGE
configmap/kube-root-ca.crt             1      63s
configmap/stockpilot-frontend-config   1      60s

NAME                                             MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
poddisruptionbudget.policy/stockpilot-backend    1               N/A               1                     60s
poddisruptionbudget.policy/stockpilot-frontend   1               N/A               1                     60s
```

_The Secret exists (database credentials generated at install time; nothing secret is in Git). I list only its name, never the values._

```console
$ kubectl get secret -n stockpilot
NAME                               TYPE                 DATA   AGE
sh.helm.release.v1.stockpilot.v1   helm.sh/release.v1   1      60s
stockpilot-db                      Opaque               2      60s
```

### Probes, storage and resources as Kubernetes sees them

_**Probes and resources:** liveness, readiness and (for the backend) startup probes, and CPU/memory requests and limits, are set on every workload._

```console
$ for d in stockpilot-backend stockpilot-frontend; do echo "== $d"; kubectl describe deploy $d -n stockpilot | grep -E "Liveness|Readiness|Startup|Limits|Requests|cpu|memory" | head -n 8; done; echo "== postgres"; kubectl describe sts stockpilot-postgres -n stockpilot | grep -E "Liveness|Readiness"
== stockpilot-backend
    Requests:
      cpu:        10m
      memory:     16Mi
    Limits:
      cpu:     500m
      memory:  384Mi
    Requests:
      cpu:      100m
== stockpilot-frontend
    Limits:
      cpu:     200m
      memory:  128Mi
    Requests:
      cpu:      25m
      memory:   32Mi
    Liveness:   http-get http://:http/healthz delay=0s timeout=1s period=10s successThreshold=1 failureThreshold=3
    Readiness:  http-get http://:http/healthz delay=0s timeout=1s period=5s successThreshold=1 failureThreshold=3
== postgres
    Liveness:   exec [sh -c pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"] delay=20s timeout=3s period=10s successThreshold=1 failureThreshold=3
    Readiness:  exec [sh -c pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"] delay=0s timeout=3s period=5s successThreshold=1 failureThreshold=3
```

_**Storage:** the PostgreSQL data lives on a PersistentVolumeClaim, provisioned dynamically by the default StorageClass._

```console
$ kubectl get pvc,pv -n stockpilot; kubectl get storageclass
NAME                                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/data-stockpilot-postgres-0   Bound    pvc-4d467740-2fc5-40e1-a45d-be069a253407   1Gi        RWO            standard       <unset>                 61s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/pvc-4d467740-2fc5-40e1-a45d-be069a253407   1Gi        RWO            Delete           Bound    stockpilot/data-stockpilot-postgres-0   standard       <unset>                          61s
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate           false                  125m
```

_**ConfigMap:** the frontend gets the backend URL (non-secret configuration) from a ConfigMap._

```console
$ kubectl get cm stockpilot-frontend-config -n stockpilot -o jsonpath="{.data}"; echo
{"BACKEND_URL":"http://stockpilot-backend.stockpilot.svc.cluster.local:8000"}
```

_**Secret:** the keys it holds (values hidden here on purpose)._

```console
$ kubectl get secret -n stockpilot -l app.kubernetes.io/instance=stockpilot -o jsonpath="{.items[0].data}" | sed "s/:\"[^\"]*\"/:\"<hidden>\"/g"; echo
{"database-url":"<hidden>","postgres-password":"<hidden>"}
```

### Storage really persists

I add an item through the API, delete the database Pod, and read the item back from the new Pod.

_Create an item (through a port-forward to the backend Service)._

```console
$ kubectl port-forward -n stockpilot svc/stockpilot-backend 8001:8000 > /tmp/pf-be.txt 2>&1 & sleep 4; curl -s -X POST localhost:8001/api/items -H "Content-Type: application/json" -d "{\"sku\":\"PERSIST-1\",\"name\":\"Persistence test item\",\"category\":\"Test\",\"quantity\":7,\"reorder_level\":2,\"unit_price\":1.5}"; echo; kill %1
{"id":11,"sku":"PERSIST-1","name":"Persistence test item","description":"","category":"Test","quantity":7,"reorder_level":2,"unit_price":1.5,"supplier":null,"location":null,"created_at":"2026-10-18T15:07:26.194928Z","updated_at":"2026-10-18T15:07:26.194928Z","stock_status":"in_stock"}
```

_Delete the database Pod: the StatefulSet recreates it and re-attaches the same volume._

```console
$ kubectl delete pod stockpilot-postgres-0 -n stockpilot && kubectl wait --for=condition=Ready pod/stockpilot-postgres-0 -n stockpilot --timeout=240s && kubectl get pod stockpilot-postgres-0 -n stockpilot
pod "stockpilot-postgres-0" deleted from stockpilot namespace
pod/stockpilot-postgres-0 condition met
NAME                    READY   STATUS    RESTARTS   AGE
stockpilot-postgres-0   1/1     Running   0          2s
```

_**The item survived** the database restart._

```console
$ sleep 8; kubectl port-forward -n stockpilot svc/stockpilot-backend 8001:8000 > /tmp/pf-be.txt 2>&1 & sleep 4; curl -s "localhost:8001/api/items?q=PERSIST" | head -c 400; echo; kill %1
[{"id":11,"sku":"PERSIST-1","name":"Persistence test item","description":"","category":"Test","quantity":7,"reorder_level":2,"unit_price":1.5,"supplier":null,"location":null,"created_at":"2026-10-18T15:07:26.194928Z","updated_at":"2026-10-18T15:07:26.194928Z","stock_status":"in_stock"}]
```

### Ingress: reach the application through one entry point

_The Ingress sends `/api`, `/docs` and `/openapi.json` to the backend Service and everything else to the frontend Service._

```console
$ kubectl get ingress -n stockpilot; kubectl describe ingress stockpilot -n stockpilot | sed -n "/^Rules:/,/^Annotations:/p"
NAME         CLASS   HOSTS              ADDRESS        PORTS   AGE
stockpilot   nginx   stockpilot.local   192.168.49.2   80      83s
Rules:
  Host              Path  Backends
  ----              ----  --------
  stockpilot.local  
                    /api            stockpilot-backend:http (10.244.0.39:8000,10.244.0.40:8000)
                    /docs           stockpilot-backend:http (10.244.0.39:8000,10.244.0.40:8000)
                    /openapi.json   stockpilot-backend:http (10.244.0.39:8000,10.244.0.40:8000)
                    /               stockpilot-frontend:http (10.244.0.38:8080,10.244.0.41:8080)
Annotations:        meta.helm.sh/release-name: stockpilot
```

_Through the Ingress controller with the host name `stockpilot.local`: the API answers, the React page is served and the API docs are reachable._

```console
$ kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 > /tmp/pf-ing.txt 2>&1 & sleep 4; curl -s -H "Host: stockpilot.local" localhost:8080/api/items/stats; echo; curl -s -H "Host: stockpilot.local" localhost:8080/ | grep -o "<title>[^<]*</title>"; curl -s -o /dev/null -w "docs: HTTP %{http_code}\n" -H "Host: stockpilot.local" localhost:8080/docs; kill %1
{"total_items":11,"total_units":1182,"total_value":8030.8,"low_stock":3,"out_of_stock":2,"categories":5}
<title>StockPilot</title>
docs: HTTP 200
```

_I opened <http://stockpilot.local:8080> in a browser (with `stockpilot.local` pointing at the port-forwarded Ingress controller, as above): the screenshot below is the application served through the Ingress._

![StockPilot running on Kubernetes, opened through the Ingress](docs/screenshots/k8s-ingress-frontend.png)

### `helm test`

_The chart ships a test Pod that calls the backend Service and the frontend `/api` proxy._

```console
$ helm test stockpilot -n stockpilot
NAME: stockpilot
LAST DEPLOYED: Sun Oct 18 20:36:18 2026
NAMESPACE: stockpilot
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE:     stockpilot-test
Last Started:   Sun Oct 18 20:37:55 2026
Last Completed: Sun Oct 18 20:37:59 2026
Phase:          Succeeded
```

### Autoscaling (HPA) under load

_The HPA (2 to 6 backend replicas at 50% CPU) and the idle CPU of the Pods._

```console
$ kubectl get hpa -n stockpilot; kubectl top pods -n stockpilot
NAME                 REFERENCE                       TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
stockpilot-backend   Deployment/stockpilot-backend   cpu: <unknown>/50%   2         6         2          100s
NAME                                   CPU(cores)   MEMORY(bytes)   
stockpilot-backend-7fbd656b85-44l2r    125m         62Mi            
stockpilot-backend-7fbd656b85-wdpxr    163m         62Mi            
stockpilot-frontend-6699c58bd7-2zr4b   1m           10Mi            
stockpilot-frontend-6699c58bd7-ckdp2   1m           10Mi            
stockpilot-postgres-0                  48m          21Mi            
```

_The project script `scripts/load-test.sh` starts a load generator Pod with 30 request loops against the backend. Every 20 seconds the HPA line: TARGETS (CPU against the request) and REPLICAS._

```console
$ bash scripts/load-test.sh stockpilot 30 150 > /tmp/load-test.txt 2>&1 & sleep 15; for i in 1 2 3 4 5 6 7 8; do echo "[$(date +%T)] $(kubectl get hpa -n stockpilot --no-headers)"; sleep 20; done; wait; tail -n 3 /tmp/load-test.txt
[20:38:15] stockpilot-backend   Deployment/stockpilot-backend   cpu: <unknown>/50%   2     6     2     116s
[20:38:35] stockpilot-backend   Deployment/stockpilot-backend   cpu: <unknown>/50%   2     6     2     2m17s
[20:38:56] stockpilot-backend   Deployment/stockpilot-backend   cpu: <unknown>/50%   2     6     2     2m37s
[20:39:16] stockpilot-backend   Deployment/stockpilot-backend   cpu: 218%/50%   2     6     2     2m58s
[20:39:37] stockpilot-backend   Deployment/stockpilot-backend   cpu: 218%/50%   2     6     4     3m18s
[20:39:57] stockpilot-backend   Deployment/stockpilot-backend   cpu: 218%/50%   2     6     6     3m39s
[20:40:18] stockpilot-backend   Deployment/stockpilot-backend   cpu: 373%/50%   2     6     6     3m59s
[20:40:38] stockpilot-backend   Deployment/stockpilot-backend   cpu: 373%/50%   2     6     6     4m20s
Load finished. The HPA scales back down after its 2 minute stabilisation window.

Stopping the load generator...
```

_The backend Pods that exist now and the autoscaler events._

```console
$ kubectl get pods -n stockpilot -l app.kubernetes.io/component=backend; kubectl describe hpa -n stockpilot | sed -n "/^Events:/,\$p" | grep -v FailedGet | grep -v FailedCompute | cut -c1-200
NAME                                  READY   STATUS    RESTARTS   AGE
stockpilot-backend-7fbd656b85-44l2r   1/1     Running   0          4m40s
stockpilot-backend-7fbd656b85-8pp5t   1/1     Running   0          115s
stockpilot-backend-7fbd656b85-9q8hb   1/1     Running   0          85s
stockpilot-backend-7fbd656b85-j7r5j   1/1     Running   0          85s
stockpilot-backend-7fbd656b85-j8sxr   1/1     Running   0          115s
stockpilot-backend-7fbd656b85-wdpxr   1/1     Running   0          4m40s
Events:
  Type     Reason                        Age                    From                       Message
  ----     ------                        ----                   ----                       -------
  Normal   SuccessfulRescale             116s                   horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             86s                    horizontal-pod-autoscaler  New size: 6; reason: cpu resource utilization (percentage of request) above target
```

_The load generator has ended. The chart tunes the HPA behaviour (`templates/hpa.yaml`): scale-up adds at most 2 Pods per 30 seconds (the 2 -> 4 -> 6 steps above) and the scale-down waits a 2 minute stabilisation window; the Kubernetes default of 5 minutes was shown in Session 13._

```console
$ kubectl get hpa -n stockpilot; kubectl get pods -n stockpilot | grep -c load-generator || true
NAME                 REFERENCE                       TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
stockpilot-backend   Deployment/stockpilot-backend   cpu: 202%/50%   2         6         6          5m1s
1
```

## 8. Terraform infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars    # optional, the defaults work
terraform init
terraform plan
terraform apply                                  # about 15-20 minutes
aws eks update-kubeconfig --region ap-south-1 --name stockpilot-eks
```

Creates a VPC with public and private subnets in two availability zones, an internet gateway and a NAT gateway, an EKS cluster and a managed node group (3 x `t3.medium`), plus the EBS CSI add-on for the database volume. Full details, the cost estimate and the correct teardown order are in [`terraform/README.md`](terraform/README.md). **EKS and the NAT gateway cost money while they exist, so the stack must be destroyed when finished.**

### Terraform: format, initialise and validate

The code in [`terraform/`](terraform/) provisions an AWS VPC with two public subnets and an EKS cluster with a managed node group. **I did not apply it** (that needs a real AWS account and costs money). What can be checked without AWS credentials was checked in a Terraform container, on a temporary copy; the AWS calls use dummy environment values, so nothing can reach a real account.

_The Terraform files and what they declare._

```console
$ ls terraform; echo; grep -E '^(resource|module|data|provider|variable|output) ' terraform/*.tf | sed 's#terraform/##' | head -n 40
README.md
main.tf
outputs.tf
terraform.tfvars.example
variables.tf
versions.tf

main.tf:data "aws_availability_zones" "available" {
main.tf:module "vpc" {
main.tf:module "eks" {
outputs.tf:output "region" {
outputs.tf:output "vpc_id" {
outputs.tf:output "public_subnet_ids" {
outputs.tf:output "private_subnet_ids" {
outputs.tf:output "cluster_name" {
outputs.tf:output "cluster_endpoint" {
outputs.tf:output "configure_kubectl" {
variables.tf:variable "region" {
variables.tf:variable "cluster_name" {
variables.tf:variable "kubernetes_version" {
variables.tf:variable "vpc_cidr" {
variables.tf:variable "az_count" {
variables.tf:variable "node_instance_types" {
variables.tf:variable "node_min_size" {
variables.tf:variable "node_desired_size" {
variables.tf:variable "node_max_size" {
variables.tf:variable "single_nat_gateway" {
variables.tf:variable "endpoint_public_access" {
versions.tf:provider "aws" {
```

_Terraform version used._

```console
$ docker run --rm -e AWS_ACCESS_KEY_ID=dummy -e AWS_SECRET_ACCESS_KEY=dummy -e AWS_EC2_METADATA_DISABLED=true -v "$PWD/terraform:/work" -w /work hashicorp/terraform:latest version
Terraform v1.16.5
on linux_amd64
+ provider registry.terraform.io/hashicorp/aws v6.68.0
+ provider registry.terraform.io/hashicorp/cloudinit v2.4.1
+ provider registry.terraform.io/hashicorp/null v3.3.2
+ provider registry.terraform.io/hashicorp/time v0.14.2
+ provider registry.terraform.io/hashicorp/tls v4.4.1

Your version of Terraform is out of date! The latest version
is 1.16.6. You can update by downloading from https://developer.hashicorp.com/terraform/install
```

_**`terraform fmt -check`**: all files are canonically formatted (exit code 0, no diff)._

```console
$ docker run --rm -e AWS_ACCESS_KEY_ID=dummy -e AWS_SECRET_ACCESS_KEY=dummy -e AWS_EC2_METADATA_DISABLED=true -v "$PWD/terraform:/work" -w /work hashicorp/terraform:latest fmt -no-color -check -recursive -diff; echo "fmt exit code: $?"
fmt exit code: 0
```

_**`terraform init`**: downloads the AWS provider and the VPC and EKS modules (`-backend=false` because no remote state is needed for a syntax check)._

```console
$ docker run --rm -e AWS_ACCESS_KEY_ID=dummy -e AWS_SECRET_ACCESS_KEY=dummy -e AWS_EC2_METADATA_DISABLED=true -v "$PWD/terraform:/work" -w /work hashicorp/terraform:latest init -no-color -backend=false -input=false 2>&1 | tail -n 16
- Installing hashicorp/aws v6.68.0...
- Installed hashicorp/aws v6.68.0 (signed by HashiCorp)
- Installing hashicorp/tls v4.4.1...
- Installed hashicorp/tls v4.4.1 (signed by HashiCorp)
- Installing hashicorp/time v0.14.2...
- Installed hashicorp/time v0.14.2 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

_**`terraform validate`**: the configuration is valid (syntax, references, types)._

```console
$ docker run --rm -e AWS_ACCESS_KEY_ID=dummy -e AWS_SECRET_ACCESS_KEY=dummy -e AWS_EC2_METADATA_DISABLED=true -v "$PWD/terraform:/work" -w /work hashicorp/terraform:latest validate -no-color
Success! The configuration is valid.
```

**What was not run:** `terraform plan`, `apply` and `destroy` against AWS. `plan` needs real credentials because the EKS module reads data sources from AWS (availability zones, the node image). See [`terraform/README.md`](terraform/README.md) for the exact commands, the expected cost and the reminder to run `terraform destroy` afterwards. Terraform with a local emulator (real `apply` and `destroy`) is demonstrated in [Session 18](../../session18-terraform-iac) and [Session 19](../../session19-cloud-terraform).

## 9. CI/CD pipeline

[`.github/workflows/ci-cd.yml`](.github/workflows/ci-cd.yml) runs on every push and pull request to `main`:

```text
test (pytest + frontend build)   validate-infra (helm, terraform)   secret-scan (gitleaks, full history)
      \                                |                                 /
       build-scan-push  (backend, frontend in parallel)
          1. docker build
          2. Trivy scan  -> fails the job on HIGH/CRITICAL
          3. docker push -> ghcr.io/<owner>/stockpilot-{backend,frontend}:<git sha>   (push to main only)
                 |
              deploy (helm upgrade --install on EKS; optional)
```

- **Quality gates:** a failing test, a committed secret or a broken chart stops the pipeline before any image is built; a vulnerable image is never pushed.
- **Tags are the commit SHA**, never `latest`: commit A produces image A, so what runs in the cluster is traceable to source.
- **Pushing needs no secrets:** the workflow uses the built-in `GITHUB_TOKEN`.
- **Deploy is opt-in:** the `deploy` job is skipped until the repository variable `DEPLOY_ENABLED` is `true` (it needs AWS credentials as GitHub secrets, which never live in Git).
- **Paths:** in this folder the workflow uses the final-project layout (`application/`, `docker/` and so on). The workflow validates with `actionlint` (no findings).

**Real execution on GitHub.** This pipeline ran on GitHub (the same workflow, in my repository <https://github.com/Yash-1706/devops-assgn>): 4 successful runs, the latest with all jobs green (tests, secret scan, infrastructure validation, both image builds, Trivy, push to GHCR) and the deploy job skipped by design. The run page, the list of runs and the published packages are shown, with the real job data, in [Session 16](../../session16-github-actions/README.md#pipeline-execution-on-github-real-data):

![GitHub Actions run of the CI/CD pipeline](../../session16-github-actions/screenshots/actions-run-38807406432.png)

## 10. DevSecOps implementation

The security checks form a **pipeline with a gate**: nothing is pushed unless every scan passes.

| Stage | Tool | Where it runs | Configuration |
|---|---|---|---|
| SAST (static analysis of my code) | Semgrep | [`devsecops.yml`](.github/workflows/devsecops.yml) job `sast` | [`security/semgrep-rules.yml`](security/semgrep-rules.yml) |
| SCA (known vulnerable dependencies) | pip-audit (Python), npm audit (frontend) | job `sca` | `requirements*.txt`, `package-lock.json` |
| Secret scanning | gitleaks (whole Git history) | `ci-cd.yml` (ran on GitHub) and `devsecops.yml` | [`security/.gitleaks.toml`](security/.gitleaks.toml) |
| Container image scanning | Trivy (HIGH/CRITICAL, fixable only) | `ci-cd.yml` (ran on GitHub) and `devsecops.yml` | [`security/trivy.yaml`](security/trivy.yaml), [`.trivyignore`](security/.trivyignore) |
| Security gate | a job that needs all of the above and fails if any failed | `devsecops.yml` job `security-gate` | branch protection can require it |

What I ran for this project: the Trivy gate on both final images (section 5: **0 fixable HIGH/CRITICAL findings, exit code 0**), and the complete set of tools, including a demonstration of the gate *closing* on a deliberately vulnerable image and the secret scanner catching a fake key, are documented with their real output in [Session 17](../../session17-devsecops/README.md). The same scans can be run on a laptop with [`security/run-security-scans.sh`](security/run-security-scans.sh) (Docker only). Earlier findings and how they were fixed are in [`security/trivy-findings.md`](security/trivy-findings.md); the policy is in [`security/SECURITY.md`](security/SECURITY.md).

Other hardening in the workloads: non-root users, `readOnlyRootFilesystem`, all Linux capabilities dropped, `seccompProfile: RuntimeDefault`, resource requests and limits on every container, no secret in Git, and the database password generated inside the cluster.

## 11. Monitoring

### Start Prometheus and Grafana next to the running stack

_Prometheus (port 9091) and Grafana (port 3001) join the application network so Prometheus can reach `backend:8000`._

```console
$ cd monitoring/local && docker compose -p stockpilot-mon up -d 2>&1 | tail -n 6
 Container stockpilot-mon-grafana Creating 
 Container stockpilot-mon-grafana Created 
 Container stockpilot-mon-prometheus Starting 
 Container stockpilot-mon-prometheus Started 
 Container stockpilot-mon-grafana Starting 
 Container stockpilot-mon-grafana Started 
```

_Both targets are up: Prometheus itself and the StockPilot backend (value 1)._

```console
$ curl -s localhost:9091/api/v1/query --data-urlencode 'query=up' | grep -o '"job":"[a-z-]*"\|"value":\[[^]]*\]' | paste - -
"job":"prometheus"	"value":[1792334780.590,"1"]
"job":"stockpilot-backend"	"value":[1792334780.590,"1"]
```

_Send real traffic through the frontend proxy and directly to the API._

```console
$ for i in $(seq 1 60); do curl -s -o /dev/null localhost:3000/api/items; curl -s -o /dev/null localhost:3000/api/items/stats; curl -s -o /dev/null localhost:3000/api/movements; done; for i in $(seq 1 15); do curl -s -o /dev/null localhost:8000/api/items/99999; done; echo "sent 195 requests (15 of them are 404s for a missing item)"
sent 195 requests (15 of them are 404s for a missing item)
```

_The request counters by endpoint and status class, as Prometheus stores them._

```console
$ curl -s localhost:9091/api/v1/query --data-urlencode 'query=sum by (handler, status) (http_requests_total)' | grep -o '"handler":"[^"]*"\|"status":"[0-9x]*"\|"value":\[[^]]*\]' | paste - - -
"handler":"/api/items"	"status":"2xx"	"value":[1792334819.155,"60"]
"handler":"/api/items/stats"	"status":"2xx"	"value":[1792334819.155,"60"]
"handler":"/api/movements"	"status":"2xx"	"value":[1792334819.155,"60"]
"handler":"/api/items/{item_id}"	"status":"4xx"	"value":[1792334819.155,"15"]
```

_95th percentile latency in seconds (second number)._

```console
$ curl -s localhost:9091/api/v1/query --data-urlencode 'query=histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[1m])))' | grep -o '"value":\[[^]]*\]'
"value":[1792334819.437,"0.09499999999999999"]
```

![Grafana dashboard for the StockPilot backend](docs/screenshots/grafana-stockpilot.png)

![Prometheus targets](docs/screenshots/prometheus-stockpilot-targets.png)

### An alert on the real application: the backend goes down

_Stopping the backend makes the scrape fail (`up` = 0) and the **BackendDown** alert fires after its 15 s `for:` period._

```console
$ docker stop stockpilot-final-backend-1 && sleep 30 && curl -s localhost:9091/api/v1/alerts | grep -o '"alertname":"[A-Za-z]*"\|"state":"[a-z]*"' | paste - -
stockpilot-final-backend-1
"alertname":"BackendDown"	"state":"firing"
```

_Start the backend again: it becomes ready, the target is up and the alert resolves._

```console
$ docker start stockpilot-final-backend-1 && sleep 25 && curl -s localhost:8000/ready; echo; sleep 10; curl -s localhost:9091/api/v1/alerts | grep -o "\"alertname\":\"[A-Za-z]*\"" ; echo "(no alert name above = nothing is firing)"
stockpilot-final-backend-1
{"status":"READY"}
(no alert name above = nothing is firing)
```

![BackendDown alert in Prometheus](docs/screenshots/prometheus-stockpilot-alert.png)

_Stop the monitoring stack (the application stack keeps running for the next steps)._

```console
$ cd monitoring/local && docker compose -p stockpilot-mon down -v 2>&1 | tail -n 4
 Container stockpilot-mon-prometheus Removing 
 Container stockpilot-mon-prometheus Removed 
 Network stockpilot-mon_default Removing 
 Network stockpilot-mon_default Removed 
```

On Kubernetes the same metrics are scraped through the chart's `ServiceMonitor` (enable it with `serviceMonitor.enabled=true`) by the Prometheus of `kube-prometheus-stack`; its values and a dashboard ConfigMap are in [`monitoring/`](monitoring) and are installed by [`scripts/install-cluster-addons.sh`](scripts/install-cluster-addons.sh). The full Prometheus stack was **not** installed in Minikube for this submission (the local Docker stack above was used instead); autoscaling used the metrics-server (section 7).

## 12. GitOps

The Argo CD `Application` in [`gitops/argocd-application.yaml`](gitops/argocd-application.yaml) points at the Helm chart in this repository (`helm/stockpilot` with `values-dev.yaml`). Argo CD renders the chart itself, so **the cluster is created from Git without running `helm install` by hand**. The demonstration below was run on my Minikube cluster with Argo CD installed (see [Session 20](../../session20-monitoring-observability-gitops/README.md#task-3-gitops)); it pulls the chart from my GitHub repository <https://github.com/Yash-1706/devops-git-assgn>.

Two rules in the Application are worth understanding (they are the lessons of this demo):

| Rule | Why |
|---|---|
| `ignoreDifferences` on the database **Secret** | the chart generates a random password at install time (no secret in Git). Argo CD renders with plain `helm template`, which cannot look up the existing value, so without this rule every sync would replace the password and break the database login |
| `ignoreDifferences` on Deployment **replicas** | the HPA owns the replica count, and Argo CD must not fight the autoscaler |

_The relevant part of the Application._

```console
$ cat gitops/argocd-application.yaml | sed -n "/^spec:/,/^  syncPolicy/p" | head -n 36
spec:
  project: default
  source:
    repoURL: https://github.com/Yash-1706/devops-git-assgn.git
    targetRevision: main
    path: session21-final-devops-project/final-devops-project/helm/stockpilot
    helm:
      valueFiles:
        - values-dev.yaml # local images (tag "local"); an EKS setup would use values-eks.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: stockpilot
  # Two things that must NOT be reconciled from Git:
  #  - the database Secret: the chart generates a random password at install time (nothing secret
  #    in Git), but a plain `helm template` (what Argo CD runs) cannot look up the existing value,
  #    so without this rule every sync would replace the password and break the database login;
  #  - the number of replicas: the HPA owns it, Argo CD must not fight the autoscaler.
  ignoreDifferences:
    - group: ""
      kind: Secret
      jsonPointers:
        - /data
        - /stringData
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas
  syncPolicy:
```

_The only `kubectl apply` for the whole application._

```console
$ kubectl apply -f gitops/argocd-application.yaml
application.argoproj.io/stockpilot created
```

_Argo CD syncs the chart and creates every object (SYNC STATUS `Synced`). HEALTH stays `Degraded` for a couple of minutes although the Pods come up; the cause is explained in [Why was the Application `Degraded` for a while?](#why-was-the-application-degraded-for-a-while) below. The `degraded: []` column is a filter I added to name the Degraded resources; it stays empty because this version of Argo CD does not keep the health of each resource in the `Application` object._

```console
$ for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14; do echo "[$(date +%T)] $(kubectl get application stockpilot -n argocd --no-headers 2>&1 | tr -s " ")  degraded: [$(kubectl get application stockpilot -n argocd -o jsonpath="{.status.resources[?(@.health.status==\"Degraded\")].kind}")]"; sleep 10; done
[21:15:34] stockpilot   degraded: []
[21:15:44] stockpilot Synced Degraded  degraded: []
[21:15:55] stockpilot Synced Degraded  degraded: []
[21:16:05] stockpilot Synced Degraded  degraded: []
[21:16:16] stockpilot Synced Degraded  degraded: []
[21:16:27] stockpilot Synced Degraded  degraded: []
[21:16:37] stockpilot Synced Degraded  degraded: []
[21:16:48] stockpilot Synced Degraded  degraded: []
[21:16:58] stockpilot Synced Degraded  degraded: []
[21:17:09] stockpilot Synced Degraded  degraded: []
[21:17:20] stockpilot Synced Degraded  degraded: []
[21:17:30] stockpilot Synced Degraded  degraded: []
[21:17:41] stockpilot Synced Degraded  degraded: []
[21:17:51] stockpilot Synced Degraded  degraded: []
```

_The whole application, created by Argo CD from the Helm chart in Git: Deployments, the database StatefulSet with its volume, Services, the Ingress, the HPA and the ConfigMap._

```console
$ kubectl get deploy,statefulset,pods,svc,ingress,hpa,pvc,configmap -n stockpilot
NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/stockpilot-backend    2/2     2            2           2m25s
deployment.apps/stockpilot-frontend   2/2     2            2           2m25s

NAME                                   READY   AGE
statefulset.apps/stockpilot-postgres   1/1     2m25s

NAME                                       READY   STATUS    RESTARTS   AGE
pod/stockpilot-backend-7fbd656b85-57s8r    1/1     Running   0          2m25s
pod/stockpilot-backend-7fbd656b85-8jnbq    1/1     Running   0          2m25s
pod/stockpilot-frontend-6699c58bd7-jk8b6   1/1     Running   0          2m25s
pod/stockpilot-frontend-6699c58bd7-snntr   1/1     Running   0          2m25s
pod/stockpilot-postgres-0                  1/1     Running   0          2m25s

NAME                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/stockpilot-backend    ClusterIP   10.102.244.140   <none>        8000/TCP   2m25s
service/stockpilot-frontend   ClusterIP   10.111.222.48    <none>        80/TCP     2m25s
service/stockpilot-postgres   ClusterIP   None             <none>        5432/TCP   2m25s

NAME                                   CLASS   HOSTS              ADDRESS        PORTS   AGE
ingress.networking.k8s.io/stockpilot   nginx   stockpilot.local   192.168.49.2   80      2m25s

NAME                                                     REFERENCE                       TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/stockpilot-backend   Deployment/stockpilot-backend   cpu: 3%/50%   2         6         2          2m25s

NAME                                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/data-stockpilot-postgres-0   Bound    pvc-25515000-2db2-489b-81c6-2d433a344625   1Gi        RWO            standard       <unset>                 2m25s

NAME                                   DATA   AGE
configmap/kube-root-ca.crt             1      2m26s
configmap/stockpilot-frontend-config   1      2m26s
```

_The application works through the Ingress: real data from the database and the frontend page._

```console
$ kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 > /tmp/pf-ing.txt 2>&1 & sleep 4; curl -s -H "Host: stockpilot.local" localhost:8080/api/items/stats; echo; curl -s -o /dev/null -w "frontend: HTTP %{http_code}\n" -H "Host: stockpilot.local" localhost:8080/; kill %1
{"total_items":10,"total_units":1175,"total_value":8020.3,"low_stock":3,"out_of_stock":2,"categories":4}
frontend: HTTP 200
```

### Self-healing on the real application: the Ingress fault comes back and is repaired by Argo CD

In the troubleshooting challenge I broke the Ingress by hand and had to fix it by hand. Under GitOps the same fault repairs itself:

_The wrong service name lasts only seconds: Argo CD notices the difference with Git and restores `stockpilot-backend`._

```console
$ kubectl patch ingress stockpilot -n stockpilot --type json -p "[{\"op\":\"replace\",\"path\":\"/spec/rules/0/http/paths/0/backend/service/name\",\"value\":\"stockpilot-backendd\"}]"; echo "right after the manual (wrong) change:"; kubectl describe ingress stockpilot -n stockpilot | grep -E "^  *\/api " | cut -c1-150; sleep 25; echo "25 seconds later:"; kubectl describe ingress stockpilot -n stockpilot | grep -E "^  *\/api " | cut -c1-150
ingress.networking.k8s.io/stockpilot patched
right after the manual (wrong) change:
                    /api            stockpilot-backendd:http (<error: services "stockpilot-backendd" not found>)
25 seconds later:
                    /api            stockpilot-backend:http (10.244.0.97:8000,10.244.0.98:8000)
```

### A change through Git: more memory for the backend

I raise the backend memory limit in `values-dev.yaml` (from the chart default of 384Mi to 512Mi), commit and push.

_**Edit, commit and push** the values file._

```console
$ sed -i '/^backend:/,/^frontend:/ s/^  image:/  resources:\n    limits:\n      memory: 512Mi\n  image:/' session21-final-devops-project/final-devops-project/helm/stockpilot/values-dev.yaml && git diff --stat -- session21-final-devops-project/final-devops-project/helm/stockpilot/values-dev.yaml && git diff -U1 -- session21-final-devops-project/final-devops-project/helm/stockpilot/values-dev.yaml | grep -E '^[+-] ' && git commit -q session21-final-devops-project/final-devops-project/helm/stockpilot/values-dev.yaml -m 'Raise backend memory limit to 512Mi (gitops demo)' && git push -q origin main && git log --oneline -n 2
 session21-final-devops-project/final-devops-project/helm/stockpilot/values-dev.yaml | 3 +++
 1 file changed, 3 insertions(+)
+  resources:
+    limits:
+      memory: 512Mi
6ffb787 Raise backend memory limit to 512Mi (gitops demo)
55fc6cc Add argo cd demo output (session 20)
```

_Argo CD picks up the commit and rolls the backend out with the new limit (384Mi to 512Mi), without any `helm` or `kubectl` command from me. The `Degraded` at the end is the autoscaler waiting for metrics of the new Pods (see below)._

```console
$ kubectl annotate application stockpilot -n argocd argocd.argoproj.io/refresh=hard --overwrite >/dev/null; for i in 1 2 3 4 5 6 7 8 9 10; do echo "[$(date +%T)] $(kubectl get deploy stockpilot-backend -n stockpilot -o jsonpath="limit={.spec.template.spec.containers[0].resources.limits.memory} ready={.status.readyReplicas}/{.spec.replicas}")  $(kubectl get application stockpilot -n argocd --no-headers | tr -s " " | cut -d" " -f2-3) degraded: [$(kubectl get application stockpilot -n argocd -o jsonpath="{.status.resources[?(@.health.status==\"Degraded\")].kind}")]"; sleep 8; done
[21:18:37] limit=384Mi ready=2/2  Synced Healthy degraded: []
[21:18:46] limit=512Mi ready=2/2  Synced Progressing degraded: []
[21:18:55] limit=512Mi ready=2/2  Synced Progressing degraded: []
[21:19:04] limit=512Mi ready=2/2  Synced Healthy degraded: []
[21:19:13] limit=512Mi ready=2/2  Synced Degraded degraded: []
[21:19:21] limit=512Mi ready=2/2  Synced Degraded degraded: []
[21:19:30] limit=512Mi ready=2/2  Synced Degraded degraded: []
[21:19:39] limit=512Mi ready=2/2  Synced Degraded degraded: []
[21:19:48] limit=512Mi ready=2/2  Synced Degraded degraded: []
[21:19:56] limit=512Mi ready=2/2  Synced Degraded degraded: []
```

_The new backend Pods are running; the synced revision is my commit._

```console
$ kubectl get pods -n stockpilot -l app.kubernetes.io/component=backend; kubectl get application stockpilot -n argocd -o jsonpath="synced revision: {.status.sync.revision}{\"\\n\"}"
NAME                                 READY   STATUS    RESTARTS   AGE
stockpilot-backend-997b87f69-5sgtx   1/1     Running   0          74s
stockpilot-backend-997b87f69-fpch8   1/1     Running   0          85s
synced revision: 6ffb787d9a3ccb62fbf6da58ed150edddaf198e4
```

### Roll back with `git revert`

_The rollback is a commit._

```console
$ git revert --no-edit HEAD >/dev/null && git push -q origin main && git log --oneline -n 3
3f33e52 Revert "Raise backend memory limit to 512Mi (gitops demo)"
6ffb787 Raise backend memory limit to 512Mi (gitops demo)
55fc6cc Add argo cd demo output (session 20)
```

_The cluster returns to the original limit (384Mi). The Application shows `Degraded` again for the same reason as before; the next step waits for it to turn `Healthy`._

```console
$ kubectl annotate application stockpilot -n argocd argocd.argoproj.io/refresh=hard --overwrite >/dev/null; for i in 1 2 3 4 5 6 7 8 9 10; do echo "[$(date +%T)] $(kubectl get deploy stockpilot-backend -n stockpilot -o jsonpath="limit={.spec.template.spec.containers[0].resources.limits.memory} ready={.status.readyReplicas}/{.spec.replicas}") $(kubectl get application stockpilot -n argocd --no-headers | tr -s " " | cut -d" " -f2-3) degraded: [$(kubectl get application stockpilot -n argocd -o jsonpath="{.status.resources[?(@.health.status==\"Degraded\")].kind}")]"; sleep 8; done
[21:20:10] limit=512Mi ready=2/2 Synced Degraded degraded: []
[21:20:19] limit=384Mi ready=2/2 Synced Degraded degraded: []
[21:20:28] limit=384Mi ready=2/2 Synced Degraded degraded: []
[21:20:36] limit=384Mi ready=2/2 Synced Degraded degraded: []
[21:20:45] limit=384Mi ready=2/2 Synced Degraded degraded: []
[21:20:54] limit=384Mi ready=2/2 Synced Degraded degraded: []
[21:21:03] limit=384Mi ready=2/2 Synced Degraded degraded: []
[21:21:12] limit=384Mi ready=2/2 Synced Degraded degraded: []
[21:21:21] limit=384Mi ready=2/2 Synced Degraded degraded: []
[21:21:29] limit=384Mi ready=2/2 Synced Degraded degraded: []
```

_Wait until the Application is `Synced` and `Healthy` again. The Application was `Degraded` after this rollout for the same reason as after the first sync (shown in the section after the cleanup)._

```console
$ for i in $(seq 1 24); do st=$(kubectl get application stockpilot -n argocd --no-headers | tr -s " " | cut -d" " -f2-3); echo "[$(date +%T)] $st"; [ "$st" = "Synced Healthy" ] && break; sleep 10; done; kubectl get hpa stockpilot-backend -n stockpilot
[21:21:39] Synced Degraded
[21:21:49] Synced Degraded
[21:21:59] Synced Healthy
NAME                 REFERENCE                       TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
stockpilot-backend   Deployment/stockpilot-backend   cpu: 3%/50%   2         6         2          6m22s
```

_Cleanup._

```console
$ kubectl delete application stockpilot -n argocd; kubectl delete namespace stockpilot --wait=true; kubectl get ns
application.argoproj.io "stockpilot" deleted from argocd namespace
namespace "stockpilot" deleted
NAME              STATUS   AGE
argocd            Active   20m
default           Active   170m
ingress-nginx     Active   109m
kube-node-lease   Active   170m
kube-public       Active   170m
kube-system       Active   170m
```

### Why was the Application `Degraded` for a while?

After every sync and after every backend rollout above, Argo CD showed `Synced` but **`Degraded`** for one to three minutes, although every Pod was `Running` and `Ready`. The last column in my polling loops was a filter meant to name the resources that were `Degraded`; it stays empty because this version of Argo CD does not keep the health of each resource inside the `Application` object. So I created the application once more from an empty cluster (no commits this time) and looked at the object I suspected: the HorizontalPodAutoscaler.

_Start again from an empty cluster._

```console
$ kubectl delete application stockpilot -n argocd; kubectl delete namespace stockpilot --wait=true; kubectl apply -f gitops/argocd-application.yaml
application.argoproj.io "stockpilot" deleted from argocd namespace
namespace "stockpilot" deleted
application.argoproj.io/stockpilot created
```

_One minute after the sync._

```console
$ sleep 60; kubectl get application stockpilot -n argocd --no-headers | tr -s " "; kubectl get pods -n stockpilot; kubectl get hpa -n stockpilot; kubectl describe hpa stockpilot-backend -n stockpilot | sed -n "/^Conditions:/,/^Events:/p" | cut -c1-210
stockpilot Synced Degraded
NAME                                   READY   STATUS    RESTARTS   AGE
stockpilot-backend-7fbd656b85-2wqqh    1/1     Running   0          56s
stockpilot-backend-7fbd656b85-gxjz6    1/1     Running   0          56s
stockpilot-frontend-6699c58bd7-65m54   1/1     Running   0          56s
stockpilot-frontend-6699c58bd7-t8sfs   1/1     Running   0          56s
stockpilot-postgres-0                  1/1     Running   0          55s
NAME                 REFERENCE                       TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
stockpilot-backend   Deployment/stockpilot-backend   cpu: <unknown>/50%   2         6         2          56s
Conditions:
  Type           Status  Reason                   Message
  ----           ------  ------                   -------
  AbleToScale    True    SucceededGetScale        the HPA controller was able to get the target's current scale
  ScalingActive  False   FailedGetResourceMetric  the HPA was unable to compute the replica count: failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metric
Events:
```

_Watching the Application and the HPA together._

```console
$ for i in $(seq 1 18); do h=$(kubectl get application stockpilot -n argocd --no-headers | tr -s " " | cut -d" " -f2-3); echo "[$(date +%T)] app: $h | hpa target: $(kubectl get hpa stockpilot-backend -n stockpilot --no-headers 2>/dev/null | tr -s " " | cut -d" " -f3-4) | ScalingActive: $(kubectl get hpa stockpilot-backend -n stockpilot -o jsonpath="{.status.conditions[?(@.type==\"ScalingActive\")].status}" 2>/dev/null)"; [ "$h" = "Synced Healthy" ] && break; sleep 10; done
[21:26:48] app: Synced Degraded | hpa target: cpu: <unknown>/50% | ScalingActive: False
[21:26:59] app: Synced Degraded | hpa target: cpu: <unknown>/50% | ScalingActive: False
[21:27:10] app: Synced Degraded | hpa target: cpu: <unknown>/50% | ScalingActive: False
[21:27:21] app: Synced Degraded | hpa target: cpu: <unknown>/50% | ScalingActive: False
[21:27:32] app: Synced Degraded | hpa target: cpu: <unknown>/50% | ScalingActive: False
[21:27:43] app: Synced Degraded | hpa target: cpu: <unknown>/50% | ScalingActive: False
[21:27:54] app: Synced Healthy | hpa target: cpu: 3%/50% | ScalingActive: True
```

_Cleanup._

```console
$ kubectl delete application stockpilot -n argocd; kubectl delete namespace stockpilot --wait=true; kubectl get ns
application.argoproj.io "stockpilot" deleted from argocd namespace
namespace "stockpilot" deleted
NAME              STATUS   AGE
argocd            Active   26m
default           Active   176m
ingress-nginx     Active   115m
kube-node-lease   Active   176m
kube-public       Active   176m
kube-system       Active   176m
```

**What this shows:** the Pods were never unhealthy. While the HPA could not read any CPU metric (`TARGETS` is `<unknown>`, condition `ScalingActive` is `False` with reason `FailedGetResourceMetric`), Argo CD reported the whole Application as `Degraded`. In every observation the Application turned `Healthy` in the same ten-second window in which the HPA got its first CPU value (`3%/50%`, `ScalingActive` `True`). This happens after the first sync and after every backend rollout, because metrics-server needs some time to report brand-new Pods. It needs no fix, but it is worth knowing: **`Degraded` in Argo CD is not always a broken application**, and the Pods, events and the HPA conditions are the first things to read.

## 13. Troubleshooting

Two parts: the **troubleshooting lab** (two deliberately broken manifests kept in [`kubernetes/troubleshooting/`](kubernetes/troubleshooting): a Deployment with a bad image and a Service whose selector matches nothing, the same situations I diagnosed in Session 14) and the **final troubleshooting challenge**, in which I intentionally introduce multiple faults into the running project and handle each one with the same method: identify, investigate the logs and resources, find the root cause, fix, verify, document.

The task: **intentionally introduce multiple issues**, then identify, investigate (logs and resources), find the root cause, fix, verify and document each one. I break the running application in four different ways, one after the other. Before each one the application is healthy.

| # | Layer | The fault I introduce |
|---|---|---|
| 1 | Image / release | a Helm upgrade with an image tag that does not exist |
| 2 | Configuration / Secret | a typo in the database host stored in the Secret |
| 3 | Networking / Ingress | the Ingress points to a Service name that does not exist |
| 4 | Resources | a memory limit far below what the backend needs |

### Baseline (healthy)

I start from a **clean install** of the release (fresh namespace, so the autoscaler is back at the chart's 2 replicas and Helm and the HPA agree on the replica count).

_Clean install of the release._

```console
$ helm install stockpilot helm/stockpilot -n stockpilot -f helm/stockpilot/values-dev.yaml --wait --timeout 8m | head -n 7
NAME: stockpilot
LAST DEPLOYED: Sun Oct 18 20:54:35 2026
NAMESPACE: stockpilot
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
NOTES:
```

_All Pods Ready, the API answers through the Ingress, and the Helm history has one revision._

```console
$ kubectl get pods -n stockpilot; kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 > /tmp/pf-ing.txt 2>&1 & sleep 4; curl -s -o /dev/null -w "API through the Ingress: HTTP %{http_code}\n" -H "Host: stockpilot.local" localhost:8080/api/items/stats; kill %1; helm history stockpilot -n stockpilot
NAME                                   READY   STATUS    RESTARTS   AGE
stockpilot-backend-7fbd656b85-rgn95    1/1     Running   0          27s
stockpilot-backend-7fbd656b85-wqwdb    1/1     Running   0          27s
stockpilot-frontend-6699c58bd7-g7r5s   1/1     Running   0          27s
stockpilot-frontend-6699c58bd7-rzf2c   1/1     Running   0          27s
stockpilot-postgres-0                  1/1     Running   0          27s
API through the Ingress: HTTP 200
REVISION	UPDATED                 	STATUS  	CHART           	APP VERSION	DESCRIPTION     
1       	Sun Oct 18 20:54:35 2026	deployed	stockpilot-1.0.0	1.0.0      	Install complete
```

### Issue 1: a bad image tag in a release

**Introduce the fault:** a Helm upgrade to a backend image tag that does not exist.

_**Identify:** Helm reports the upgrade as done (there was no `--wait`), but the backend Pods show a problem: a new Pod cannot start while the two old ones keep running (rolling update)._

```console
$ helm upgrade stockpilot helm/stockpilot -n stockpilot --reuse-values --set backend.image.tag=v9.9.9-does-not-exist; sleep 30; kubectl get pods -n stockpilot -l app.kubernetes.io/component=backend
Release "stockpilot" has been upgraded. Happy Helming!
NAME: stockpilot
LAST DEPLOYED: Sun Oct 18 20:55:08 2026
NAMESPACE: stockpilot
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
NOTES:
StockPilot 1.0.0 was deployed as release "stockpilot" in namespace "stockpilot".

See what is running:
  kubectl get pods,svc,hpa -n stockpilot

Smoke test (backend + database + frontend proxy):
  helm test stockpilot -n stockpilot

The Ingress routes "/" to the frontend and "/api" to the backend:
  kubectl get ingress -n stockpilot
  Open http://stockpilot.local  (add the Ingress address to your hosts file if needed)
NAME                                  READY   STATUS         RESTARTS   AGE
stockpilot-backend-6b496fbbb5-rqt9j   0/1     ErrImagePull   0          30s
stockpilot-backend-7fbd656b85-rgn95   1/1     Running        0          63s
stockpilot-backend-7fbd656b85-wqwdb   1/1     Running        0          63s
```

_Revision 2 is "deployed", but the rollout never completes._

```console
$ helm history stockpilot -n stockpilot; kubectl rollout status deployment/stockpilot-backend -n stockpilot --timeout=20s; echo "rollout exit code: $?"
REVISION	UPDATED                 	STATUS    	CHART           	APP VERSION	DESCRIPTION     
1       	Sun Oct 18 20:54:35 2026	superseded	stockpilot-1.0.0	1.0.0      	Install complete
2       	Sun Oct 18 20:55:08 2026	deployed  	stockpilot-1.0.0	1.0.0      	Upgrade complete
Waiting for deployment "stockpilot-backend" rollout to finish: 1 out of 2 new replicas have been updated...
error: timed out waiting for the condition
rollout exit code: 1
```

_**Investigate:** the Pod events show the pull failure for the new tag._

```console
$ kubectl describe pod -n stockpilot -l app.kubernetes.io/component=backend | grep -E "Failed to pull|ErrImagePull|ImagePullBackOff|Image:" | sort -u | cut -c1-200; kubectl get events -n stockpilot --sort-by=.lastTimestamp | grep -E "Failed|BackOff" | tail -n 3 | cut -c1-200
      Reason:       ImagePullBackOff
    Image:          stockpilot-backend:local
    Image:          stockpilot-backend:v9.9.9-does-not-exist
    Image:         postgres:16-alpine
9s          Warning   FailedComputeMetricsReplicas   horizontalpodautoscaler/stockpilot-backend         invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: f
5s          Warning   Failed                         pod/stockpilot-backend-6b496fbbb5-rqt9j            Failed to pull image "stockpilot-backend:v9.9.9-does-not-exist": failed to pull and unpack image
5s          Warning   Failed                         pod/stockpilot-backend-6b496fbbb5-rqt9j            Error: ErrImagePull
```

**Root cause:** the image tag `v9.9.9-does-not-exist` was never built or pushed, so the kubelet cannot pull it. Thanks to the rolling update the old Pods keep serving: there is no outage, only a stuck rollout.

**Fix:** roll the release back to the last good revision.

_**Fix and verify:** revision 3 carries the content of revision 1; all backend Pods are Ready on the original image._

```console
$ helm rollback stockpilot 1 -n stockpilot --wait --timeout 5m && helm history stockpilot -n stockpilot && kubectl get pods -n stockpilot -l app.kubernetes.io/component=backend
Rollback was a success! Happy Helming!
REVISION	UPDATED                 	STATUS    	CHART           	APP VERSION	DESCRIPTION     
1       	Sun Oct 18 20:54:35 2026	superseded	stockpilot-1.0.0	1.0.0      	Install complete
2       	Sun Oct 18 20:55:08 2026	superseded	stockpilot-1.0.0	1.0.0      	Upgrade complete
3       	Sun Oct 18 20:56:01 2026	deployed  	stockpilot-1.0.0	1.0.0      	Rollback to 1   
NAME                                  READY   STATUS    RESTARTS   AGE
stockpilot-backend-7fbd656b85-rgn95   1/1     Running   0          86s
stockpilot-backend-7fbd656b85-wqwdb   1/1     Running   0          86s
```

_Confirmed: the original image, all replicas ready._

```console
$ kubectl get deploy stockpilot-backend -n stockpilot -o jsonpath="image={.spec.template.spec.containers[0].image}  ready={.status.readyReplicas}/{.spec.replicas}{\"\\n\"}"
image=stockpilot-backend:local  ready=2/2
```

### Issue 2: a typo in the database host (Secret)

**Introduce the fault:** the Secret that holds the database URL gets a wrong host name (`stockpilot-postgress`), and the backend is restarted so it reads it.

_**Identify:** the new backend Pods do not become ready: `CrashLoopBackOff` / `Error`, while the old Pods (still running with the old value) keep serving._

```console
$ SEC=$(kubectl get secret -n stockpilot -l app.kubernetes.io/instance=stockpilot -o jsonpath="{.items[0].metadata.name}"); kubectl patch secret $SEC -n stockpilot --type merge -p "{\"stringData\":{\"database-url\":\"postgresql+psycopg://stockpilot:placeholder@stockpilot-postgress:5432/stockpilot\"}}" && kubectl rollout restart deployment/stockpilot-backend -n stockpilot && sleep 45 && kubectl get pods -n stockpilot -l app.kubernetes.io/component=backend
secret/stockpilot-db patched
deployment.apps/stockpilot-backend restarted
NAME                                  READY   STATUS             RESTARTS     AGE
stockpilot-backend-7fbd656b85-rgn95   1/1     Running            0            2m12s
stockpilot-backend-7fbd656b85-wqwdb   1/1     Running            0            2m12s
stockpilot-backend-85746df75-bhbvd    0/1     CrashLoopBackOff   2 (8s ago)   45s
```

_**Investigate (logs):** the backend runs the database migration first and fails to find the database host: "could not translate host name"._

```console
$ POD=$(kubectl get pods -n stockpilot -l app.kubernetes.io/component=backend --sort-by=.metadata.creationTimestamp -o name | tail -n 1); echo "newest backend Pod (one of the failing ones): $POD"; kubectl logs $POD -n stockpilot -c backend --tail=6 | cut -c1-200
newest backend Pod (one of the failing ones): pod/stockpilot-backend-85746df75-bhbvd
    attempts = conninfo_attempts(params)
               ^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.12/site-packages/psycopg/_conninfo_attempts.py", line 55, in conninfo_attempts
    raise last_exc
sqlalchemy.exc.OperationalError: (psycopg.OperationalError) failed to resolve host 'stockpilot-postgress': [Errno -2] Name or service not known
(Background on this error at: https://sqlalche.me/e/20/e3q8)
```

_**Investigate (resources):** the host in the Secret (credentials masked) is `stockpilot-postgress`, but the real Service is called `stockpilot-postgres`._

```console
$ SEC=$(kubectl get secret -n stockpilot -l app.kubernetes.io/instance=stockpilot -o jsonpath="{.items[0].metadata.name}"); kubectl get secret $SEC -n stockpilot -o jsonpath="{.data.database-url}" | base64 -d | sed "s#//[^@]*@#//<user>:<password>@#"; echo; kubectl get svc -n stockpilot | grep postgres
postgresql+psycopg://<user>:<password>@stockpilot-postgress:5432/stockpilot
stockpilot-postgres   ClusterIP   None            <none>        5432/TCP   2m13s
```

**Root cause:** a typo in the host name of `database-url`: DNS cannot resolve `stockpilot-postgress`, so every new backend container fails at start-up. (The old Pods still work only because they started before the change.)

**Fix:** write the correct URL back into the Secret (built from the password the chart generated, which stays inside the cluster and is not printed) and restart the backend.

_**Fix and verify:** corrected Secret, restarted backend: all Pods are Ready again._

```console
$ SEC=$(kubectl get secret -n stockpilot -l app.kubernetes.io/instance=stockpilot -o jsonpath="{.items[0].metadata.name}"); PW=$(kubectl get secret $SEC -n stockpilot -o jsonpath="{.data.postgres-password}" | base64 -d); kubectl patch secret $SEC -n stockpilot --type merge -p "{\"stringData\":{\"database-url\":\"postgresql+psycopg://stockpilot:${PW}@stockpilot-postgres:5432/stockpilot\"}}" > /dev/null && kubectl rollout restart deployment/stockpilot-backend -n stockpilot && kubectl rollout status deployment/stockpilot-backend -n stockpilot --timeout=240s && kubectl get pods -n stockpilot -l app.kubernetes.io/component=backend
deployment.apps/stockpilot-backend restarted
Waiting for deployment "stockpilot-backend" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "stockpilot-backend" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "stockpilot-backend" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "stockpilot-backend" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "stockpilot-backend" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "stockpilot-backend" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "stockpilot-backend" rollout to finish: 1 old replicas are pending termination...
deployment "stockpilot-backend" successfully rolled out
NAME                                  READY   STATUS        RESTARTS   AGE
stockpilot-backend-69557cd975-2p7d2   1/1     Running       0          11s
stockpilot-backend-69557cd975-47jjq   1/1     Running       0          21s
stockpilot-backend-7fbd656b85-wqwdb   1/1     Terminating   0          2m36s
```

_The application answers with real data from the database again._

```console
$ kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 > /tmp/pf-ing.txt 2>&1 & sleep 4; curl -s -H "Host: stockpilot.local" localhost:8080/api/items/stats; echo; kill %1
{"total_items":10,"total_units":1175,"total_value":8020.3,"low_stock":3,"out_of_stock":2,"categories":4}
```

### Issue 3: the Ingress points to a Service that does not exist

**Introduce the fault:** the `/api` route of the Ingress is changed to the Service name `stockpilot-backendd`.

_**Identify:** all Pods are Running and Ready, nothing looks wrong in Kubernetes..._

```console
$ kubectl patch ingress stockpilot -n stockpilot --type json -p "[{\"op\":\"replace\",\"path\":\"/spec/rules/0/http/paths/0/backend/service/name\",\"value\":\"stockpilot-backendd\"}]"; sleep 5; kubectl get pods -n stockpilot -l app.kubernetes.io/component=backend
ingress.networking.k8s.io/stockpilot patched
NAME                                  READY   STATUS    RESTARTS   AGE
stockpilot-backend-69557cd975-2p7d2   1/1     Running   0          21s
stockpilot-backend-69557cd975-47jjq   1/1     Running   0          31s
```

_...but through the Ingress the page loads while the API fails with **503 Service Temporarily Unavailable**: the user would see an empty application with a backend error._

```console
$ kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 > /tmp/pf-ing.txt 2>&1 & sleep 4; curl -s -o /dev/null -w "frontend page /:        HTTP %{http_code}\n" -H "Host: stockpilot.local" localhost:8080/; curl -s -o /dev/null -w "API /api/items/stats: HTTP %{http_code}\n" -H "Host: stockpilot.local" localhost:8080/api/items/stats; kill %1
frontend page /:        HTTP 200
API /api/items/stats: HTTP 503
```

_**Investigate:** the Ingress description shows the `/api` backend with an error ("services ... not found"); the real Service is `stockpilot-backend`._

```console
$ kubectl describe ingress stockpilot -n stockpilot | sed -n "/^Rules:/,/^Annotations:/p" | cut -c1-170; kubectl get svc -n stockpilot
Rules:
  Host              Path  Backends
  ----              ----  --------
  stockpilot.local  
                    /api            stockpilot-backendd:http (<error: services "stockpilot-backendd" not found>)
                    /docs           stockpilot-backend:http (10.244.0.69:8000,10.244.0.70:8000)
                    /openapi.json   stockpilot-backend:http (10.244.0.69:8000,10.244.0.70:8000)
                    /               stockpilot-frontend:http (10.244.0.62:8080,10.244.0.64:8080)
Annotations:        meta.helm.sh/release-name: stockpilot
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
stockpilot-backend    ClusterIP   10.104.37.144   <none>        8000/TCP   2m51s
stockpilot-frontend   ClusterIP   10.99.46.216    <none>        80/TCP     2m51s
stockpilot-postgres   ClusterIP   None            <none>        5432/TCP   2m51s
```

**Root cause:** the Ingress backend references `stockpilot-backendd` (typo), a Service that does not exist, so the controller has no endpoints for `/api` and answers 503.

**Fix:** point the route back to the real Service.

_**Fix and verify:** the API returns HTTP 200 through the Ingress again._

```console
$ kubectl patch ingress stockpilot -n stockpilot --type json -p "[{\"op\":\"replace\",\"path\":\"/spec/rules/0/http/paths/0/backend/service/name\",\"value\":\"stockpilot-backend\"}]"; sleep 8; kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 > /tmp/pf-ing.txt 2>&1 & sleep 5; curl -s -o /dev/null -w "API /api/items/stats: HTTP %{http_code}\n" -H "Host: stockpilot.local" localhost:8080/api/items/stats; kill %1; kubectl describe ingress stockpilot -n stockpilot | grep -E "/api " | cut -c1-150
ingress.networking.k8s.io/stockpilot patched
API /api/items/stats: HTTP 200
                    /api            stockpilot-backend:http (10.244.0.69:8000,10.244.0.70:8000)
```

### Issue 4: a memory limit that is too low

**Introduce the fault:** a Helm upgrade lowers the backend memory limit to 40Mi (the process normally uses about 60-85 MiB). The memory *request* is lowered with it, because Kubernetes rejects a request that is higher than the limit.

_**Identify:** the new backend Pods are restarted over and over (`OOMKilled`, `CrashLoopBackOff`) while the old Pods still serve._

```console
$ helm upgrade stockpilot helm/stockpilot -n stockpilot --reuse-values --set backend.resources.limits.memory=40Mi --set backend.resources.requests.memory=32Mi | head -n 6; sleep 50; kubectl get pods -n stockpilot -l app.kubernetes.io/component=backend
Release "stockpilot" has been upgraded. Happy Helming!
NAME: stockpilot
LAST DEPLOYED: Sun Oct 18 20:57:41 2026
NAMESPACE: stockpilot
STATUS: deployed
REVISION: 4
NAME                                  READY   STATUS    RESTARTS      AGE
stockpilot-backend-69557cd975-2p7d2   1/1     Running   0             91s
stockpilot-backend-69557cd975-47jjq   1/1     Running   0             101s
stockpilot-backend-f4dd7f967-p48w4    0/1     Running   3 (26s ago)   50s
```

_**Investigate:** Last State Terminated, **Reason: OOMKilled, Exit Code 137**, and the memory limit in the Pod spec is 40Mi._

```console
$ kubectl describe pod -n stockpilot -l app.kubernetes.io/component=backend | grep -B1 -A6 "Last State" | grep -E "Last State|Reason|Exit Code|Limits|memory" | head -n 8; kubectl top pods -n stockpilot -l app.kubernetes.io/component=backend --no-headers
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
stockpilot-backend-69557cd975-2p7d2   132m   62Mi   
stockpilot-backend-69557cd975-47jjq   81m    62Mi   
```

**Root cause:** the limit (40Mi) is lower than what the FastAPI process needs to start (about 85 MiB), so the kernel kills it as soon as it grows past the limit.

**Fix:** go back to the last good release (the previous revision, whose limit is 384Mi).

_**Fix and verify:** rollback to the last good revision; the Pods run normally again._

```console
$ helm history stockpilot -n stockpilot | tail -n 3; LAST_GOOD=$(helm history stockpilot -n stockpilot -o json | grep -o "\"revision\":[0-9]*" | cut -d: -f2 | sort -n | tail -n 2 | head -n 1); echo "rolling back to revision $LAST_GOOD"; helm rollback stockpilot $LAST_GOOD -n stockpilot --wait --timeout 5m && kubectl get pods -n stockpilot -l app.kubernetes.io/component=backend
2       	Sun Oct 18 20:55:08 2026	superseded	stockpilot-1.0.0	1.0.0      	Upgrade complete
3       	Sun Oct 18 20:56:01 2026	superseded	stockpilot-1.0.0	1.0.0      	Rollback to 1   
4       	Sun Oct 18 20:57:41 2026	deployed  	stockpilot-1.0.0	1.0.0      	Upgrade complete
rolling back to revision 3
Rollback was a success! Happy Helming!
NAME                                  READY   STATUS        RESTARTS      AGE
stockpilot-backend-69557cd975-2p7d2   1/1     Running       0             94s
stockpilot-backend-69557cd975-47jjq   1/1     Running       0             104s
stockpilot-backend-f4dd7f967-p48w4    0/1     Terminating   3 (29s ago)   53s
```

_The limit is 384Mi again and all replicas are ready. The history shows the whole story, including the faulty revisions._

```console
$ kubectl get deploy stockpilot-backend -n stockpilot -o jsonpath="memory limit={.spec.template.spec.containers[0].resources.limits.memory}  ready={.status.readyReplicas}/{.spec.replicas}{\"\\n\"}"; helm history stockpilot -n stockpilot
memory limit=384Mi  ready=2/2
REVISION	UPDATED                 	STATUS    	CHART           	APP VERSION	DESCRIPTION     
1       	Sun Oct 18 20:54:35 2026	superseded	stockpilot-1.0.0	1.0.0      	Install complete
2       	Sun Oct 18 20:55:08 2026	superseded	stockpilot-1.0.0	1.0.0      	Upgrade complete
3       	Sun Oct 18 20:56:01 2026	superseded	stockpilot-1.0.0	1.0.0      	Rollback to 1   
4       	Sun Oct 18 20:57:41 2026	superseded	stockpilot-1.0.0	1.0.0      	Upgrade complete
5       	Sun Oct 18 20:58:34 2026	deployed  	stockpilot-1.0.0	1.0.0      	Rollback to 3   
```

_Final verification of the whole application: the API answers through the Ingress and `helm test` passes._

```console
$ kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 > /tmp/pf-ing.txt 2>&1 & sleep 4; curl -s -o /dev/null -w "final check, API through the Ingress: HTTP %{http_code}\n" -H "Host: stockpilot.local" localhost:8080/api/items/stats; kill %1; helm test stockpilot -n stockpilot | tail -n 4
final check, API through the Ingress: HTTP 200
TEST SUITE:     stockpilot-test
Last Started:   Sun Oct 18 20:58:40 2026
Last Completed: Sun Oct 18 20:58:43 2026
Phase:          Succeeded
```

### Summary of the four issues

| # | Symptom | Where I looked | Root cause | Fix |
|---|---|---|---|---|
| 1 | new backend Pod `ImagePullBackOff`, rollout stuck | `get pods`, events, `helm history` | image tag does not exist | `helm rollback` |
| 2 | new backend Pods `CrashLoopBackOff`, old Pods fine | `logs` (host not found), Secret (masked), `get svc` | typo in the database host in the Secret | corrected Secret + `rollout restart` |
| 3 | page loads, API returns 503 through the Ingress | `describe ingress`, `get svc` | Ingress backend Service name typo | patched the Ingress back |
| 4 | new backend Pods `OOMKilled` (exit 137) | `describe pod` (Last State), limits | memory limit below what the process needs | `helm rollback` to the previous limit |

_Cleanup: the release and the namespace (with its volume) are removed._

```console
$ kubectl delete namespace stockpilot --wait=true && kubectl get ns
namespace "stockpilot" deleted
NAME              STATUS   AGE
default           Active   147m
ingress-nginx     Active   85m
kube-node-lease   Active   147m
kube-public       Active   147m
kube-system       Active   147m
```

## 14. Screenshots

All screenshots of this project, in the order of the README. They were taken from a real (headless) Microsoft Edge browser against the running systems.

**1. StockPilot frontend**

![StockPilot frontend](docs/screenshots/app-frontend.png)

**2. StockPilot API documentation (FastAPI /docs)**

![StockPilot API documentation (FastAPI /docs)](docs/screenshots/app-api-docs.png)

**3. StockPilot running on Kubernetes, opened through the Ingress**

![StockPilot running on Kubernetes, opened through the Ingress](docs/screenshots/k8s-ingress-frontend.png)

**4. GitHub Actions run of the CI/CD pipeline**

![GitHub Actions run of the CI/CD pipeline](../../session16-github-actions/screenshots/actions-run-38807406432.png)

**5. Grafana dashboard for the StockPilot backend**

![Grafana dashboard for the StockPilot backend](docs/screenshots/grafana-stockpilot.png)

**6. Prometheus targets**

![Prometheus targets](docs/screenshots/prometheus-stockpilot-targets.png)

**7. BackendDown alert in Prometheus**

![BackendDown alert in Prometheus](docs/screenshots/prometheus-stockpilot-alert.png)

## 15. Lessons learned

- **One artefact, many environments.** The same two images and the same chart run in Compose, in Minikube and (with `values-eks.yaml`) on EKS; only values change. A chart with a ConfigMap, a Secret and probes is easier to reason about than hand-written manifests.
- **Gates beat good intentions.** Tests, secret scanning and an image scan that *fail the build* are what actually keep a broken or vulnerable image out of the registry; the Trivy gate was green here because earlier findings were fixed, not ignored.
- **Readiness, liveness and startup probes do different jobs**, and the rolling update plus a readiness probe is what kept the site up in two of the four troubleshooting faults even though new Pods were failing.
- **Secrets must stay out of Git.** The database password is generated in the cluster; a wrong host name in the Secret showed how a one-line configuration mistake becomes a crash loop, and how to read that from the logs.
- **Read the events.** `kubectl describe` and `kubectl get events` explained each of the faults (image pull, OOMKilled, missing Service) in one screen; most "mysteries" are in the events.
- **Autoscaling needs requests.** The HPA measures CPU as a percentage of the Pod's *request*; without requests it cannot work, and scale-down deliberately waits 5 minutes to avoid flapping.
- **Git as the source of truth changes how I work.** With Argo CD I stopped applying changes by hand: a commit changes the cluster, a manual change is reverted, and `git revert` is the rollback.
- **Be honest about what ran.** Parts that need paid cloud accounts (EKS, a real registry push from CI) are validated as far as is possible without them and clearly labelled instead of being presented as done.
