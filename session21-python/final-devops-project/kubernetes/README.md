# kubernetes/ - plain manifests (Kustomize)

TaskBoard as plain Kubernetes YAML in namespace `taskboard`. Apply everything with `kubectl apply -k kubernetes/`.

| File | What it creates | Notes |
|------|-----------------|-------|
| `namespace.yaml` | Namespace `taskboard` | |
| `configmap.yaml` | `taskboard-config` | `DB_HOST`, `DB_PORT`, `DB_NAME`, `APP_NAME`, `LOG_LEVEL` |
| `secret.yaml` | `taskboard-db` | `DB_USER` and `DB_PASSWORD`. These are demo values only: in a real cluster, use Sealed Secrets or External Secrets. |
| `postgres.yaml` | Headless Service and StatefulSet `postgres` | A `volumeClaimTemplate` creates the 1Gi PVC `data-postgres-0`. `PGDATA` is a subdirectory. `pg_isready` is used for both probes. |
| `backend.yaml` | Deployment and Service `backend:8000` | Details below. |
| `frontend.yaml` | Deployment and Service `frontend:80` (target port 8080) | Unprivileged nginx (uid 101) with a read-only root filesystem and `/tmp` as an emptyDir. |
| `ingress.yaml` | Ingress `taskboard.local` | `/api` goes to `backend:8000` and `/` goes to `frontend:80` (ingress-nginx). |
| `hpa.yaml` | HPA `backend` | 1 to 4 replicas at 50% CPU, with a 60s scale-down window so the demo can be watched. |
| `load-generator.yaml` | busybox Pod (not part of the kustomization) | Applied by hand to drive the HPA demo. |

Details of `backend.yaml`:

* **Init container `wait-for-db`:** runs `pg_isready` until Postgres accepts connections.
* **Probes:** a startup probe on `/health` allows up to 120s for Alembic migrations, the liveness probe uses `/health`, and the readiness probe uses `/ready`, which runs a DB query.
* **Resources:** requests of 100m CPU and 128Mi memory, limits of 500m CPU and 256Mi memory.
* **Environment:** `envFrom` the ConfigMap, plus `secretKeyRef` for the credentials. `DATABASE_URL` is built from `$(DB_USER)`-style references.
* **Security:** runs as uid 10001 with `runAsNonRoot`, a read-only root filesystem, all capabilities dropped and the seccomp `RuntimeDefault` profile.

Why the backend Service is named `backend`: the frontend's nginx proxies `/api/` to `http://backend:8000`. The Service name has to match, otherwise nginx fails to resolve the upstream.

## Run it

```bash
# images built on the host and loaded into the minikube node
docker build -t taskboard-backend:1.0.0  application/backend
docker build -t taskboard-frontend:1.0.0 application/frontend
minikube -p session21 image load taskboard-backend:1.0.0 taskboard-frontend:1.0.0

kubectl apply -k kubernetes/
kubectl -n taskboard rollout status statefulset/postgres
kubectl -n taskboard rollout status deploy/backend
kubectl -n taskboard get all,pvc,ingress

# docker driver on macOS: the node IP isn't routable, so port-forward the ingress controller
kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8080:80 &
curl --resolve taskboard.local:8080:127.0.0.1 http://taskboard.local:8080/api/tasks

# HPA demo
kubectl apply -f kubernetes/load-generator.yaml
kubectl -n taskboard get hpa backend -w
kubectl -n taskboard delete pod load-generator

kubectl delete -k kubernetes/      # clean up before installing the Helm chart
```

Screenshots: `40` (apply), `41` (all resources and bound PVC), `42` (probes and securityContext), `43` (ingress curl and DB rows), `44` (readiness probe taking a pod out of the Service while the DB is down), `45`/`46` (HPA scaling from 1 to 4 and back to 1), `47` (cleanup).

## Gotchas

* **Ingress webhook not ready yet.** Applying straight after `minikube addons enable ingress` can fail with `failed calling webhook "validate.nginx.ingress.kubernetes.io"`. Wait for the controller pod, then apply again.
* **`pg_isready` as uid 10001.** There is no passwd entry for that uid, so `pg_isready` printed `no attempt`. The fix is to pass `-U probe`, which can be any user name.
* **HPA load on 2 vCPUs.** Six request loops pushed CPU to 391% of the request and the HPA went from 1 to 4 replicas. The node was then so busy that metrics-server timed out against the kubelet and the HPA briefly showed `<unknown>`. Two pods also restarted after liveness timeouts. The probe timeouts were raised to 5s afterwards.
* **Leftover data on the hostPath provisioner.** The minikube hostPath provisioner can leave `Released` PVs behind, and on one run the data directory was reused. Clean up with `kubectl get pv`.
