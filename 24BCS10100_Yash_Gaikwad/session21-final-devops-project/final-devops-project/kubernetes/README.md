# kubernetes/

The Kubernetes objects of the application (Deployments, Services, ConfigMap, Secret, Ingress, HPA, probes, storage, PodDisruptionBudgets) are written **once, as templates, in the Helm chart** [`../helm/stockpilot`](../helm/stockpilot). This folder holds what sits around the chart.

| File | Purpose |
|---|---|
| [`namespace.yaml`](namespace.yaml) | the `stockpilot` namespace (apply it first) |
| [`storageclass-gp3.yaml`](storageclass-gp3.yaml) | an EBS gp3 StorageClass for EKS (Minikube already has a default `standard` class) |
| [`troubleshooting/broken-image.yaml`](troubleshooting/broken-image.yaml) | a deliberately broken Deployment (bad image) for the troubleshooting lab |
| [`troubleshooting/broken-service.yaml`](troubleshooting/broken-service.yaml) | a deliberately broken Service (selector that matches nothing) |

Where each required object is defined:

| Required | Defined in | Notes |
|---|---|---|
| Deployment | `helm/stockpilot/templates/backend-deployment.yaml`, `frontend-deployment.yaml` | 2 replicas each, rolling update, anti-affinity, non-root, read-only root filesystem |
| StatefulSet (database) | `templates/postgres.yaml` | PostgreSQL with a volume claim |
| Service | `backend-service.yaml`, `frontend-service.yaml`, `postgres.yaml` | ClusterIP |
| ConfigMap | `templates/configmap.yaml` | the frontend's `BACKEND_URL` |
| Secret | `templates/secret.yaml` | database credentials, generated at install time, never stored in Git |
| Ingress | `templates/ingress.yaml` | `/api`, `/docs`, `/openapi.json` to the backend, `/` to the frontend |
| HPA | `templates/hpa.yaml` | backend 2 to 6 replicas at 50% CPU |
| Probes | in each workload template | startup (backend), liveness, readiness |
| Storage | `templates/postgres.yaml` (volumeClaimTemplates) | dynamic provisioning through the StorageClass |
| PodDisruptionBudget | `templates/poddisruptionbudgets.yaml` | keeps at least one replica during node drains |

Render the plain manifests at any time (they are not stored in Git, because the Secret is generated):

```bash
helm template stockpilot ../helm/stockpilot -n stockpilot -f ../helm/stockpilot/values-dev.yaml
```
