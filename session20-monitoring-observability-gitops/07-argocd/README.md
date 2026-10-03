# GitOps Demo with Argo CD

Argo CD watches this Git repository and keeps your Kubernetes cluster in sync with whatever is committed here.

```
You  →  git push  →  GitHub  →  Argo CD detects change  →  Kubernetes updated automatically
```

---

## Repository Structure

```
gitops-demo/
├── README.md                        ← this file
└── app/
    ├── deployment.yaml              ← your actual application (nginx pods)
    ├── service.yaml                 ← exposes the app inside the cluster
    └── argocd-application.yaml      ← tells Argo CD WHERE to find the above files
```

### What is what?

| File | What it is | Who applies it |
|------|-----------|----------------|
| `app/deployment.yaml` | Your **actual application** — nginx containers | Argo CD (automatically from Git) |
| `app/service.yaml` | Makes the app reachable inside the cluster | Argo CD (automatically from Git) |
| `app/argocd-application.yaml` | Argo CD config that points at this repo | **You apply this once manually** |

> **The key confusion point:** You never directly apply `deployment.yaml` or `service.yaml` with kubectl.
> Instead, you apply `argocd-application.yaml` **once**, and then Argo CD reads the `app/` folder
> from GitHub and deploys everything automatically — now and on every future `git push`.

---

## Prerequisites

| Tool | Install |
|------|---------|
| Docker Desktop | https://www.docker.com/products/docker-desktop/ |
| kind | https://kind.sigs.k8s.io/docs/user/quick-start/#installation |
| kubectl | https://kubernetes.io/docs/tasks/tools/ |

---

## Step 1 — Create a Local Kubernetes Cluster

```bash
kind create cluster --name session20
```

Verify it is running:

```bash
kubectl cluster-info
kubectl get nodes
```

Expected:

```
NAME                     STATUS   ROLES
session20-control-plane  Ready    control-plane
```

---

## Step 2 — Install Argo CD

```bash
kubectl create namespace argocd

kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply the ApplicationSet CRD separately (required — avoids CrashLoopBackOff)
curl -sL https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/applicationset-crd.yaml \
  | kubectl apply --server-side -f -
```

Wait for all pods to reach `Running` (takes 2–5 min, images are large):

```bash
kubectl get pods -n argocd -w
```

Expected output when ready:

```
argocd-application-controller-0                    1/1  Running
argocd-applicationset-controller-...               1/1  Running
argocd-dex-server-...                              1/1  Running
argocd-notifications-controller-...               1/1  Running
argocd-redis-...                                   1/1  Running
argocd-repo-server-...                             1/1  Running
argocd-server-...                                  1/1  Running
```

Press `Ctrl+C` when all show `Running`.

---

## Step 3 — Access the Argo CD UI

Open a **new terminal tab** and run (keep it open):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open your browser at:

```
https://localhost:8080
```

> Your browser shows a certificate warning — click **Advanced → Proceed**. This is normal for local labs.

### Get the admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

Login with:
- **Username:** `admin`
- **Password:** output of the command above

---

## Step 4 — Register Your App with Argo CD (One-time Step)

This is the **single manual step** you do once. It tells Argo CD:
*"Watch the `app/` folder in this GitHub repo and deploy whatever is there into the `session20` namespace."*

```bash
kubectl apply -f app/argocd-application.yaml
```

### What this file does

```yaml
# app/argocd-application.yaml
source:
  repoURL: https://github.com/Nency-Ravaliya/gitops-demo.git
  targetRevision: main
  path: app          # ← Argo CD reads deployment.yaml + service.yaml from here

destination:
  namespace: session20   # ← deploys into this namespace in your cluster

syncPolicy:
  automated:
    prune: true        # ← deletes k8s resources if you remove files from Git
    selfHeal: true     # ← reverts manual kubectl changes back to what Git says
  syncOptions:
    - CreateNamespace=true   # ← creates the session20 namespace automatically
```

After applying, Argo CD will:
1. Read `deployment.yaml` and `service.yaml` from GitHub
2. Create the `session20` namespace
3. Deploy your nginx application

---

## Step 5 — Verify Your Application is Running

Check that Argo CD deployed your app:

```bash
# See the pods (your actual nginx containers)
kubectl get pods -n session20

# See the deployment
kubectl get deployment session20-gitops-app -n session20

# See what Argo CD thinks
kubectl get applications -n argocd
```

Expected:

```
# pods
NAME                                    READY   STATUS
session20-gitops-app-...               1/1     Running
session20-gitops-app-...               1/1     Running
... (5 total)

# application
NAME            SYNC STATUS   HEALTH STATUS
session20-app   Synced        Healthy
```

---

## Step 6 — Open Your Actual Application in a Browser

Your app is nginx running inside Kubernetes. To access it locally:

