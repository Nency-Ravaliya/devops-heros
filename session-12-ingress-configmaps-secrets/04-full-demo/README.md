# Full Demo — ConfigMap + Secret + Ingress Working Together

## What This Demo Does

This demo deploys two microservices behind a single NGINX Ingress on a Minikube cluster:

* **Frontend** (`/`) — Nginx serving an HTML page. Reads `LOG_LEVEL` and `ENVIRONMENT` from a ConfigMap.
* **Backend API** (`/api/`) — A Python HTTP server. Reads plain config from a ConfigMap AND database credentials from a Secret.

Traffic flows like this:

```text
Your Browser
     |
     | http://yatri.local/       --> Frontend (Nginx)
     | http://yatri.local/api/   --> Backend  (Python API)
     v
NGINX Ingress Controller (path-based routing)
     |                     |
     v                     v
Frontend ClusterIP    Backend ClusterIP
     |                     |
     v                     v
Nginx Pods            Python Pods
(reads ConfigMap)     (reads ConfigMap + Secret)
```

---

## Architecture: What Each File Does

| File | Kind | Purpose |
| :--- | :--- | :--- |
| `configmap.yaml` | ConfigMap | Stores 5 non-sensitive config values (`ENVIRONMENT`, `LOG_LEVEL`, etc.) |
| `secret.yaml` | Secret | Stores Base64-encoded database credentials |
| `frontend.yaml` | Deployment + Service | Nginx frontend; reads ConfigMap as environment vars |
| `backend.yaml` | Deployment + Service | Python HTTP server; reads ConfigMap + individual Secret keys |
| `ingress.yaml` | Ingress | Routes `/api/*` to backend and `/` to frontend |
| `run-demo.sh` | Shell Script | One-command full deploy with Ingress addon setup |
| `cleanup.sh` | Shell Script | Removes all created resources |

---

## Prerequisites

* Minikube running (`minikube status`)
* `kubectl` configured to the Minikube context

```bash
minikube status
kubectl config current-context
# Expected output: minikube
```

---

## Step-by-Step Manual Run

### Step 1: Enable the NGINX Ingress Addon on Minikube
```bash
minikube addons enable ingress
```

Wait for the Ingress Controller to become ready:
```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

Expected output:
```text
pod/ingress-nginx-controller-7c6974c4d8-xqzvf condition met
```

### Step 2: Apply the ConfigMap
```bash
kubectl apply -f 04-full-demo/configmap.yaml
```

Verify the stored values:
```bash
kubectl describe configmap yatri-app-config
```

Expected output:
```text
Name:         yatri-app-config
Data
====
DEFAULT_CURRENCY:  INR
ENVIRONMENT:       production
LOG_LEVEL:         INFO
MAX_BOOKING_DAYS:  30
APP_PORT:          5000
```

### Step 3: Apply the Secret
```bash
kubectl apply -f 04-full-demo/secret.yaml
```

Verify (values are masked):
```bash
kubectl describe secret yatri-db-secret
```

Expected output:
```text
Name:         yatri-db-secret
Type:         Opaque

Data
====
POSTGRES_DB:        22 bytes
POSTGRES_PASSWORD:  14 bytes
POSTGRES_USER:      11 bytes
```

### Step 4: Deploy the Frontend
```bash
kubectl apply -f 04-full-demo/frontend.yaml
```

Check pods and service:
```bash
kubectl get pods -l app=yatri-frontend
kubectl get svc yatri-frontend-service
```

Expected:
```text
NAME                             READY   STATUS    RESTARTS   AGE
yatri-frontend-7b69b5b5d7-6k9qh  1/1     Running   0          18s
yatri-frontend-7b69b5b5d7-8mxzt  1/1     Running   0          18s

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
yatri-frontend-service    ClusterIP   10.96.210.51    <none>        80/TCP    20s
```

### Step 5: Deploy the Backend
```bash
kubectl apply -f 04-full-demo/backend.yaml
```

Check pods and service:
```bash
kubectl get pods -l app=yatri-backend
kubectl get svc yatri-backend-service
```

Wait until Running:
```bash
kubectl rollout status deployment/yatri-backend --timeout=90s
```

### Step 6: Apply the Ingress
```bash
kubectl apply -f 04-full-demo/ingress.yaml
```

Inspect routing rules:
```bash
kubectl describe ingress yatri-ingress
```

Expected output (key section):
```text
Name:             yatri-ingress
Namespace:        default
Address:          192.168.49.2
Ingress Class:    nginx

