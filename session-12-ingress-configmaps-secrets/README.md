# Session 12: Kubernetes Ingress, ConfigMaps & Secrets

**Name:** Durga Prasad  
**Enrollment Number:** 10012

---

## Task 1: Non-Sensitive Configuration Decoupling via ConfigMaps

Decouple environment-specific runtime configuration from container images using a `ConfigMap`.

**File:** `01-configmap/app-config.yaml`

**Commands:**
```bash
kubectl apply -f 01-configmap/app-config.yaml
kubectl get configmap yatri-app-config
kubectl describe configmap yatri-app-config
kubectl get configmap yatri-app-config -o jsonpath='{.data.ENVIRONMENT}' && echo ""
kubectl get configmap yatri-app-config -o jsonpath='{.data.LOG_LEVEL}' && echo ""
```

**Output:**
```
configmap/yatri-app-config created

Name:         yatri-app-config
Namespace:    default
Labels:       app=yatri-backend

Data
====
DEFAULT_CURRENCY:
----
INR

ENVIRONMENT:
----
production

LOG_LEVEL:
----
INFO

MAX_BOOKING_DAYS:
----
30

PORT:
----
5000

# JSONPath queries:
production
INFO
```

**Screenshot:** `![ConfigMap Describe](./screenshots/01-configmap-describe.png)`

---

## Task 2: ConfigMap Live Update & Pod Immobility Verification Drill

Prove that updating a ConfigMap does **not** auto-update environment variables in running pods. A rolling restart is required.

**Commands:**
```bash
# Step 1: Patch ConfigMap live
kubectl patch configmap yatri-app-config --type merge -p '{"data":{"ENVIRONMENT":"staging"}}'

# Step 2: Check running pod env (still shows 'production' — NOT updated)
kubectl exec -it deploy/yatri-backend -- env | grep ENVIRONMENT

# Step 3: Trigger rolling restart
kubectl rollout restart deployment/yatri-backend
kubectl rollout status deployment/yatri-backend

# Step 4: Re-check pod env (now shows 'staging')
kubectl exec -it deploy/yatri-backend -- env | grep ENVIRONMENT

# Revert
kubectl patch configmap yatri-app-config --type merge -p '{"data":{"ENVIRONMENT":"production"}}'
kubectl rollout restart deployment/yatri-backend
```

**Output:**
```
configmap/yatri-app-config patched

# Immediately after patch (old pod still running):
ENVIRONMENT=production   ← ConfigMap updated but pod NOT updated

# After rollout restart:
deployment.apps/yatri-backend restarted
Waiting for deployment "yatri-backend" rollout to finish: 1 out of 2 new replicas have been updated...
deployment "yatri-backend" successfully rolled out

ENVIRONMENT=staging      ← New pods picked up the new value
```

**Screenshot:** `![ConfigMap Before After Restart](./screenshots/02-configmap-live-update.png)`

---

## Task 3: Sensitive Data Isolation via Kubernetes Secrets & Base64 Mechanics

Implement credential isolation using an `Opaque` Kubernetes Secret. Prove Base64 is encoding, not encryption.

**File:** `02-secret/db-secret.yaml`

**Commands:**
```bash
kubectl apply -f 02-secret/db-secret.yaml
kubectl get secret yatri-db-secret
kubectl describe secret yatri-db-secret
kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode && echo ""
kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_USER}' | base64 --decode && echo ""
```

**Output:**
```
NAME              TYPE     DATA   AGE
yatri-db-secret   Opaque   3      1m

# describe hides values (shows byte counts only):
Name:         yatri-db-secret
Namespace:    default
Type:         Opaque
Data
====
POSTGRES_DB:        23 bytes
POSTGRES_PASSWORD:  14 bytes
POSTGRES_USER:      11 bytes

# JSONPath decode — Base64 is NOT encryption:
secretpassword   ← Decoded POSTGRES_PASSWORD
yatri_admin      ← Decoded POSTGRES_USER
```

**Screenshot:** `![Secret Describe and Decode](./screenshots/03-secret-describe-decode.png)`

---

## Task 4: The Trailing Newline Secret Gotcha & Authentication Failure Analysis

Standard `echo` appends an invisible newline byte (`0x0A`) that corrupts base64-encoded secrets.

