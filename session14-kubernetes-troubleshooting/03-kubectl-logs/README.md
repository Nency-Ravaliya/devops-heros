# `kubectl logs`

```bash
kubectl logs
```

Think of logs as:

> "Let me see what the application itself is saying."

Kubernetes commonly exposes container output written to standard output and standard error through `kubectl logs`.

---

## 1. Create the Pod

```bash
kubectl apply -f pod.yaml
```

Expected output:

```text
pod/logs-demo created
```

---

## 2. Check the Pod

```bash
kubectl get pod logs-demo
```

Expected output:

```text
NAME        READY   STATUS    RESTARTS   AGE
logs-demo   1/1     Running   0          10s
```

---

## 3. Check Logs

```bash
kubectl logs logs-demo
```

Expected output:

```text
Application started
Connecting to database...
Database connection successful
Application is running
Application is healthy
```

*(You may see the last line multiple times.)*

---

## 4. Follow Logs

Run:

```bash
kubectl logs -f logs-demo
```

`-f` means follow. You can watch new logs as the application produces them.

Press `Ctrl + C` to stop following.

---

## 5. Why Are Logs Important?

Imagine:

```text
Pod
 │
 └── STATUS = CrashLoopBackOff
```

`kubectl get` tells us: **Something is wrong.**

Then:

```bash
kubectl logs <pod-name>
```

may tell us:

```text
Error connecting to database
```

Now we have a possible reason.

---

## 6. Previous Container Logs

If a container has crashed and restarted, try:

```bash
kubectl logs <pod-name> --previous
```

This is very useful for `CrashLoopBackOff` problems.

---

## 7. Multiple Containers

If a Pod has multiple containers:

```bash
kubectl logs <pod-name> -c <container-name>
```

Example:

```bash
kubectl logs my-pod -c backend
```

---

## Useful Commands

```bash
kubectl logs logs-demo
kubectl logs -f logs-demo
kubectl logs logs-demo --previous
kubectl logs logs-demo -c app
```

---

## Key Learning

Remember:

```text
kubectl logs
     │
     ▼
"What is the application saying?"
```

Logs are often the first place to look when an application is crashing or behaving unexpectedly.

---

## Reference

* **Kubernetes Logging Architecture:**  
  https://kubernetes.io/docs/concepts/cluster-administration/logging/
