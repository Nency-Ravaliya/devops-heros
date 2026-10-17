# LiftLog — Workout Tracker

LiftLog is a strength-training log: build an exercise library, log every workout set by set (weight, reps, RPE), and watch your progress with analytics usually found in premium tracking apps: **personal records, estimated one-rep max, muscle-group volume and per-exercise progress charts**.

It's also a complete DevOps capstone: the app is tested, containerised, scanned, published by CI, provisioned on AWS with Terraform, deployed to EKS with Helm through **GitOps (Argo CD)**, and monitored with Prometheus and Grafana.

Video Link: [Presentation Video](https://youtu.be/2FtC1-wvGKg)
---

## Features

| Area                    | What you can do                                                                                                                                                                |
|:------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Exercise library**    | 21 starter exercises (seeded by the database migration), grouped by muscle group and equipment; add, rename and delete your own. Exercises used in a workout can't be deleted. |
| **Workout logging**     | Log a session with any number of exercises and sets: weight (kg), reps and optional RPE, plus duration and notes. Edit or delete workouts later.                               |
| **History**             | Every workout with its sets per exercise, total sets and total volume (kg lifted).                                                                                             |
| **Personal records** ⭐ | Best set per exercise, ranked by **estimated 1RM** (Epley: `weight × (1 + reps / 30)`).                                                                                        |
| **Volume analytics** ⭐ | Workouts and volume over the last 7 days; volume per muscle group over the last 30 days.                                                                                       |
| **Progress charts** ⭐  | Estimated 1RM and top-set weight over time for any exercise.                                                                                                                   |

⭐ = "premium" analytics.

## Architecture

```text
Browser ──► frontend (React + Vite, served by nginx, non-root) ──/api──► backend (FastAPI, non-root) ──► PostgreSQL
                                                                              │
                                                                              └── /metrics ──► Prometheus ──► Grafana

git push ──► GitHub Actions: pytest + frontend build ──► docker build ──► Trivy gate ──► GHCR (:<sha>)
                                     └──► commit the new SHA to helm/liftlog/values-eks.yaml ──► Argo CD ──► EKS
```

| Layer          | Technology                                                                                                                                |
|:---------------|:------------------------------------------------------------------------------------------------------------------------------------------|
| Frontend       | React 19, Vite 8, nginx (`nginxinc/nginx-unprivileged`)                                                                                   |
| Backend        | Python 3.12, FastAPI, SQLAlchemy 2, Alembic, Pydantic 2, `prometheus-fastapi-instrumentator`                                              |
| Database       | PostgreSQL 16                                                                                                                             |
| CI/CD          | GitHub Actions → GHCR, Trivy, GitOps with Argo CD                                                                                         |
| Infrastructure | Terraform: AWS VPC (2 public + 2 private subnets) and EKS 1.36, with EBS CSI driver and AWS Load Balancer Controller via EKS Pod Identity |
| Kubernetes     | Helm chart (`helm/liftlog`), HPA, ALB Ingress (`/` → frontend, `/api` → backend)                                                          |
| Observability  | kube-prometheus-stack, ServiceMonitor, Grafana dashboard as code                                                                          |

## Repository layout

```text
backend/        FastAPI app (app/), Alembic migrations, pytest suite
frontend/       React UI and nginx config
docker-compose.yml
.github/workflows/ci-cd.yml
terraform/      VPC + EKS (+ terraform.tfvars.example)
k8s/            namespace and default StorageClass
helm/liftlog/   Helm chart; values-eks.yaml is managed by CI (GitOps)
argocd/         Argo CD Application for EKS
monitoring/     kube-prometheus-stack values and the Grafana dashboard
troubleshooting/  deliberately broken manifests for practice
```

## Run locally

```bash
docker compose up --build
```

| URL                                                    |                                                               |
|:-------------------------------------------------------|:--------------------------------------------------------------|
| <http://localhost:3000>                                | LiftLog UI (on Windows with WSL, use `http://127.0.0.1:3000`) |
| <http://localhost:8000/docs>                           | API docs (Swagger UI)                                         |
| <http://localhost:8000/health> · `/ready` · `/metrics` | Liveness, readiness (checks the DB), Prometheus metrics       |

### Tests

```bash
cd backend
pip install -r requirements.txt
python -m pytest -v      # uses a throwaway SQLite database, never Postgres
```

## API

| Method | Path                           | Description                                                  |
|:-------|:-------------------------------|:-------------------------------------------------------------|
| GET    | `/api/exercises`               | List the exercise library                                    |
| POST   | `/api/exercises`               | Add an exercise (`409` on duplicate name)                    |
| PUT    | `/api/exercises/{id}`          | Update an exercise                                           |
| DELETE | `/api/exercises/{id}`          | Delete an unused exercise (`409` if it's in a workout)       |
| GET    | `/api/exercises/{id}/progress` | Top set, estimated 1RM and volume per workout (oldest first) |
| GET    | `/api/workouts`                | List workouts with their sets, newest first                  |
| POST   | `/api/workouts`                | Log a workout with nested `sets`                             |
| GET    | `/api/workouts/{id}`           | One workout                                                  |
| PUT    | `/api/workouts/{id}`           | Update a workout (`sets`, when given, replaces all sets)     |
| DELETE | `/api/workouts/{id}`           | Delete a workout                                             |
| GET    | `/api/stats`                   | 7-day totals, 30-day muscle-group volume, personal records   |

Example:

```bash
curl -X POST http://localhost:8000/api/workouts -H 'Content-Type: application/json' -d '{
  "title": "Push Day", "duration_min": 60,
  "sets": [{"exercise_id": 1, "reps": 5, "weight_kg": 100}, {"exercise_id": 1, "reps": 5, "weight_kg": 102.5, "rpe": 8.5}]
}'
```

## CI/CD and GitOps

On every push to `main`, [`.github/workflows/ci-cd.yml`](.github/workflows/ci-cd.yml):

1. **test**: `pytest` and the frontend production build.
2. **build-scan-push**: builds both images, fails on any fixable HIGH/CRITICAL CVE (Trivy), then pushes `ghcr.io/<owner>/liftlog-backend` and `liftlog-frontend` tagged with the **commit SHA** (and `latest`).
3. **update-gitops**: writes that SHA into [`helm/liftlog/values-eks.yaml`](helm/liftlog/values-eks.yaml) and commits it. Argo CD on EKS sees the commit and rolls the new images out. No cloud credentials are stored in CI.

**Live demo:** change something visible (e.g. the dashboard greeting in `frontend/src/main.jsx`), push, watch the Actions run go green and the `deploy: liftlog images <sha>` commit appear, then refresh the app as Argo CD rolls out the new pods.

## Deploy to AWS (EKS)

```bash
cd terraform
terraform init && terraform plan -out main.tfplan && terraform apply main.tfplan
aws eks update-kubeconfig --region ap-southeast-2 --name liftlog-eks

kubectl apply -f k8s/namespace.yaml -f k8s/storageclass.yaml
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
  --set clusterName=liftlog-eks --set serviceAccount.name=aws-load-balancer-controller --set vpcId=<vpc-id> --set region=ap-southeast-2
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace -f monitoring/prometheus-values.yaml
kubectl apply -f monitoring/liftlog-dashboard.yaml

kubectl create namespace argocd
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/liftlog-application.yaml      # Argo CD deploys helm/liftlog with values-eks.yaml
kubectl get ingress -n liftlog                         # ALB address
```

Tear down when finished: uninstall the Helm releases first (so the ALB and EBS volumes are deleted), then run `terraform destroy`.

> Cost: EKS control plane, a NAT gateway, 2 × `m7i-flex.large` and an ALB come to roughly US$0.45/hour.
