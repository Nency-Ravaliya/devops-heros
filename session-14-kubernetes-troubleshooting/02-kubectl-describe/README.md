# `kubectl describe`

```bash
kubectl describe
```

If `kubectl get` tells us:
> "Something is wrong."

`kubectl describe` helps us ask:
> "What exactly happened?"

---

## 1. Create the Pod

```bash
kubectl apply -f pod.yaml
```

Expected output:

```text
pod/describe-demo created
```

Check:

```bash
kubectl get pod
```

---

## 2. Describe the Pod

Run:

```bash
kubectl describe pod describe-demo
```

The output contains many sections. Important sections include:

* **Name**
* **Namespace**
* **Labels**
* **Status**
* **IP**
* **Containers**
* **Conditions**
* **Events**

---

## 3. Containers Section

You can see:

```text
Containers:
  nginx:
    Image: nginx:1.27
    State: Running
    Ready: True
```

This tells us:
* Which image is running
* Container state
* Whether it is ready

---

## 4. Events Section

At the bottom, you may see:

```text
Events:
  Type     Reason    Message
  Normal   Pulling   Pulling image
  Normal   Pulled    Successfully pulled image
  Normal   Created   Created container
  Normal   Started   Started container
```

Events are extremely useful when troubleshooting.

---

## 5. Compare `get` and `describe`

**`kubectl get`**
```bash
kubectl get pod
```
Gives us a quick summary.

**`kubectl describe`**
```bash
kubectl describe pod describe-demo
```
Gives us detailed information.

Think of it like this:

```text
get
 │
 └── quick view

describe
 │
 └── detailed investigation
```

---

## 6. Describe Other Resources

**Deployment:**
```bash
kubectl describe deployment <deployment-name>
```

**Service:**
```bash
kubectl describe service <service-name>
```

**Node:**
```bash
kubectl describe node <node-name>
```

---

## Troubleshooting Habit

If you see:

```text
STATUS: Pending
```

Don't immediately delete the Pod.

Run:

```bash
kubectl describe pod <pod-name>
```

Then look at the **Events** section.

Kubernetes documentation specifically recommends `kubectl describe pod` as one of the standard ways to investigate Pod problems.

---

## Key Learning

Remember:

```text
kubectl get
     │
     ▼
"What is happening?"

kubectl describe
     │
     ▼
"Why is it happening?"
```

---

## Reference

* **Kubernetes Pod Lifecycle:**  
  https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
