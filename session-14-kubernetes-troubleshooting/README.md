# Session 14: Kubernetes Troubleshooting

Name: Durga Prasad
Enrollment: 10012

---

## Architectural Deep Dive: `kubectl logs` vs `kubectl get events`

A foundational concept in Kubernetes observability is distinguishing between **Application Telemetry (`kubectl logs`)** and **Cluster Control Plane Activity (`kubectl get events`)**.

```
                ┌─────────────────────────────────────────────────────────┐
                │                 KUBERNETES ARCHITECTURE                 │
                └─────────────────────────────────────────────────────────┘

        +-----------------------------------------------------------------+
        |                      CONTROL PLANE (etcd)                       |
        |                                                                 |
        |   [kube-scheduler]    [kube-controller-manager]    [API Server] |
        |          │                       │                       │      |
        |          └───────────────────────┼───────────────────────┘      |
        |                                  ▼                              |
        |                    Event Stream (Stored in etcd)                |
        |                    Lifecycle: 1-hour TTL                        |
        |                    Command: kubectl get events                  |
        +-----------------------------------------------------------------+
                                           │
                                           │ Schedules & Monitors
                                           ▼
        +-----------------------------------------------------------------+
        |                          WORKER NODE                            |
        |                                                                 |
        |   +-----------------------+     +---------------------------+   |
        |   |        Kubelet        |     |     Container Runtime     |   |
        |   | Emits: Pulled,        |     |        (containerd)       |   |
        |   | BackOff, Started      |     +-------------+-------------+   |
        |   +-----------------------+                   │                 |
        |                                               ▼                 |
        |                                     ┌──────────────────┐        |
        |                                     │    Pod / App     │        |
        |                                     │  stdout / stderr │        |
        |                                     └─────────┬────────┘        |
        |                                               │                 |
        |                             Writes to: /var/log/pods/*.log      |
        |                             Command: kubectl logs <pod>         |
        +-----------------------------------------------------------------+
```

### Detailed Comparison Table

| Feature / Dimension | `kubectl logs` | `kubectl get events` |
|---|---|---|
| **What it answers** | *"What is the application code saying or failing on?"* | *"What did the Kubernetes control plane attempt to do, and what happened?"* |
| **Data Source** | `stdout` & `stderr` written by container processes | API Server `Event` resource objects emitted by controllers, scheduler, and kubelet |
| **Storage Location** | Node local disk (`/var/log/pods/...` or `/var/log/containers/...`) via CRI | `etcd` key-value database on the Control Plane |
| **Retention Policy** | Preserved as long as the pod container remains on node; rotated by kubelet / CRI log max limits | Strictly ephemeral: deleted from `etcd` after **1 hour** (`--event-ttl=1h0m0s`) |
| **Scope** | Single container process level | Cluster, namespace, or individual resource lifecycle level |
| **Availability when container crashes** | Available via `--previous` for the most recent dead container | Always available for all lifecycle attempts (restarts, pulls, scheduling) |
| **Availability when Pod is `Pending`** | **Not available** (no container process has started yet) | **Fully available** (shows `FailedScheduling`, node affinities, taints) |
| **Availability when Image fails** | **Not available** (image cannot be pulled, no process spawned) | **Fully available** (shows `Failed`, `ErrImagePull`, `BackOff`) |
| **Primary Use Cases** | Application exceptions, database timeouts, 500 errors, stack traces | Scheduling failures, OOM kills, ImagePullBackOff, crash backoffs, node reboots |

### When to Use Which: Decision Flow

```text
                               Is the Pod running?
                                      │
                   ┌──────────────────┴──────────────────┐
                   ▼                                     ▼
                  YES                                    NO
                   │                                     │
           Is app returning error?              Is status Pending or ImagePullBackOff?
                   │                                     │
         ┌─────────┴─────────┐                 ┌─────────┴─────────┐
         ▼                   ▼                 ▼                   ▼
    kubectl logs       kubectl exec      kubectl describe    kubectl get events
    (Check stack       (Test network,    (Check Events       (Identify scheduler
     trace)             curl local)       section)            or CRI error)
```

---

## The Golden Troubleshooting Process

```text
              1. OBSERVE (kubectl get pods -o wide)
                          │
                          ▼
            2. INSPECT (kubectl describe pod <name>)
                          │
                          ▼
             3. ANALYZE (Events & Termination State)
                          │
                          ▼
        4. APPLICATION LOGS (kubectl logs [--previous])
                          │
                          ▼
      5. INTERNAL VERIFICATION (kubectl exec -it -- sh/curl)
                          │
                          ▼
          6. SERVICE ROUTING (kubectl get endpoints <svc>)
                          │
                          ▼
             7. IDENTIFY ROOT CAUSE & APPLY FIX
                          │
                          ▼
             8. VERIFY (kubectl get pods / curl svc)
```

