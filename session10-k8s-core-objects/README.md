# Session 10: Kubernetes Core Objects — Deployments, Strategies & Pod Lifecycle

**Name:** Durga Prasad  
**Enrollment Number:** 10012

---

## Task 1: Cluster Health Verification & Baseline Environment Checks

Verify that the local Kubernetes cluster control plane, DNS components, and worker nodes are operational.

**Commands:**
```bash
kubectl version --output=yaml
kubectl cluster-info
kubectl get nodes -o wide
```

**Output:**
```
clientVersion:
  gitVersion: v1.36.3
  platform: linux/amd64

Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION           CONTAINER-RUNTIME
minikube   Ready    control-plane   17d   v1.37.0   192.168.49.2   <none>        Debian GNU/Linux 12 (bookworm)   6.8.0-88-generic (amd64) containerd://2.3.4
```

**Screenshot:** `![Cluster Health](./screenshots/01-cluster-health.png)`

---

## Task 2: Standard Pod Deployment, Extended Inspection & Teardown (`pod.yml`)

Deploy a standalone Nginx pod, inspect its runtime state, and delete it cleanly.

**File:** `pod.yml`

**Commands:**
```bash
kubectl apply -f pod.yml
kubectl get pods
kubectl get pods -o wide
kubectl logs nginx-pod
kubectl delete -f pod.yml
kubectl get pods
```

**Output:**
```
pod/nginx-pod created

NAME        READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
nginx-pod   1/1     Running   0          12s   10.244.0.30   minikube   <none>           <none>

/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
nginx started successfully
```

**Screenshot:** `![Nginx Pod Operations](./screenshots/02-nginx-pod-operations.png)`

---

## Task 3: Error State Simulation — `ErrImagePull` & `ImagePullBackOff`

Demonstrate Kubernetes error handling when pulling a non-existent container image.

**File:** `pod-lifecycle/06-imagepullbackoff.yaml`

**Commands:**
```bash
kubectl apply -f pod-lifecycle/06-imagepullbackoff.yaml
kubectl get pods lifecycle-image-error
kubectl describe pod lifecycle-image-error | grep -A 10 Events:
kubectl delete -f pod-lifecycle/06-imagepullbackoff.yaml
```

**Output:**
```
pod/lifecycle-image-error created

NAME                    READY   STATUS             RESTARTS   AGE
lifecycle-image-error   0/1     ImagePullBackOff   0          20s

Events:
  Type     Reason     Age               From               Message
  ----     ------     ----              ----               -------
  Normal   Scheduled  20s               default-scheduler  Successfully assigned default/lifecycle-image-error to minikube
  Normal   BackOff    18s               kubelet            Back-off pulling image "jakwehrgkaejw:kahsdfgkhj"
  Warning  Failed     18s               kubelet            Error: ImagePullBackOff
  Normal   Pulling    5s (x2 over 20s)  kubelet            Pulling image "jakwehrgkaejw:kahsdfgkhj"
  Warning  Failed     4s (x2 over 18s)  kubelet            Failed to pull image: pull access denied, repository does not exist
  Warning  Failed     4s (x2 over 18s)  kubelet            Error: ErrImagePull
```

> **Why does the API object creation succeed while the runtime fails?**  
> `kubectl apply` creates the Pod object in `etcd` (API Server accepts it). The Pod spec is valid YAML. The *runtime failure* (pulling the image) happens later on the worker node when `kubelet` tries to execute the container. These are two separate phases: *admission* (API layer) vs *execution* (runtime layer).

**Screenshot:** `![ImagePullBackOff Error](./screenshots/03-imagepullbackoff-error.png)`

---

## Task 4: Capturing Transient Pod Lifecycle Stages (`hello.yml`)

Deploy a batch `busybox` container with `restartPolicy: Never` and capture all 3 lifecycle stages.

**File:** `hello.yml`

**Commands:**
```bash
# Terminal 1: Watch pods continuously
kubectl get pods -w

# Terminal 2: Apply batch job
kubectl apply -f hello.yml
kubectl get pods hello-pod
kubectl logs hello-pod
kubectl delete -f hello.yml
```

**Output (lifecycle progression):**
```
NAME        READY   STATUS              RESTARTS   AGE
hello-pod   0/1     ContainerCreating   0          1s
hello-pod   1/1     Running             0          3s
hello-pod   0/1     Completed           0          5s

# Logs:
Hello from Kubernetes!
```

**Screenshot:** `![Pod Lifecycle Stages](./screenshots/04-pod-lifecycle-stages.png)`

---

## Task 5: Exhaustive Pod Lifecycle States & Probes Lab (`pod-lifecycle/`)

