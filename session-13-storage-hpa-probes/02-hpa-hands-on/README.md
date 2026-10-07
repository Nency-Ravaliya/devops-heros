# Session 13 - Task 2: HPA Hands-on & Autoscaling Verification

**Author:** Shivansh Singh  
**Course:** SST DevOps & Cloud [SWE]  
**Topic:** Horizontal Pod Autoscaler (HPA) Elastic Load Scaling  

---

## 1. Overview & Architecture

Horizontal Pod Autoscaler (HPA) automatically scales the number of Pod worker replicas based on observed CPU utilization (or custom metrics). In this exercise, we configure an HPA rule targeting **50% average CPU utilization** across the `hpa-demo` deployment.

```text
                  +--------------------------------+
                  |         Load Generator         |
                  |  (while true; wget / curl ...) |
                  +---------------+----------------+
                                  |
                                  | High Traffic HTTP Spikes
                                  v
                  +--------------------------------+
                  |  Service: hpa-demo-service     |
                  +---------------+----------------+
                                  |
               +------------------+------------------+
               |                  |                  |
               v                  v                  v
        +--------------+   +--------------+   +--------------+
        | Pod replica1 |   | Pod replica2 |   | Pod replicaN |
        +-------+------+   +-------+------+   +-------+------+
                |                  |                  |
                +------------------+------------------+
                                   |
                                   | Metrics polled (every 15s)
                                   v
                  +--------------------------------+
                  |         Metrics Server         |
                  +----------------+---------------+
                                   |
                                   v
                  +--------------------------------+
                  |   HPA Controller (hpa-demo)    |
                  |     (Target: 50% CPU util)     |
                  +----------------+---------------+
                                   |
                                   | Scales Replicas 1 -> 5
                                   v
                  +--------------------------------+
                  |     Deployment / ReplicaSet    |
                  +--------------------------------+
```

---

## 2. Step-by-Step Hands-on Execution

### Step 2.1: Deploy Application Workload & Service
First, we deploy `php-apache` application with explicit CPU requests and limits:

```bash
$ kubectl apply -f deployment.yaml
deployment.apps/hpa-demo created

$ kubectl apply -f service.yaml
service/hpa-demo-service created

$ kubectl get pods -l app=hpa-demo
NAME                        READY   STATUS    RESTARTS   AGE
hpa-demo-755776d546-d8k2z   1/1     Running   0          18s

$ kubectl get svc hpa-demo-service
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
hpa-demo-service   ClusterIP   10.108.92.144   <none>        80/TCP    24s
```

---

### Step 2.2: Configure Horizontal Pod Autoscaler (`hpa.yml`)
We apply the autoscaling policy specifying:
- **`scaleTargetRef`**: Deployment `hpa-demo`
- **`minReplicas`**: 1
- **`maxReplicas`**: 5
- **`averageUtilization`**: 50%

```bash
$ kubectl apply -f hpa.yml
horizontalpodautoscaler.autoscaling/hpa-demo created
```

---

### Step 2.3: Verify Initial HPA Status
We check that the HPA has registered and is pulling metrics from the cluster's Metrics Server:

```bash
$ kubectl get hpa hpa-demo
NAME       REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   0%/50%    1         5         1          35s
```

Detailed inspection using `kubectl describe hpa`:

```bash
$ kubectl describe hpa hpa-demo
Name:                                                  hpa-demo
Namespace:                                             default
Labels:                                                app=hpa-demo
Annotations:                                           <none>
CreationTimestamp:                                     Wed, 07 Oct 2026 15:20:00 +0530
Reference:                                             Deployment/hpa-demo
Metrics:                                               ( current / target )
  resource cpu on pods  (as a percentage of request):  0% (0m) / 50%
Min replicas:                                          1
Max replicas:                                          5
Deployment pods:                                       1 current / 1 desired
Conditions:
  Type            Status  Reason               Message
  ----            ------  ------               -------
  AbleToScale     True    ScaleDownStabilized  recent recommendations were higher than current one, applying the highest
  ScalingActive   True    ValidMetricFound     the HPA was able to successfully calculate a replica count from cpu resource...
Events:           <none>
```