---

## Module 01: `kubectl get` — High-Level Status Observation

`kubectl get` provides an immediate tabular overview of resource states across the cluster.

### Commands Executed:
```bash
kubectl apply -f 01-kubectl-get/pod.yaml
kubectl get pod get-demo
kubectl get pod get-demo -o wide
```

### Live Cluster Output:
```text
pod/get-demo created
NAME       READY   STATUS    RESTARTS   AGE
get-demo   1/1     Running   0          10s

NAME       READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
get-demo   1/1     Running   0          20s   10.244.0.41   minikube   <none>           <none>
```

**Key Parameters Observed:**
* `READY`: `1/1` (1 container ready out of 1 defined)
* `STATUS`: `Running`
* `RESTARTS`: `0`
* `IP`: `10.244.0.41` (Direct Pod IP on the Calico/Bridge CNI overlay)

---

## Module 02: `kubectl describe` — Deep Resource Inspection

`kubectl describe` compiles detailed internal status from the API server, revealing container states, volume mounts, conditions, and correlated Events.

### Commands Executed:
```bash
kubectl apply -f 02-kubectl-describe/demo-pod.yaml
kubectl describe pod describe-demo
```

### Live Cluster Output:
```text
Name:             describe-demo
Namespace:        default
Node:             minikube/192.168.49.2
Labels:           app=describe-demo
Status:           Running
IP:               10.244.0.42
Containers:
  nginx:
    Container ID:   containerd://395d9bc...
    Image:          nginx:1.27
    State:          Running
      Started:      Wed, 23 Sep 2026 09:47:48 +0530
    Ready:          True
    Restart Count:  0
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  4s    default-scheduler  Successfully assigned default/describe-demo to minikube
  Normal  Pulled     5s    kubelet            spec.containers{nginx}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Normal  Created    5s    kubelet            spec.containers{nginx}: Container created
  Normal  Started    5s    kubelet            spec.containers{nginx}: Container started
```

---

## Module 03: `kubectl logs` — Application Stream Inspection

`kubectl logs` retrieves standard output and standard error from container processes.

### Commands Executed:
```bash
kubectl apply -f 03-kubectl-logs/pod.yaml
kubectl logs logs-demo
```

### Live Cluster Output:
```text
pod/logs-demo created
Application started
Connecting to database...
Database connection successful
Application is running
Application is healthy
Application is healthy
```

### Advanced Log Flags:
* `kubectl logs -f <pod>`: Follows log stream in real time.
* `kubectl logs <pod> --previous`: Retrieves logs of the previous crashed instance of the container.
* `kubectl logs <pod> -c <container-name>`: Targets a specific container in a multi-container Pod.
* `kubectl logs <pod> --tail=50`: Retrieves only the last 50 lines.

---

## Module 04: `kubectl exec` — In-Container Diagnostics

`kubectl exec` allows running diagnostic commands directly inside a running container's network and process namespace.

### Commands Executed:
```bash
kubectl apply -f 04-kubectl-exec/pod.yaml
kubectl exec exec-demo -- hostname
kubectl exec exec-demo -- ls /usr/share/nginx/html
kubectl exec exec-demo -- curl -s http://localhost
```

### Live Cluster Output:
```text
pod/exec-demo created
exec-demo
50x.html
index.html

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
```

**Diagnostic Rule:** If `curl localhost` works from inside the pod, but the service is unreachable from outside, the container is healthy and the issue lies in Service selector, TargetPort, or CNI network routing.

---

## Module 05: Kubernetes Events — Cluster Activity Logging

Events record state transitions, scheduler assignments, image pull operations, and controller reconciliations.

### Commands Executed:
```bash
kubectl apply -f 05-events/pod.yaml
kubectl get events --sort-by=.lastTimestamp
kubectl describe pod events-demo | tail -n 8
```

### Live Cluster Output:
```text
pod/events-demo created
LAST SEEN   TYPE      REASON      OBJECT             MESSAGE
10s         Normal    Scheduled   pod/events-demo    Successfully assigned default/events-demo to minikube
9s          Normal    Pulled      pod/events-demo    Container image "nginx:1.27" already present on machine
9s          Normal    Created     pod/events-demo    Container created
8s          Normal    Started     pod/events-demo    Container started
```

**Production Pro-Tip:**
```bash
# Filter only warnings across the entire cluster
kubectl get events --field-selector type=Warning -A
```

---

## Module 06: Troubleshooting `CrashLoopBackOff`

### Failure Scenario:
The container is configured with a command that deliberately exits with exit code `1`:
```yaml
command: ["sh", "-c", "echo 'Application starting...' && echo 'Something went wrong!' && exit 1"]
```