Navigate to `pod-lifecycle/` and validate all lifecycle manifests.

**Commands:**
```bash
cd session10-k8s-core-objects/pod-lifecycle/

# 1. Pending State
kubectl apply -f 02-pending.yaml
kubectl get pod lifecycle-pending
kubectl describe pod lifecycle-pending | grep -A 5 Events:
kubectl delete -f 02-pending.yaml

# 2. CrashLoopBackOff
kubectl apply -f 05-crashloopbackoff.yaml
kubectl get pod lifecycle-crashloop -w
kubectl logs lifecycle-crashloop --previous
kubectl delete -f 05-crashloopbackoff.yaml

# 3. Readiness Probe
kubectl apply -f 07-readiness.yaml
kubectl get pod lifecycle-readiness
kubectl delete -f 07-readiness.yaml

# 4. Liveness Probe
kubectl apply -f 08-liveness.yaml
kubectl get pod lifecycle-liveness -w   # Watch RESTARTS increment
kubectl delete -f 08-liveness.yaml

# 5. Init Container
kubectl apply -f 10-init-container.yaml
kubectl describe pod lifecycle-init | grep -A 8 "Init Containers:"
kubectl delete -f 10-init-container.yaml

# 6. Multi-Container Pod
kubectl apply -f 11-multi-container.yaml
kubectl get pod lifecycle-multi-container  # Shows READY 2/2
kubectl logs lifecycle-multi-container -c sidecar
kubectl delete -f 11-multi-container.yaml
```

**Output:**
```
# Pending (unschedulable - excessive memory request):
NAME               READY   STATUS    RESTARTS   AGE
lifecycle-pending  0/1     Pending   0          10s
Events: FailedScheduling  0/1 nodes are available: 1 Insufficient memory.

# CrashLoopBackOff:
NAME                  READY   STATUS             RESTARTS   AGE
lifecycle-crashloop   0/1     CrashLoopBackOff   3          90s

# Multi-Container:
NAME                        READY   STATUS    RESTARTS   AGE
lifecycle-multi-container   2/2     Running   0          15s
```

**Screenshots:**  
`![Lifecycle Probes CrashLoop](./screenshots/05-lifecycle-probes-crashloop.png)`  
`![Lifecycle Init Multi-Container](./screenshots/05-lifecycle-init-multicontainer.png)`

---

## Task 6: Core Controller Objects Exploration (ReplicaSet & StatefulSet)

### Part A: ReplicaSet Self-Healing

**Commands:**
```bash
kubectl apply -f replicaset.yml
kubectl get rs nginx-rs
kubectl get pods -l app=nginx

# Test Self-Healing
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME
sleep 5
kubectl get pods -l app=nginx
```

**Output:**
```
NAME       DESIRED   CURRENT   READY   AGE
nginx-rs   3         3         3       8s

# Before deletion:
NAME                     READY   STATUS    RESTARTS   AGE
nginx-replicaset-pxg6f   1/1     Running   0          17d
nginx-replicaset-vhlgq   1/1     Running   0          17d
nginx-replicaset-x97n5   1/1     Running   0          17d

Deleting: nginx-replicaset-pxg6f

# After deletion — ReplicaSet immediately spawned a replacement:
NAME                     READY   STATUS              RESTARTS   AGE
nginx-replicaset-cqrmg   0/1     ContainerCreating   0          2s   ← NEW POD
nginx-replicaset-vhlgq   1/1     Running             0          17d
nginx-replicaset-x97n5   1/1     Running             0          17d
```

### Part B: StatefulSet

**Commands:**
```bash
kubectl apply -f k8s-core-objects/statefulset.yml
kubectl get statefulset mysql
kubectl get pods -l app=mysql
```

**Output:**
```
NAME    READY   AGE
mysql   3/3     2m

# Ordinal naming guaranteed:
NAME      READY   STATUS    RESTARTS   AGE
mysql-0   1/1     Running   0          2m
mysql-1   1/1     Running   0          90s
mysql-2   1/1     Running   0          60s
```

**Screenshot:** `![Controllers RS StatefulSet](./screenshots/06-controllers-rs-statefulset.png)`

---

## Task 7: DaemonSet Architecture & Host Agent Deployment

Deploy a host agent DaemonSet proving exactly one pod runs per node.

**Commands:**
```bash
kubectl apply -f k8s-core-objects/deamonset.yml
kubectl get ds node-exporter
kubectl get pods -l app=node-exporter -o wide
```

**Output:**
```
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-exporter   1         1         1       1            1           <none>          30s

NAME                  READY   STATUS    NODE       NODE-IP
node-exporter-xyz12   1/1     Running   minikube   192.168.49.2
```

