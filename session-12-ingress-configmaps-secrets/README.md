# Session 12 — Kubernetes Ingress, ConfigMaps & Secrets

Lab guide: [`lab.md`](./lab.md). Cluster: local `minikube` (Docker driver, macOS), `default` namespace.

This lab builds one small app (**Yatri**) piece by piece — a ConfigMap for plain config, a Secret for DB credentials, a backend + frontend that consume both, and an Ingress that exposes them both through a single entry point — then wires everything together in `04-full-demo/`.

## Folder structure

```text
01-configmap/    ConfigMap concepts + yatri-app-config
02-secret/       Secret concepts + yatri-db-secret (base64 gotcha)
03-ingress/      Ingress concepts + TLS/host-based routing
04-full-demo/    ConfigMap + Secret + Backend + Frontend + Ingress, wired together
troubleshooting/ secret-base64-gotcha.md post-mortem
```

---

## 1. ConfigMap — `01-configmap/`

Non-sensitive config (`ENVIRONMENT`, `LOG_LEVEL`, `APP_PORT`, `DEFAULT_CURRENCY`, `MAX_BOOKING_DAYS`) stored outside the container image as `yatri-app-config`, so the same image can run in dev/staging/prod with different values.

**Steps performed:**
1. `cat configmap.yaml` → 5 plain-text key-value pairs, no secrets.
2. `kubectl apply -f configmap.yaml` → `configmap/yatri-app-config created`.
3. `kubectl get configmap yatri-app-config` → `5` data keys stored.
4. `kubectl describe configmap yatri-app-config` → all 5 keys and values listed in plain text.
5. `kubectl get configmap yatri-app-config -o jsonpath='{.data.ENVIRONMENT}'` → `production`.

**Screenshots:**

![apply and describe configmap](<01-configmap/Screenshot 2026-09-20 at 7.38.29 PM.png>)
*Terminal: `cat configmap.yaml`, `kubectl apply`, `kubectl get configmap` (5 keys), `kubectl describe configmap` showing all 5 values in plain text.*

![jsonpath read](<01-configmap/Screenshot 2026-09-20 at 7.38.41 PM.png>)
*Terminal: `kubectl get configmap yatri-app-config -o jsonpath='{.data.ENVIRONMENT}'` → `production`.*

**Takeaway:** ConfigMaps are for non-sensitive values only, readable in plain text by anyone with `get`/`describe` access — never store passwords here.

---

## 2. Secret — `02-secret/`