### Step 1: Observe Problem
```bash
kubectl apply -f 06-crashloopbackoff/broken-pod.yaml
kubectl get pod crash-demo
```
**Live Output:**
```text
pod/crash-demo created
NAME         READY   STATUS             RESTARTS     AGE
crash-demo   0/1     CrashLoopBackOff   1 (3s ago)   4s
```

### Step 2: Investigate Logs & Exit Codes
```bash
kubectl logs crash-demo
kubectl describe pod crash-demo | grep -A 8 "Last State:"
```
**Live Output:**
```text
Application starting...
Something went wrong!

    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Wed, 23 Sep 2026 09:48:35 +0530
      Finished:     Wed, 23 Sep 2026 09:48:35 +0530
```

### Step 3: Fix and Verify
Apply `fixed-pod.yaml` (which includes `sleep 3600` instead of `exit 1`):
```bash
kubectl delete pod crash-demo --grace-period=0 --force
kubectl apply -f 06-crashloopbackoff/fixed-pod.yaml
kubectl get pod crash-demo
kubectl logs crash-demo
```
**Live Output:**
```text
pod/crash-demo created
NAME         READY   STATUS    RESTARTS   AGE
crash-demo   1/1     Running   0          3s
Application starting...
Application is healthy
```

---

## Module 07: Troubleshooting `ImagePullBackOff`

### Failure Scenario:
The Pod references an invalid, non-existent Docker image:
```yaml
image: nginx:this-image-does-not-exist
```

### Step 1: Observe Problem
```bash
kubectl apply -f 07-imagepullbackoff/broken-pod.yaml
kubectl get pod image-demo
```
**Live Output:**
```text
NAME         READY   STATUS         RESTARTS   AGE
image-demo   0/1     ErrImagePull   0          5s
```
After backoff:
```text
NAME         READY   STATUS             RESTARTS   AGE
image-demo   0/1     ImagePullBackOff   0          18s
```

### Step 2: Investigate Events
```bash
kubectl describe pod image-demo | tail -n 8
```
**Live Output:**
```text
Events:
  Type     Reason     Age   From     Message
  ----     ------     ----  ----     -------
  Normal   Pulling    10s   kubelet  Pulling image "nginx:this-image-does-not-exist"
  Warning  Failed     9s    kubelet  Failed to pull image "nginx:this-image-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:this-image-does-not-exist": not found
  Warning  Failed     9s    kubelet  Error: ErrImagePull
  Normal   BackOff    8s    kubelet  Back-off pulling image "nginx:this-image-does-not-exist"
```

### Step 3: Fix and Verify
Apply `fixed-pod.yaml` with valid image `nginx:1.27`:
```bash
kubectl delete pod image-demo --grace-period=0 --force
kubectl apply -f 07-imagepullbackoff/fixed-pod.yaml
kubectl get pod image-demo
```
**Live Output:**
```text
NAME         READY   STATUS    RESTARTS   AGE
image-demo   1/1     Running   0          4s
```

---

## Module 08: Troubleshooting `Pending` Pods

### Failure Scenario:
The Pod specifies an unsatisfiable `nodeSelector`:
```yaml
nodeSelector:
  kubernetes.io/hostname: node-that-does-not-exist
```

### Step 1: Observe Problem
```bash
kubectl apply -f 08-pending-pods/broken-pod.yaml
kubectl get pod pending-demo
```
**Live Output:**
```text
NAME           READY   STATUS    RESTARTS   AGE
pending-demo   0/1     Pending   0          3s
```

### Step 2: Investigate Scheduler Events
```bash
kubectl describe pod pending-demo | tail -n 6
```
**Live Output:**
```text
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  3s    default-scheduler  0/1 nodes are available: 1 node(s) didn't match Pod's node affinity/selector. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
```

### Step 3: Fix and Verify
Remove the invalid `nodeSelector` by applying `fixed-pod.yaml`:
```bash
kubectl delete pod pending-demo --grace-period=0 --force
kubectl apply -f 08-pending-pods/fixed-pod.yaml
kubectl get pod pending-demo
```
**Live Output:**
```text
NAME           READY   STATUS    RESTARTS   AGE
pending-demo   1/1     Running   0          4s
```

---

## Module 09: Troubleshooting Services & CoreDNS

### Failure Scenario:
A Service is deployed with a typo in its selector (`app: web-ahsgdf`), while backing pods have label `app: web`.