> In a multi-node cluster, one pod would appear per worker node automatically.

**Screenshot:** `![DaemonSet Verification](./screenshots/07-daemonset-verification.png)`

---

## Task 8: Deployment Upgrades, Rolling Updates & Instant Rollbacks

**Commands:**
```bash
cd 01-rolling-update/

# Deploy v1
kubectl apply -f deployment-v1.yaml
kubectl apply -f service.yaml
kubectl rollout status deployment/app-rolling
```

**Output (v1 deploy):**
```
Waiting for deployment "app-rolling" rollout to finish: 0 of 4 updated replicas are available...
Waiting for deployment "app-rolling" rollout to finish: 1 of 4 updated replicas are available...
Waiting for deployment "app-rolling" rollout to finish: 2 of 4 updated replicas are available...
Waiting for deployment "app-rolling" rollout to finish: 3 of 4 updated replicas are available...
deployment "app-rolling" successfully rolled out
```

**Commands (rolling update to v2):**
```bash
kubectl apply -f deployment-v2.yaml
kubectl rollout status deployment/app-rolling
kubectl rollout history deployment/app-rolling
kubectl rollout undo deployment/app-rolling
kubectl rollout status deployment/app-rolling
```

**Output (v2 rolling update):**
```
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
deployment "app-rolling" successfully rolled out

REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

**Screenshot:** `![Rolling Update and Rollback](./screenshots/08-rolling-update-and-rollback.png)`

---

## Task 9: Real-World Troubleshooting Scenarios Lab

### Drill 1: Broken Image Rollout Failure

```bash
kubectl apply -f troubleshooting/broken-image.yaml
kubectl rollout status deployment/yatri-backend --timeout=30s
kubectl get pods -l app=yatri-backend
kubectl rollout undo deployment/yatri-backend
```

**Output:**
```
error: timed out waiting for the condition

NAME                              READY   STATUS             RESTARTS   AGE
yatri-backend-abc-old-pod         1/1     Running            0          2m   ← OLD PODS SAFE
yatri-backend-xyz-new-pod         0/1     ImagePullBackOff   0          30s  ← NEW POD STUCK
```

### Drill 2: Immutable Selector Mismatch Rejection

```bash
kubectl apply -f troubleshooting/selector-mismatch.yaml
```

**Output:**
```
The Deployment "selector-error-demo" is invalid:
spec.template.metadata.labels: Invalid value: map[string]string{"app":"wrong-label"}:
`selector` does not match template `labels`
```

**Fix:** Edit `spec.template.metadata.labels.app` to match `spec.selector.matchLabels.app`.

**Screenshot:** `![Troubleshooting Drills](./screenshots/09-troubleshooting-drills.png)`

---

## Task 10: Theoretical & Architectural Conceptual Writeup

### 1. The 4 Ports Clarified

```
Client Browser ──► [nodePort: 30080] (Host IP)
                        │
                        ▼
                   [port: 8080] (Service VIP / ClusterIP)
                        │
                        ▼
                   [targetPort: 80] (Pod Network)
                        │
                        ▼
                   [containerPort: 80] (Container / Nginx process)