---

### Step 2.4: Deploy Load Generator & Increase Application Load
Now we launch a load generator pod that performs an infinite loop of HTTP queries against `hpa-demo-service`:

```bash
$ kubectl apply -f load-generator.yaml
deployment.apps/load-generator created

$ kubectl get pods -l app=load-generator
NAME                              READY   STATUS    RESTARTS   AGE
load-generator-58647bb6b6-q7x9w   1/1     Running   0          10s
```

---

### Step 2.5: Observe CPU Utilization Spike
Within 15–30 seconds, the continuous traffic causes CPU consumption to exceed the target 50%:

```bash
$ kubectl top pods
NAME                              CPU(cores)   MEMORY(bytes)
hpa-demo-755776d546-d8k2z         142m         18Mi
load-generator-58647bb6b6-q7x9w   12m          2Mi

$ kubectl get hpa hpa-demo
NAME       REFERENCE             TARGETS     MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   142%/50%    1         5         1          1m45s
```

---

### Step 2.6: Observe Pod Scaling in Real-Time
Because current CPU utilization (`142%`) is far above target (`50%`), HPA computes required replicas:
$$\lceil 1 \times (142 / 50) \rceil = 3 \text{ to } 4 \text{ replicas}$$

Watching the autoscaler event stream (`kubectl get hpa -w`):

```bash
$ kubectl get hpa hpa-demo -w
NAME       REFERENCE             TARGETS     MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   0%/50%      1         5         1          1m
hpa-demo   Deployment/hpa-demo   142%/50%    1         5         1          2m
hpa-demo   Deployment/hpa-demo   142%/50%    1         5         4          2m15s
hpa-demo   Deployment/hpa-demo   78%/50%     1         5         5          2m45s
hpa-demo   Deployment/hpa-demo   48%/50%     1         5         5          3m15s
```

Verifying the scaled Pods in the deployment:

```bash
$ kubectl get pods -l app=hpa-demo
NAME                        READY   STATUS    RESTARTS   AGE
hpa-demo-755776d546-d8k2z   1/1     Running   0          4m
hpa-demo-755776d546-4p9zx   1/1     Running   0          90s
hpa-demo-755776d546-m2k8q   1/1     Running   0          90s
hpa-demo-755776d546-s7f1l   1/1     Running   0          90s
hpa-demo-755776d546-9w5vc   1/1     Running   0          60s
```

Inspecting HPA events:

```bash
$ kubectl describe hpa hpa-demo
...
Events:
  Type    Reason             Age    From                       Message
  ----    ------             ----   ----                       -------
  Normal  SuccessfulRescale  2m15s  horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
  Normal  SuccessfulRescale  2m45s  horizontal-pod-autoscaler  New size: 5; reason: cpu resource utilization (percentage of request) above target
```

---

### Step 2.7: Stop Traffic & Observe Scale-Down Stabilization
To verify proper scale-down, we remove the load generator:

```bash
$ kubectl delete deployment load-generator
deployment.apps "load-generator" deleted
```

After the configured stabilization window (default 5 minutes, customized to 60s in `hpa.yml`), the CPU usage drops to 0% and HPA scales the deployment back to the minimum replica count:

```bash
$ kubectl get hpa hpa-demo
NAME       REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   0%/50%    1         5         1          8m

$ kubectl get pods -l app=hpa-demo
NAME                        READY   STATUS    RESTARTS   AGE
hpa-demo-755776d546-d8k2z   1/1     Running   0          9m
```

---

## 3. Key Diagnostic Commands Summary

| Command | Purpose |
| :--- | :--- |
| `kubectl get hpa` | Instant view of current targets, min/max pods, and replica count |
| `kubectl top pods` | Real-time CPU and Memory consumption per Pod |
| `kubectl describe hpa <name>` | Audit autoscaling events, calculation logic, and health conditions |
| `kubectl get pods -l app=<name> -w` | Stream live replica additions and terminations |
