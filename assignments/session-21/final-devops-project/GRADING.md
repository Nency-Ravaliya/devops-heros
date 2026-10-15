# Session 21 — Final Capstone Project: Grading Rubric

This document defines the evaluation criteria, module weights, and exact submission requirements for the DevOps Final Capstone Project.

The capstone is worth **100 points** in total. Each module below maps directly to a skill block from the course. A student who skips a module receives zero for that section — partial credit is awarded only within a module.

---

## Grading Overview

| Module | Topic | Points |
|--------|-------|--------|
| M1 | Application — Frontend + Backend + Database | 10 |
| M2 | Testing — Pytest + Code Quality | 10 |
| M3 | Git and GitHub | 5 |
| M4 | Docker — Dockerfile + Compose | 10 |
| M5 | CI/CD — GitHub Actions Pipeline | 15 |
| M6 | DevSecOps — Trivy Security Scan | 5 |
| M7 | Terraform — AWS Infrastructure as Code | 15 |
| M8 | Kubernetes + Helm | 15 |
| M9 | Observability — Prometheus + Grafana | 10 |
| M10 | Final Presentation + Documentation | 5 |
| **Total** | | **100** |

---

## M1 — Application: Frontend + Backend + Database (10 points)

This is the foundation. Without a working application, no DevOps layer can be meaningfully demonstrated.

### Grading Criteria

| Criterion | Points |
|-----------|--------|
| FastAPI backend starts and responds to `/health` | 2 |
| Minimum 4 REST API endpoints implemented (GET, POST, PUT, DELETE) | 3 |
| PostgreSQL database with at least one table managed by Alembic migrations | 2 |
| React/HTML frontend renders and makes API calls | 2 |
| Responsive and usable UI (not a blank page) | 1 |

### What to Submit

- `backend/app/` — all Python source files (models, schemas, routes, database config)
- `backend/alembic/versions/` — at least one migration file
- `backend/requirements.txt`
- `frontend/` — all frontend source files
- `docker-compose.yml` — working stack definition
- Screenshot or short screen recording of the running application in the browser

---

## M2 — Testing: Pytest + Code Quality (10 points)

Tests are the first quality gate. They must run and pass before any Docker image is built or pushed.

### Grading Criteria

| Criterion | Points |
|-----------|--------|
| `pytest` runs without errors | 3 |
| Minimum 5 test cases covering at least 3 API endpoints | 4 |
| Tests use a test database or mock, not the production database | 2 |
| `pytest.ini` or `conftest.py` is present and correctly configured | 1 |

### What to Submit

- `backend/tests/` — all test files
- `backend/pytest.ini` or `backend/conftest.py`
- Terminal output screenshot showing all tests passing (`pytest -v`)

---

## M3 — Git and GitHub (5 points)

Version control is non-negotiable in professional engineering teams.

### Grading Criteria

| Criterion | Points |
|-----------|--------|
| Public GitHub repository linked in the submission form | 2 |
| Meaningful commit messages (not "update", "fix", "test") | 2 |
| `.gitignore` excludes `.env`, `__pycache__`, `node_modules`, `.venv` | 1 |

### What to Submit

- GitHub repository URL (public or with instructor access granted)
- Commit history screenshot showing at least 10 commits

---

## M4 — Docker: Dockerfile + Compose (10 points)

Students must be able to containerize the entire application stack and run it with a single command.

### Grading Criteria

| Criterion | Points |
|-----------|--------|
| `backend/Dockerfile` builds successfully | 2 |
| `frontend/Dockerfile` uses multi-stage build (Node build + Nginx runtime) | 3 |
| Docker images run as non-root users | 2 |
| `docker compose up --build` starts all three services (frontend, backend, postgres) | 3 |

### What to Submit

- `backend/Dockerfile`
- `frontend/Dockerfile`
- `docker-compose.yml`
- Terminal output screenshot showing `docker compose up --build` running successfully
- Screenshot of the browser at `http://localhost:3000` with the application loaded

---

## M5 — CI/CD: GitHub Actions Pipeline (15 points)

The pipeline is the automation backbone. It must run on every push to the `main` branch.

### Grading Criteria

| Criterion | Points |
|-----------|--------|
| `.github/workflows/` contains at least one workflow file | 1 |
| Pipeline triggers on push to `main` | 1 |
| `pytest` runs as a pipeline job and fails the build on test failure | 3 |
| Frontend is built as part of the pipeline | 2 |
| Docker images are built for both frontend and backend | 3 |
| Images are pushed to GitHub Container Registry (GHCR) | 3 |
| Image tags use the Git commit SHA (not `latest`) | 2 |

### What to Submit

- `.github/workflows/` — all workflow YAML files
- GitHub Actions run URL showing a successful green pipeline
- GHCR package page screenshot showing the published images with SHA-based tags

---

## M6 — DevSecOps: Trivy Security Scan (5 points)

Security scanning is a non-negotiable gate in modern pipelines.

### Grading Criteria

| Criterion | Points |
|-----------|--------|
| Trivy scan runs in the CI pipeline on both backend and frontend images | 3 |
| Pipeline is configured to fail on HIGH or CRITICAL CVEs | 1 |
| Student can explain one CVE found (or explain a clean scan result) | 1 |

### What to Submit

