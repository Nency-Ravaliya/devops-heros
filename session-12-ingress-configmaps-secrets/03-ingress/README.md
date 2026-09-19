# Ingress — One Entry Point for All Your Microservices

## Why Do We Need Ingress?

### The Problem: One Load Balancer Per Service = Expensive Chaos

Imagine your application has 5 microservices: Frontend, Backend API, Auth Service, Payment Service, and Admin Dashboard. Without Ingress, you need a separate `LoadBalancer` service for each one:

```text
Without Ingress:
  Frontend     -> AWS Load Balancer 1 ($25/month)
  Backend API  -> AWS Load Balancer 2 ($25/month)
  Auth         -> AWS Load Balancer 3 ($25/month)
  Payment      -> AWS Load Balancer 4 ($25/month)
  Admin        -> AWS Load Balancer 5 ($25/month)
  Total: $125/month just for load balancers
```

Users also get ugly non-standard ports and URLs like `http://3.15.22.100:30080`. There is no SSL/TLS termination, no centralized routing, and no ability to do host-based routing like `api.myapp.com` vs `myapp.com`.

### The Solution: Ingress Controller + Ingress Rules

An **Ingress Controller** (e.g., NGINX Ingress Controller) is a single pod running a reverse proxy. You deploy **one** `LoadBalancer` Service pointing to it. All routing logic is declared as `Ingress` YAML rules.

```text
With Ingress:
  1 AWS Load Balancer ($25/month)
       |
  NGINX Ingress Controller
       |
       +-- yatri.local/         -> Frontend ClusterIP Service
       +-- yatri.local/api/*    -> Backend API ClusterIP Service
```

```text
Public Internet
      |
      | https://yatri.local (Port 80/443)
      v
+------------------------------------------+
|   NGINX Ingress Controller Pod           |
|   (Layer 7 HTTP Reverse Proxy)           |
+------------------------------------------+
      |                        |
      | Path: /                | Path: /api/*
      v                        v
+----------------+     +---------------------+
| Frontend Svc   |     | Backend API Svc      |
| (ClusterIP)    |     | (ClusterIP)          |
+----------------+     +---------------------+
```

---

## Important Points

* An `Ingress` resource is **just a routing rule definition**. It does nothing on its own. You MUST have an **Ingress Controller** installed in your cluster (e.g., `ingress-nginx`).
* Ingress operates at **Layer 7 (HTTP/HTTPS)**. It can route based on hostnames (`api.shop.com`) and URL paths (`/orders`, `/users`).
* Ingress supports **TLS/HTTPS termination**: you configure your SSL certificate once in Ingress, and all backend services communicate over plain HTTP internally. This is the standard pattern.
* On Minikube, enable the addon: `minikube addons enable ingress`.
* On AWS EKS, install `ingress-nginx` via Helm and one AWS NLB is automatically provisioned for it.

---

## Real-World Use Cases
* Routing `app.company.com` to the frontend and `api.company.com` to the backend API — from a single public IP.
* SSL/TLS termination: attaching a certificate to `https://myapp.com` without modifying any application code.
* Canary deployments: routing 10% of `/api` traffic to a `v2` service and 90% to `v1`.
* Rate limiting, authentication headers, and CORS rules applied centrally via Ingress annotations.

---

## Code

### ingress/ingress-routes.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: yatri-ingress
  labels:
    app: yatri-app
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
    - host: yatri.local
      http:
        paths:
          - path: /api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: yatri-backend-service
                port:
                  number: 80
          - path: /
            pathType: Prefix
            backend:
              service:
                name: yatri-frontend-service
                port:
                  number: 80
```

### Apply and Inspect
```bash
kubectl apply -f ingress/ingress-routes.yaml
kubectl get ingress yatri-ingress
kubectl describe ingress yatri-ingress
```

Expected Output:
```text
NAME            CLASS   HOSTS        ADDRESS        PORTS   AGE
yatri-ingress   nginx   yatri.local  192.168.49.2   80      12s
```

---

## Hands-on: Host-Based Routing and TLS/HTTPS Termination

### Step 1: Generate a Self-Signed TLS Certificate
To secure your Ingress with HTTPS without paying a third-party certificate authority in local testing, create a local certificate pair:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=campus.local/O=CampusDevOps"
```

### Step 2: Create a Kubernetes TLS Secret
Store the public certificate and private key inside Kubernetes as a `kubernetes.io/tls` Secret:

```bash
kubectl create secret tls campus-tls-cert \
  --cert=tls.crt \
  --key=tls.key
```

Verify secret creation:
```bash
kubectl get secret campus-tls-cert
```

Expected Output:
```text
NAME              TYPE                DATA   AGE
campus-tls-cert   kubernetes.io/tls   2      5s
```

### Step 3: Apply the Ingress with TLS and Multi-Host Rules
Inspect `03-ingress/ingress-tls.yaml` and apply it:

```bash
kubectl apply -f 03-ingress/ingress-tls.yaml
```

Inspect the applied Ingress:
```bash
kubectl get ingress campus-ingress-tls
```

Expected Output:
```text
NAME                 CLASS   HOSTS                                  ADDRESS        PORTS     AGE
campus-ingress-tls   nginx   portal.campus.local,api.campus.local   192.168.49.2   80, 443   10s
```

Notice `PORTS` shows `80, 443`, confirming both HTTP and HTTPS are active.

### Step 4: Test Host-Based and TLS Routing with curl
Map the local domain in `/etc/hosts` or use `curl --resolve`:

```bash
INGRESS_IP=$(kubectl get ingress campus-ingress-tls -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test Host 1: Portal with HTTPS (-k ignores self-signed certificate warning)
curl -k --resolve portal.campus.local:443:$INGRESS_IP https://portal.campus.local/

# Test Host 2: API with HTTPS
curl -k --resolve api.campus.local:443:$INGRESS_IP https://api.campus.local/api/health
```

### Cleanup
```bash
kubectl delete ingress campus-ingress-tls
kubectl delete secret campus-tls-cert
rm -f tls.key tls.crt
```

