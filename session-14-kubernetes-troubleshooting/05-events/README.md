# Kubernetes Events

Events help us understand what Kubernetes is doing with our resources.

Think of Events as:

> "Kubernetes' activity log for a resource."

---

## 1. Create the Pod

```bash
kubectl apply -f pod.yaml
```

Expected output:

```text
pod/events-demo created
```

---

## 2. Check Events

Run:

```bash
kubectl get events
```

You may see:

```text
TYPE     REASON    OBJECT              MESSAGE
Normal   Scheduled Pod/events-demo     Successfully assigned...
Normal   Pulling   Pod/events-demo     Pulling image...
Normal   Pulled    Pod/events-demo     Successfully pulled...
Normal   Created   Pod/events-demo     Created container...
Normal   Started   Pod/events-demo     Started container...
```

*(The exact messages depend on your cluster.)*

---

## 3. Sort Events

Run:

```bash
kubectl get events --sort-by=.lastTimestamp
```

This makes recent events easier to understand.

---

## 4. Describe Also Shows Events

Run:

```bash
kubectl describe pod events-demo
```

At the bottom, look for:

```text
Events:
```

---

## 5. Why Are Events Important?

Suppose a Pod is `Pending`. You don't know why.

Run:

```bash
kubectl describe pod <pod-name>
```

You might find:

```text
FailedScheduling
```

with a message explaining that the Pod cannot be scheduled.

Or for an image problem:

```text
Failed
Failed to pull image
```

Events help us find the reason behind the status.

---

## 6. Watch Events

You can watch events:

```bash
kubectl events --watch
```

You can also filter for a specific resource:

```bash
kubectl events --for pod/events-demo
```

---

## Useful Commands

```bash
kubectl get events
kubectl get events --sort-by=.lastTimestamp
kubectl events
kubectl events --watch
kubectl describe pod events-demo
```

---

## Key Learning

Remember:

```text
kubectl get
     │
     ▼
Current status

kubectl describe
     │
     ▼
Detailed information

Events
     │
     ▼
What Kubernetes tried to do and what happened
```

* Events are the fastest way to understand what the Kubernetes control plane is doing.
* Always filter with `--field-selector type=Warning` to cut through noise during incidents.
* Remember that events expire from `etcd` after 1 hour by default.
* The message in `FailedScheduling` events will tell you exactly why a Pod is stuck in `Pending`.

---

## Reference

* **Kubernetes Events API:**  
  https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/event-v1/
