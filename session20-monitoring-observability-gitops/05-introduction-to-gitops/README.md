# 05 - Introduction to GitOps

GitOps is a way of managing infrastructure and application deployment using Git.

The central idea:

> Git describes the desired state of the system.

---

# Traditional Deployment

A developer might do:

```bash
kubectl apply -f deployment.yaml
```

Directly:

```text
Developer
    |
    v
kubectl
    |
    v
Kubernetes
```

---

# GitOps Deployment

With GitOps:

```text
Developer
    |
    v
Git
    |
    v
Argo CD
    |
    v
Kubernetes
```

The developer changes Git.

Argo CD notices.

Argo CD synchronizes the cluster.

---

# Why Git?

Git gives us:

```text
History
Review
Diffs
Rollback point
Collaboration
Audit trail
```

Suppose:

```text
Monday:
replicas = 2

Tuesday:
replicas = 5

Wednesday:
replicas = 2
```

Git records these changes.

---

# Desired State

Suppose Git contains:

```yaml
spec:
  replicas: 3
```

This means:

> "I want 3 replicas."

The cluster might currently have:

```text
2 replicas
```

GitOps controller sees:

```text
Desired = 3
Actual  = 2
```

It works toward:

```text
Actual = 3
```

---

# Demo Manifest

Look at:

```text
app/deployment.yaml
```

It says:

```yaml
replicas: 2
```

Apply it manually once just to understand Kubernetes:

```bash
kubectl apply -f app/
```

Check:

```bash
kubectl get deployment
```

Expected shape:

```text
NAME             READY   UP-TO-DATE   AVAILABLE
session20-app    2/2     2            2
```

---

# Important

In real GitOps:

```text
Git
  |
  v
Controller
  |
  v
Cluster
```

You generally do not make routine production changes by manually editing the cluster.

You change the Git configuration.

---

# Practice

Explain:

```text
Git = desired state
Cluster = actual state
Argo CD = keeps them synchronized
```
