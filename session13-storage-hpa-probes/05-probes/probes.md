# Kubernetes Probes

## What will we learn?

* Liveness Probe
* Readiness Probe
* Startup Probe

---

## 1. Why Do We Need Probes?

A Pod can be:

> **Running**

but the application inside it may not actually be working correctly.

For example:

* `Pod = Running`
* `Application = Broken`

Kubernetes needs a way to check the application.

That's where probes are used.

---

## 2. Liveness Probe

Liveness asks:

> **"Are you still alive?"**

If the liveness check keeps failing, Kubernetes can restart the container.

### Example:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
```

This tells Kubernetes to make an HTTP request to port 80.

---

## 3. Run Liveness Example

Apply:

```bash
kubectl apply -f liveness.yaml
```

Check:

```bash
kubectl get pod liveness-demo
```

Expected output:

```text
NAME            READY   STATUS
liveness-demo   1/1     Running
```

Check details:

```bash
kubectl describe pod liveness-demo
```

Look for:

```text
Liveness
```

---

## 4. Readiness Probe

Readiness asks:

> **"Are you ready to receive traffic?"**

If readiness fails:

```text
Pod stays running
        │
        ▼
Pod becomes NotReady
        │
        ▼
Service should not send normal traffic to it
```

A readiness failure does **NOT** normally restart the container.

---

## 5. Run Readiness Example

Apply:

```bash
kubectl apply -f readiness.yaml
```

Check:

```bash
kubectl get pod readiness-demo
```

You should eventually see:

```text
NAME             READY   STATUS
readiness-demo   1/1     Running
```

Create a Service:

```bash
kubectl expose pod readiness-demo \
  --name=readiness-service \
  --port=80
```

Check endpoints:

```bash
kubectl get endpoints readiness-service
```

---

## 6. Startup Probe

Startup asks:

> **"Has the application finished starting?"**

It is useful for applications that take a long time to start.

### For example:

```text
Java application
      │
      ├── starting...
      ├── starting...
      ├── starting...
      ▼
Application ready
```

Without a startup probe, an aggressive liveness probe could restart the application before it has finished starting.

---

## 7. Run Startup Example

Apply:

```bash
kubectl apply -f startup.yaml
```

Check:

```bash
kubectl get pod startup-demo
```

Then:

```bash
kubectl describe pod startup-demo
```

You can see the startup, liveness, and readiness probe configuration.

---

## 8. Difference Between The Three

### Startup Probe
* **Question:** Has the application started?
* Used mainly during startup.

---

### Readiness Probe
* **Question:** Can the application receive traffic?
* Controls whether the Pod is considered ready for traffic.

---

### Liveness Probe
* **Question:** Is the application still healthy/alive?
* A persistent failure can cause the container to be restarted.

---

## 9. Easy Way To Remember

```text
STARTUP
  └── "Have you started?"

READINESS
  └── "Can I send users to you?"

LIVENESS
  └── "Are you still alive?"
```

---

## 10. Probe Types

Kubernetes supports different ways to perform probes.

Common ones are:

* **HTTP**
* **TCP**
* **Exec**
* **gRPC**

For our examples, we are using HTTP because it is easy to understand.

---

## 11. Probe Configuration

### Example snippet:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 2
  failureThreshold: 3
```

* **`initialDelaySeconds`**: How long Kubernetes waits before starting the checks.
* **`periodSeconds`**: How often Kubernetes performs the check.
* **`timeoutSeconds`**: How long Kubernetes waits for a response.
* **`failureThreshold`**: How many consecutive failures are allowed before the probe is considered failed.

---

## 12. Try Breaking Readiness

Change:

```yaml
path: /
```

to:

```yaml
path: /wrong-path
```

Apply again:

```bash
kubectl apply -f readiness.yaml
```

Check:

```bash
kubectl get pod readiness-demo
```

The Pod can still be:

* `STATUS = Running`

but:

* `READY = 0/1`

This is because the application is running but it is failing the readiness check.

---

## 13. Try Breaking Liveness

Change the liveness path:

```yaml
path: /wrong-path
```

Apply:

```bash
kubectl apply -f liveness.yaml
```

Watch:

```bash
kubectl get pod liveness-demo -w
```

Check:

```bash
kubectl describe pod liveness-demo
```

You can observe liveness probe failures and container restarts.

---

## 14. Debugging Probes

If a probe fails, inspect the Pod events:

```bash
kubectl describe pod <pod-name>
```

Then check container logs:

```bash
kubectl logs <pod-name>
```

You can also enter the container:

```bash
kubectl exec -it <pod-name> -- sh
```

Then test the application locally. For example:

```bash
wget -qO- http://localhost:80/
```

---

## 15. Important Difference

Remember this table:

| Probe | Main Question | What happens when it fails? |
| :--- | :--- | :--- |
| **Startup** | Has the app started? | Container can be restarted |
| **Readiness** | Can it receive traffic? | Pod becomes `NotReady` |
| **Liveness** | Is it still healthy? | Container can be restarted |

### The most important thing:

> **Readiness failure $\neq$ Container restart**

---

## 16. Useful Commands

```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events --sort-by=.lastTimestamp
kubectl exec -it <pod-name> -- sh
```

---

## 17. Key Learning

Remember:

```text
Startup
   │
   ▼
Application is starting

Readiness
   │
   ▼
Application can/cannot receive traffic

Liveness
   │
   ▼
Application should continue/restart
```

---

## Reference

* **Kubernetes Probes:**  
  https://kubernetes.io/docs/concepts/workloads/pods/probes/
* **Probe Configuration:**  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
