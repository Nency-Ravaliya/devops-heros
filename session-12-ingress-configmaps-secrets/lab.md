# Session 12 Lab Guide: Kubernetes Ingress, ConfigMaps & Secrets


## Lab Setup: Navigate to the Session Folder

Open a terminal on your cloud instance and change into the session directory:

```bash
cd session-12-ingress-configmaps-secrets
ls
```

You should see:

```text
01-configmap/  02-secret/  03-ingress/  04-full-demo/  troubleshooting/
README.md      instructor-notes.md
```

All the files you need for this lab are inside `04-full-demo/`. Navigate to it:

```bash
cd 04-full-demo
ls
```

Output:

```text
backend.yaml  cleanup.sh  configmap.yaml  frontend.yaml  ingress.yaml  run-demo.sh  secret.yaml
```

---

## Part 1: ConfigMap — Storing Plain-Text Configuration

### What you are looking at
Open `configmap.yaml` and read it:

```bash
cat configmap.yaml
```

Output:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: yatri-app-config
  namespace: default
  labels:
    app: yatri-app
data:
  ENVIRONMENT: "production"
  LOG_LEVEL: "INFO"
  APP_PORT: "5000"
  DEFAULT_CURRENCY: "INR"
  MAX_BOOKING_DAYS: "30"
```

This ConfigMap stores five plain-text key-value pairs that your application will read as environment variables.
No passwords. No sensitive data. Just configuration values.

### Apply the ConfigMap

```bash
kubectl apply -f configmap.yaml
```

Expected output:

```text
configmap/yatri-app-config created
```

### Verify it is stored in the cluster

```bash
kubectl get configmap yatri-app-config
```

Expected output:

```text
NAME               DATA   AGE
yatri-app-config   5      8s
```

### Inspect the stored keys

```bash
kubectl describe configmap yatri-app-config
```

Expected output:

```text
Name:         yatri-app-config
Namespace:    default
Labels:       app=yatri-app
Data
====
APP_PORT:
----
5000
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
```

### Read one specific key using jsonpath

```bash
kubectl get configmap yatri-app-config -o jsonpath='{.data.ENVIRONMENT}'
echo ""
```

Expected output:

```text
production
```

---

## Part 2: Secret — Storing Sensitive Database Credentials

### The rule before you touch secrets

Run both of these commands and look at the difference:

```bash
# Wrong way — standard echo adds a hidden newline character at the end
echo "mypassword" | base64

# Correct way — -n flag suppresses the trailing newline
echo -n "mypassword" | base64
```

Output:

```text
bXlwYXNzd29yZAo=
bXlwYXNzd29yZA==
```

Notice the last characters differ. The top one ends in `Ao=` (that `o=` encodes the `\n` character).
Always use `echo -n` when encoding secrets. Your database will reject the password otherwise.

### What is inside the Secret file

```bash
cat secret.yaml
```

Output:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: yatri-db-secret
  namespace: default
  labels:
    app: yatri-app
type: Opaque
data:
  # echo -n "yatri_admin" | base64
  POSTGRES_USER: eWF0cmlfYWRtaW4=
  # echo -n "secretpassword" | base64
  POSTGRES_PASSWORD: c2VjcmV0cGFzc3dvcmQ=
  # echo -n "yatri_production_db" | base64
  POSTGRES_DB: eWF0cmlfcHJvZHVjdGlvbl9kYg==
```

### Apply the Secret

```bash
kubectl apply -f secret.yaml
```

Expected output:

```text
secret/yatri-db-secret created
```

### Verify it is stored

```bash
kubectl get secret yatri-db-secret
```

Expected output:

```text
NAME               TYPE     DATA   AGE
yatri-db-secret   Opaque   3      5s
```

### Describe the Secret — notice values are hidden

```bash
kubectl describe secret yatri-db-secret
```

Expected output:

```text
Name:         yatri-db-secret
Namespace:    default
Labels:       app=yatri-app
Type:         Opaque

Data
====
POSTGRES_DB:        19 bytes
POSTGRES_PASSWORD:  14 bytes
POSTGRES_USER:      11 bytes
```

The values are masked. Nobody standing behind you can read them from describe output.

### Prove that Base64 is NOT encryption — decode the password yourself

```bash
kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
echo ""
```

Expected output:

```text
secretpassword
```

This is why we say: Base64 is encoding, not encryption. Use RBAC to restrict who can run `kubectl get secret`.

---

## Part 3: Deploy the Backend — Inject ConfigMap + Secret as Environment Variables

### What the backend.yaml does
Open and read the file:

```bash
cat backend.yaml
```

Look for these two sections:

