# Task 11 — Blue-Green Deployment & Cutover

## Why
Blue-Green deployment runs two full environments side-by-side. Traffic is switched instantly by changing the Service selector — no rollout needed. Rollback is just flipping the selector back.

## Commands Used

```powershell
# Deploy both environments
kubectl apply -f 02-blue-green\deployment-blue.yaml
kubectl apply -f 02-blue-green\deployment-green.yaml

# Wait for both to be ready
kubectl rollout status deployment/app-blue
kubectl rollout status deployment/app-green

# Route traffic to BLUE
kubectl apply -f 02-blue-green\service-blue.yaml
curl http://localhost:30020

# SWITCH to GREEN
kubectl apply -f 02-blue-green\service-green.yaml
curl http://localhost:30020

# INSTANT ROLLBACK to BLUE
kubectl apply -f 02-blue-green\service-blue.yaml
curl http://localhost:30020

# Cleanup
kubectl delete svc myapp-service
kubectl delete deployment app-blue app-green
```

## What the Screenshot Shows

1. **Both deployments created** — `app-blue` and `app-green` both rolled out successfully
2. **Service routes to BLUE** — `curl` returns:
   ```html
   <p>BLUE ENVIRONMENT</p>
   <p>Version: v1 | Slot: BLUE (LIVE)</p>
   ```
3. **Switch to GREEN** — `service-green.yaml` applied, selector flipped to `slot: green`:
   ```html
   <p>GREEN ENVIRONMENT</p>
   <p>Version: v2 | Slot: GREEN (STANDBY -> PROMOTED)</p>
   ```
4. **Rollback to BLUE** — `service-blue.yaml` re-applied:
   ```html
   <p>BLUE ENVIRONMENT</p>
   <p>Version: v1 | Slot: BLUE (LIVE)</p>
   ```
5. **Cleanup** — service and both deployments deleted

## How It Works

```
Service Selector: app=myapp, slot=blue  →  Routes to app-blue pods (v1)
Service Selector: app=myapp, slot=green →  Routes to app-green pods (v2)
```

Flipping the selector is **instant** — no pod restart, no rollout, zero downtime.

## Key Takeaway
Blue-Green is ideal when you need **instant cutover** and **instant rollback**. The tradeoff is running double the resources (both environments active simultaneously).

![Blue-Green Cutover](Screenshot%202026-09-21%20041354.jpg)
