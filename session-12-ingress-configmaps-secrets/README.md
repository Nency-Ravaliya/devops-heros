# Session 12: Ingress, ConfigMaps & Secrets

## Assignment map

| Requirement | Implementation | Evidence |
|---|---|---|
| ConfigMap | [`01-configmap/`](01-configmap/) and [`04-full-demo/configmap.yaml`](04-full-demo/configmap.yaml) | Values injected into the backend container ([screenshot](screenshots/configmap-secret.png)) |
| Secret | [`02-secret/`](02-secret/) and [`04-full-demo/secret.yaml`](04-full-demo/secret.yaml) | Secret-backed application values verified without printing the password ([screenshot](screenshots/configmap-secret.png)) |
| Ingress | [`03-ingress/`](03-ingress/) and [`04-full-demo/ingress.yaml`](04-full-demo/ingress.yaml) | Frontend HTTP 200 and `/api/` routing ([screenshot](screenshots/ingress-working.png)) |
| Ingress vs controller | [Explanation in the lab guide](lab.md) | NGINX Ingress Controller used in Minikube |
| Troubleshooting | [`troubleshooting/README.md`](troubleshooting/README.md) | Trailing-newline Secret bug reproduced and corrected without printing the password ([before/after evidence](screenshots/secret-troubleshooting-before-after.png)) |

Secrets in this training repository contain demonstration-only values. Real passwords should be supplied by a secret manager or CI secret store and should never be committed to Git.