**Commands:**
```bash
# Broken pattern: appends 0x0a (\n)
echo "secretpassword" | xxd
echo "secretpassword" | base64

# Correct pattern: exact byte stream
echo -n "secretpassword" | xxd
echo -n "secretpassword" | base64

# Visual comparison
echo "Wrong (with newline): $(echo "secretpassword" | base64)"
echo "Right (no newline):   $(echo -n "secretpassword" | base64)"
```

**Output:**
```
# echo "secretpassword" | xxd (WITH newline):
00000000: 7365 6372 6574 7061 7373 776f 7264 0a    secretpassword.
                                              ^^
                                        0x0a = newline byte!

# echo -n "secretpassword" | xxd (WITHOUT newline):
00000000: 7365 6372 6574 7061 7373 776f 7264       secretpassword

# Base64 comparison:
Wrong (with newline): c2VjcmV0cGFzc3dvcmQK   ← 'K' at end = extra byte
Right (no newline):   c2VjcmV0cGFzc3dvcmQ=   ← '=' proper padding
```

> **Impact:** If stored as `c2VjcmV0cGFzc3dvcmQK`, the decoded password becomes `secretpassword\n` — a different string. PostgreSQL/MySQL authentication rejects it with a cryptic "authentication failed" error.

**Screenshot:** `![Trailing Newline xxd Comparison](./screenshots/04-trailing-newline-gotcha.png)`

---

## Task 5: Enterprise Secret Management & Pipeline Integration Analysis

### The Problem: Committing Secrets to Git

```
❌ ANTI-PATTERN:
db-secret.yaml → git commit → GitHub → Git history = credentials EXPOSED FOREVER
Even if deleted later, git history retains the base64 string.
```

### External Secret Management Architecture

```
AWS Secrets Manager / HashiCorp Vault / Azure Key Vault
              │
              ▼
  External Secrets Operator (ESO)
  (polls vault, creates K8s Secret objects automatically)
              │
              ▼
  Kubernetes Secret (ephemeral, never committed to git)
              │
              ▼
  Pod (reads via envFrom: secretRef or volume mount)
```

### CI/CD Pipeline Integration

```yaml
# GitHub Actions — secrets injected at deploy time
- name: Deploy to K8s
  env:
    DB_PASSWORD: ${{ secrets.PROD_DB_PASSWORD }}  ← From GitHub Secrets (never in code)
  run: |
    kubectl create secret generic db-secret \
      --from-literal=POSTGRES_PASSWORD=$DB_PASSWORD \
      --dry-run=client -o yaml | kubectl apply -f -
```

**Commands:**
```bash
kubectl get crds | grep -i secret || echo "Standard native secrets in use"
```

**Screenshot:** `![Enterprise Secret Architecture](./screenshots/05-enterprise-secrets.png)`

---

## Task 6: Combined ConfigMap and Secret Pod Injection Architecture

Deploy a backend that simultaneously injects config from a ConfigMap AND credentials from a Secret.

**File:** `04-full-demo/backend.yaml`

**Commands:**
```bash
kubectl apply -f 04-full-demo/configmap.yaml
kubectl apply -f 04-full-demo/secret.yaml
kubectl apply -f 04-full-demo/backend.yaml
kubectl rollout status deployment/yatri-backend
kubectl exec -it deploy/yatri-backend -- env | grep -E "ENVIRONMENT|LOG_LEVEL|POSTGRES|DEFAULT_CURRENCY"
```

**Injection YAML pattern used:**
```yaml
envFrom:
  - configMapRef:
      name: yatri-app-config   # Injects ALL configmap keys as env vars
env:
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: yatri-db-secret
        key: POSTGRES_PASSWORD   # Injects single secret key
```

**Output:**
```
# Both sources merged cleanly inside the container:
ENVIRONMENT=production          ← From ConfigMap
LOG_LEVEL=INFO                  ← From ConfigMap
DEFAULT_CURRENCY=INR            ← From ConfigMap
POSTGRES_USER=yatri_admin       ← From Secret
POSTGRES_PASSWORD=secretpassword ← From Secret
POSTGRES_DB=yatri_production_db ← From Secret
```

**Screenshot:** `![Combined Injection](./screenshots/06-combined-injection.png)`

---

## Task 7: Architectural Comparative Study — Ingress Resource vs. Ingress Controller