Database credentials (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`) stored as `yatri-db-secret`, base64-encoded and masked in `describe` output — but base64 is encoding, not encryption.

**Steps performed:**
1. Reproduced the classic newline bug: `echo "mypassword" | base64` → `bXlwYXNzd29yZAo=` (trailing `Ao=` encodes a hidden `\n`) vs. `echo -n "mypassword" | base64` → `bXlwYXNzd29yZA==` (clean).
2. `cat secret.yaml` → 3 base64-encoded keys, `type: Opaque`.
3. `kubectl apply -f secret.yaml` → `secret/yatri-db-secret created`.
4. `kubectl get secret yatri-db-secret` → `3` data keys, type `Opaque`.
5. `kubectl describe secret yatri-db-secret` → values masked as byte counts (`POSTGRES_PASSWORD: 14 bytes`), not shown.
6. `kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode` → `secretpassword` in plain text — proving base64 is trivially reversible.

**Screenshots:**

![base64 gotcha + apply + decode](<02-secret/Screenshot 2026-09-20 at 7.38.55 PM.png>)
*Terminal: `echo` vs `echo -n` base64 difference, `cat secret.yaml`, `kubectl apply`, `kubectl get secret` (masked), `kubectl describe secret` (byte counts only), then decoding `POSTGRES_PASSWORD` back to `secretpassword`.*

**Takeaway:** always `echo -n` when encoding secret values; `describe` hides values from onlookers, but anyone with `get secret` RBAC access can decode them instantly — base64 is not encryption.

---

## 3. Ingress — `03-ingress/`

Concepts covered: one Ingress Controller pod fronting multiple `ClusterIP` services, path-based routing (`/` → frontend, `/api/*` → backend), and (per the folder's README) TLS/host-based routing with a self-signed cert. In this run, the screenshots capture the backend and frontend being deployed and verified (env vars injected from the ConfigMap + Secret) as the prerequisite step before wiring up the Ingress in the full demo.

**Steps performed:**
1. `cat backend.yaml` → shows `envFrom.configMapRef` (all 5 ConfigMap keys at once) and `env[].valueFrom.secretKeyRef` (individual Secret keys) injected into the Python backend container.
2. `kubectl apply -f backend.yaml` → deployment + service created; `kubectl get pods -l app=yatri-backend -w` → both replicas reach `1/1 Running`.
3. `kubectl exec -it deployment/yatri-backend -- env | grep -E "ENVIRONMENT|LOG_LEVEL|DEFAULT_CURRENCY|POSTGRES"` → `ENVIRONMENT=production`, `LOG_LEVEL=INFO`, `DEFAULT_CURRENCY=INR`, `POSTGRES_USER=yatri_admin`, `POSTGRES_PASSWORD=secretpassword` — confirming both objects landed inside the pod as plain env vars.
4. `kubectl apply -f frontend.yaml` → deployment + service created; both frontend pods `Running`, both `yatri-frontend-service`/`yatri-backend-service` confirmed `ClusterIP` (only reachable inside the cluster — the reason Ingress is needed next).
5. `minikube addons enable ingress` → NGINX Ingress Controller installed; `kubectl get pods -n ingress-nginx` → controller pod `Running`.
6. `cat ingress.yaml` → one `Ingress` (`yatri-ingress`), host `yatri.local`, path `/api(/|$)(.*)` → backend, path `/` → frontend, with `rewrite-target: /$2` to strip the `/api` prefix before it reaches the backend.

**Screenshots:**

![backend deployed, env vars verified](<03-ingress/Screenshot 2026-09-20 at 7.40.02 PM.png>)
*Terminal: `cat backend.yaml` (envFrom + secretKeyRef), `kubectl apply -f backend.yaml`, pods reaching `Running`, `kubectl exec ... env` confirming all 5 ConfigMap keys + 2 Secret keys injected into the container.*

![frontend deployed + ingress addon enabled](<03-ingress/Screenshot 2026-09-20 at 7.40.16 PM.png>)
*Terminal: frontend apply + pods/services (both `ClusterIP`), `minikube addons enable ingress`, `kubectl get pods -n ingress-nginx` (controller `Running`), and `cat ingress.yaml` showing the two routing rules.*

**Takeaway:** `envFrom`/`secretKeyRef` are the bridge between ConfigMap/Secret objects and a running container's environment; both frontend and backend stayed `ClusterIP`-only (unreachable from outside) until the Ingress Controller and Ingress rule were added.

---

## 4. Full Demo — `04-full-demo/`

All the pieces from Parts 1–3 wired together and exposed through a single Ingress on `yatri.local`.

**Steps performed:**
1. Applied the Ingress: `kubectl apply -f ingress.yaml` → `ingress.networking.k8s.io/yatri-ingress created`.
2. `kubectl get ingress yatri-ingress` → `ADDRESS` populated once the controller synced.
3. `kubectl describe ingress yatri-ingress` → rules confirmed with live backend endpoints: `/api(/|$)(.*)` → `yatri-backend-service:80` (2 pod IPs), `/` → `yatri-frontend-service:80` (2 pod IPs).
4. Resolved the Ingress IP: `INGRESS_IP=$(minikube ip)`.

**Screenshots:**

![frontend pods/services running](<04-full-demo/Screenshot 2026-09-20 at 7.49.52 PM.png>)
*Terminal: `kubectl apply -f frontend.yaml`, both frontend pods `Running`, `yatri-frontend-service` and `yatri-backend-service` both listed as `ClusterIP`.*

![ingress addon + ingress.yaml](<04-full-demo/Screenshot 2026-09-20 at 7.50.25 PM.png>)
*Terminal: `minikube addons enable ingress`, controller pod `Running` in `ingress-nginx` namespace, and the full `ingress.yaml` routing rules for `yatri.local`.*

![ingress applied + IP resolved](<04-full-demo/Screenshot 2026-09-20 at 7.50.35 PM.png>)
*Terminal: `kubectl apply -f ingress.yaml`, `kubectl get ingress` (address populated), `kubectl describe ingress` (both routes resolved to live pod endpoints), and `INGRESS_IP=$(minikube ip)`.*

**Takeaway:** one Ingress Controller and one Ingress resource replaced the need for two separate `LoadBalancer` services — both microservices are now reachable through a single IP, routed purely by URL path.

---

## End-to-End Verification (root folder screenshots)

With the Ingress IP resolved, both routes were tested with the `Host: yatri.local` header to confirm path-based routing actually works end-to-end.

**Screenshots:**

![frontend via ingress](<Screenshot 2026-09-20 at 7.50.43 PM.png>)
*Browser: `http://yatri.local/` through the Ingress → "Welcome to nginx!" — the `/` path correctly routed to the frontend service.*

![backend via ingress](<Screenshot 2026-09-20 at 7.50.59 PM.png>)
*Terminal/browser: `curl -H "Host: yatri.local" http://$INGRESS_IP/api/` → `Yatri Backend API` response printing `ENVIRONMENT: production`, `LOG_LEVEL: INFO`, `DEFAULT_CURRENCY: INR`, `POSTGRES_USER: yatri_admin`, `POSTGRES_DB: yatri_production_db` — the `/api/` path correctly routed to the backend, which is reading both the ConfigMap and the Secret. `POSTGRES_PASSWORD` is intentionally not printed by the app.*

**Result:** both paths resolved correctly through one Ingress Controller and one IP address — no separate load balancer needed per microservice.

---

## Additional exercises covered in `lab.md`

- **Part 8 — Newline bug drill:** reproduced `echo` vs `echo -n` base64 encoding live (see Secret section above) and cross-referenced [`troubleshooting/secret-base64-gotcha.md`](./troubleshooting/secret-base64-gotcha.md).
- **Part 9 — ConfigMap live update:** `kubectl patch configmap yatri-app-config --type merge -p '{"data":{"ENVIRONMENT":"staging"}}'` does **not** change a running pod's env vars (they're set once at container start) until `kubectl rollout restart deployment/yatri-backend` is run — proving env vars are not hot-reloaded.

## Cleanup

```bash
bash 04-full-demo/cleanup.sh
```

Removes the Ingress, backend, frontend, Secret, and ConfigMap. Verified with:

```bash
kubectl get all -l app=yatri-app
kubectl get configmap yatri-app-config
kubectl get secret yatri-db-secret
kubectl get ingress yatri-ingress
```

All should return `No resources found` / `Error from server (NotFound)`.

---

*Reference material: [Nency-Ravaliya/Kubernetes](https://github.com/Nency-Ravaliya/Kubernetes)*
