# Session 10 - Pods, ReplicaSets & Deployments Homework

## Task 1: `hello.yml` - Pod lifecycle walkthrough

```bash
kubectl apply -f hello.yml
kubectl get pod hello-pod
```

Observed lifecycle over a few seconds:
```text
NAME        READY   STATUS              RESTARTS   AGE
hello-pod   0/1     ContainerCreating   0          3s
hello-pod   1/1     Running             0          19s
hello-pod   0/1     Completed           0          24s
```

```bash
kubectl logs hello-pod
```
```text
Hello Kubernetes
```

Because the container runs a one-shot `sh -c "echo ..."` command (like Docker's `CMD`), it exits after finishing its task and the Pod moves to `Completed`. An `nginx` container never exits on its own, so it stays in `Running` indefinitely (`restartPolicy` doesn't apply here since the container never exits).

---

## Task 2: Core objects - Pod, ReplicaSet, Deployment, Service

```bash
kubectl apply -f pod.yml        # single Pod
kubectl apply -f replicaset.yml # 3 replicas
kubectl apply -f deployment.yml # 3 replicas via Deployment
kubectl apply -f service.yml
```

- **Pod** (`pod.yml`): one `nginx-pod`, no self-healing — if deleted, it's gone.
- **ReplicaSet** (`replicaset.yml`): `nginx-rs` maintained exactly 3 pods:
  ```text
  NAME       DESIRED   CURRENT   READY   AGE
  nginx-rs   3         3         3       8s
  NAME             READY   STATUS    RESTARTS   AGE
  nginx-rs-hxnvq   1/1     Running   0          8s
  nginx-rs-pr67g   1/1     Running   0          8s
  nginx-rs-z7mjd   1/1     Running   0          8s
  ```
- **Deployment** (`deployment.yml`): wraps a ReplicaSet and adds rollout management (rolling updates, rollback, revision history) on top of it. Verified 3/3 pods running and serving traffic:
  ```bash
  kubectl rollout status deployment/nginx-deployment
  # deployment "nginx-deployment" successfully rolled out
  kubectl port-forward deployment/nginx-deployment 18080:80
  curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:18080
  # HTTP 200
  ```

Why we can't just use `pod.yml` or `replicaset.yml` directly in production: a bare Pod has no self-healing, and a bare ReplicaSet has no rollout strategy (no rolling update, no revision history, no `rollout undo`). Deployment is the object that manages both.

---

## Task 3: Deployment strategies (`01-rolling-update` .. `04-recreate`)

### Rolling Update
```bash
kubectl apply -f 01-rolling-update/deployment-v2.yaml
kubectl rollout status deployment/app-rolling
```
Old v1 pods were terminated one at a time as new v2 pods became ready — never zero pods available:
```text
Waiting for deployment "app-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
deployment "app-rolling" successfully rolled out
```
Verified `VERSION: v2` was live, then rolled back:
```bash
kubectl rollout undo deployment/app-rolling
# deployment.apps/app-rolling rolled back
```

### Blue-Green
```bash
kubectl apply -f 02-blue-green/deployment-blue.yaml
kubectl apply -f 02-blue-green/deployment-green.yaml
kubectl apply -f 02-blue-green/service-blue.yaml   # Service -> Blue
```
```text
Selector: app=myapp,slot=blue    →  curl shows "Slot: BLUE"
```
Flipped traffic instantly by changing only the Service selector:
```bash
kubectl apply -f 02-blue-green/service-green.yaml
```
```text
Selector: app=myapp,slot=green   →  curl shows "Slot: GREEN"
```
Confirmed via `kubectl get endpoints myapp-service` that the backing pod IPs changed from the 3 blue pods to the 3 green pods, with both blue and green pools kept alive the whole time (instant rollback available by re-applying `service-blue.yaml`).

### Canary
```bash
kubectl apply -f 03-canary/deployment-stable.yaml   # 9 pods v1
kubectl apply -f 03-canary/service.yaml
```
Before the canary existed, 10/10 test requests hit `STABLE v1`. After adding 1 canary pod:
```bash
kubectl apply -f 03-canary/deployment-canary.yaml
```
Ran 20 requests **from inside the cluster** (a temporary `curlimages/curl` pod, so requests are load-balanced by kube-proxy the way real Service traffic is instead of a single `port-forward` connection): result was a mix of `STABLE v1` and `CANARY v2`, confirming traffic is split purely by the *ratio of pod replicas* behind the shared Service selector (`app: myapp-canary`), not by any weighted rule.

### Recreate
```bash
kubectl apply -f 04-recreate/deployment-v1.yaml
kubectl apply -f 04-recreate/deployment-v2.yaml
kubectl get pods -l app=app-recreate -w
```
Observed all 3 v1 pods go `Terminating` simultaneously, followed immediately by new v2 pods in `Pending` / `ContainerCreating`, proving there is a real window with **zero pods running** (downtime) — unlike every other strategy above:
```text
app-recreate-...-7sq5d   1/1   Terminating
app-recreate-...-rjdxd   1/1   Terminating
app-recreate-...-vqpx4   1/1   Terminating
---
app-recreate-...-6q2jc   1/1   Running        <- v2
app-recreate-...-m56zt   1/1   Running        <- v2
app-recreate-...-xftzr   0/1   ContainerCreating <- v2
```

### Strategy comparison

