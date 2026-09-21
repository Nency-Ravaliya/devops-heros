# `kubectl get`

```bash
kubectl get
```

Think of `kubectl get` as:

> "Kubernetes, show me what is currently happening."

---

## 1. Create the Pod

Run:

```bash
kubectl apply -f pod.yaml
```

Expected output:

```text
pod/get-demo created
```

---

## 2. Check Pods

Run:

```bash
kubectl get pods
```

Expected output:

```text
NAME       READY   STATUS    RESTARTS   AGE
get-demo   1/1     Running   0          10s
```

---

## 3. Understand The Output

* **NAME**: Name of the Pod.
* **READY**: Number of ready containers.
* **STATUS**: Current Pod status.
* **RESTARTS**: Number of container restarts.
* **AGE**: How long the Pod has existed.

---

## 4. Get More Information

Run:

```bash
kubectl get pods -o wide
```

You will see additional information such as:

* Pod IP
* Node
* Container status

Example output:

```text
NAME       READY   STATUS    RESTARTS   AGE   IP           NODE
get-demo   1/1     Running   0          20s   10.244.0.5   minikube
```

*(The exact IP and node name will be different on your cluster.)*

---

## 5. Check Different Resources

**Pods:**
```bash
kubectl get pods
```

**Services:**
```bash
kubectl get services
```

**Deployments:**
```bash
kubectl get deployments
```

**Nodes:**
```bash
kubectl get nodes
```

**All resources:**
```bash
kubectl get all
```

---

## 6. Watch Changes

Run:

```bash
kubectl get pods -w
```

Now delete the Pod from another terminal:

```bash
kubectl delete pod get-demo
```

You can watch the Pod disappear in real time.

---

## 7. Troubleshooting Habit

When something is not working, start with:

```bash
kubectl get pods
```

Then look at:
* `STATUS`
* `READY`
* `RESTARTS`

For example:

```text
NAME       READY   STATUS             RESTARTS
my-app     0/1     CrashLoopBackOff   5
```

This immediately tells us: **Something is wrong with the container.**

But `kubectl get` only tells us **what** is happening. Next we need:

```bash
kubectl describe
kubectl logs
```

to understand **why**.

---

## Useful Commands

```bash
kubectl get pods
kubectl get pods -o wide
kubectl get all
kubectl get nodes
kubectl get services
kubectl get deployments
kubectl get pods -w
```

---

## Key Learning

Remember:

```text
kubectl get
     │
     ▼
"What is happening?"
```

It gives us the current state of Kubernetes resources.

---

## Reference

* **Kubernetes Command Line Tool (kubectl):**  
  https://kubernetes.io/docs/reference/kubectl/
