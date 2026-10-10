# Session 21 – Final DevOps Project: StudyTrack

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123  
**Repository / branch:** [`kushaltalati/devops-heros`](https://github.com/kushaltalati/devops-heros) → branch [`capstone-kushal-s21`](https://github.com/kushaltalati/devops-heros/tree/capstone-kushal-s21/session21-python/kushal-24bcs10123) (the pipeline and Argo CD watch this branch; the same tree is in my sessions 13–21 PR)  
**Pipeline:** [`.github/workflows/24bcs10123-final-project.yml`](https://github.com/kushaltalati/devops-heros/blob/capstone-kushal-s21/.github/workflows/24bcs10123-final-project.yml) – green run: https://github.com/kushaltalati/devops-heros/actions/runs/37665794354  
**Images:** `ghcr.io/kushaltalati/studytrack-backend`, `ghcr.io/kushaltalati/studytrack-frontend` (tag `sha-<7 chars>` + `latest`, multi-arch amd64/arm64)  
**Environment:** kind v0.33.0 cluster `kushal-lab` (Kubernetes v1.37.0, 1 control-plane + 2 workers) on Docker Desktop 29.0.1, macOS / Apple Silicon – the same cluster as sessions 9–20, with metrics-server, ingress-nginx, kube-prometheus-stack (ns `monitoring`) and Argo CD (ns `argocd`) already installed from the earlier sessions. Terraform 1.16.4, Helm 3.19, Trivy 0.75, LocalStack 4.0.3.

StudyTrack is my own small application: a study log. You record blocks of study time (subject, topic, minutes, status), mark them done, and the dashboard shows total minutes, progress against a daily goal and a per-subject breakdown. Same shape as the course's TaskBoard reference (FastAPI + PostgreSQL + React, one resource with full CRUD) but my own domain, code and schema.

Every command below was really run; raw output is in [`docs/outputs/`](docs/outputs), browser/terminal captures in [`screenshots/`](screenshots).

```text
kushal-24bcs10123/
├── README.md
├── backend/                 # FastAPI + SQLAlchemy + Alembic, pytest, Dockerfile (non-root)
│   ├── app/                 # config.py db.py models.py schemas.py metrics.py main.py
│   ├── alembic/versions/0001_create_study_entries.py
│   ├── tests/               # conftest.py (sqlite in-memory) + test_api.py (11 tests)
│   └── Dockerfile, entrypoint.sh, requirements*.txt, pytest.ini
├── frontend/                # React + Vite, multi-stage Dockerfile -> nginx-unprivileged
├── docker-compose.yml       # postgres + backend + frontend
├── k8s/namespace.yaml
├── helm/studytrack/         # chart: deployments (probes), services, configmap, secret, pvc+postgres, ingress, hpa, servicemonitor
├── gitops/argocd-application.yaml
├── monitoring/              # kube-prometheus-stack values, PrometheusRule, Grafana dashboard json
├── terraform/               # VPC, 2 public subnets, IGW/route table, security group, S3 (+ EKS module)
├── troubleshooting/         # broken-image, broken-service, broken-config
├── scripts/                 # run-local.sh load-test.sh k8s-verify.sh prom-queries.sh
├── .github/workflows/24bcs10123-final-project.yml   (copy of the root workflow)
├── docs/outputs/            # raw logs, numbered by module
└── screenshots/
```

## Architecture

```text
 developer ── git push ──> GitHub (kushaltalati/devops-heros, branch capstone-kushal-s21)
                                │
                                ▼  GitHub Actions
          test ─┬─ SAST (bandit, semgrep) ─┐
                ├─ SCA  (pip-audit, npm)   ├─ build+push ──> ghcr.io/kushaltalati/studytrack-{backend,frontend}:sha-xxxxxxx
                ├─ secret scan (gitleaks)  │        │
                └─ helm lint/template ─────┘        ▼
                                              trivy gate (HIGH/CRITICAL => fail)
                                                    │
                                                    ▼
                                   deploy job: writes image.tag into helm/studytrack/values.yaml, commits
                                                    │
                       Argo CD (ns argocd) watches the branch/path, auto-sync + self-heal
                                                    │
     ┌──────────────────────────────── kind cluster kushal-lab, namespace studytrack ─────────────────────────┐
     │  Ingress studytrack.local ──/──> Service studytrack-frontend ──> Deployment frontend (nginx, 2 pods)   │
     │        (ingress-nginx)   ──/api──> Service studytrack-backend ──> Deployment backend (uvicorn, 2..6)    │
     │                                                     │  HPA 50% cpu       │ probes: startup/ready/live   │
     │                                                     ▼                    ▼                              │
     │                                        Service studytrack-postgres ──> Deployment postgres + PVC 1Gi    │
     │   ConfigMap studytrack-config  Secret studytrack-db-secret  ServiceMonitor ──> Prometheus ──> Grafana   │
     └────────────────────────────────────────────────────────────────────────────────────────────────────────┘

 terraform/  ──> VPC 10.42.0.0/16, 2 public subnets, IGW, route table, web SG, S3 backups bucket, [EKS module]
                 applied/destroyed against LocalStack (see M7 for why not real AWS)
```

## Rubric map

| Module | What proves it |
|---|---|
| M1 Application | [`backend/app/main.py`](backend/app/main.py) (`/health`, `/ready`, `/metrics`, `GET/POST/PUT/DELETE /api/entries`, `/api/entries/summary`), [`alembic/versions/0001_create_study_entries.py`](backend/alembic/versions/0001_create_study_entries.py), [`frontend/src/App.jsx`](frontend/src/App.jsx), [`docker-compose.yml`](docker-compose.yml); logs [02](docs/outputs/02-api-smoke-test.txt), [03](docs/outputs/03-compose-db-and-nonroot.txt); screenshot [01](screenshots/01-compose-frontend-localhost-3000.png) |
| M2 Testing | [`backend/tests/`](backend/tests) – 11 tests over 7 endpoints, SQLite in-memory via `conftest.py`, [`pytest.ini`](backend/pytest.ini); log [04](docs/outputs/04-pytest-local.txt) + the `Unit tests` job in every run |
| M3 Git/GitHub | this public repo, 19 commits on the branch (`git log --oneline upstream/main..capstone-kushal-s21`), [`.gitignore`](.gitignore) excludes `.env`, `__pycache__`, `node_modules`, `.venv`, tfstate |
| M4 Docker | [`backend/Dockerfile`](backend/Dockerfile) (uid 10001), [`frontend/Dockerfile`](frontend/Dockerfile) (node build stage → `nginx-unprivileged`, uid 101), [`docker-compose.yml`](docker-compose.yml); logs [01](docs/outputs/01-docker-compose-up.txt), [03](docs/outputs/03-compose-db-and-nonroot.txt) |
| M5 CI/CD | [workflow](.github/workflows/24bcs10123-final-project.yml); green run https://github.com/kushaltalati/devops-heros/actions/runs/37665794354; images tagged `sha-<git sha>`; logs [41](docs/outputs/41-ci-run-green.txt), [42](docs/outputs/42-ghcr-images.txt) |
| M6 DevSecOps | trivy on both images with `exit-code: 1` for HIGH/CRITICAL; plus bandit, semgrep, pip-audit, npm audit, gitleaks; logs [06](docs/outputs/06-trivy-local-images.txt), [07](docs/outputs/07-sast-local.txt), [40](docs/outputs/40-ci-run-blocked-by-sca.txt) (a run the SCA gate really blocked) |
| M7 Terraform | [`terraform/`](terraform) incl. [`modules/eks`](terraform/modules/eks), [`terraform.tfvars.example`](terraform/terraform.tfvars.example); logs [20](docs/outputs/20-terraform-init-validate.txt)–[25](docs/outputs/25-terraform-destroy.txt) |
| M8 Kubernetes + Helm | [`k8s/namespace.yaml`](k8s/namespace.yaml), [`helm/studytrack/`](helm/studytrack); logs [50](docs/outputs/50-helm-install.txt), [51](docs/outputs/51-k8s-verify.txt), [52](docs/outputs/52-hpa-load-test.txt); screenshot [10](screenshots/10-ingress-studytrack-local.png) |
| M9 Observability | `/metrics` ([02](docs/outputs/02-api-smoke-test.txt)), ServiceMonitor, [`monitoring/`](monitoring); logs [60](docs/outputs/60-prometheus-targets-and-queries.txt), [61](docs/outputs/61-grafana-dashboard.txt) |
| M10 Docs / demo | this README; GitOps demo in [53](docs/outputs/53-argocd-sync-and-selfheal.txt): push → pipeline → tag bump → Argo CD rollout |

## M1 – Application

Log: [docs/outputs/02-api-smoke-test.txt](docs/outputs/02-api-smoke-test.txt) · screenshots [01](screenshots/01-compose-frontend-localhost-3000.png) (UI), [02](screenshots/02-backend-swagger-docs.png) (Swagger)

Backend (`backend/app/`): FastAPI + SQLAlchemy 2 + Alembic, one table `study_entries`.

```text
GET    /                      app name, version, environment, uptime
GET    /health                liveness  – process answers HTTP, no dependency checked
GET    /ready                 readiness – SELECT 1 against PostgreSQL, 503 when the DB is down
GET    /metrics               Prometheus text format
GET    /api/entries           list (filters: ?subject=  ?status_filter=planned|in_progress|done)
GET    /api/entries/summary   totals, done minutes vs daily goal, by_status, by_subject
GET    /api/entries/{id}
POST   /api/entries           201, validated by pydantic (minutes 1..600, status enum)
PUT    /api/entries/{id}      partial update, 422 on empty body, 404 on unknown id
DELETE /api/entries/{id}      204
```

```text
$ curl -s -X POST localhost:8000/api/entries -H 'Content-Type: application/json' -d '{"subject":"DBMS","topic":"B+ tree indexes","minutes":60,"status":"done"}'
{"subject":"DBMS","topic":"B+ tree indexes","minutes":60,"status":"done","notes":"","id":2,"created_at":"2026-10-07T17:40:46.0...","updated_at":"..."}

$ curl -s localhost:8000/api/entries/summary | python3 -m json.tool
{
    "total_entries": 4,
    "total_minutes": 225,
    "done_minutes": 195,
    "daily_goal_minutes": 120,
    "goal_reached": true,
    "by_status": {"done": 3, "in_progress": 1},
    "by_subject": [{"subject": "DevOps", "minutes": 90, "entries": 1}, {"subject": "Operating Systems", "minutes": 75, "entries": 2}, ...]
}
```

Configuration is 12-factor style: every setting in [`config.py`](backend/app/config.py) is an env var (`DATABASE_URL`, `APP_ENV`, `DAILY_GOAL_MINUTES`, `CORS_ORIGINS`), which is exactly what the ConfigMap/Secret inject in Kubernetes. The migration ([`0001_create_study_entries.py`](backend/alembic/versions/0001_create_study_entries.py)) runs from the container entrypoint (`alembic upgrade head`) before uvicorn starts, so a fresh database is ready on first boot and a second replica is a no-op:

```text
$ docker compose exec postgres psql -U studytrack -d studytrack -c '\dt' -c 'select version_num from alembic_version'
              List of relations
 Schema |      Name       | Type  |   Owner
--------+-----------------+-------+------------
 public | alembic_version | table | studytrack
 public | study_entries   | table | studytrack
 version_num
-------------
 0001
```

Frontend (`frontend/src/`): React 19 + Vite. Sidebar with the daily-goal bar and per-subject totals, KPI cards, add form, status filters, table with mark-done / start / delete. All API calls are relative (`/api/...`), so the browser only talks to the host that served the page: in compose nginx proxies `/api` to `backend:8000`, in Kubernetes the Ingress routes `/api` to the backend Service (and nginx can still proxy via the ConfigMap's `BACKEND_URL`). Responsive: the grid collapses to one column under 800px.

## M2 – Testing

Log: [docs/outputs/04-pytest-local.txt](docs/outputs/04-pytest-local.txt)

11 tests in [`tests/test_api.py`](backend/tests/test_api.py) covering `/health`, `/ready`, `/metrics` and all six `/api/entries*` operations, including validation (422), not-found (404), filters and the summary maths. [`conftest.py`](backend/tests/conftest.py) sets `DATABASE_URL=sqlite://` *before* importing the app and overrides the `get_db` dependency with an in-memory SQLite engine (`StaticPool`), recreating the schema for every test, so the suite never touches PostgreSQL and runs in well under a second.

```text
$ pytest -v --cov=app --cov-report=term-missing
tests/test_api.py::test_health PASSED
tests/test_api.py::test_ready_reports_database_up PASSED
tests/test_api.py::test_metrics_endpoint_is_prometheus_text PASSED
tests/test_api.py::test_list_entries_empty PASSED
tests/test_api.py::test_create_entry PASSED
tests/test_api.py::test_create_entry_validation PASSED
tests/test_api.py::test_get_entry_and_404 PASSED
tests/test_api.py::test_update_entry PASSED
tests/test_api.py::test_delete_entry PASSED
tests/test_api.py::test_filter_by_subject_and_status PASSED
tests/test_api.py::test_summary PASSED
======================== 11 passed, 1 warning in 0.37s =========================
backend/app/main.py           85      6    93%
```

The same command is the first job of the pipeline; everything else `needs: test`, so a red test means no image is ever built or pushed.

## M3 – Git and GitHub

`git log --oneline upstream/main..capstone-kushal-s21` shows 20 commits, one per logical step (skeleton → models → migration → tests → Dockerfile → frontend → compose → chart → terraform → monitoring → pipeline → fixes the pipeline asked for). Author identity is my GitHub account. [`.gitignore`](.gitignore) excludes `.env`, `__pycache__/`, `.venv/`, `node_modules/`, `dist/`, `*.tfstate`, `.terraform/` and `terraform.tfvars`; gitleaks runs in CI over the history to make sure nothing secret slipped in.

## M4 – Docker

Logs: [01-docker-compose-up.txt](docs/outputs/01-docker-compose-up.txt), [03-compose-db-and-nonroot.txt](docs/outputs/03-compose-db-and-nonroot.txt)

* [`backend/Dockerfile`](backend/Dockerfile): `python:3.12-slim`, system user `studytrack` uid 10001, `HEALTHCHECK` on `/health`, entrypoint runs the migration then `uvicorn`.
* [`frontend/Dockerfile`](frontend/Dockerfile): stage 1 `node:24-alpine` runs `npm ci && npm run build`; stage 2 `nginxinc/nginx-unprivileged:stable-alpine` only gets `dist/` and the nginx template. The image runs as uid 101 and listens on 8080 (no root needed for port 80). The first version used `1.27-alpine`; trivy found 42 HIGH/CRITICAL fixable CVEs in that alpine 3.21 base, `stable-alpine` (alpine 3.24) scans clean – see M6.
* [`docker-compose.yml`](docker-compose.yml): `postgres:16-alpine` with a named volume and a `pg_isready` healthcheck, backend waits for `service_healthy`, frontend on `localhost:3000`, backend on `localhost:8000`.

```text
$ docker compose up --build -d
 ✔ Container studytrack-postgres-1  Healthy
 ✔ Container studytrack-backend-1   Started
 ✔ Container studytrack-frontend-1  Started

$ docker compose exec backend id
uid=10001(studytrack) gid=10001 groups=10001
$ docker compose exec frontend id
uid=101(nginx) gid=101(nginx) groups=101(nginx)
```

The data survived rebuilding the backend image (`docker compose up --build -d backend`): the rows live in the `pgdata` volume, not in the container.

## M5 – CI/CD pipeline (GitHub Actions)

Workflow: [`.github/workflows/24bcs10123-final-project.yml`](https://github.com/kushaltalati/devops-heros/blob/capstone-kushal-s21/.github/workflows/24bcs10123-final-project.yml) (a copy sits in this folder). Logs: [40-ci-run-blocked-by-sca.txt](docs/outputs/40-ci-run-blocked-by-sca.txt), [41-ci-run-green.txt](docs/outputs/41-ci-run-green.txt), [42-ghcr-images.txt](docs/outputs/42-ghcr-images.txt)

Triggers: `push` to `capstone-kushal-s21`, `sessions-13-21-kushal` and `main`, filtered to this folder and the workflow file (so classmates' pushes to the shared fork do not run my pipeline), plus `workflow_dispatch`. Never `pull_request`, so it does not run inside the course repo's Actions.

| Job | What it does | Gate |
|---|---|---|
| `test` | `pip install -r requirements-dev.txt`, `pytest -v --cov=app` | every other job `needs: test` |
| `sast` | bandit (`-ll`) and semgrep (`p/python`, `p/security-audit`, `--error`) on `backend/app` | fails on findings |
| `sca` | `pip-audit -r requirements.txt --strict`, `npm audit --omit=dev --audit-level=high` | fails on known CVEs |
| `secret-scan` | gitleaks over the git history and the working tree of this folder, with [`.gitleaks.toml`](.gitleaks.toml) allow-listing the obvious lab placeholders | fails on a leak |
| `helm-lint` | `helm lint` + `helm template` with `values-prod.yaml` | chart must render |
| `build-and-push` | buildx + QEMU, both Dockerfiles for `linux/amd64,linux/arm64`, pushed to GHCR as `sha-<7>` **and** `latest`, GHA layer cache | needs all four gates green |
| `image-scan` (matrix backend/frontend) | trivy full report, then trivy with `--severity HIGH,CRITICAL --ignore-unfixed --exit-code 1` | fails the pipeline on a fixable HIGH/CRITICAL |
| `deploy` | writes the new `sha-` tag into `helm/studytrack/values.yaml` and commits it back (`[skip ci]`) – Argo CD does the rest (M10) | – |

The multi-arch build matters here: GitHub runners are amd64 and my kind cluster is arm64 (Apple Silicon). The first image I pushed was amd64-only and the pods would have died with `exec format error`.

Run history, in order (every red one taught me something):

* https://github.com/kushaltalati/devops-heros/actions/runs/37660923678 – failed at parse time: a step name containing a colon was not quoted.
* https://github.com/kushaltalati/devops-heros/actions/runs/37661287105 – **blocked by the SCA gate**: `pip-audit` found 10 known vulnerabilities in `starlette 0.50.0` (PYSEC-2026-161/248/249/2280/2281, fixed in 1.3.1). Nothing was built or pushed. Fix: FastAPI 0.142 + `starlette>=1.3.1`; that in turn forced me to drop `prometheus-fastapi-instrumentator` (pinned to starlette <1.0) for my own 40-line middleware in [`metrics.py`](backend/app/metrics.py). Log [40](docs/outputs/40-ci-run-blocked-by-sca.txt).
* two runs where the trivy marketplace action could not be resolved / could not download its binary – replaced with `docker run aquasec/trivy:0.65.0`.
* https://github.com/kushaltalati/devops-heros/actions/runs/37665794354 – **green**: all gates, images `sha-ada2a45` on GHCR, trivy clean for both images, `deploy` committed the tag bump and Argo CD rolled it out (log [54](docs/outputs/54-gitops-rollout.txt)).

Images (both multi-arch, tag = git sha + `latest`): `ghcr.io/kushaltalati/studytrack-backend`, `ghcr.io/kushaltalati/studytrack-frontend` – package pages under https://github.com/kushaltalati?tab=packages. GHCR packages are private by default; the cluster pulls them with a `kubernetes.io/dockerconfigjson` Secret `ghcr-pull` that I created out of band with `kubectl create secret docker-registry` (never committed; the chart only references its name).

## M6 – DevSecOps

Logs: [06-trivy-local-images.txt](docs/outputs/06-trivy-local-images.txt), [07-sast-local.txt](docs/outputs/07-sast-local.txt), [40-ci-run-blocked-by-sca.txt](docs/outputs/40-ci-run-blocked-by-sca.txt) and the `image-scan` jobs in the green run.

Trivy scans both images after they are pushed, twice: one full report that never fails (so the complete list is in the log) and one gate that exits 1 on HIGH/CRITICAL with a fix available (`--ignore-unfixed`, because a CVE with no patched package yet can only be noted, not fixed). Result on the final images:

```text
$ trivy image --severity HIGH,CRITICAL --ignore-unfixed studytrack-backend     studytrack-backend (debian 13.7)   Total: 0
$ trivy image --severity HIGH,CRITICAL --ignore-unfixed studytrack-frontend    studytrack-frontend (alpine 3.24.2)   Total: 0
```

What Trivy scanned and what it found: it reads the OS package database of each image (dpkg for the Debian-based python image, apk for the nginx alpine image) and compares the installed versions with the vulnerability databases. The first frontend image, on `nginx-unprivileged:1.27-alpine` (alpine 3.21.3), came back with **42 HIGH/CRITICAL fixable CVEs** (40 HIGH, 2 CRITICAL), all in alpine base packages such as `libcrypto3`/`libssl3`/`busybox`, not in my code. Moving to `stable-alpine` (alpine 3.24.2) removed every one of them – that is exactly the kind of fix the gate is there to force. The backend image on `python:3.12-slim` (Debian 13.7) was clean from the start. In the green run the full (non-gating) report still lists 6 LOW/MEDIUM findings for the backend and 1 MEDIUM for the frontend with no HIGH/CRITICAL, so the gate passed; those are the ones to watch in the next base-image bump.

The rest of the chain: bandit + semgrep (SAST, static analysis of the Python source), pip-audit + npm audit (SCA, known CVEs in dependencies – this is the gate that really fired, see M5), gitleaks (secrets in history and tree; local run: `no leaks found`). Semgrep is also why the API has no wildcard CORS any more: origins are an explicit env var and the middleware is only added when it is set.

## M7 – Terraform (infrastructure as code)

Logs: [20-init-validate](docs/outputs/20-terraform-init-validate.txt), [21-plan](docs/outputs/21-terraform-plan.txt), [22-apply-output-show](docs/outputs/22-terraform-apply-output.txt), [23-aws-cli-verify](docs/outputs/23-aws-cli-verify-localstack.txt), [24-plan-with-eks](docs/outputs/24-terraform-plan-with-eks.txt), [25-destroy](docs/outputs/25-terraform-destroy.txt)

**Where it ran, honestly.** The AWS access key on this laptop is no longer valid (`aws sts get-caller-identity` → `InvalidClientTokenId`) and I did not want to create a new paid account for the assignment, so the apply/destroy cycle ran against **LocalStack** (AWS API emulator, `localstack/localstack:4.0.3` in Docker on `localhost:4566`). The Terraform code itself is plain AWS-provider HCL: [`providers.tf`](terraform/providers.tf) only switches the endpoints, dummy keys and `skip_*` flags on when `var.aws_endpoint_url` is set, so the same files work against a real account by leaving that variable empty and letting `aws configure` supply credentials. The `AWS Console` screenshots the rubric asks for are therefore replaced by `aws --endpoint-url` CLI output against LocalStack.

What the project creates ([`main.tf`](terraform/main.tf)):

```text
aws_vpc.main                       10.42.0.0/16, DNS support + hostnames
aws_subnet.public[0..1]            10.42.1.0/24 (az a), 10.42.2.0/24 (az b), public IPs, tagged for EKS (kubernetes.io/cluster/..., role/elb)
aws_internet_gateway.main
aws_route_table.public + 2 associations   0.0.0.0/0 -> igw
aws_security_group.web             80/443 in, all out
aws_s3_bucket.backups              studytrack-24bcs10123-backups-dev, versioning on, public access blocked, force_destroy
aws_s3_object.readme               a marker object
module.eks (count = var.create_eks ? 1 : 0)   IAM roles + aws_eks_cluster + aws_eks_node_group
```

```text
$ terraform init -input=false         Terraform has been successfully initialized!
$ terraform fmt -check -recursive && terraform validate     Success! The configuration is valid.
$ terraform plan -var-file=localstack.tfvars -out=tfplan    Plan: 12 to add, 0 to change, 0 to destroy.
$ terraform apply tfplan                                    Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

$ terraform output
backup_bucket         = "studytrack-24bcs10123-backups-dev"
eks_cluster_name      = "not created (create_eks=false)"
public_subnet_ids     = ["subnet-0fe094cb", "subnet-291d6d0a"]
vpc_id                = "vpc-98e2ca57"
web_security_group_id = "sg-244bdadd7db034858"

$ aws --endpoint-url=http://localhost:4566 ec2 describe-subnets ...      # two 10.42.x.0/24 subnets in us-east-1a / us-east-1b
$ aws --endpoint-url=http://localhost:4566 s3 ls s3://studytrack-24bcs10123-backups-dev/
2026-10-07 23:12:21   76 README.txt

$ terraform destroy -auto-approve -var-file=localstack.tfvars   Destroy complete! Resources: 12 destroyed.
$ terraform state list                                          (empty)
```

**EKS.** LocalStack's free edition has no EKS API, so the cluster + managed node group live in [`modules/eks`](terraform/modules/eks) behind `create_eks` (default `false`, because a real EKS control plane costs money the moment it exists). `terraform validate` covers the module and `terraform plan -var create_eks=true` renders it: 8 more resources (2 IAM roles, 4 policy attachments, `aws_eks_cluster.main`, `aws_eks_node_group.default` with `t3.medium`, desired 2 / min 1 / max 3) – log [24](docs/outputs/24-terraform-plan-with-eks.txt). On a real account the full stack is `terraform apply -var create_eks=true`, then `aws eks update-kubeconfig` and the same Helm chart below. [`terraform.tfvars.example`](terraform/terraform.tfvars.example) documents the inputs; no credentials are in the repo (the LocalStack run uses the literal keys `test`/`test`).

## M8 – Kubernetes + Helm

Logs: [30-namespace.txt](docs/outputs/30-namespace.txt), [50-helm-install.txt](docs/outputs/50-helm-install.txt), [51-k8s-verify.txt](docs/outputs/51-k8s-verify.txt), [52-hpa-load-test.txt](docs/outputs/52-hpa-load-test.txt) · screenshot [10-ingress-studytrack-local.png](screenshots/10-ingress-studytrack-local.png)

Chart [`helm/studytrack/`](helm/studytrack): `Chart.yaml`, `values.yaml` (+ `values-dev.yaml`, `values-prod.yaml`), templates for ConfigMap, Secret (`DATABASE_URL`, postgres credentials – `stringData`, lab password, clearly marked), PVC + postgres Deployment (`Recreate` strategy: one writer per volume) + Service, backend Deployment (startup/readiness/liveness probes, `runAsNonRoot`, resources, config checksum annotation so a ConfigMap change rolls the pods) + Service, frontend Deployment + Service, Ingress (`/api` → backend, `/` → frontend, host `studytrack.local`), HPA (cpu 50%, 2–6, 60s scale-down window), ServiceMonitor (`release: kube-prometheus-stack` label). `imagePullSecrets` is a value.

```text
$ helm upgrade --install studytrack helm/studytrack -n studytrack --set image.tag=sha-da417a0 --wait --timeout 10m
Release "studytrack" does not exist. Installing it now.
STATUS: deployed   REVISION: 1

$ helm list -n studytrack
NAME        NAMESPACE   REVISION  STATUS    CHART             APP VERSION
studytrack  studytrack  1         deployed  studytrack-0.1.0  0.1.0

$ kubectl -n studytrack get pods -o wide
studytrack-backend-...    1/1  Running  kushal-lab-worker2
studytrack-backend-...    1/1  Running  kushal-lab-worker
studytrack-frontend-...   1/1  Running  kushal-lab-worker
studytrack-frontend-...   1/1  Running  kushal-lab-worker2
studytrack-postgres-...   1/1  Running  kushal-lab-worker2

$ kubectl -n studytrack get svc
studytrack-backend    ClusterIP   10.96.197.64   8000/TCP
studytrack-frontend   ClusterIP   10.96.55.87    80/TCP
studytrack-postgres   ClusterIP   10.96.37.24    5432/TCP

$ kubectl -n studytrack get ingress
studytrack   nginx   studytrack.local   localhost   80

$ kubectl -n studytrack get pvc
studytrack-pgdata   Bound   pvc-16736d3d-...   1Gi   RWO   standard

$ curl -s -H 'Host: studytrack.local' http://localhost/api/entries/summary
{"total_entries":5,"total_minutes":270,"done_minutes":195,"daily_goal_minutes":120,"goal_reached":true,...}
$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' -H 'Host: studytrack.local' http://localhost/
HTTP 200
```

The backend pods restarted twice or three times during the very first install: PostgreSQL was still initialising its data directory, `alembic upgrade head` failed on connection refused, the container exited and kubelet restarted it with back-off (log [51](docs/outputs/51-k8s-verify.txt) has the previous-container log). Harmless, but ugly, so the entrypoint now retries the migration for up to a minute – the change that went through the pipeline as the live demo in M10.

**HPA.** [`scripts/load-test.sh`](scripts/load-test.sh) fires 16 parallel `curl` loops at `/api/entries/summary` through the Ingress for 180s:

```text
$ kubectl -n studytrack get hpa studytrack-backend -w
NAME                 REFERENCE                       TARGETS        MINPODS   MAXPODS   REPLICAS
studytrack-backend   Deployment/studytrack-backend   cpu: 4%/50%    2         6         2
studytrack-backend   Deployment/studytrack-backend   cpu: 242%/50%  2         6         2
studytrack-backend   Deployment/studytrack-backend   cpu: 463%/50%  2         6         6
studytrack-backend   Deployment/studytrack-backend   cpu: 160%/50%  2         6         6
...
studytrack-backend   Deployment/studytrack-backend   cpu: 11%/50%   2         6         6      <- load stopped, 60s stabilisation before scale-down
  Normal  SuccessfulRescale  horizontal-pod-autoscaler  New size: 6; reason: cpu resource utilization (percentage of request) above target
```

Four extra pods appeared within one HPA sync period, and `kubectl top pods` showed each backend at 120–130m against a 100m request. Scale-down back to 2 happened after the load (default 5-minute scale-down window had been shortened to 60s in the HPA `behavior`).

## M9 – Observability (Prometheus + Grafana)

Logs: [60-prometheus-targets-and-queries.txt](docs/outputs/60-prometheus-targets-and-queries.txt), [61-grafana-dashboard.txt](docs/outputs/61-grafana-dashboard.txt) · files: [`monitoring/prometheus-values.yaml`](monitoring/prometheus-values.yaml) (kube-prometheus-stack values, cross-namespace selectors on), [`monitoring/prometheusrule.yaml`](monitoring/prometheusrule.yaml), [`monitoring/grafana-dashboard-studytrack.json`](monitoring/grafana-dashboard-studytrack.json), [`scripts/prom-queries.sh`](scripts/prom-queries.sh)

`/metrics` ([`metrics.py`](backend/app/metrics.py)) exposes `http_requests_total{method,handler,status}`, `http_request_duration_seconds` histogram, two business counters (`studytrack_entries_created_total{subject}`, `studytrack_minutes_logged_total`) and the default process metrics. The `handler` label is the route template, not the raw path, so ids do not explode the cardinality. The chart's ServiceMonitor is picked up by the Prometheus Operator; the Targets page shows both backend pods `up`:

```text
$ curl -s localhost:21090/api/v1/targets?state=active | ...
  job=studytrack-backend pod=studytrack-backend-5f8784687-sl7l8 url=http://10.244.1.78:8000/metrics health=up
  job=studytrack-backend pod=studytrack-backend-5f8784687-22kc5 url=http://10.244.3.104:8000/metrics health=up

$ scripts/prom-queries.sh          (during a 70s load test)
# requests per second by handler    sum by (handler) (rate(http_requests_total{job="studytrack-backend"}[1m]))
  handler=/api/entries/summary => 38.88
# p95 latency (s)                   histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
   => 0.198
# entries created, by subject       subject=DevOps => 2, subject=DBMS => 1, subject=Operating Systems => 1, subject=Computer Networks => 1
# minutes logged                     => 270
# backend cpu (cores) per pod       pod=studytrack-backend-...-sl7l8 => 0.128   pod=...-22kc5 => 0.124
# hpa current replicas               => 2
```

Three alert rules ([`prometheusrule.yaml`](monitoring/prometheusrule.yaml)): backend target down, 5xx ratio above 5%, p95 above 500ms – all `inactive / health=ok` while the app is healthy.

Grafana (admin password in the values file, lab only) got the dashboard JSON imported through its API (`POST /api/dashboards/db` → `"status":"success"`, uid `studytrack`, 8 panels: targets up, req/s, p95, minutes logged, req/s by handler, status codes, CPU vs HPA replicas, memory). Querying the "HTTP requests / s by handler" panel through `/api/ds/query` returned 17 points for `/api/entries/summary` peaking at 174 req/s during the load test, and the p95 panel 0.14 s – so the panels are populated with live application metrics, not just installed. I did not manage a browser screenshot of Grafana (headless Chrome cannot get past the login form without a session); the API responses in log [61](docs/outputs/61-grafana-dashboard.txt) are the evidence, and the dashboard is reachable at `http://localhost:21300/d/studytrack` after `kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 21300:80`.

## M10 – GitOps demo (Argo CD) and documentation

Logs: [53-argocd-sync-and-selfheal.txt](docs/outputs/53-argocd-sync-and-selfheal.txt), [54-gitops-rollout.txt](docs/outputs/54-gitops-rollout.txt)

CI cannot reach a kind cluster on my laptop, so "deploy to Kubernetes" is done the GitOps way: the pipeline's last job edits `image.tag` in `helm/studytrack/values.yaml` and commits, and Argo CD ([`gitops/argocd-application.yaml`](gitops/argocd-application.yaml), `automated` sync with `prune` and `selfHeal`) watches `capstone-kushal-s21:session21-python/kushal-24bcs10123/helm/studytrack` and applies whatever is there. To hand over cleanly I `helm uninstall`ed the manual release first; Argo CD recreated every object from git within a minute:

```text
$ kubectl apply -f gitops/argocd-application.yaml
application.argoproj.io/studytrack created
$ kubectl -n argocd get application studytrack
NAME         SYNC STATUS   HEALTH STATUS
studytrack   Synced        Healthy
  ConfigMap/studytrack-config  Synced   PersistentVolumeClaim/studytrack-pgdata  Synced   Secret/studytrack-db-secret  Synced
  Service/{backend,frontend,postgres}  Synced   Deployment/{backend,frontend,postgres}  Synced
  HorizontalPodAutoscaler/studytrack-backend  Synced   ServiceMonitor/studytrack-backend  Synced   Ingress/studytrack  Synced
```

Self-heal: `kubectl scale deploy studytrack-frontend --replicas=5` was reverted to the 2 replicas in git without me doing anything (checked every 5s, reverted within about 2 minutes, Argo CD's default 3-minute reconcile window).

**Live demo (commit → pipeline → deployment update).** The commit that added the migration retry loop to `entrypoint.sh` went through the whole pipeline (https://github.com/kushaltalati/devops-heros/actions/runs/37665794354); the `deploy` job committed `tag: sha-ada2a45`, Argo CD noticed the new revision and rolled both Deployments to the new image:

```text
$ git log --oneline -2 origin/capstone-kushal-s21
58f742e deploy: studytrack image sha-ada2a45 [skip ci]          <- written by the pipeline
ada2a45 studytrack: retry migrations while postgres starts, ...  <- my commit

$ kubectl -n argocd get application studytrack -o jsonpath='{range .status.history[*]}{.id} {.deployedAt} {.revision}{"\n"}{end}'
0 2026-10-07T18:15:49Z 676c5cd3...   first sync (image tag latest)
1 2026-10-07T18:23:41Z 58f742e1...   the deploy commit, picked up automatically

$ kubectl -n studytrack get deploy -o custom-columns='NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image,READY:.status.readyReplicas'
NAME                  IMAGE                                                  READY
studytrack-backend    ghcr.io/kushaltalati/studytrack-backend:sha-ada2a45    2
studytrack-frontend   ghcr.io/kushaltalati/studytrack-frontend:sha-ada2a45   2
studytrack-postgres   postgres:16-alpine                                     1

$ kubectl -n studytrack get events --sort-by=.lastTimestamp | grep -E 'ScalingReplicaSet|Pulled' | tail -4
Pulled             pod/studytrack-backend-97c8bb58c-twmv4   Successfully pulled image "ghcr.io/kushaltalati/studytrack-backend:sha-ada2a45"
ScalingReplicaSet  deployment/studytrack-frontend           Scaled up replica set studytrack-frontend-f9479c859 from 1 to 2
ScalingReplicaSet  deployment/studytrack-backend            Scaled down replica set studytrack-backend-5f8784687 from 1 to 0

$ kubectl -n studytrack logs deploy/studytrack-backend | head -3
[entrypoint] migrations applied, starting uvicorn            <- the new entrypoint message: the new image is live
$ curl -s -H 'Host: studytrack.local' http://localhost/api/entries/summary
{"total_entries":5,"total_minutes":270,"done_minutes":195,...}   <- data survived the rollout (PVC)
```

## Troubleshooting exercises

Logs: [31](docs/outputs/31-troubleshoot-imagepullbackoff.txt), [32](docs/outputs/32-troubleshoot-service-no-endpoints.txt), [33](docs/outputs/33-troubleshoot-not-ready-bad-config.txt) · manifests in [`troubleshooting/`](troubleshooting)

| # | Symptom | How I found it | Root cause | Fix | Verified |
|---|---|---|---|---|---|
| 1 `broken-image.yaml` | pod `ErrImagePull` → `ImagePullBackOff`, 0/1 | `kubectl describe pod` events: `manifest unknown` from ghcr.io; `kubectl logs` empty (never started) | tag `does-not-exist` is not in the registry | `kubectl set image ... :sha-da417a0` | `rollout status` → successfully rolled out, pod 1/1 |
| 2 `broken-service.yaml` | `curl http://broken-service:8080` from a pod → exit 000 | `kubectl get endpointslices -l kubernetes.io/service-name=broken-service` → no endpoints; `describe svc` shows selector `app=label-that-does-not-exist`; `get pods --show-labels` shows the real label | selector matches no pod (and targetPort 8080 vs container port 80) | `kubectl patch svc` selector + targetPort | endpoints populated, `curl` → HTTP 200 `Welcome to nginx!` |
| 3 `broken-config.yaml` (mine) | pod `Running` but `0/1`, never Ready, no restarts | `describe pod`: `Readiness probe failed: HTTP 503`; `/health` 200 but `/ready` → `{"status":"not_ready","database":"down"}`; env shows `DATABASE_URL` host `no-such-db`; `getent hosts no-such-db` fails | configuration error, not code: wrong DB host, liveness is fine so kubelet never restarts it, readiness keeps it out of the Service | `kubectl set env --from=secret/studytrack-db-secret --keys=DATABASE_URL` | pod 1/1, rollout complete |

The process was always the same: `get` → `describe` (events) → `logs` → `exec` into the pod → find the root cause → change one thing → verify. Scenario 3 is the one that taught me most: a wrong probe design would have hidden it (if readiness had only checked `/health`, the broken pod would have received traffic and returned 500s).

## How to run it yourself

```bash
# local
docker compose up --build            # http://localhost:3000  (API: http://localhost:8000/docs)
cd backend && python -m venv .venv && .venv/bin/pip install -r requirements-dev.txt && .venv/bin/pytest -v

# kubernetes (needs metrics-server, ingress-nginx, kube-prometheus-stack, a ghcr pull secret named ghcr-pull)
kubectl apply -f k8s/namespace.yaml
helm upgrade --install studytrack helm/studytrack -n studytrack --set image.tag=sha-ada2a45
curl -H 'Host: studytrack.local' http://localhost/api/entries/summary
scripts/load-test.sh 180 16 ; kubectl -n studytrack get hpa -w

# gitops
kubectl apply -f gitops/argocd-application.yaml

# infrastructure (LocalStack: docker run -d -p 4566:4566 localstack/localstack:4.0.3)
cd terraform && terraform init && terraform apply -var-file=localstack.tfvars && terraform destroy -var-file=localstack.tfvars
```

## Checklist (rubric)

- [x] Application runs via `docker compose up --build`; 7 REST endpoints (GET list/one/summary, POST, PUT, DELETE); Alembic migration `0001`
- [x] 11 pytest cases, SQLite test DB, `pytest.ini` + `conftest.py`
- [x] public repo, 20 meaningful commits, `.gitignore` covers env/pycache/node_modules/venv
- [x] backend Dockerfile builds; frontend multi-stage (node → nginx); both non-root (uid 10001 / 101); compose starts all three services
- [x] workflow present, pytest job gates everything, frontend built in the pipeline (inside the Docker build), both images built and pushed to GHCR with `sha-` tags
- [x] trivy on both images, fails on HIGH/CRITICAL; one CVE set explained (alpine 3.21 base, 42 findings, fixed by the base bump); SAST/SCA/secret scan too, with a real SCA block
- [x] terraform init/fmt/validate/plan/apply/show/output/destroy logged; VPC with two public subnets; EKS module validated and planned (`create_eks=true`), not applied – LocalStack, see M7; `terraform.tfvars.example`, no credentials
- [x] `k8s/namespace.yaml`; Helm chart; `helm upgrade --install` ok; 2 replicas each; ClusterIP services; Ingress `/`→frontend `/api`→backend; all pods Running; HPA scaled 2→6 under load
- [x] `/metrics` Prometheus format; Prometheus scraping via ServiceMonitor (targets `up`); Grafana dashboard imported and panels return live data; alert rules loaded
- [x] README (this file); live demo = commit → green pipeline → tag bump → Argo CD rollout; three troubleshooting scenarios with before/after

## What I understood

* **Gates only matter if they can say no.** The SCA job really blocked a run, and the fix was not "add an ignore" but upgrading the framework and dropping a library. The trivy gate forced a base-image bump. Both would have shipped silently without the pipeline.
* **CI builds, GitOps deploys.** The runner never gets a kubeconfig. It changes one line in git; Argo CD, which already has access to the cluster, does the apply, and it also undoes drift (`selfHeal`) and deletes what git deleted (`prune`). The git history is the deployment log.
* **Readiness and liveness answer different questions.** `/health` = "restart me?", `/ready` = "send me traffic?". Scenario 3 shows a pod that is alive and useless at the same time, and the Service correctly ignores it. The startup probe is what stops a slow first boot (migrations) from being killed by liveness.
* **Tags are deployments.** `latest` tells you nothing; `sha-da417a0` tells you which commit is running, and HPA/Argo/`kubectl rollout` all become reproducible.
* **Non-root and multi-arch are not optional details.** nginx on 8080 as uid 101, uvicorn as uid 10001; and an image built on an amd64 runner has to be built for the arm64 nodes it will run on.
* **Infrastructure code must be portable to be testable.** The same Terraform ran against LocalStack with one variable flipped; the EKS part could only be planned, and saying so is better than a screenshot I do not have.

