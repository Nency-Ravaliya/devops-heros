# Module 04: Horizontal Pod Autoscaler (HPA) & Metrics Server

## Overview
During high-traffic events (e.g., flash sales, unexpected surges), workloads must scale elastically to absorb load without human intervention. 

The **Horizontal Pod Autoscaler (HPA)** automatically scales the number of Pod replicas in a Deployment, StatefulSet, or ReplicaSet based on observed resource utilization (CPU, memory) or custom metrics.

---

## Important Theoretical Concepts

### 1. Horizontal Scaling vs Vertical Scaling
- **Vertical Scaling (VPA)**: Making a single existing container bigger (more CPU/RAM). Requires restarting the container in most environments.
- **Horizontal Scaling (HPA)**: Adding or removing identical Pod replicas behind a Service. Provides zero-downtime elasticity and distributed load resilience.

### 2. The Metrics Pipeline & Metrics Server
The HPA controller cannot read hardware statistics directly from Linux containers. It relies on the Kubernetes Metrics Pipeline:

```text
Pod Containers (cgroups)
          │
          ▼
Kubelet (cAdvisor daemon)
          │
          ▼
Metrics Server (scrapes cluster-wide every 15s)
          │
          ▼
Kubernetes Metrics API (metrics.k8s.io/v1)
          │
          ▼
Horizontal Pod Autoscaler (queries every 15s)
          │
          ▼
Deployment (updates .spec.replicas)
```

Without **Metrics Server**, `kubectl top nodes` and `kubectl top pods` fail, and HPA displays `TARGETS: <unknown>/50%`.

### 3. HPA Calculation Formula
Every 15 seconds (configurable via `--horizontal-pod-autoscaler-sync-period`), the HPA controller evaluates:

$$\text{Desired Replicas} = \left\lceil \text{Current Replicas} \times \left( \frac{\text{Current Metric Value}}{\text{Target Metric Value}} \right) \right\rceil$$

**Example Calculation**:
- Current Replicas: 2 Pods
- Current Average CPU: 120m
- Requested CPU per container: 100m (Current Utilization = 120%)
- Target Utilization: 50%

$$\text{Desired Replicas} = \left\lceil 2 \times \left( \frac{120}{50} \right) \right\rceil = \left\lceil 2 \times 2.4 \right\rceil = \lceil 4.8 \rceil = 5 \text{ Pods}$$

### 4. The Critical Role of `resources.requests.cpu`
> **GOLDEN RULE**: HPA calculates percentage utilization as:
> $$\text{Utilization} = \frac{\text{Current CPU Usage}}{\text{Requested CPU}} \times 100$$
> If `resources.requests.cpu` is omitted from the Pod specification, the denominator is undefined. HPA cannot compute percentage, and autoscaling will **never** trigger!

### 5. Flapping & Cooldown Stabilization Window
To prevent "flapping" (rapidly scaling up and down due to tiny momentary traffic spikes), Kubernetes enforces a stabilization window:
- Scale-up: Immediate reaction to absorb incoming traffic.
- Scale-down: Enforces a default 5-minute cooldown (`stabilizationWindowSeconds: 300`) to ensure traffic has truly returned to baseline before terminating Pods.

---

## Code Manifests in This Directory

| File | Resource Kind | Purpose |
| :--- | :--- | :--- |
| [`deployment.yaml`](file:///Users/nensiravaliya/Downloads/scaler-devops-session/devops-course/sessions/session-13-storage-hpa-probes/04-hpa/deployment.yaml) | `Deployment` | Nginx web app with explicit CPU requests (`100m`) and limits (`200m`) |
| [`service.yaml`](file:///Users/nensiravaliya/Downloads/scaler-devops-session/devops-course/sessions/session-13-storage-hpa-probes/04-hpa/service.yaml) | `Service` | ClusterIP service exposing port 80 to distribute traffic across Pods |
| [`hpa.yaml`](file:///Users/nensiravaliya/Downloads/scaler-devops-session/devops-course/sessions/session-13-storage-hpa-probes/04-hpa/hpa.yaml) | `HorizontalPodAutoscaler` | Autoscaling rule targeting `hpa-demo` between 1 and 5 replicas at 50% CPU |

---

## Step-by-Step Hands-on Commands & Expected Outputs

### Step 1: Enable and Verify Metrics Server
In Minikube:
```bash
minikube addons enable metrics-server
```
Wait 30–60 seconds, then verify:
```bash
kubectl top nodes
```
Expected output:
```text
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
minikube   180m         9%     950Mi           24%
```

### Step 2: Deploy Workload, Service, and HPA
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml
```
Check initial HPA status:
```bash
kubectl get hpa hpa-demo
```
Expected output:
```text
NAME       REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   0%/50%    1         5         1          20s
```

### Step 3: Run Traffic Load Generator & Watch Scaling Out
In a second terminal pane, launch a load generator pod:
```bash
kubectl run load-generator \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://hpa-demo-service; done"
```

In the main terminal, watch live HPA decisions:
```bash
kubectl get hpa hpa-demo -w
```
Expected log progression:
```text
NAME       REFERENCE             TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   0%/50%     1         5         1          30s
hpa-demo   Deployment/hpa-demo   85%/50%    1         5         2          1m
hpa-demo   Deployment/hpa-demo   125%/50%   1         5         3          2m
hpa-demo   Deployment/hpa-demo   60%/50%    1         5         4          3m
```

Check the active Pod count:
```bash
kubectl get pods -l app=hpa-demo
```
Expected output:
```text
NAME                        READY   STATUS    RESTARTS   AGE
hpa-demo-7988df964b-abcde   1/1     Running   0          4m
hpa-demo-7988df964b-fghij   1/1     Running   0          2m
hpa-demo-7988df964b-klmno   1/1     Running   0          1m
hpa-demo-7988df964b-pqrst   1/1     Running   0          45s
```

### Step 4: Stop Traffic & Watch Scale In
```bash
kubectl delete pod load-generator
kubectl get hpa hpa-demo -w
```
After the 5-minute stabilization window, replicas will gradually reduce back down to 1:
```text
hpa-demo   Deployment/hpa-demo   0%/50%   1   5   1   8m
```

---

## Common Mistakes & Troubleshooting
1. **`TARGETS: <unknown>/50%`**:
   - Cause 1: Metrics Server not running. Check `kubectl get pods -n kube-system | grep metrics-server`.
   - Cause 2: Deployment spec lacks `spec.template.spec.containers[].resources.requests.cpu`.
2. **HPA does not scale beyond maxReplicas**:
   - Expected behavior. HPA will never scale past `maxReplicas: 5` to prevent runaway cloud costs.
