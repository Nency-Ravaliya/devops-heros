# 08 - Session 20 Mini Project

You will combine:

```text
Kubernetes
+
Git
+
GitOps
+
Argo CD
```

The goal:

```text
Git
 |
 | desired state
 v
Argo CD
 |
 | automatic sync
 v
Kubernetes
 |
 v
Application
```

---

# Requirements

Build a small application with:

```text
Namespace
Deployment
Service
Argo CD Application
```

The Deployment should have:

```text
replicas: 2
```

---

# Step 1 - Create Cluster

```bash
kind create cluster --name session20
```

Check:

```bash
kubectl get nodes
```

Expected:

```text
NAME
session20-control-plane
```

---

# Step 2 - Install Argo CD

```bash
kubectl create namespace argocd
```

Then:

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait:

```bash
kubectl get pods -n argocd
```

---

# Step 3 - Create a Git Repository

Create a repository on GitHub/GitLab/Bitbucket.

Copy these application manifests into the Git repository:

```text
namespace.yaml
deployment.yaml
service.yaml
```

Your Git repository should contain:

```text
app/
|
|-- namespace.yaml
|-- deployment.yaml
|-- service.yaml
```

Keep this teaching project's `argocd-application.yaml` outside the Git `app/` path. The Application object tells Argo CD which repository/path to watch; it should not be rendered as one of the workload manifests from that same path.

---

# Step 4 - Change Repository URL

Open:

```text
app/argocd-application.yaml
```

Replace:

```text
https://github.com/YOUR_USERNAME/YOUR_GITOPS_REPO.git
```

with your actual repository URL.

Commit and push.

---

# Step 5 - Create Application

Apply the Argo CD Application:

```bash
kubectl apply -f app/argocd-application.yaml
```

Check:

```bash
kubectl get applications -n argocd
```

Expected shape:

```text
NAME             SYNC STATUS   HEALTH STATUS
session20-mini   Synced        Healthy
```

---

# Step 6 - Check Kubernetes

```bash
kubectl get all -n session20
```

You should see:

```text
deployment.apps/session20-mini
service/session20-mini
pod/session20-mini-xxxxx
pod/session20-mini-yyyyy
```

---

# Step 7 - Make a Git Change

Change in the Git repository:

```yaml
replicas: 2
```

to:

```yaml
replicas: 3
```

Commit:

```bash
git add .
git commit -m "Scale application to three replicas"
git push
```

Watch:

```bash
kubectl get deployment -n session20 -w
```

Eventually:

```text
READY   3/3
```

The change travelled through:

```text
Git
 |
 v
Argo CD
 |
 v
Kubernetes
```

That is GitOps.

---

# Step 8 - Demonstrate Self-Healing

After Argo CD has synchronized:

```bash
kubectl scale deployment session20-mini \
  -n session20 \
  --replicas=1
```

Check:

```bash
kubectl get deployment -n session20
```

Because Git still says:

```text
replicas: 3
```

and self-healing is enabled, Argo CD can reconcile the cluster back toward:

```text
replicas: 3
```

This demonstrates:

```text
Git = desired state
Kubernetes = actual state
Argo CD = reconciler
```

---

# Step 9 - Observe the System

Check application logs:

```bash
kubectl logs deployment/session20-mini -n session20
```

Check resources:

```bash
kubectl get pods -n session20
```

Check Argo CD:

```bash
kubectl get application session20-mini -n argocd
```

---

# Final Architecture

```text
              Developer
                  |
                  v
               Git Repo
                  |
             desired state
                  |
                  v
              Argo CD
                  |
             reconciliation
                  |
                  v
            Kubernetes
                  |
          +-------+-------+
          |               |
      Deployment        Service
          |
        Pods
```

---

# Final Viva Questions

Explain these in your own words:

```text
1. Monitoring vs Observability
2. Metrics vs Logs vs Traces
3. What is Prometheus?
4. What is Grafana?
5. What is GitOps?
6. Why is Git called the source of truth?
7. What does Argo CD do?
8. What does "desired state" mean?
9. What does "actual state" mean?
10. What is reconciliation?
11. What does self-healing mean in Argo CD?
12. What happens when replicas change from 2 to 3 in Git?
```

---

# Cleanup

Delete the application:

```bash
kubectl delete -f app/argocd-application.yaml
```

Delete the cluster:

```bash
kind delete cluster --name session20
```

---

# Final Mental Model

Remember only this:

```text
METRICS -> numbers
LOGS    -> events
TRACES  -> request journey

PROMETHEUS -> metrics
GRAFANA    -> dashboards

GIT        -> desired state
ARGO CD    -> reconciliation
KUBERNETES -> actual state
```

And the most important GitOps loop:

```text
        +------------------+
        |       Git        |
        | Desired State    |
        +--------+---------+
                 |
                 v
             Argo CD
                 |
                 v
          Kubernetes
          Actual State
                 |
                 |
                 +-------> Compare
                              |
                              v
                         Reconcile
                              |
                              +----> back to desired state
```