- Trivy scan step in the GitHub Actions workflow file
- Screenshot of the Trivy scan output from a pipeline run (can be clean or with findings)
- 2-3 sentence written explanation of what Trivy scanned and what the result means

---

## M7 — Terraform: AWS Infrastructure as Code (15 points)

Students must provision real AWS infrastructure using code, not the console.

### Grading Criteria

| Criterion | Points |
|-----------|--------|
| `terraform/` directory with valid HCL files | 2 |
| `terraform init` completes without errors | 1 |
| `terraform plan` produces a non-empty plan with no errors | 2 |
| VPC with at least two public subnets is provisioned | 3 |
| EKS cluster is provisioned with at least one worker node group | 4 |
| `terraform destroy` tears down all resources cleanly | 2 |
| `terraform.tfvars.example` present (no real credentials committed) | 1 |

### What to Submit

- `terraform/` — all `.tf` files
- `terraform plan` output screenshot
- AWS Console screenshot showing VPC and EKS cluster in the expected region
- `terraform destroy` completion screenshot (to confirm no runaway AWS costs)

[IMPORTANT] Do not commit AWS access keys, secret keys, or any credentials to GitHub. The grading team will reject submissions where secrets are found in the commit history.

---

## M8 — Kubernetes + Helm (15 points)

The application must run in a Kubernetes cluster and be managed through a Helm chart.

### Grading Criteria

| Criterion | Points |
|-----------|--------|
| `k8s/namespace.yaml` exists and applies cleanly | 1 |
| Helm chart in `helm/` directory with `Chart.yaml`, `values.yaml`, and templates | 3 |
| `helm upgrade --install` deploys the application without errors | 3 |
| Backend and frontend Deployments are running with at least 2 replicas each | 2 |
| ClusterIP Services expose backend and frontend | 2 |
| Ingress resource routes `/` to frontend and `/api` to backend | 2 |
| `kubectl get pods -n <namespace>` shows all pods in `Running` state | 2 |

### What to Submit

- `k8s/` — namespace and bootstrap manifests
- `helm/` — complete Helm chart directory
- `kubectl get pods -n <namespace>` screenshot showing Running pods
- `kubectl get svc -n <namespace>` screenshot
- `helm list -n <namespace>` screenshot
- Browser screenshot of the application accessed through the Ingress hostname or LoadBalancer IP

---

## M9 — Observability: Prometheus + Grafana (10 points)

The application must expose metrics and those metrics must be visible in a dashboard.

### Grading Criteria

| Criterion | Points |
|-----------|--------|
| `/metrics` endpoint on the backend returns Prometheus-formatted output | 2 |
| Prometheus is installed in the cluster and scraping the application | 3 |
| Grafana is installed and accessible | 2 |
| At least one Grafana panel shows live application metrics (HTTP requests, latency, or error rate) | 3 |

### What to Submit

- `monitoring/` — Prometheus and Grafana Helm values files
- Screenshot of `curl http://<backend>/metrics` output
- Screenshot of the Prometheus Targets page showing the application as `UP`
- Screenshot of the Grafana dashboard with at least one populated panel

---

## M10 — Final Presentation + Documentation (5 points)

The presentation is the final demonstration that the student understands what they built and why each component exists.

### Grading Criteria

| Criterion | Points |
|-----------|--------|
| `README.md` in the project root explaining what the application does | 2 |
| Live demo: commit a change, watch the pipeline run, see the deployment update | 3 |


### What to Submit

- `README.md` in the repository root
- Live demo during the presentation session (or a recorded walkthrough if remote)

---

## Submission Checklist

Before submitting, verify every item below. Incomplete submissions will not receive partial credit for items that cannot be evaluated.

```text
Application
  [ ] GitHub repository URL submitted
  [ ] Application runs via docker compose up --build
  [ ] At least 4 REST API endpoints implemented
  [ ] Alembic migration file present

Testing
  [ ] pytest passes (screenshot submitted)
  [ ] At least 5 test cases present

Docker
  [ ] backend/Dockerfile builds
  [ ] frontend/Dockerfile uses multi-stage build
  [ ] Non-root user in both Dockerfiles

CI/CD
  [ ] GitHub Actions workflow present
  [ ] Pipeline runs on push to main
  [ ] pytest runs in pipeline
  [ ] Images pushed to GHCR with SHA tags

Security
  [ ] Trivy scan in pipeline
  [ ] No secrets committed to Git

Terraform
  [ ] terraform plan output submitted
  [ ] VPC + EKS provisioned (AWS Console screenshot)
  [ ] terraform destroy output submitted

Kubernetes + Helm
  [ ] kubectl get pods screenshot (all Running)
  [ ] helm list screenshot
  [ ] Application accessible via Ingress

Observability
  [ ] /metrics endpoint screenshot
  [ ] Prometheus Targets page screenshot (UP)
  [ ] Grafana dashboard screenshot

Documentation
  [ ] README.md present
  [ ] Presentation completed or recording submitted
```

---

## Grading Policy

- Late submissions: 5 points deducted per 24-hour period after the deadline.
- Plagiarism: A submission that is a copy of another student's work or a direct clone of the TaskBoard reference project without meaningful changes receives a zero for all modules.
- The application domain must be your own. The DevOps layer may follow the same architecture as TaskBoard.
- AWS cost responsibility: Students are responsible for running `terraform destroy` after the evaluation. Runaway AWS bills are not the course's responsibility.
