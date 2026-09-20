# Session 12 — Kubernetes Ingress, ConfigMaps & Secrets

**Submitted by:** Antara Utane
**Cluster used:** Kubernetes v1.36.1, single node (`desktop-control-plane`), arm64
**Ingress controller:** ingress-nginx v1.11.3

The full lab in [`../lab.md`](../lab.md) was completed end to end on a live cluster. All
command output in these notes was captured from that run.

## Contents

| # | Topic | Notes |
|---|---|---|
| 01 | ConfigMap | [01-configmap/](01-configmap/) — storing plain-text config |
| 02 | Secret | [02-secret/](02-secret/) — base64 is not encryption, the newline bug |
| 03 | Ingress | [03-ingress/](03-ingress/) — one entry point, path-based routing |
| 04 | Full demo | [04-full-demo/](04-full-demo/) — env injection + ConfigMap reload behaviour |

## The application

"Yatri", a two-tier app:

```
                      Ingress (yatri.local)
                             |
              +--------------+--------------+
              |                             |
         path /                        path /api/
              |                             |
   yatri-frontend-service          yatri-backend-service
        (ClusterIP)                     (ClusterIP)
              |                             |
      2x nginx pods                  2x python pods
                                            |
                          envFrom: ConfigMap (5 keys)
                          env:     Secret    (3 keys)
```

Both Services stay `ClusterIP` — only the Ingress is exposed.

## The four things that actually landed

**1. Base64 is encoding, not encryption.** `describe` masks Secret values as byte counts,
which feels secure. One command undoes it:

```bash
kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
# secretpassword
```

Protection comes from RBAC and encryption at rest, not from the Secret object itself.

**2. The `echo -n` newline bug is real and invisible.** `echo "pw" | base64` silently appends
`\n`, producing a 15-byte password instead of 14. The YAML is valid, the Secret exists, the
pod starts — and the database rejects the login for reasons that look nothing like a
formatting error. Details in [02-secret/](02-secret/).

**3. Environment variables are frozen at container start.** Patching the ConfigMap to
`staging` left the running pod reporting `production`. Only `kubectl rollout restart` applied
it. If live reload is needed, the ConfigMap must be mounted as a volume instead.

**4. Ingress replaces one-LoadBalancer-per-service.** Session 11 exposed a single service per
external IP. Here one Ingress fronts two services on one IP and splits by path, with rewrite
rules a LoadBalancer cannot express.

## Two real problems I had to solve

The lab assumes minikube (`minikube addons enable ingress`). My cluster is not minikube, so
I installed ingress-nginx manually and hit two failures:

| Problem | Cause | Fix |
|---|---|---|
| Controller stuck `Pending` | manifest requires `ingress-ready=true` node label | `kubectl label node desktop-control-plane ingress-ready=true` |
| Admission jobs `ImagePullBackOff` | webhook image unavailable for arm64 | deleted the webhook — it only validates YAML, routing works without it |

Full diagnosis in [03-ingress/](03-ingress/).

## Something the lab did not mention

Testing the API *during* a rolling restart returned the old value, because old and new pods
were both serving traffic. `kubectl exec deployment/X` only checks one pod, so it reported
the new value while the Service was still load balancing across both generations.

During any rolling update, two versions of config are live at once. A single spot-check is
not proof that a rollout has taken effect. Written up in [04-full-demo/](04-full-demo/).

## ConfigMap vs Secret

| | ConfigMap | Secret |
|---|---|---|
| Stores | plain config | sensitive values |
| Encoding | plain text | base64 |
| Shown by `describe` | full values | byte counts only |
| Encrypted at rest | no | only if configured |
| Injection used here | `envFrom` (all 5 keys) | `env` + `secretKeyRef` (3 keys) |
