# Recreate Deployment Strategy

## What is the Recreate Strategy?

The **Recreate** deployment strategy is an "all-or-nothing" approach to updating applications in Kubernetes.

When you update a Deployment configured with `type: Recreate`:
1. Kubernetes **immediately terminates all existing pods** (v1) simultaneously.
2. The cluster waits until every old pod has fully stopped.
3. Once zero old pods are running, Kubernetes **creates the new pods** (v2).

```text
Time Line:
[v1] [v1] [v1]  (Healthy running pods)
      |
      v  Update triggered (kubectl apply -f deployment-v2.yaml)
[Terminating] [Terminating] [Terminating]
      |
      v
[No pods running]  <--- DOWNTIME WINDOW (Users get 502 / Connection Refused)
      |
      v
[ContainerCreating] [ContainerCreating] [ContainerCreating]
      |
      v
[v2] [v2] [v2]  (Service restored with new version)
```

---

## Real-World Mental Model

Think of a **restaurant renovation**:
* **Rolling Update**: Renovation happens room by room while the restaurant stays open. Customers are routed to available tables.
* **Blue-Green**: You build a brand new restaurant building across the street. Once completely ready, you redirect customers to the new building.
* **Canary**: You open a tiny VIP tasting counter with the new menu for 10% of customers to test reactions before revamping the main menu.
* **Recreate**: You hang a sign: *"Closed for renovations from 2 PM to 5 PM"*. All dining stops. The entire interior is gutted and rebuilt. Doors reopen at 5 PM.

---

## Why Would Anyone Choose Downtime?

At first glance, deliberate downtime seems undesirable. However, production systems use `Recreate` for specific architectural constraints:

### 1. Breaking Database Schema Migrations
If v1 expects a database column named `phone_number` and v2 modifies it to `country_code + national_number`, running v1 and v2 simultaneously will corrupt customer data. You must shut down v1 before applying the migration and starting v2.

### 2. ReadWriteOnce (RWO) Storage Volumes
Cloud disks (AWS EBS, GCP Persistent Disk) can only be mounted by **one virtual machine node at a time** in ReadWriteOnce mode. A Rolling Update fails because the old pod holds the volume lock, preventing the new pod from attaching the volume. `Recreate` releases the volume first so the new pod can mount it.

### 3. State-Locked Legacy Applications
Legacy monolithic software that cannot operate in distributed multi-instance modes (e.g., license servers, single-writer queues).

### 4. Cost and Resource Constraints in Non-Production
In development or staging clusters with limited CPU and RAM quotas, there may not be capacity to surge extra pods.

---

## Step-by-Step Hands-on Demonstration

### Step 1: Deploy Version 1 (3 replicas)
```bash
kubectl apply -f 04-recreate/deployment-v1.yaml
kubectl apply -f 04-recreate/service.yaml
```

Output:
```text
deployment.apps/app-recreate created
service/app-recreate-service created
```

Verify pods are running:
```bash
kubectl get pods -l app=app-recreate
```

Output:
```text
NAME                            READY   STATUS    RESTARTS   AGE
app-recreate-5899479b69-84x9q   1/1     Running   0          22s
app-recreate-5899479b69-q2f7m   1/1     Running   0          22s
app-recreate-5899479b69-z8l2k   1/1     Running   0          22s
```

Test access via NodePort 30040:
```bash
curl http://localhost:30040
```

Output:
```html
<html><body style="background:#1b262c;color:#0f4c81;font-family:monospace;font-size:2.5em;text-align:center;padding-top:20vh">
<p style="color:#bbe1fa">STRATEGY: RECREATE</p>
<p style="color:#3282b8">VERSION: v1</p>
<p style="font-size:0.4em;color:#bbe1fa">All v1 pods will be killed before v2 starts</p>
</body></html>
```

---

### Step 2: Trigger the Recreate Update

Open two terminal windows side-by-side to watch the downtime behavior:

#### Terminal 1: Watch pods in real time
```bash
kubectl get pods -l app=app-recreate -w
```

