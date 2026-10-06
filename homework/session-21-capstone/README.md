# Session 21 — Final project

Student: Viraj Bhanage, roll 24BCS10274  
Enrollment number: `24BCS10274`

The capstone application is **TaskBoard** in [`session21-python`](../../session21-python). It already contains the application, Dockerfiles, Compose file, tests, Terraform for VPC and EKS, Helm chart, Kubernetes namespace, monitoring values, and the troubleshooting manifests. The root workflow [`.github/workflows/taskboard-ci.yml`](../../.github/workflows/taskboard-ci.yml) is what GitHub will run, because Actions ignores workflows nested inside `session21-python/.github`.

## How the pieces map

| Homework folder | Where it is |
|---|---|
| application | `session21-python/frontend`, `session21-python/backend` |
| docker | `frontend/Dockerfile`, `backend/Dockerfile`, `docker-compose.yml` |
| kubernetes | `session21-python/k8s`, Helm templates |
| helm | `session21-python/helm/taskboard` |
| terraform | `session21-python/terraform` |
| CI | `.github/workflows/taskboard-ci.yml` |
| security | Trivy steps in that workflow |
| monitoring | `session21-python/monitoring` plus `/metrics` |
| gitops | Session 20 Argo CD example, path `session21-python/helm/taskboard` |

## Troubleshooting challenge

`session21-python/troubleshooting/broken-image.yaml` sets the image to `ghcr.io/example/taskboard-backend:does-not-exist`. The Pod stays in `ImagePullBackOff`. `kubectl describe pod` shows the pull error. The fix is the real GHCR image tag from the pipeline (`github.sha`).

`broken-service.yaml` selects `app: label-that-does-not-exist`. The Service has no endpoints, so traffic never reaches a Pod. `kubectl get endpoints broken-service -n taskboard` is empty. The fix is the real app label used by the Helm chart.

For each one: describe the object, name the root cause, apply the corrected manifest, and show the Pod `Running` or the endpoints populated.

## What still needs your screenshots

The grading rubric in `session21-python/GRADING.md` wants pictures of a running system. Those cannot be invented here. Capture:

1. Browser on the TaskBoard UI (`docker compose up --build`, then `http://localhost:3000`).
2. `pytest -v` with the tests passing.
3. At least 10 meaningful commits. The homework commit is one of them. Make small follow-up commits as you add screenshots.
4. Actions run URL, green or with the Trivy log explained.
5. GHCR packages tagged with the commit SHA.
6. `terraform plan` for `session21-python/terraform`, then the VPC and EKS console, then `terraform destroy`.
7. `kubectl get pods -n taskboard`, `kubectl get svc -n taskboard`, `helm list -n taskboard`, and the Ingress in a browser.
8. `/metrics`, a Prometheus target that is UP, and a Grafana panel.

Do not commit AWS keys, kubeconfigs, or `.env` files.
