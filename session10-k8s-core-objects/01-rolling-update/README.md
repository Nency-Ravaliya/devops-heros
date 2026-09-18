# Rolling Update Strategy

## What is a Rolling Update?

A **Rolling Update** is Kubernetes' default deployment strategy. Instead of killing all old pods and starting new ones at the same time (which causes downtime), Kubernetes incrementally replaces old pods with new ones — a few at a time — while the service stays alive throughout the entire process.

```text
BEFORE UPDATE                           DURING UPDATE                         AFTER UPDATE
4 pods running v1                       3 pods v1 + 1 pod v2                  4 pods running v2
[v1][v1][v1][v1]  -> Service ->  [v1][v1][v1][v2]  -> Service ->  [v2][v2][v2][v2]
    Users get served                Users still served                Users on new version
```

---

## Why Do We Need Rolling Updates?

### The Problem: Big-Bang Deployment (Recreate)
If you shut down 4 old pods and start 4 new pods simultaneously, there is a window (often 30-60 seconds) where **zero pods are running**. Users get `503 Service Unavailable` errors. In production, this is a P1 incident.

### The Solution: Roll pods gradually
* Kubernetes starts 1 new v2 pod (`maxSurge: 1`).
* Waits until the new pod passes its `readinessProbe`.
* Only then terminates 1 old v1 pod.
* Repeats until all 4 pods are v2.
* At no point do 0 pods exist. Zero downtime is guaranteed.

---

## The Two Key Parameters

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1       # How many EXTRA pods can exist above desired count during update
    maxUnavailable: 0 # How many pods can be MISSING from desired count during update
```

| Setting | Meaning | Effect |
| :--- | :--- | :--- |
| `maxSurge: 1` | 1 extra pod allowed temporarily | 4 desired + 1 surge = max 5 pods during rollout |
| `maxUnavailable: 0` | Zero pods can be missing | Service capacity never drops below 4 |
| `maxSurge: 25%` | 25% extra pods (e.g. 1 of 4) | Cloud-cost efficient, same effect |
| `maxUnavailable: 1` | 1 pod can be offline | Faster rollout, brief 75% capacity |

---

## Important Points

* Rolling Update is the **default strategy** if you omit `spec.strategy`. Always set it explicitly for clarity.
* The rollout only advances to the next pod **after** the new pod passes its `readinessProbe`. Without a readiness probe, Kubernetes blindly moves forward and can route traffic to a broken pod.
* Always set `maxUnavailable: 0` for production workloads with SLAs.
* You can **pause** a rollout mid-way: `kubectl rollout pause deployment/app-rolling`
* You can **resume** it: `kubectl rollout resume deployment/app-rolling`
* You can **rollback** to the previous version instantly: `kubectl rollout undo deployment/app-rolling`
* Kubernetes keeps a **rollout history** of the last 10 revisions by default (`revisionHistoryLimit: 10`).

---

## Production Use Case
* **Any stateless microservice** doing a new feature release or bug fix — zero-downtime updates to the order service, payment API, authentication service.
* Rolling updates are the backbone of **Continuous Delivery (CD) pipelines** in GitHub Actions, ArgoCD, and Tekton.

---

## Code Files
* `deployment-v1.yaml` — 4 replicas of v1 app (nginx 1.24, blue background page).
* `deployment-v2.yaml` — 4 replicas of v2 app (nginx 1.25, dark blue background page, "NEW VERSION!" tag).
* `service.yaml` — NodePort Service on port `30010`.

---

## Step-by-Step Commands

### Step 1: Deploy v1
```bash
kubectl apply -f 01-rolling-update/deployment-v1.yaml
kubectl apply -f 01-rolling-update/service.yaml
```

Wait for all pods to be ready:
```bash
kubectl rollout status deployment/app-rolling
```

Expected output:
```text
deployment "app-rolling" successfully rolled out
```

Check pods and their version label:
```bash
kubectl get pods -l app=app-rolling --show-labels
```

Expected output:
```text
NAME                           READY   STATUS    RESTARTS   AGE   LABELS
app-rolling-7b5f9d4c6-5kghm   1/1     Running   0          30s   app=app-rolling,version=v1
app-rolling-7b5f9d4c6-8mfnt   1/1     Running   0          30s   app=app-rolling,version=v1
app-rolling-7b5f9d4c6-d4zlt   1/1     Running   0          30s   app=app-rolling,version=v1
app-rolling-7b5f9d4c6-jkp2q   1/1     Running   0          30s   app=app-rolling,version=v1
```

### Step 2: Check v1 in Browser / Terminal
```bash
# Minikube
curl http://$(minikube ip):30010
# OR
minikube service app-rolling-service --url
```

Expected: Page shows `VERSION: v1` with a dark background.

### Step 3: Trigger the Rolling Update to v2
```bash
kubectl apply -f 01-rolling-update/deployment-v2.yaml
```

### Step 4: Watch the Rollout Happen in Real Time (Run in a separate terminal)
```bash
# Terminal A: Watch pod churn
kubectl get pods -l app=app-rolling -w

# Terminal B: Keep curling the service continuously — zero errors!
while true; do curl -s http://$(minikube ip):30010 | grep VERSION; sleep 1; done
```

Expected pod watch output (you will see v1 pods Terminating as v2 pods start):
```text
NAME                           READY   STATUS              RESTARTS   AGE
app-rolling-7b5f9d4c6-5kghm   1/1     Running             0          2m      <- v1
app-rolling-7b5f9d4c6-8mfnt   1/1     Running             0          2m      <- v1
app-rolling-7b5f9d4c6-d4zlt   1/1     Running             0          2m      <- v1
app-rolling-7b5f9d4c6-jkp2q   1/1     Running             0          2m      <- v1
app-rolling-9c4d8f6b7-t2wnz   0/1     ContainerCreating   0          3s      <- v2 starting
app-rolling-9c4d8f6b7-t2wnz   1/1     Running             0          8s      <- v2 ready
app-rolling-7b5f9d4c6-5kghm   1/1     Terminating         0          2m      <- v1 killed
app-rolling-9c4d8f6b7-m8pxr   0/1     ContainerCreating   0          2s      <- v2 starting
...
```

Expected curl output (service stays alive the whole time):
```text
<p>VERSION: v1</p>
<p>VERSION: v1</p>
<p>VERSION: v2</p>    <- Gradually switches to v2
<p>VERSION: v2</p>
```

### Step 5: Verify v2 is Fully Deployed
```bash
kubectl rollout status deployment/app-rolling
```

```text
deployment "app-rolling" successfully rolled out
```

```bash
kubectl get pods -l app=app-rolling --show-labels
```

All pods now show `version=v2`.

### Step 6: Check Rollout History
```bash
kubectl rollout history deployment/app-rolling
```

Expected output:
```text
deployment.apps/app-rolling
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

### Step 7: Rollback to v1 (One Command!)
```bash
kubectl rollout undo deployment/app-rolling
```

Expected output:
```text
deployment.apps/app-rolling rolled back
```

Verify it rolled back:
```bash
kubectl get pods -l app=app-rolling --show-labels
# All pods show version=v1 again
```

---

## Cleanup
```bash
kubectl delete -f 01-rolling-update/service.yaml
kubectl delete -f 01-rolling-update/deployment-v1.yaml
```
