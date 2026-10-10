# Session 21 - LabTrack DevOps capstone

LabTrack is my final course project. I built it as a small journal for planning and recording hands-on DevOps labs. It is a different application domain from the instructor's reference project while using the same DevOps ideas taught in the course.

The React interface talks to a FastAPI REST API. PostgreSQL stores the labs, and the API exposes health checks and Prometheus metrics. I can run the full application with Docker Compose or package it for Kubernetes with Helm.

## What the application does

A lab has a title, objective, tool, difficulty, owner, and status. The available tools are Docker, Kubernetes, Terraform, CI/CD, and Monitoring. From the interface I can:

- add a new lab;
- view and filter labs;
- move a lab through PLANNED, RUNNING, and COMPLETED;
- delete a lab;
- see live counts from PostgreSQL.

The same operations are available through Swagger at http://localhost:8000/docs.

## Architecture

~~~text
Developer -> GitHub Actions -> tests -> security scans -> container images -> GHCR
                                                                    |
                                                                    v
Browser -> Nginx frontend -> FastAPI backend -> PostgreSQL       Kubernetes
                              |                                     |
                              +-> /metrics -> Prometheus -> Grafana  +-> Ingress + HPA
~~~

## Project layout

| Path | Purpose |
|---|---|
| [frontend/](frontend/) | React/Vite interface and non-root Nginx image |
| [backend/](backend/) | FastAPI, SQLAlchemy, Alembic, PostgreSQL, and pytest |
| [docker-compose.yml](docker-compose.yml) | Local frontend, backend, and database |
| [helm/labtrack/](helm/labtrack/) | Deployments, Services, Ingress, HPA, probes, ConfigMap, Secret, and PVC |
| [terraform/](terraform/) | AWS VPC, public/private subnets, EKS, and managed nodes |
| [monitoring/](monitoring/) | Prometheus and provisioned Grafana dashboard |
| [gitops/](gitops/) | Argo CD Application for the Helm release |
| [troubleshooting/](troubleshooting/) | Broken image and broken Service exercises |

## 1. Backend tests

The test database is SQLite, so the tests are isolated from the development PostgreSQL database. Eight tests cover health, readiness, create, list, get, update, delete, validation, and statistics.

~~~bash
cd session21-final-devops-project/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest -v
~~~

![Eight backend tests passing](evidence/labtrack-pytest.png)

## 2. Run the application locally

~~~bash
cd session21-final-devops-project
docker compose up --build -d
docker compose ps
curl -fsS http://localhost:8000/health
curl -fsS http://localhost:8000/ready
~~~

Open:

- application: http://localhost:3000
- Swagger: http://localhost:8000/docs
- metrics: http://localhost:8000/metrics

This is the final LabTrack interface connected to the running API and database.

![LabTrack running locally](evidence/labtrack-live-application.png)

Swagger shows the CRUD endpoints under /api/labs.

![LabTrack Swagger API](evidence/labtrack-swagger-crud.png)

I checked the saved rows directly in PostgreSQL:

~~~bash
docker compose exec postgres psql -U labtrack -d labtrack \
  -c "select id,title,tool,difficulty,status,owner from labs order by id;"
~~~

![Lab data in PostgreSQL](evidence/labtrack-postgres-data.png)

## 3. Container checks

The backend image uses UID 10001. The frontend is a multi-stage build and serves the compiled React files with the unprivileged Nginx image as UID 101.

~~~bash
docker image inspect labtrack-backend --format '{{.Config.User}}'
docker image inspect labtrack-frontend --format '{{.Config.User}}'
docker compose ps
~~~

![Running containers and non-root users](evidence/labtrack-containers.png)

## 4. CI/CD and security

The Session 21 workflow:

1. runs the eight backend tests;
2. builds the React frontend;
3. runs Bandit, pip-audit, and Gitleaks;
4. lints and renders the Helm chart;
5. builds both container images and confirms their non-root users;
6. scans both images with Trivy and fails on fixed HIGH or CRITICAL findings;
7. pushes immutable commit-SHA tags and latest tags to GHCR;
8. deploys to a temporary Kind cluster and runs an HTTP smoke test.