```yaml
envFrom:
  - configMapRef:
      name: yatri-app-config    # Injects all 5 keys from ConfigMap at once

env:
  - name: POSTGRES_USER
    valueFrom:
      secretKeyRef:
        name: yatri-db-secret
        key: POSTGRES_USER
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: yatri-db-secret
        key: POSTGRES_PASSWORD
  - name: POSTGRES_DB
    valueFrom:
      secretKeyRef:
        name: yatri-db-secret
        key: POSTGRES_DB
```

- `envFrom` with `configMapRef` pulls all keys from the ConfigMap in one go.
- `env` with `secretKeyRef` picks individual keys from the Secret one by one.

### Apply the backend deployment

```bash
kubectl apply -f backend.yaml
```

Expected output:

```text
deployment.apps/yatri-backend created
service/yatri-backend-service created
```

### Watch the pods come up

```bash
kubectl get pods -l app=yatri-backend -w
```

Wait until both pods show `Running`. Press `Ctrl+C` to stop watching.

```text
NAME                             READY   STATUS    RESTARTS   AGE
yatri-backend-7c9f6b8d4-4xp2q   1/1     Running   0          25s
yatri-backend-7c9f6b8d4-mwrtk   1/1     Running   0          25s
```

### Verify the environment variables were injected inside the pod

```bash
kubectl exec -it deployment/yatri-backend -- env | grep -E "ENVIRONMENT|LOG_LEVEL|DEFAULT_CURRENCY|POSTGRES"
```

Expected output:

```text
ENVIRONMENT=production
LOG_LEVEL=INFO
DEFAULT_CURRENCY=INR
POSTGRES_USER=yatri_admin
POSTGRES_PASSWORD=secretpassword
POSTGRES_DB=yatri_production_db
```

The pod is reading both the ConfigMap values and the Secret values as normal Linux environment variables.

---

## Part 4: Deploy the Frontend

### Apply the frontend deployment

```bash
kubectl apply -f frontend.yaml
```

Expected output:

```text
deployment.apps/yatri-frontend created
service/yatri-frontend-service created
```

### Verify it is running

```bash
kubectl get pods -l app=yatri-frontend
kubectl get svc yatri-frontend-service yatri-backend-service
```

Expected output:

```text
NAME                              READY   STATUS    RESTARTS   AGE
yatri-frontend-6d8b4c7f5-9lkpj   1/1     Running   0          18s
yatri-frontend-6d8b4c7f5-xmn2r   1/1     Running   0          18s

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
yatri-frontend-service     ClusterIP   10.96.45.12     <none>        80/TCP    22s
yatri-backend-service      ClusterIP   10.96.112.88    <none>        80/TCP    3m
```

Both services are `ClusterIP` — they are only reachable from inside the cluster.
This is why we need Ingress to expose them.

---

## Part 5: Ingress — One Entry Point for Both Services

### Enable the NGINX Ingress Controller

```bash
minikube addons enable ingress
```

Wait about 30 seconds, then verify the controller pod is running:

```bash
kubectl get pods -n ingress-nginx
```

Expected output:

```text
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-controller-7799c6795f-9k2lw   1/1     Running     0          35s
```

### Read the Ingress routing rules

```bash
cat ingress.yaml
```

Output:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: yatri-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
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

There is one rule, one host (`yatri.local`), and two paths:
- `/api/*` goes to the backend.
- `/` goes to the frontend.

### Apply the Ingress

```bash
kubectl apply -f ingress.yaml
```

Expected output:

```text
ingress.networking.k8s.io/yatri-ingress created
```

### Verify the Ingress received an address

```bash
kubectl get ingress yatri-ingress
```

Wait a few seconds and run it again until the `ADDRESS` column is filled:

```text
NAME            CLASS   HOSTS        ADDRESS        PORTS   AGE
yatri-ingress   nginx   yatri.local  192.168.49.2   80      15s
```

### Describe the Ingress to see the routing rules

```bash
kubectl describe ingress yatri-ingress
```

Expected output:

```text
Name:             yatri-ingress
Namespace:        default
Address:          192.168.49.2
Rules:
  Host         Path                  Backends
  ----         ----                  --------
  yatri.local  /api(/|$)(.*)         yatri-backend-service:80
               /                     yatri-frontend-service:80
```

---

## Part 6: Test the Routing on Your Cloud Instance

Get the Ingress IP address:

```bash
INGRESS_IP=$(kubectl get ingress yatri-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress IP: ${INGRESS_IP}"
```

If you are on Minikube:

```bash
INGRESS_IP=$(minikube ip)
echo "Ingress IP: ${INGRESS_IP}"
```

