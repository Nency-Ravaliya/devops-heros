# 07 - Argo CD

Argo CD is a GitOps continuous delivery tool for Kubernetes.

Think:

> "Argo CD watches Git and keeps Kubernetes synchronized with it."

---

# Architecture

```text
Developer
   |
   v
   Git
   |
   | desired state
   v
Argo CD
   |
   | synchronize
   v
Kubernetes
   |
   v
Application
```

---

# Install Argo CD

This lab assumes a local Kubernetes cluster.

Create one:

```bash
kind create cluster --name session20
```

Install Argo CD:

```bash
kubectl create namespace argocd
```

Then:

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Check:

```bash
kubectl get pods -n argocd
```

You should eventually see Argo CD components in:

```text
Running
```

Some pods may take a little time to start.

---

# Access the Argo CD UI

Port forward:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open:

```text
https://localhost:8080
```

Your browser may show a local certificate warning because this is a local lab.

---

# Get the Initial Admin Password

```bash
argocd admin initial-password -n argocd
```

If the `argocd` CLI is not installed, use:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Username:

```text
admin
```

---

# Install the Argo CD CLI

If needed, install `argocd` using the official instructions for your operating system.

Check:

```bash
argocd version --client
```

---

# Connect

With port-forward running:

```bash
argocd login localhost:8080 --insecure
```

Then:

```bash
argocd app list
```

At first there may be no applications.

---

# The Application Manifest

Open:

```text
app/argocd-application.yaml
```

The important fields are:

```yaml
source:
  repoURL: ...
  path: ...
```

and:

```yaml
destination:
  server: ...
  namespace: ...
```

Meaning:

```text
source      = where desired state lives
destination = where it should be deployed
```

---

# IMPORTANT: Replace the Repository URL

The example uses a placeholder:

```text
https://github.com/YOUR_USERNAME/YOUR_GITOPS_REPO.git
```

Replace it with a real Git repository containing the application's Kubernetes manifests.

For this lab, the repository's `app/` folder should contain:

```text
app/
├── deployment.yaml
└── service.yaml
```

Keep `argocd-application.yaml` outside that `app/` folder in the teaching project. It is the Argo CD object that points to the Git repository.

---

# Create the Argo CD Application

After replacing the repository URL:

```bash
kubectl apply -f app/argocd-application.yaml
```

Check:

```bash
kubectl get applications -n argocd
```

Or:

```bash
argocd app list
```

Expected shape:

```text
NAME             SYNC STATUS   HEALTH STATUS
session20-app    Synced        Healthy
```

Exact output depends on repository contents and timing.

---

# What Just Happened?

```text
Git
 |
 | deployment.yaml
 v
Argo CD
 |
 | reads desired state
 v
Kubernetes
 |
 | creates resources
 v
Pods
```

---

# Test GitOps

Change your Git repository:

```yaml
replicas: 2
```

to:

```yaml
replicas: 3
```

Commit and push:

```bash
git add .
git commit -m "Scale application to three replicas"
git push
```

Argo CD detects the Git change.

Depending on sync configuration, it will either:

```text
automatically sync
```

or show the application as:

```text
OutOfSync
```

and wait for a sync.

---

# Enable Automatic Sync

The example Application contains:

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

This means Argo CD can automatically reconcile changes.

Simple meaning:

```text
Git says 3 replicas
        |
        v
Argo CD
        |
        v
Kubernetes should become 3
```

---

# Check

```bash
kubectl get deployment session20-gitops-app
```

Expected after synchronization:

```text
READY   3/3
```

---

# Clean Up

Delete the Argo CD application:

```bash
kubectl delete -f app/argocd-application.yaml
```

Then remove the cluster:

```bash
kind delete cluster --name session20
```

---

# Important Production Idea

GitOps does not mean:

```text
Nobody can ever use kubectl.
```

It means:

> Routine desired-state changes should normally flow through Git so the system remains reviewable and reproducible.