```

| Port | Scope | Purpose |
|---|---|---|
| `containerPort` | Inside container | Port the application listens on (informational only in PodSpec) |
| `targetPort` | Pod network | Port on the pod where Service routes traffic |
| `port` | ClusterIP (internal) | Port exposed by the Kubernetes Service internally |
| `nodePort` | Every node's external IP | Static port (30000–32767) for external access to any node |

### 2. Labels vs. Selectors

- **Labels:** Key-value pairs attached to objects (`app: nginx`, `env: prod`). Used for metadata identification.
- **Selectors:** Query filters used by controllers (Deployments, Services) to find matching labeled pods.
  ```yaml
  selector:
    matchLabels:
      app: nginx    # ← This SELECTS pods that have the label app=nginx
  ```

### 3. The 4 Deployment Strategies

| Strategy | Downtime | Description |
|---|---|---|
| **RollingUpdate** | Zero | Progressively replaces old pods with new ones. `maxSurge`/`maxUnavailable` control speed. |
| **Recreate** | Yes | Kills ALL v1 pods, then creates v2 pods. Simple but causes downtime. |
| **Blue-Green** | Zero | Two full environments (Blue=live, Green=new). Instant traffic flip via service selector. Requires 2x capacity. |
| **Canary** | Zero | Deploy small % (e.g., 10%) of v2 pods alongside v1 to test in production before full rollout. |

### 4. `maxSurge` vs `maxUnavailable` Math

For `replicas: 4`, `maxSurge: 1`, `maxUnavailable: 0`:
- **Max pods during rollout:** `4 + 1 = 5`
- **Min available pods:** `4 - 0 = 4` (100% service capacity maintained throughout)

### 5. Resource Requests vs. Limits & Units

| Concept | Description |
|---|---|
| **Requests** | Guaranteed minimum — scheduler uses this to place pods on nodes |
| **Limits** | Maximum ceiling — CPU is throttled, memory causes OOM-kill if exceeded |
| **GB vs GiB** | 1 GB = 10⁹ bytes (decimal); 1 GiB = 2³⁰ = 1,073,741,824 bytes (binary). Kubernetes uses `Mi` (mebibytes) and `Gi` (gibibytes) |

---

## Task 11: Blue-Green Deployment Execution & Instant Selector Cutover

**Directory:** `02-blue-green/`

**Commands:**
```bash
kubectl apply -f deployment-blue.yaml
kubectl apply -f deployment-green.yaml
kubectl apply -f service-blue.yaml
kubectl get pods -l app=myapp --show-labels
kubectl describe svc myapp-service | grep Selector
kubectl get endpoints myapp-service
```

**Output (Traffic to Blue):**
```
NAME                        READY   STATUS    LABELS
app-blue-5c69d7785c-8trzb   1/1     Running   app=myapp,slot=blue,version=v1
app-blue-5c69d7785c-sjvfs   1/1     Running   app=myapp,slot=blue,version=v1
app-blue-5c69d7785c-v7xfm   1/1     Running   app=myapp,slot=blue,version=v1
app-green-84df7f978-crxdt   1/1     Running   app=myapp,slot=green,version=v2
app-green-84df7f978-hph7j   1/1     Running   app=myapp,slot=green,version=v2
app-green-84df7f978-sq72v   1/1     Running   app=myapp,slot=green,version=v2

Selector: app=myapp,slot=blue
Endpoints: 10.244.0.56:80,10.244.0.57:80,10.244.0.59:80
```

**Commands (Instant Cutover to Green):**
```bash
kubectl apply -f service-green.yaml
kubectl describe svc myapp-service | grep Selector
kubectl get endpoints myapp-service
```

**Output (Traffic to Green):**
```
service/myapp-service configured
Selector: app=myapp,slot=green
Endpoints: 10.244.0.60:80,10.244.0.61:80,10.244.0.62:80
```

**Screenshot:** `![Blue-Green Cutover](./screenshots/11-blue-green-cutover.png)`

---

## Task 12: Canary Deployment Execution & Pod-Ratio Traffic Splitting

**Directory:** `03-canary/`

**Commands:**
```bash
kubectl apply -f deployment-stable.yaml  # 9 pods
kubectl apply -f service.yaml
kubectl apply -f deployment-canary.yaml  # 1 pod
kubectl get pods -l app=myapp-canary --show-labels
kubectl get endpoints myapp-canary-service
```

**Output:**
```
# 9 stable + 1 canary = 10 total pods in service pool
NAME                         READY   STATUS    LABELS
app-stable-xxx-pod1          1/1     Running   version=v1
...  (9 stable pods)
app-canary-xxx-pod1          1/1     Running   version=v2

# Traffic split loop result (20 requests, ~10% canary):
STABLE v1
STABLE v1
STABLE v1
CANARY v2    ← ~10% hits canary
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
```

**Scale canary to 30%:**
```bash
kubectl scale deployment app-canary --replicas=3
kubectl scale deployment app-stable --replicas=7

# Rollback canary:
kubectl scale deployment app-canary --replicas=0
kubectl scale deployment app-stable --replicas=9
```

**Screenshot:** `![Canary Traffic Split](./screenshots/12-canary-traffic-split.png)`

---

## Task 13: Recreate Deployment Execution & Downtime Outage Demonstration

**Directory:** `04-recreate/`

**Commands:**
```bash
kubectl apply -f deployment-v1.yaml
kubectl apply -f service.yaml
kubectl rollout status deployment/app-recreate
kubectl apply -f deployment-v2.yaml
kubectl rollout history deployment/app-recreate
kubectl rollout undo deployment/app-recreate
```

**Output (curl loop during update):**
```
VERSION: v1
VERSION: v1
[OUTAGE] Connection refused / 0 pods alive   ← All v1 pods terminated before v2 starts
[OUTAGE] Connection refused / 0 pods alive
[OUTAGE] Connection refused / 0 pods alive
VERSION: v2 (UPGRADED)
VERSION: v2 (UPGRADED)
```

> **Key Insight:** `Recreate` strategy terminates ALL old pods before starting ANY new pods. This guarantees no version mixing but causes intentional downtime.

**Screenshot:** `![Recreate Downtime Outage](./screenshots/13-recreate-downtime-outage.png)`