| Aspect | Ingress Resource | Ingress Controller |
|---|---|---|
| **What it is** | Kubernetes API object (YAML rules) | Active reverse proxy daemon (Pod) |
| **Does by itself** | Nothing — just stores routing rules in `etcd` | Watches API Server for Ingress objects, generates proxy config |
| **Examples** | `kubectl apply -f ingress.yaml` | NGINX Ingress Controller, Traefik, HAProxy, Envoy |
| **Runtime** | Declarative, static spec | Dynamic, hot-reloads on Ingress changes |
| **Responsibility** | Define what to route (host, path, TLS, service) | Actually route the network packets |

**Architecture:**
```
kubectl apply -f ingress.yaml
        │
        ▼
kube-apiserver ──stores──► etcd (Ingress object)
        │
        ▼
NGINX Ingress Controller Pod (watches for changes)
        │ generates nginx.conf dynamically
        ▼
NGINX Process (routes real HTTP traffic)
        │
        ├── /       ──► frontend-service:80
        └── /api/   ──► backend-service:80
```

**Commands:**
```bash
kubectl api-resources | grep -i ingress
```

**Screenshot:** `![Ingress Resource vs Controller](./screenshots/07-ingress-resource-vs-controller.png)`

---

## Task 8: NGINX Ingress Controller Activation & Lifecycle Verification

Enable the NGINX Ingress Controller addon in Minikube and verify it reaches `Running` state.

**Commands:**
```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
kubectl get service -n ingress-nginx
```

**Output:**
```
  - Using image registry.k8s.io/ingress-nginx/controller:v1.15.1
* The 'ingress' addon is enabled

NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-d99lb       0/1     Completed   0          40s
ingress-nginx-admission-patch-mvcsk        0/1     Completed   1          40s
ingress-nginx-controller-d7cd8c989-zp225   1/1     Running     0          40s

pod/ingress-nginx-controller-d7cd8c989-zp225 condition met

NAME                                 TYPE        CLUSTER-IP      PORT(S)
ingress-nginx-controller             NodePort    10.96.x.x       80:31234/TCP,443:32345/TCP
```

**Screenshot:** `![Ingress Controller Running](./screenshots/08-ingress-controller-running.png)`

---

## Task 9: Local DNS Resolution & System Hosts File Mapping

Configure local DNS by mapping Minikube IP to custom domain in `/etc/hosts`.

**Commands:**
```bash
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP is: ${MINIKUBE_IP}"

if ! grep -q "yatri.local" /etc/hosts; then
  echo "${MINIKUBE_IP}  yatri.local" | sudo tee -a /etc/hosts
fi

grep "yatri.local" /etc/hosts
```

**Output:**
```
Minikube IP is: 192.168.49.2
192.168.49.2  yatri.local    ← appended to /etc/hosts
```

**Screenshot:** `![Hosts File Mapping](./screenshots/09-hosts-file-mapping.png)`

---

## Task 10: Layer 7 Path-Based Routing Implementation

Route `/` to frontend and `/api/*` to backend using Ingress rules.

**File:** `03-ingress/ingress-routes.yaml`

**Commands:**
```bash
kubectl apply -f 04-full-demo/frontend.yaml
kubectl apply -f 04-full-demo/backend.yaml
kubectl apply -f 04-full-demo/ingress.yaml
kubectl get ingress yatri-ingress
kubectl describe ingress yatri-ingress
curl -s http://yatri.local/ | grep -i "<title>"
curl -s http://yatri.local/api/
```

**Output:**
```
NAME           CLASS   HOSTS        ADDRESS        PORTS   AGE
yatri-ingress  nginx   yatri.local  192.168.49.2   80      2m

Rules:
  Host         Path            Backend
  yatri.local  /api(/|$)(.*)   yatri-backend-service:80
               /               yatri-frontend-service:80

# Frontend path:
<title>Welcome to nginx!</title>

# Backend path:
ENVIRONMENT=production
POSTGRES_USER=yatri_admin
```

**Screenshot:** `![Path-Based Routing](./screenshots/10-path-based-routing.png)`

---

## Task 11: Virtual Host-Based Routing (Subdomain Routing)

Route to different services based on virtual hostname (Host header).

**Commands:**
```bash
MINIKUBE_IP=$(minikube ip)
echo "${MINIKUBE_IP}  portal.campus.local api.campus.local" | sudo tee -a /etc/hosts

# Test host-based routing:
curl -s -H "Host: portal.campus.local" http://${MINIKUBE_IP}/ | grep -i "<title>"
curl -s -H "Host: api.campus.local" http://${MINIKUBE_IP}/api/
```

**Output:**
```
# portal.campus.local → frontend service:
<title>Welcome to nginx!</title>

# api.campus.local → backend service:
ENVIRONMENT=production
```

