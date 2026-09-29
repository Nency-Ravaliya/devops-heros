# 06 - Git as Source of Truth

This folder focuses on one important GitOps idea:

> Git stores what we WANT the system to look like.

---

# Source of Truth

Imagine:

```text
Git says:
replicas = 3
```

But Kubernetes currently has:

```text
replicas = 2
```

GitOps says:

```text
Desired state = 3
Actual state  = 2
```

A GitOps controller works to reconcile the difference.

---

# Git Repository Example

Inside:

```text
gitops-repo/
```

we have:

```text
gitops-repo/
|
|-- README.md
|
|-- app/
    |-- deployment.yaml
    |-- service.yaml
```

A real repository could look like:

```text
my-company-gitops/
|
|-- apps/
|   |-- payments/
|   |-- orders/
|   |-- users/
|
|-- environments/
    |-- dev/
    |-- staging/
    |-- production/
```

The exact structure is an engineering choice.

---

# Create a Git Repository

Inside `gitops-repo`:

```bash
cd gitops-repo
git init
```

Check:

```bash
git status
```

Add files:

```bash
git add .
```

Commit:

```bash
git commit -m "Add session 20 application manifests"
```

Expected shape:

```text
[main abc1234] Add session 20 application manifests
 2 files changed
```

The hash is different on every repository.

---

# Change the Desired State

Open:

```text
app/deployment.yaml
```

Change:

```yaml
replicas: 2
```

to:

```yaml
replicas: 3
```

Then:

```bash
git diff
```

You should see a change similar to:

```diff
-  replicas: 2
+  replicas: 3
```

Commit it:

```bash
git add .
git commit -m "Scale application to three replicas"
```

---

# Why This Is Powerful

Now we have history:

```text
Commit 1
replicas = 2
     |
     v
Commit 2
replicas = 3
```

If the team asks:

> "Who changed the deployment?"

Git can answer.

If the team asks:

> "What changed?"

Git can show the diff.

---

# Important Distinction

Git is not the Kubernetes cluster.

```text
Git
 |
 +-- Desired state
 |
 v
Argo CD
 |
 v
Kubernetes
 |
 +-- Actual state
```

Argo CD connects the two.

---

# Practice

Why is Git useful as a source of truth?

Expected ideas:

```text
Version history
Review
Diff
Auditability
Collaboration
Rollback/reference point
```
