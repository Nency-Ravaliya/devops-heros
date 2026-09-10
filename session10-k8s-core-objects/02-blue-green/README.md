# Blue-Green Deployment Strategy

## What is Blue-Green Deployment?

**Blue-Green Deployment** is a release strategy where you maintain **two identical production environments** running side-by-side at all times — called **Blue** (current live version) and **Green** (new version being prepared).

* **Blue** = Current production environment. Serving 100% of live user traffic.
* **Green** = New version environment. Fully deployed and tested, but receiving zero user traffic.

When you are confident the Green environment is healthy and tested, you flip a **single switch** (a Kubernetes Service selector change) to redirect 100% of traffic from Blue to Green — **instantaneously**.

```text
PHASE 1: Normal Operation
  Users ------> [Service] ------> [BLUE: v1] [BLUE: v1] [BLUE: v1]  (LIVE)
                                  [GREEN: v2] [GREEN: v2] [GREEN: v2] (IDLE - warming up)

PHASE 2: Flip the Switch (kubectl apply service-green.yaml)
  Users ------> [Service] ------> [GREEN: v2] [GREEN: v2] [GREEN: v2] (NOW LIVE)
                                  [BLUE: v1]  [BLUE: v1]  [BLUE: v1]  (STANDBY - instant rollback)

PHASE 3: Rollback (if needed) — just flip back
  Users ------> [Service] ------> [BLUE: v1]  (Back to v1 in under 5 seconds)
```

---

## Why Do We Need Blue-Green?

### Problems with Rolling Update:
* During a rolling update, **both v1 and v2 pods are simultaneously serving traffic**. If v2 has a database schema migration incompatible with v1, mixed traffic causes data corruption.
* You cannot do pre-production load testing on the new version with zero user impact.

### Benefits of Blue-Green:
* **Instant cutover:** The switch from v1 to v2 takes under 5 seconds.
* **Instant rollback:** If v2 has a bug, flip the selector back. Rollback takes under 5 seconds.
* **Pre-production testing under production conditions:** Green runs full load tests in the real cluster before receiving user traffic.
* **No mixed traffic:** At any point, 100% of users are on v1 OR 100% are on v2. Never both.

---

## Important Points

* Blue-Green requires **2x the compute resources** (double the pods running simultaneously). This is the trade-off for instant switchover and rollback.
* The **only thing that changes** between Blue and Green is the `selector` field in the Service manifest.
* Keep the Blue environment running for **at least 24 hours** after switching to Green — as your instant rollback safety net.
* Blue-Green is the preferred strategy for **database schema changes** because you can run the migration against the Green pods before switching traffic.
* After a successful Green deployment, recycle Blue pods to save resource costs.

---

## Production Use Cases

* Swiggy, Zomato, Flipkart releasing major application versions during off-peak hours.
* Applications with database migrations requiring a specific version to run first.
* Compliance-regulated applications (banking, healthcare) where rollback SLA must be under 60 seconds.
* Any service with a firm SLA (e.g. 99.99% uptime) that cannot tolerate even 1 request failure during update.

---

## Code Files

| File | Purpose |
| :--- | :--- |
| `deployment-blue.yaml` | 3 pods of v1 (blue background) — initially LIVE |
| `deployment-green.yaml` | 3 pods of v2 (green background) — initially STANDBY |
| `service-blue.yaml` | Service with `selector: slot: blue` — routes to v1 |
| `service-green.yaml` | Service with `selector: slot: green` — routes to v2 |

---

## Step-by-Step Commands

### Step 1: Deploy Both Environments Simultaneously
```bash
kubectl apply -f 02-blue-green/deployment-blue.yaml
kubectl apply -f 02-blue-green/deployment-green.yaml
```

Wait for all 6 pods to be Ready:
```bash
kubectl get pods -l app=myapp --show-labels
```

Expected output (6 pods total — 3 blue, 3 green):
```text
NAME                         READY   STATUS    RESTARTS   AGE   LABELS
app-blue-6c8d9b5f4-5k9tz    1/1     Running   0          30s   app=myapp,slot=blue,version=v1
app-blue-6c8d9b5f4-8qmzj    1/1     Running   0          30s   app=myapp,slot=blue,version=v1
app-blue-6c8d9b5f4-r2lxp    1/1     Running   0          30s   app=myapp,slot=blue,version=v1
app-green-7d4f8c6b9-4hqnw   1/1     Running   0          28s   app=myapp,slot=green,version=v2
app-green-7d4f8c6b9-6kpzt   1/1     Running   0          28s   app=myapp,slot=green,version=v2
app-green-7d4f8c6b9-9trmq   1/1     Running   0          28s   app=myapp,slot=green,version=v2
```

### Step 2: Point Service to BLUE (v1 goes LIVE)
```bash
kubectl apply -f 02-blue-green/service-blue.yaml
```

Test Blue is serving traffic:
```bash
curl http://$(minikube ip):30020
# OR
minikube service myapp-service --url
```

Expected output (visible in browser or terminal):
```text
BLUE ENVIRONMENT
Version: v1 | Slot: BLUE (LIVE)
```

### Step 3: Confirm Service Selector Before the Switch
```bash
kubectl describe svc myapp-service | grep Selector
```

Expected output:
```text
Selector:   app=myapp,slot=blue
```

```bash
kubectl get endpoints myapp-service
```

Expected output (3 blue pod IPs):
```text
NAME             ENDPOINTS                                         AGE
myapp-service    10.244.0.10:80,10.244.0.11:80,10.244.0.12:80    45s
```

### Step 4: THE SWITCH — Flip 100% Traffic to GREEN (v2) Instantly
```bash
kubectl apply -f 02-blue-green/service-green.yaml
```

Expected output:
```text
service/myapp-service configured
```

Test Green is now live:
```bash
curl http://$(minikube ip):30020
```

Expected output:
```text
GREEN ENVIRONMENT
Version: v2 | Slot: GREEN (STANDBY -> PROMOTED)
```

Verify the selector changed:
```bash
kubectl describe svc myapp-service | grep Selector
```

Expected output:
```text
Selector:   app=myapp,slot=green
```

The switch from Blue to Green happened in **milliseconds** — a single `kubectl apply` changed the routing.

### Step 5: Verify Endpoints Changed
```bash
kubectl get endpoints myapp-service
```

Expected output (now shows 3 green pod IPs):
```text
NAME             ENDPOINTS                                         AGE
myapp-service    10.244.0.20:80,10.244.0.21:80,10.244.0.22:80    10s
```

### Step 6: Rollback — Flip Back to Blue in Under 5 Seconds
```bash
kubectl apply -f 02-blue-green/service-blue.yaml
```

Confirm Blue is serving again:
```bash
curl http://$(minikube ip):30020
# Output: BLUE ENVIRONMENT
```

### Step 7: Decommission the Old Blue Environment (After Green is Confirmed Stable)
```bash
kubectl delete deployment app-blue
```

---

## Cleanup
```bash
kubectl delete -f 02-blue-green/service-blue.yaml
kubectl delete -f 02-blue-green/deployment-blue.yaml
kubectl delete -f 02-blue-green/deployment-green.yaml
```