| Strategy | Downtime | Extra resources | Rollback speed | Use case |
|---|---|---|---|---|
| Rolling Update | None | Small surge (+1 pod) | Fast (`rollout undo`) | Default for stateless services |
| Blue-Green | None | 2x (both pools live) | Instant (flip Service selector) | Atomic cutover, DB migrations tested pre-switch |
| Canary | None | Small (1 extra pod) | Fast (scale canary to 0) | Validate a new version on a slice of real traffic |
| Recreate | Yes | None | Slower (kill v2, start v1) | Schema migrations, RWO volumes, legacy single-instance apps |

---

## Task 4: Pod lifecycle deep-dive (`pod-lifecycle/`)

Ran the representative cases from the 12-file lab:

| File | Result |
|---|---|
| `01-running.yaml` | `1/1 Running` — long-lived container |
| `02-pending.yaml` | Stuck `Pending` — `FailedScheduling: 0/1 nodes are available: 1 Insufficient memory` (requests more memory than the node has) |
| `05-crashloopbackoff.yaml` | `Running` then restarts climbing (`RESTARTS 2 (13s ago)`) — container exits repeatedly, Kubernetes backs off between restarts |
| `06-imagepullbackoff.yaml` | `0/1 ImagePullBackOff` — image tag doesn't exist |
| `10-init-container.yaml` | Init container logged `Init container running` / `Init complete`, then the main container started (`1/1 Running`) — proves init containers run to completion before the main container starts |

Key distinction confirmed: `kubectl get pods` STATUS column (Pending/Running/Completed/CrashLoopBackOff/ImagePullBackOff/...) is a mix of the pod's real **phase** (`Pending`, `Running`, `Succeeded`, `Failed`, `Unknown`) and the **container state** reason (`Waiting`/`Running`/`Terminated`) — e.g. `ImagePullBackOff` is a *container waiting reason*, not an official pod phase.

---

## Task 5: DaemonSet (`daemonset/node-agent-ds.yaml`)

```bash
kubectl apply -f daemonset/node-agent-ds.yaml
kubectl get daemonset
```
```text
NAME                 DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE
node-logging-agent   1         1         0       1            0
```
With a single-node Minikube cluster, the DaemonSet scheduled **exactly 1 pod** — matching the node count. On a real multi-node cluster it would automatically place one pod per node, and automatically add/remove a pod whenever a node joins/leaves — that's the point of a DaemonSet: node-level agents (log collectors like Fluentd, monitoring agents, `kube-proxy` itself is deployed this way).

---

## Task 6: Troubleshooting exercises

### `broken-image.yaml`
```bash
kubectl apply -f troubleshooting/broken-image.yaml
kubectl describe pod -l app=yatri-backend
```
New surge pod stuck in `ImagePullBackOff` (tag `non-existent-tag-v999` doesn't exist), while `maxUnavailable: 0` meant Kubernetes correctly refused to touch the old healthy pods — the rollout just halts, it doesn't take the app down.

**Fix:** corrected the image reference and re-applied:
```bash
kubectl apply -f troubleshooting/broken-image-fixed.yaml
kubectl rollout status deployment/yatri-backend
# deployment "yatri-backend" successfully rolled out
```

### `selector-mismatch.yaml`
```bash
kubectl apply -f troubleshooting/selector-mismatch.yaml
```
```text
The Deployment "selector-error-demo" is invalid: spec.template.metadata.labels:
Invalid value: {"app":"wrong-app-name"}: `selector` does not match template `labels`
```
The API server rejects this at admission time — `spec.selector` is immutable and **must** be a subset of `spec.template.metadata.labels`, otherwise the Deployment would never be able to find/manage its own pods.

**Fix:** changed the pod template label from `wrong-app-name` to `correct-app-name` to match the selector:
```bash
kubectl apply -f troubleshooting/selector-mismatch-fixed.yaml
# deployment.apps/selector-error-demo created
kubectl get deployment selector-error-demo
# READY 1/1
```

---

## Task 7: StatefulSet vs DaemonSet vs Deployment

| | Deployment | DaemonSet | StatefulSet |
|---|---|---|---|
| **Pod identity** | Random names (`nginx-6946987795-5m4kt`), interchangeable | Random names, one per node | Stable, ordered names (`app-0`, `app-1`, `app-2`) |
| **Scaling target** | You choose `replicas: N`, scheduled anywhere there's room | Always exactly 1 pod per matching node — you don't set `replicas` | You choose `replicas: N`, created/deleted **in order** (0, then 1, then 2...) |
| **Storage** | Pods typically share nothing, or share the same volume definition | Usually local/host-level access (e.g. `/var/log` via hostPath) | Each pod gets its **own** dedicated PersistentVolumeClaim that follows it across restarts |
| **Networking** | Reached via a normal Service (load-balanced, any pod can answer) | One agent per node, usually not addressed individually | Usually paired with a **headless Service** so each pod gets a stable DNS name (`app-0.app-headless.default.svc.cluster.local`) |
| **Use case** | Stateless apps: web servers, APIs | Node-level agents: log shippers, monitoring/metrics agents, CNI/kube-proxy | Stateful apps that need stable identity/storage: databases (Postgres, MongoDB, Kafka, Elasticsearch) |

In short: **Deployment** = "I want N interchangeable copies of this app, anywhere." **DaemonSet** = "I want exactly one copy on every node." **StatefulSet** = "I want N copies, each with its own stable name and its own disk, that comes back as the *same* pod after a restart."

---

## Resources
- https://github.com/Nency-Ravaliya/Kubernetes
- k8s core objects: https://github.com/Nency-Ravaliya/Kubernetes/blob/main/core-objects.md
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
- https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/
