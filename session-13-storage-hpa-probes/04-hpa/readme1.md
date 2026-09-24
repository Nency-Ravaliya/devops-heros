# Kubernetes HPA


**HPA** means:
> **Horizontal Pod Autoscaler**

---

## 1. Why Do We Need HPA?

Imagine our application has:

* `1 Pod`

During normal traffic:

* `CPU = 20%`

But suddenly many users start using the application:

* `CPU = 90%`

We may need more Pods.

Instead of manually running:

```bash
kubectl scale deployment hpa-demo --replicas=5
```

HPA can automatically change the number of replicas.

---

## 2. Horizontal Scaling

Horizontal scaling means:

> **Add more Pods**

### Example:

```text
Before:
  Pod 1

After scaling:
  Pod 1   Pod 2   Pod 3   Pod 4
```

HPA does **not** make the existing Pod bigger.

---

## 3. Deployment

Create the Deployment:

```bash
kubectl apply -f deployment.yaml
```

Check:

```bash
kubectl get deployment
```

Then:

```bash
kubectl get pods
```

---

## 4. CPU Requests

Our Deployment contains:

```yaml
resources:
  requests:
    cpu: 100m
```

CPU requests are important for CPU utilization calculations used by HPA.

For example:

* CPU request = `100m`
* CPU usage   = `50m`
* Utilization = `50%`

---

## 5. Service

Create the Service:

```bash
kubectl apply -f service.yaml
```

Check:

```bash
kubectl get svc
```

Expected output:

```text
NAME               TYPE        CLUSTER-IP
hpa-demo-service   ClusterIP   ...
```

---

## 6. Metrics Server

HPA needs metrics.

Check:

```bash
kubectl top nodes
```

and:

```bash
kubectl top pods
```

If you get:

```text
Metrics API not available
```

Metrics Server is not available yet.

For Minikube:

```bash
minikube addons enable metrics-server
```

Check:

```bash
kubectl get pods -n kube-system
```

Look for:

```text
metrics-server-xxxxx
```

Then try again:

```bash
kubectl top pods
```

---

## 7. Create HPA

Apply:

```bash
kubectl apply -f hpa.yaml
```

Check:

```bash
kubectl get hpa
```

You may see:

```text
NAME       TARGETS   MINPODS   MAXPODS   REPLICAS
hpa-demo   0%/50%    1         5         1
```

The exact CPU percentage will depend on your system.

---

## 8. Generate Load

Run the load generator:

```bash
kubectl run load-generator \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c \
  "while true; do wget -q -O- http://hpa-demo-service; done"
```

Watch HPA:

```bash
kubectl get hpa -w
```

Also watch Pods:

```bash
kubectl get pods -w
```

When CPU increases, HPA can increase the number of Pods.

---

## 9. Stop The Load

Delete the load generator:

```bash
kubectl delete pod load-generator
```

Watch:

```bash
kubectl get hpa -w
```

After some time, the number of replicas can decrease again.

---

## 10. HPA Flow

Remember this:

```text
Application
     │
     ▼
 CPU usage
     │
     ▼
Metrics Server
     │
     ▼
    HPA
     │
     ▼
 Deployment
     │
     ▼
More / fewer Pods
```

---

## 11. Important HPA Fields

* **`scaleTargetRef`**: Which workload should HPA scale?
* **`minReplicas`**: Minimum number of Pods.
* **`maxReplicas`**: Maximum number of Pods.
* **`metrics`**: What should HPA monitor?

---

## Useful Commands

```bash
kubectl top nodes
kubectl top pods
kubectl get hpa
kubectl describe hpa hpa-demo
kubectl get deployment
kubectl get pods
kubectl get pods -w
```

---

## Key Learning

Remember:

* **HPA** = Automatically changes Pod count
* **High load** = More Pods
* **Low load** = Fewer Pods

---

## Reference

* **Horizontal Pod Autoscaling:**  
  https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/
* **HPA Walkthrough:**  
  https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
* **Metrics Pipeline:**  
  https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/