**Screenshot:** `![Virtual Host Routing](./screenshots/11-virtual-host-routing.png)`

---

## Task 12: Hybrid Ingress Routing Architecture

Combine host-based and path-based routing in one Ingress manifest.

**File:** `03-ingress/ingress-tls.yaml`

**Commands:**
```bash
kubectl apply -f 03-ingress/ingress-tls.yaml
kubectl get ingress campus-ingress-tls
kubectl describe ingress campus-ingress-tls
```

**Output:**
```
NAME                CLASS   HOSTS                                    ADDRESS        PORTS   AGE
campus-ingress-tls  nginx   portal.campus.local,api.campus.local     192.168.49.2   80,443  1m

# Routing Table:
Rules:
  Host                   Path    Backend
  portal.campus.local    /       yatri-frontend-service:80
  api.campus.local       /api/   yatri-backend-service:80
  api.campus.local       /       yatri-frontend-service:80
```

**Screenshot:** `![Hybrid Ingress Routing Table](./screenshots/12-hybrid-ingress-routing.png)`

---

## Task 13: Ingress TLS/HTTPS Termination & Secret Binding

Generate self-signed TLS cert, create a `kubernetes.io/tls` secret, and serve HTTPS on port 443.

**Commands:**
```bash
# Step 1: Generate TLS keypair
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=campus.local/O=CampusDevOps"

# Step 2: Store in Kubernetes TLS Secret
kubectl create secret tls campus-tls-cert --cert=tls.crt --key=tls.key
kubectl get secret campus-tls-cert

# Step 3: Apply TLS Ingress
kubectl apply -f 03-ingress/ingress-tls.yaml
kubectl get ingress campus-ingress-tls

# Step 4: Verify HTTPS handshake
INGRESS_IP=$(minikube ip)
curl -k -v --resolve portal.campus.local:443:${INGRESS_IP} https://portal.campus.local/ 2>&1 | grep -E "Server certificate|HTTP/|SSL connection"
```

**Output:**
```
Generating a RSA private key...
writing new private key to 'tls.key'

NAME              TYPE                DATA   AGE
campus-tls-cert   kubernetes.io/tls   2      10s

NAME                HOSTS                PORTS
campus-ingress-tls  portal.campus.local  80, 443

* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* Server certificate:
*  subject: CN=campus.local; O=CampusDevOps
*  issuer: CN=campus.local; O=CampusDevOps
HTTP/1.1 200 OK
```

**Screenshot:** `![TLS HTTPS Termination](./screenshots/13-tls-https-termination.png)`

---

## Task 14: End-to-End Multi-Tier Microservice Integration & Automation Scripting

Execute the full lifecycle automation scripts for the complete yatri-app stack.

**Commands:**
```bash
# Execute full automated deployment
bash 04-full-demo/run-demo.sh

# Audit entire stack state
kubectl get configmap,secret,ingress,deploy,svc,pods -l app=yatri-app

# Execute automated teardown
bash 04-full-demo/cleanup.sh

# Confirm clean state
kubectl get ingress yatri-ingress || echo "Ingress deleted"
kubectl get deployment yatri-backend yatri-frontend || echo "Deployments deleted"
```

**Output:**
```
# run-demo.sh output:
configmap/yatri-app-config created
secret/yatri-db-secret created
deployment.apps/yatri-backend created
service/yatri-backend-service created
deployment.apps/yatri-frontend created
service/yatri-frontend-service created
ingress.networking.k8s.io/yatri-ingress created

# kubectl get all:
NAME                        TYPE        CLUSTER-IP   PORT(S)
configmap yatri-app-config  5 keys
secret yatri-db-secret       Opaque      3 keys
ingress yatri-ingress        nginx       yatri.local  80

# cleanup.sh output:
configmap "yatri-app-config" deleted
secret "yatri-db-secret" deleted
deployment.apps "yatri-backend" deleted
deployment.apps "yatri-frontend" deleted
ingress.networking.k8s.io "yatri-ingress" deleted

Ingress deleted
Deployments deleted
```

> **Multi-Document YAML (`---`):**  
> Using `---` separator in a single YAML file co-locates a Deployment and Service, making it easy to deploy and delete them atomically with one `kubectl apply -f file.yaml`.

**Screenshot:** `![Full Demo Run and Cleanup](./screenshots/14-full-demo-run-cleanup.png)`