### Step 1: Deploy & Observe Empty Endpoints
```bash
kubectl apply -f 09-service-dns-troubleshooting/deployment.yaml
kubectl apply -f 09-service-dns-troubleshooting/service.yaml
kubectl get pods -l app=web --show-labels
kubectl describe service web-service | grep -E "Selector|Endpoints"
kubectl get endpoints web-service
```
**Live Output:**
```text
NAME                   READY   STATUS    LABELS
web-557577df75-jwlf4   1/1     Running   app=web,pod-template-hash=557577df75
web-557577df75-qrxw7   1/1     Running   app=web,pod-template-hash=557577df75

Selector:                 app=web-ahsgdf
Endpoints:                <none>
```

### Step 2: Fix Selector & Verify Endpoint Restoration
```bash
kubectl set selector service web-service app=web
kubectl get endpoints web-service
```
**Live Output:**
```text
NAME          ENDPOINTS                       AGE
web-service   10.244.0.51:80,10.244.0.52:80   7s
```

### Step 3: Verify CoreDNS Service Resolution & HTTP Connectivity
From an in-cluster client pod (`dns-test`):
```bash
kubectl exec dns-test -- nslookup web-service.default.svc.cluster.local
kubectl exec dns-test -- wget -qO- --timeout=5 http://web-service | head -n 6
```
**Live Output:**
```text
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	web-service.default.svc.cluster.local
Address: 10.98.72.26

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

### Step 4: Verify CoreDNS Logs
```bash
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=4
```
**Live Output:**
```text
[INFO] 10.244.0.54:41808 - 44130 "AAAA IN web-service.default.svc.cluster.local. udp 55 false 512" NOERROR qr,aa,rd 148 0.000938562s
[INFO] 10.244.0.54:41808 - 57485 "A IN web-service.default.svc.cluster.local. udp 55 false 512" NOERROR qr,aa,rd 108 0.000938384s
```

---

## Mini-Project: Production Troubleshooting Challenge Summary

The complete mini-project was executed and documented in [`session-14-kubernetes-troubleshooting/mini-project/README.md`](./mini-project/README.md).

### Summary of Completed Challenges:
1. **Application Baseline:** Deployed 2-replica Nginx deployment with ClusterIP service and validated `curl localhost` within the container.
2. **Broken Pod Challenge:**
   - Applied `project-broken-pod` configured with invalid tag `nginx:this-tag-does-not-exist`.
   - Identified `ErrImagePull` / `ImagePullBackOff` caused by `rpc error: code = NotFound (docker.io/library/nginx:this-tag-does-not-exist: not found)`.
   - Verified that `kubectl describe pod` Events provided the exact reason.
3. **Service Selector Breakage:**
   - Changed service selector to `app: wrong-app`.
   - Confirmed endpoints collapsed to `<none>`.
   - Used `kubectl get pods --show-labels` vs `kubectl describe service` to identify label mismatch.
   - Restored selector to `app: troubleshooting-app` and verified instantaneous endpoint re-attachment.
4. **All 10 Technical Questions Answered:** Comprehensive explanations provided for `get`, `describe`, `logs`, `exec`, `CrashLoopBackOff`, `ImagePullBackOff`, `Pending`, empty endpoints, selectors, and CoreDNS.

---

## Troubleshooting Quick-Reference Table

| Pod Status | Primary Diagnostic Command | Most Frequent Root Cause | Permanent Resolution |
|---|---|---|---|
| `CrashLoopBackOff` | `kubectl logs <pod> --previous` | App exit 1, missing env vars, bad DB connection, failed liveness probe | Correct app config, fix credentials, adjust probe thresholds |
| `ImagePullBackOff` | `kubectl describe pod <pod>` (Events) | Non-existent image tag, registry authentication missing, network drop | Fix tag, create `imagePullSecret`, verify Docker Hub access |
| `Pending` | `kubectl describe pod <pod>` (Events) | CPU/Memory exhaustion, nodeSelector mismatch, taints without toleration | Add node capacity, relax requests, fix nodeSelector / tolerations |
| Service `<none>` endpoints | `kubectl describe service <svc>` & `kubectl get pods --show-labels` | Label vs selector mismatch, Pods failing readiness probes | Align `spec.selector` with `metadata.labels`, fix readiness probe |
| DNS NXDOMAIN | `kubectl logs -n kube-system -l k8s-app=kube-dns` | Typo in service FQDN, CoreDNS pod crash, search domain misconfig | Query correct FQDN (`<svc>.<ns>.svc.cluster.local`), restart CoreDNS |

---

## Conclusion & Engineering Takeaway

Kubernetes troubleshooting is a disciplined, hypothesis-driven science. By systematically traversing from high-level observation (`kubectl get`), through control plane telemetry (`kubectl describe` and `events`), down to runtime application telemetry (`kubectl logs` and `kubectl exec`), any failure mode in a Kubernetes cluster can be isolated and resolved without trial-and-error guesswork.