The workflow file is [.github/workflows/session21-final-project.yml](../.github/workflows/session21-final-project.yml).

![Session 21 GitHub Actions workflow](evidence/labtrack-github-actions.png)

![LabTrack images in GHCR](evidence/labtrack-ghcr-images.png)

Trivy is configured with severity HIGH,CRITICAL, ignore-unfixed enabled, and exit code 1 for both images. This blocks delivery when a fixable serious vulnerability is present instead of only printing a warning.

![Trivy scans for both images](evidence/labtrack-trivy-scans.png)

## 5. Kubernetes and Helm

The chart creates two frontend replicas, two backend replicas, PostgreSQL, ClusterIP Services, probes, resource limits, an optional Ingress, and an HPA.

~~~bash
helm lint helm/labtrack

helm upgrade --install labtrack helm/labtrack \
  --namespace labtrack --create-namespace \
  -f helm/labtrack/values-dev.yaml

kubectl rollout status deployment/labtrack-labtrack-backend -n labtrack
kubectl rollout status deployment/labtrack-frontend -n labtrack
kubectl get pods,svc,ingress,pvc,hpa -n labtrack
helm list -n labtrack
~~~

![LabTrack Helm release and Kubernetes resources](evidence/labtrack-kubernetes-resources.png)

For local browser access without changing DNS:

~~~bash
kubectl port-forward service/frontend -n labtrack 8080:80
~~~

Then open http://localhost:8080.

## 6. Monitoring

FastAPI exports Prometheus metrics at /metrics. The chart includes a ServiceMonitor for kube-prometheus-stack. For a free local demonstration I also provisioned Prometheus and Grafana with Docker Compose:

~~~bash
cd monitoring
docker compose up -d
curl -fsS http://localhost:9091/-/ready
curl -fsS http://localhost:3001/api/health
~~~

Prometheus scrapes the running LabTrack backend every five seconds. Grafana loads the data source and dashboard automatically from this repository.

![Prometheus target is up](evidence/labtrack-prometheus-target.png)

![Live LabTrack Grafana dashboard](evidence/labtrack-grafana-dashboard.png)

## 7. Troubleshooting

The two files under [troubleshooting/](troubleshooting/) reproduce common failures:

- broken-image.yaml produces ImagePullBackOff because the image tag does not exist;
- broken-service.yaml creates an empty EndpointSlice because its selector matches no Pod.

I first inspect the status, events, labels, and EndpointSlices, then correct the image or selector and repeat the request.

![Broken image diagnosis and recovery](evidence/labtrack-broken-image.png)

![Broken Service diagnosis and recovery](evidence/labtrack-broken-service.png)

## 8. Terraform

The Terraform code defines an AWS VPC across two Availability Zones, two public subnets, two private subnets, a NAT gateway, EKS, and a managed node group.

~~~bash
cd terraform
terraform init
terraform fmt -check
terraform validate
terraform plan
~~~

[terraform.tfvars.example](terraform/terraform.tfvars.example) documents the inputs without storing credentials.

I did not run terraform apply because this account has no AWS credits and EKS, worker nodes, and NAT Gateway incur charges. The code can be initialized and validated locally, but real AWS console, EKS, and terraform destroy screenshots require a funded AWS account.

![Terraform initialization and validation](evidence/labtrack-terraform-validate.png)

## 9. GitOps

[gitops/application.yaml](gitops/application.yaml) is an Argo CD Application that watches the LabTrack Helm chart on main. Automated pruning and self-healing are enabled. This lets Git remain the desired state for the cluster.

## Result

The free local parts of the capstone are reproducible from this repository: the application, CRUD API, tests, containers, CI/security workflow, GHCR delivery, Helm deployment, HPA definition, monitoring, GitOps manifest, and troubleshooting labs. The only unfinished graded evidence is the paid AWS apply/destroy portion.