#### Terminal 2: Apply the v2 deployment
```bash
kubectl apply -f 04-recreate/deployment-v2.yaml
```

Observe Terminal 1:
```text
NAME                            READY   STATUS        RESTARTS   AGE
app-recreate-5899479b69-84x9q   1/1     Terminating   0          84s
app-recreate-5899479b69-q2f7m   1/1     Terminating   0          84s
app-recreate-5899479b69-z8l2k   1/1     Terminating   0          84s
app-recreate-5899479b69-84x9q   0/1     Terminating   0          87s
app-recreate-5899479b69-q2f7m   0/1     Terminating   0          87s
app-recreate-5899479b69-z8l2k   0/1     Terminating   0          87s

# NOTICE: ZERO PODS ARE RUNNING AT THIS POINT (DOWNTIME WINDOW)

app-recreate-7774c869c8-d42wz   0/1     Pending            0          0s
app-recreate-7774c869c8-k9x12   0/1     Pending            0          0s
app-recreate-7774c869c8-m78qp   0/1     Pending            0          0s
app-recreate-7774c869c8-d42wz   0/1     ContainerCreating  0          1s
app-recreate-7774c869c8-k9x12   0/1     ContainerCreating  0          1s
app-recreate-7774c869c8-m78qp   0/1     ContainerCreating  0          1s
app-recreate-7774c869c8-d42wz   1/1     Running            0          4s
app-recreate-7774c869c8-k9x12   1/1     Running            0          4s
app-recreate-7774c869c8-m78qp   1/1     Running            0          4s
```

---

### Step 3: Observe the Outage During Recreate

If you run a curl loop during the transition:
```bash
while true; do curl -s --connect-timeout 1 http://localhost:30040 | grep -o 'VERSION: [^<]*' || echo "[OUTAGE] Connection failed"; sleep 0.5; done
```

Output:
```text
VERSION: v1
VERSION: v1
[OUTAGE] Connection failed
[OUTAGE] Connection failed
[OUTAGE] Connection failed
VERSION: v2 (UPGRADED)
VERSION: v2 (UPGRADED)
```

This live output clearly proves to students why Recreate has downtime and why it must be used intentionally during scheduled maintenance windows.

---

### Step 4: Verify Version 2

```bash
curl http://localhost:30040
```

Output:
```html
<html><body style="background:#0f4c81;color:#ffffff;font-family:monospace;font-size:2.5em;text-align:center;padding-top:20vh">
<p style="color:#bbe1fa">STRATEGY: RECREATE</p>
<p style="color:#00ffcc">VERSION: v2 (UPGRADED)</p>
<p style="font-size:0.4em;color:#ffffff">Successfully replaced after full shutdown</p>
</body></html>
```

---

### Step 5: Rollback Demonstration

If v2 has an issue and you must revert to v1:
```bash
kubectl rollout undo deployment/app-recreate
```

Output:
```text
deployment.apps/app-recreate rolled back
```

Check rollout status:
```bash
kubectl rollout status deployment/app-recreate
```

Output:
```text
deployment "app-recreate" successfully rolled out
```

---

## Strategy Comparison Matrix

| Strategy | Downtime? | Cost / Resource Overhead | Rollback Speed | Best Used For |
|---|---|---|---|---|
| **RollingUpdate** | Zero downtime | Low (+25% capacity during update) | Fast (`kubectl rollout undo`) | Default for stateless web apps and microservices |
| **Blue-Green** | Zero downtime | High (200% capacity required) | Instant (update service selector) | Mission-critical apps requiring atomic cutover and instant rollback |
| **Canary** | Zero downtime | Low (only small extra canary pool) | Fast (scale canary down to 0) | High-traffic services needing real-user validation before full rollout |
| **Recreate** | Yes (brief outage) | Zero (no surge capacity needed) | Slower (requires killing v2 and starting v1) | Schema migrations, RWO storage locks, dev environments |

---

## Cleanup
```bash
kubectl delete -f 04-recreate/service.yaml
kubectl delete -f 04-recreate/deployment-v2.yaml
```
