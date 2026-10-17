# Task 12 — Canary Deployment & Traffic Split

## Why
A canary deployment routes a small percentage of traffic to the new version while most users still hit the stable version. This lets you test v2 in production with real traffic before fully promoting it. The traffic split is **probabilistic** — based on the ratio of canary pods to total pods.

## How It Works

```
Service: myapp-canary-service (selector: app=myapp-canary)
         ├── app-stable pods (track=stable, v1)  →  9 pods  →  ~90% traffic
         └── app-canary pods (track=canary, v2)  →  1 pod   →  ~10% traffic
```

The Service uses `selector: app=myapp-canary` which matches **both** deployments (they share that label). kube-proxy load-balances across all 10 pods, so the traffic ratio equals the pod count ratio.

## YAML Files Used

| File | Purpose |
|------|---------|
| `deployment-stable.yaml` | 9 replicas of v1 (nginx:1.24-alpine), label `track=stable` |
| `deployment-canary.yaml` | 1 replica of v2 (nginx:1.25-alpine), label `track=canary` |
| `service.yaml` | NodePort service on port 30030, selects all `app=myapp-canary` pods |

---

## Step-by-Step Commands (PowerShell)

### Step 1 — Deploy stable (v1) and canary (v2)

```powershell
kubectl apply -f 03-canary/deployment-stable.yaml
kubectl apply -f 03-canary/service.yaml
kubectl apply -f 03-canary/deployment-canary.yaml
```

### Step 2 — Wait for rollout

```powershell
kubectl rollout status deployment/app-stable
kubectl rollout status deployment/app-canary
```

Expected output:
```
deployment "app-stable" successfully rolled out
deployment "app-canary" successfully rolled out
```

### Step 3 — Verify pod counts (9 stable + 1 canary = 10 total)

```powershell
kubectl get pods -l app=myapp-canary -o wide
```

Expected output:
```
NAME                            READY   STATUS    RESTARTS   AGE   IP            NODE
app-stable-xxxxx-aaaaa          1/1     Running   0          30s   10.244.0.x    minikube
app-stable-xxxxx-bbbbb          1/1     Running   0          30s   10.244.0.x    minikube
app-stable-xxxxx-ccccc          1/1     Running   0          30s   10.244.0.x    minikube
app-stable-xxxxx-ddddd          1/1     Running   0          30s   10.244.0.x    minikube
app-stable-xxxxx-eeeee          1/1     Running   0          30s   10.244.0.x    minikube
app-stable-xxxxx-fffff          1/1     Running   0          30s   10.244.0.x    minikube
app-stable-xxxxx-ggggg          1/1     Running   0          30s   10.244.0.x    minikube
app-stable-xxxxx-hhhhh          1/1     Running   0          30s   10.244.0.x    minikube
app-stable-xxxxx-iiiii          1/1     Running   0          30s   10.244.0.x    minikube
app-canary-xxxxx-jjjjj          1/1     Running   0          10s   10.244.0.x    minikube
```

### Step 4 — Test ~10% traffic split (200 requests)

**Note:** On Windows, use `curl.exe` and `Measure-Command` or a PowerShell loop:

```powershell
$stableCount = 0; $canaryCount = 0
for ($i = 1; $i -le 200; $i++) {
    $response = curl.exe -s http://localhost:30030
    if ($response -match "CANARY v2") { $canaryCount++ }
    else { $stableCount++ }
}
Write-Host "=== 10% Phase ==="
Write-Host "STABLE v1: $stableCount / 200 requests"
Write-Host "CANARY v2: $canaryCount / 200 requests"
Write-Host "Canary percentage: $([math]::Round($canaryCount/200*100, 1))%"
```

**Note:** You need port-forward running in another terminal:
```powershell
kubectl port-forward svc/myapp-canary-service 30030:80
```

Expected output (approximate — probabilistic):
```
=== 10% Phase ===
STABLE v1: 177 / 200 requests
CANARY v2: 23 / 200 requests
Canary percentage: 11.5%
```

### Step 5 — Scale up canary to ~30% (3 canary + 7 stable)

```powershell
kubectl scale deployment app-canary --replicas=3
kubectl scale deployment app-stable --replicas=7
```

Wait for new pods:
```powershell
kubectl rollout status deployment/app-canary
kubectl rollout status deployment/app-stable
```

### Step 6 — Test ~30% traffic split

```powershell
$stableCount = 0; $canaryCount = 0
for ($i = 1; $i -le 200; $i++) {
    $response = curl.exe -s http://localhost:30030
    if ($response -match "CANARY v2") { $canaryCount++ }
    else { $stableCount++ }
}
Write-Host "=== 30% Phase ==="
Write-Host "STABLE v1: $stableCount / 200 requests"
Write-Host "CANARY v2: $canaryCount / 200 requests"
Write-Host "Canary percentage: $([math]::Round($canaryCount/200*100, 1))%"
```

Expected output (approximate):
```
=== 30% Phase ===
STABLE v1: 135 / 200 requests
CANARY v2: 65 / 200 requests
Canary percentage: 32.5%
```

### Step 7 — Rollback (scale canary to 0)

```powershell
kubectl scale deployment app-canary --replicas=0
kubectl scale deployment app-stable --replicas=9
```

Verify 100% stable:
```powershell
$stableCount = 0; $canaryCount = 0
for ($i = 1; $i -le 20; $i++) {
    $response = curl.exe -s http://localhost:30030
    if ($response -match "CANARY v2") { $canaryCount++ }
    else { $stableCount++ }
}
Write-Host "=== Rollback Phase ==="
Write-Host "STABLE v1: $stableCount / 20 requests"
Write-Host "CANARY v2: $canaryCount / 20 requests"
```

Expected output:
```
=== Rollback Phase ===
STABLE v1: 20 / 20 requests
CANARY v2: 0 / 20 requests
```

### Step 8 — Cleanup

```powershell
kubectl delete svc myapp-canary-service
kubectl delete deployment app-stable app-canary
```

---

## Traffic Split Summary

| Phase | Canary Replicas | Stable Replicas | Total | Expected Canary % |
|-------|----------------|-----------------|-------|-------------------|
| Initial | 1 | 9 | 10 | ~10% |
| Scale up | 3 | 7 | 10 | ~30% |
| Rollback | 0 | 9 | 9 | 0% |

## Key Takeaway

- **Traffic split = pod count ratio** — no special networking config needed
- The Service selects both deployments via the shared label `app=myapp-canary`
- Scaling canary up/down **instantly** changes the traffic percentage
- Rolling back is just `scale canary to 0` — zero downtime, zero disruption
- Results are **probabilistic** (kube-proxy random load balancing), so actual percentages may vary slightly from the target

> **Note:** Screenshots not yet captured..