Rules:
  Host        Path              Backends
  ----        ----              --------
  yatri.local
              /api(/|$)(.*)    yatri-backend-service:80
              /                yatri-frontend-service:80
```

### Step 7: Add yatri.local to /etc/hosts
```bash
echo "$(minikube ip)  yatri.local" | sudo tee -a /etc/hosts
```

Verify:
```bash
cat /etc/hosts | grep yatri.local
# Expected: 192.168.49.2  yatri.local
```

---

## How to Check the Website

### Test 1: Frontend (at root path /)
Open your browser and visit:
```text
http://yatri.local
```

Or via curl:
```bash
curl http://yatri.local
```

Expected output (NGINX default HTML page served through Ingress):
```html
<!DOCTYPE html>
<html>
<head><title>Welcome to nginx!</title></head>
...
<h1>Welcome to nginx!</h1>
...
</html>
```

### Test 2: Backend API (at /api/) — Proves ConfigMap + Secret injection
```bash
curl http://yatri.local/api/
```

Expected output:
```text
Yatri Backend API
=================
ENVIRONMENT     : production
LOG_LEVEL       : INFO
DEFAULT_CURRENCY: INR
POSTGRES_USER   : yatri_admin
POSTGRES_DB     : yatri_production_db
```

The backend pod printed real values pulled from the ConfigMap (`ENVIRONMENT`, `LOG_LEVEL`, `DEFAULT_CURRENCY`) and the Secret (`POSTGRES_USER`, `POSTGRES_DB`). The `POSTGRES_PASSWORD` is intentionally not printed (a good practice: never log passwords).

### Test 3: Confirm Environment Variables Are Injected in the Pod
```bash
kubectl exec -it deploy/yatri-backend -- env | grep -E "ENVIRONMENT|LOG_LEVEL|POSTGRES"
```

Expected output:
```text
ENVIRONMENT=production
LOG_LEVEL=INFO
POSTGRES_USER=yatri_admin
POSTGRES_PASSWORD=secretpassword
POSTGRES_DB=yatri_production_db
```

### Test 4: Decode Secret Password (Classroom Demonstration)
```bash
kubectl get secret yatri-db-secret \
  -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
```

Output:
```text
secretpassword
```

This confirms that Base64 is encoding, NOT encryption!

---

## One-Command Automated Deploy

Instead of the 7 manual steps above, run:
```bash
bash 04-full-demo/run-demo.sh
```

This automatically:
1. Enables the Minikube Ingress addon.
2. Applies ConfigMap, Secret, Frontend, Backend, and Ingress.
3. Waits for all pods to be Ready.
4. Patches `/etc/hosts` with `yatri.local`.

---

## Cleanup
```bash
bash 04-full-demo/cleanup.sh
```

Or manually:
```bash
kubectl delete -f 04-full-demo/ingress.yaml
kubectl delete -f 04-full-demo/backend.yaml
kubectl delete -f 04-full-demo/frontend.yaml
kubectl delete -f 04-full-demo/secret.yaml
kubectl delete -f 04-full-demo/configmap.yaml
```

---

## Key Interview Points

* **Why not use a ConfigMap to store passwords?**
  ConfigMaps store data in plain text and are visible to any user with `kubectl get configmap` RBAC access. Secrets use Base64 encoding and rely on Kubernetes RBAC + etcd encryption-at-rest for protection.

* **What is `ingressClassName: nginx`?**
  Modern Kubernetes (v1.18+) requires you to specify which Ingress Controller handles the Ingress resource. If you forget this field, the Ingress rule is silently ignored.

* **Why is `rewrite-target: /$2` needed?**
  Without it, the request path `/api/orders` is forwarded to the backend as `/api/orders`. The backend may not have an `/api/` prefix in its route handlers. The `rewrite-target: /$2` strips the `/api` prefix so the backend receives `/orders`.

* **What happens if a ConfigMap referenced in `envFrom` does not exist?**
  The pod will fail to start and will enter `CreateContainerConfigError` status.