### Test 1: Root path — should hit the Nginx Frontend

```bash
curl -s -H "Host: yatri.local" http://${INGRESS_IP}/ | grep -i "<title>"
```

Expected output:

```text
<title>Welcome to nginx!</title>
```

### Test 2: API path — should hit the Python Backend and return config values

```bash
curl -s -H "Host: yatri.local" http://${INGRESS_IP}/api/
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

Both paths work through one single IP address and one single Ingress Controller pod.

---

## Part 7: See the Full Picture — All Resources at Once

```bash
kubectl get configmap yatri-app-config
kubectl get secret    yatri-db-secret
kubectl get pods      -l app=yatri-frontend
kubectl get pods      -l app=yatri-backend
kubectl get svc       yatri-frontend-service yatri-backend-service
kubectl get ingress   yatri-ingress
```

---

## Part 8: The Newline Bug — Live Debugging Drill

Read the post-mortem file:

```bash
cat ../troubleshooting/secret-base64-gotcha.md
```

Now reproduce the bug yourself. Encode a password with standard `echo` (wrong way):

```bash
echo "secretpassword" | base64
```

Observe the output ends in `Ao=`.

Now decode it back:

```bash
echo "c2VjcmV0cGFzc3dvcmQK" | base64 --decode
```

Watch your cursor jump to the next line. That invisible character at the end is `\n`. PostgreSQL sees `secretpassword\n` — 15 characters — not `secretpassword` — 14 characters.

Now encode it the correct way:

```bash
echo -n "secretpassword" | base64
```

Output ends cleanly in `=` (no `Ao=`):

```text
c2VjcmV0cGFzc3dvcmQ=
```

---

## Part 9: What Happens When You Update a ConfigMap?

Patch the ConfigMap live:

```bash
kubectl patch configmap yatri-app-config --type merge -p '{"data":{"ENVIRONMENT":"staging"}}'
```

Now check if the running pod sees the change:

```bash
kubectl exec -it deployment/yatri-backend -- env | grep ENVIRONMENT
```

Output:

```text
ENVIRONMENT=production
```

It did not change. Environment variables are set once when the container starts.
To apply the new value, trigger a rolling restart:

```bash
kubectl rollout restart deployment/yatri-backend
kubectl rollout status deployment/yatri-backend
```

Now check again:

```bash
kubectl exec -it deployment/yatri-backend -- env | grep ENVIRONMENT
```

Output:

```text
ENVIRONMENT=staging
```

Patch it back to production before cleanup:

```bash
kubectl patch configmap yatri-app-config --type merge -p '{"data":{"ENVIRONMENT":"production"}}'
kubectl rollout restart deployment/yatri-backend
```

---

## Lab Cleanup

When the instructor says to clean up, run:

```bash
bash cleanup.sh
```

Expected output:

```text
[INFO] Deleting Ingress...
ingress.networking.k8s.io "yatri-ingress" deleted
[INFO] Deleting Backend Deployment and Service...
deployment.apps "yatri-backend" deleted
service "yatri-backend-service" deleted
[INFO] Deleting Frontend Deployment and Service...
deployment.apps "yatri-frontend" deleted
service "yatri-frontend-service" deleted
[INFO] Deleting Secret...
secret "yatri-db-secret" deleted
[INFO] Deleting ConfigMap...
configmap "yatri-app-config" deleted
[INFO] All demo resources removed.
```

Verify everything is gone:

```bash
kubectl get all -l app=yatri-app
kubectl get configmap yatri-app-config
kubectl get secret yatri-db-secret
kubectl get ingress yatri-ingress
```

Each command should return `No resources found` or `Error from server (NotFound)`.

---

## Lab Completion Checklist

- [ ] Applied `configmap.yaml` and read a key using `-o jsonpath`.
- [ ] Applied `secret.yaml` and decoded `POSTGRES_PASSWORD` with `base64 --decode`.
- [ ] Applied `backend.yaml` and verified environment variables inside the pod with `kubectl exec`.
- [ ] Applied `frontend.yaml` and confirmed both services are `ClusterIP` type.
- [ ] Enabled the NGINX Ingress Controller and confirmed the controller pod is `Running`.
- [ ] Applied `ingress.yaml` and confirmed an `ADDRESS` appeared in `kubectl get ingress`.
- [ ] Tested path `/` returns Nginx HTML using `curl -H "Host: yatri.local"`.
- [ ] Tested path `/api/` returns the backend config values using `curl -H "Host: yatri.local"`.
- [ ] Demonstrated the `echo` vs `echo -n` newline bug difference.
- [ ] Triggered a rolling restart after updating a ConfigMap value and confirmed the new value was loaded.