Open a **new terminal tab** and run (keep it open):

```bash
kubectl port-forward svc/session20-gitops-app -n session20 9090:80
```

Then open:

```
http://localhost:9090
```

You will see the **nginx welcome page** — this is your actual application running in the cluster.

```
Two port-forwards you need open simultaneously:
  Terminal 1: kubectl port-forward svc/argocd-server -n argocd 8080:443    → Argo CD UI
  Terminal 2: kubectl port-forward svc/session20-gitops-app -n session20 9090:80 → Your app
```

---

## Step 7 — GitOps in Action: Scale by Committing to Git

This is the whole point of GitOps. You **do not** run `kubectl scale`.
You change a file, push it to Git, and Argo CD syncs the cluster automatically.

---

### Scale down to 2 replicas

**1. Edit `app/deployment.yaml`:**

```yaml
# Change this:
replicas: 5

# To this:
replicas: 2
```

**2. Commit and push:**

```bash
git add app/deployment.yaml
git commit -m "Scale down to 2 replicas"
git push
```

**3. Watch Argo CD sync (within ~30 seconds):**

```bash
kubectl get pods -n session20 -w
```

You will see pods terminating until only 2 remain.

**4. Verify:**

```bash
kubectl get deployment session20-gitops-app -n session20
```

```
NAME                   READY   UP-TO-DATE   AVAILABLE
session20-gitops-app   2/2     2            2
```

---

### Scale up to 3 replicas

**1. Edit `app/deployment.yaml`:**

```yaml
replicas: 3
```

**2. Commit and push:**

```bash
git add app/deployment.yaml
git commit -m "Scale up to 3 replicas"
git push
```

**3. Verify:**

```bash
kubectl get deployment session20-gitops-app -n session20
```

```
NAME                   READY   UP-TO-DATE   AVAILABLE
session20-gitops-app   3/3     3            3
```

---

## How Auto-Sync Works

```
┌─────────────────────────────────────────────────────────────┐
│  You edit app/deployment.yaml and git push                  │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
                   GitHub Repository
             (Nency-Ravaliya/gitops-demo)
                           │
              Argo CD polls every 3 minutes
                           │
                           ▼
            ┌──────────────────────────┐
            │        Argo CD           │
            │  Sees Git changed        │
            │  Compares desired state  │
            │  vs current cluster      │
            │  Applies the difference  │
            └──────────────┬───────────┘
                           │
                           ▼
            ┌──────────────────────────┐
            │  Kubernetes (kind)       │
            │  namespace: session20    │
            │  session20-gitops-app    │
            │  (nginx pods updated)    │
            └──────────────────────────┘
```

---

## Quick Reference — Commit Message Conventions

```bash
# Scaling changes
git commit -m "Scale to 2 replicas"
git commit -m "Scale up to 5 replicas for load testing"

# Image updates
git commit -m "Bump nginx to 1.28-alpine"

# Config changes
git commit -m "Add resource limits to deployment"
```

---

## Useful Commands

```bash
# ─── Argo CD ───────────────────────────────────────────────
kubectl get pods -n argocd                          # see Argo CD pods
kubectl get applications -n argocd                  # see sync status

# ─── Your Application ──────────────────────────────────────
kubectl get pods -n session20                       # see nginx pods
kubectl get deployment session20-gitops-app -n session20  # see replica count
kubectl get svc -n session20                        # see services

# ─── Port Forwards ─────────────────────────────────────────
# Argo CD UI   → https://localhost:8080
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Your app     → http://localhost:9090
kubectl port-forward svc/session20-gitops-app -n session20 9090:80

# ─── Get Admin Password ────────────────────────────────────
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

---

## Clean Up

```bash
# Remove the Argo CD application (also removes your app from the cluster)
kubectl delete -f app/argocd-application.yaml

# Delete the local Kubernetes cluster entirely
kind delete cluster --name session20
```

---

## Troubleshooting

### My app is not showing up in the `session20` namespace

Make sure you applied the Argo CD Application:

```bash
kubectl get applications -n argocd
```

If the list is empty:

```bash
kubectl apply -f app/argocd-application.yaml
```

### Argo CD shows `OutOfSync` and is not syncing automatically

Check that `automated` is set in `app/argocd-application.yaml`:

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

Or manually trigger a sync:

```bash
kubectl patch application session20-app -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'
```

### `argocd-applicationset-controller` in CrashLoopBackOff

**Error:** `no matches for kind "ApplicationSet" in version "argoproj.io/v1alpha1"`

**Fix:** Re-apply the full install to restore the missing CRD:

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl rollout restart deployment argocd-applicationset-controller -n argocd
```

### Port-forward disconnects

Just re-run the port-forward command. Port-forwards are not persistent — they drop if the terminal closes or the pod restarts.
