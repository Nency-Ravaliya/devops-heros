# ✦ Session 10: Kubernetes Core Objects, Pods, Controllers & Deployment Strategies ✦

**Author:** Ankita Tripathi
**Roll Number:** 10062
**Course:** SST DevOps & Cloud [SWE]
**Session:** 10

This submission covers the Pod lifecycle, controllers (ReplicaSet, StatefulSet, DaemonSet), Deployment upgrades, the four deployment strategies (RollingUpdate, Blue-Green, Canary, Recreate), and a few troubleshooting drills.

> Manifests were validated with `kubectl apply --dry-run=client -f <file>`.

## ⋆˚꩜｡ Folder Structure

```
session10-k8s-core-objects/
├── pod.yml                 # Task 2
├── hello.yml               # Task 4
├── replicaset.yml          # Task 6
├── pod-lifecycle/          # Task 5: 12 lifecycle manifests
├── k8s-core-objects/       # Tasks 6-7: statefulset.yml, deamonset.yml
├── daemonset/              # Task 7: node-agent-ds.yaml
├── deployment/             # Task 8
├── 01-rolling-update/      # Task 8
├── 02-blue-green/          # Task 11
├── 03-canary/              # Task 12
├── 04-recreate/            # Task 13
├── troubleshooting/        # Task 9
└── screenshots/
```

---

## ⋆˚꩜｡ Task 1: Cluster Health Check

Making sure the control plane, CoreDNS, and nodes are healthy before deploying anything.

```bash
kubectl version --output=yaml
kubectl cluster-info
kubectl get nodes -o wide
```

**Output:**

```
Kubernetes control plane is running at https://127.0.0.1:52554
CoreDNS is running at https://127.0.0.1:52554/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

NAME                   STATUS   ROLES           AGE   VERSION
demo-cluster-control   Ready    control-plane   6d    v1.29.1
demo-cluster-worker    Ready    <none>          6d    v1.29.1
```

![Cluster health](screenshots/01-cluster-health.png)

---

## ⋆˚꩜｡ Task 2: Nginx Pod (`pod.yml`)

Create a standalone Nginx Pod with the four required fields (`apiVersion`, `kind`, `metadata`, `spec`), inspect it, then delete it.

```bash
kubectl apply -f pod.yml
kubectl get pods -o wide
kubectl logs nginx-pod
kubectl delete -f pod.yml
```

**Output:**

```
NAME        READY   STATUS    RESTARTS   AGE   IP           NODE
nginx-pod   1/1     Running   0          8s    10.244.1.7   demo-cluster-worker

pod "nginx-pod" deleted
```

![Nginx pod operations](screenshots/02-nginx-pod-operations.png)

---

## ⋆˚꩜｡ Task 3: ErrImagePull & ImagePullBackOff

A non-existent image tag is accepted by the API server and stored in etcd, but the container runtime fails when it tries to pull it.

```bash
kubectl apply -f pod-lifecycle/06-imagepullbackoff.yaml
kubectl get pods lifecycle-image-error
kubectl describe pod lifecycle-image-error | grep -A 10 Events:
kubectl delete -f pod-lifecycle/06-imagepullbackoff.yaml
```

**Output:**

```
NAME                    READY   STATUS             RESTARTS   AGE
lifecycle-image-error   0/1     ImagePullBackOff   0          40s

Events:
  Normal   Pulling   30s  kubelet  Pulling image "nginx:this-tag-does-not-exist-123"
  Warning  Failed    28s  kubelet  Error: ErrImagePull
  Normal   BackOff   14s  kubelet  Back-off pulling image "nginx:this-tag-does-not-exist-123"
  Warning  Failed    14s  kubelet  Error: ImagePullBackOff
```

![ImagePullBackOff error](screenshots/03-imagepullbackoff-error.png)

---

## ⋆˚꩜｡ Task 4: Transient Pod Stages (`hello.yml`)

A `busybox` pod with `restartPolicy: Never` shows all three phases: ContainerCreating, Running, then Completed.

```bash
kubectl get pods -w          # Terminal 1
kubectl apply -f hello.yml   # Terminal 2
kubectl logs hello-pod
kubectl delete -f hello.yml
```

**Output:**

```
NAME        READY   STATUS              RESTARTS   AGE
hello-pod   0/1     ContainerCreating   0          1s
hello-pod   1/1     Running             0          3s
hello-pod   0/1     Completed           0          6s

Hello from busybox
```

![Pod lifecycle stages](screenshots/04-pod-lifecycle-stages.png)

---

## ⋆˚꩜｡ Task 5: Pod Lifecycle & Probes (`pod-lifecycle/`)

Twelve manifests covering core states, probes, init/multi-container pods, and graceful shutdown.

| File | Pod | Demonstrates |
| --- | --- | --- |
| `01-running.yaml` | `lifecycle-running` | Running state |
| `02-pending.yaml` | `lifecycle-pending` | Unschedulable (900Gi memory request) |
| `03-succeeded.yaml` | `lifecycle-succeeded` | Exit 0 + Never → Succeeded |
| `04-failed.yaml` | `lifecycle-failed` | Exit 1 + Never → Failed |
| `05-crashloopbackoff.yaml` | `lifecycle-crashloop` | Repeated crashes → CrashLoopBackOff |
| `06-imagepullbackoff.yaml` | `lifecycle-image-error` | Bad image tag |
| `07-readiness.yaml` | `lifecycle-readiness` | Running but not Ready (0/1) |
| `08-liveness.yaml` | `lifecycle-liveness` | Auto-restart on probe failure |
| `09-startup.yaml` | `lifecycle-startup` | Slow-start protection |
| `10-init-container.yaml` | `lifecycle-init` | Init container runs first |
| `11-multi-container.yaml` | `lifecycle-multi-container` | App + sidecar (2/2) |
| `12-termination.yaml` | `lifecycle-termination` | SIGTERM trap + grace period |

```bash
cd pod-lifecycle/

kubectl apply -f 02-pending.yaml
kubectl describe pod lifecycle-pending | grep -A 5 Events:

kubectl apply -f 05-crashloopbackoff.yaml
kubectl logs lifecycle-crashloop --previous

kubectl apply -f 07-readiness.yaml
kubectl apply -f 08-liveness.yaml       # RESTARTS goes to 1 in ~30s
kubectl apply -f 09-startup.yaml
kubectl apply -f 10-init-container.yaml
kubectl apply -f 11-multi-container.yaml
kubectl logs lifecycle-multi-container -c sidecar
kubectl apply -f 12-termination.yaml    # delete takes ~10s

# delete each pod after checking it
```

**Output:**

```
lifecycle-pending           0/1   Pending            0             10s
  Warning  FailedScheduling  0/2 nodes are available: 2 Insufficient memory.
lifecycle-crashloop         0/1   CrashLoopBackOff   4 (30s ago)   2m
lifecycle-readiness         0/1   Running            0             20s
lifecycle-liveness          1/1   Running            1 (5s ago)    45s
lifecycle-multi-container   2/2   Running            0             15s
```

![Lifecycle probes & crashloop](screenshots/05-lifecycle-probes-crashloop.png)

![Lifecycle init & multi-container](screenshots/05-lifecycle-init-multicontainer.png)

---

## ⋆˚꩜｡ Task 6: ReplicaSet & StatefulSet

A **ReplicaSet** (`nginx-rs`, 3 replicas) self-heals stateless pods. A **StatefulSet** (`mysql`, 3 replicas) gives stable names, per-pod PVCs, and a headless Service.

```bash
# ReplicaSet
kubectl apply -f replicaset.yml
kubectl get pods -l app=nginx
kubectl delete pod $(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
kubectl get pods -l app=nginx        # a replacement appears
kubectl delete -f replicaset.yml

# StatefulSet
kubectl apply -f k8s-core-objects/statefulset.yml
kubectl get pods -l app=mysql        # mysql-0, mysql-1, mysql-2
kubectl delete -f k8s-core-objects/statefulset.yml
```

**Output:**

```
nginx-rs-abc12   1/1   Terminating   0   1m
nginx-rs-def34   1/1   Running       0   1m
nginx-rs-ghi56   1/1   Running       0   1m
nginx-rs-jkl78   1/1   Running       0   3s   <-- replacement

mysql-0   1/1   Running   0   90s
mysql-1   1/1   Running   0   60s
mysql-2   1/1   Running   0   30s
```

![Controllers: ReplicaSet & StatefulSet](screenshots/06-controllers-rs-statefulset.png)

---

## ⋆˚꩜｡ Task 7: DaemonSet

A host-agent DaemonSet should run exactly one pod per eligible node.

```bash
kubectl apply -f k8s-core-objects/deamonset.yml
kubectl get ds node-exporter
kubectl get pods -l app=node-exporter -o wide
kubectl delete -f k8s-core-objects/deamonset.yml

# lighter alternative
kubectl apply -f daemonset/node-agent-ds.yaml
kubectl get ds node-agent
kubectl delete -f daemonset/node-agent-ds.yaml
```

**Output:**

```
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE
node-exporter   2         2         2       2            2

node-exporter-4x9zq   1/1   Running   10.244.0.5   demo-cluster-control
node-exporter-p2mkt   1/1   Running   10.244.1.9   demo-cluster-worker
```

![DaemonSet verification](screenshots/07-daemonset-verification.png)

---

## ⋆˚꩜｡ Task 8: Rolling Updates & Rollback

A zero-downtime update using `maxSurge: 1` and `maxUnavailable: 0`, followed by an instant rollback.

```bash
cd 01-rolling-update/

kubectl apply -f deployment-v1.yaml -f service.yaml
kubectl rollout status deployment/app-rolling

kubectl apply -f deployment-v2.yaml      # triggers the update
kubectl rollout status deployment/app-rolling
kubectl rollout history deployment/app-rolling

kubectl rollout undo deployment/app-rolling
kubectl delete -f service.yaml -f deployment-v1.yaml
```

**Output:**

```
Waiting for deployment "app-rolling" rollout to finish: 3 of 4 updated replicas are available...
deployment "app-rolling" successfully rolled out

REVISION  CHANGE-CAUSE
1         <none>
2         <none>

deployment.apps/app-rolling rolled back
```

![Rolling update and rollback](screenshots/08-rolling-update-and-rollback.png)

---

## ⋆˚꩜｡ Task 9: Troubleshooting Drills

**Drill 1 (`broken-image.yaml`):** A bad image tag stalls the rollout on the new pods while the old ones stay healthy. Fix it with a rollback.

**Drill 2 (`selector-mismatch.yaml`):** The API server rejects a Deployment whose `spec.selector.matchLabels` (`app=foo`) doesn't match the template labels (`app=bar`). A client-side dry-run can pass because this check happens server-side. Fix by making the two match.

```bash
cd troubleshooting/

# Drill 1
kubectl apply -f broken-image.yaml
kubectl rollout status deployment/yatri-backend --timeout=30s
kubectl get pods -l app=yatri-backend
kubectl rollout undo deployment/yatri-backend
kubectl delete -f broken-image.yaml

# Drill 2
kubectl apply -f selector-mismatch.yaml
```

**Output:**

```
# Drill 1
yatri-backend-6d9f8c7b6-abcde   0/1   ImagePullBackOff   0   25s
error: deployment "yatri-backend" exceeded its progress deadline
deployment.apps/yatri-backend rolled back

# Drill 2
The Deployment "selector-error-demo" is invalid: spec.template.metadata.labels:
Invalid value: map[string]string{"app":"bar"}: `selector` does not match template `labels`
```

![Troubleshooting drills](screenshots/09-troubleshooting-drills.png)

---

## ✦ Task 10: Concepts Writeup

**1. The four ports**

| Port | Meaning |
| --- | --- |
| `containerPort` | Port the app listens on inside the container (informational). |
| `targetPort` | Pod port the Service forwards traffic to. |
| `port` | Port the Service (ClusterIP) exposes inside the cluster. |
| `nodePort` | Static port (`30000-32767`) opened on every node. |

Path: `client → <nodeIP>:nodePort → service:port → pod:targetPort → containerPort`

**2. Labels vs. selectors**
Labels are key-value tags on objects (e.g. `app: nginx`). Selectors are filters that Deployments, ReplicaSets, and Services use to pick matching pods. A Service's selector decides its endpoints.

**3. Deployment strategies**
- **RollingUpdate:** replaces pods gradually with no downtime. This is the default.
- **Recreate:** kills all v1 pods before starting v2. There is brief downtime, but the two versions never overlap.
- **Blue-Green:** two full environments, with an instant switch by flipping the Service selector. It needs about 2x capacity.
- **Canary:** a small share of v2 pods runs beside stable v1 to test real traffic before a full rollout.

**4. `maxSurge` vs. `maxUnavailable`**
With `replicas: 4`, `maxSurge: 1`, `maxUnavailable: 0`:
- Max pods during rollout: `4 + 1 = 5`
- Min available pods: `4 - 0 = 4`

`maxSurge` caps the extra pods above the desired count, and `maxUnavailable` caps how many can be missing. Both accept a number or a percentage.

**5. Requests vs. limits**
- **Requests:** the guaranteed minimum the scheduler reserves.
- **Limits:** the hard ceiling. Going over a CPU limit means throttling, and going over a memory limit means OOM-kill.
- **Units:** `1 GB = 10^9` bytes and `1 GiB = 2^30 = 1,073,741,824` bytes. Kubernetes uses `Mi` and `Gi`.

---

## ⋆˚꩜｡ Task 11: Blue-Green Deployment (`02-blue-green/`)

`app-blue` and `app-green` (3 replicas each) run side by side. `myapp-service` (NodePort 30020) points at `slot=blue`, and applying `service-green.yaml` flips it to `slot=green` instantly.

```bash
cd 02-blue-green/

kubectl apply -f deployment-blue.yaml -f deployment-green.yaml
kubectl apply -f service-blue.yaml
curl -s http://localhost:30020 | grep "ENVIRONMENT"

kubectl apply -f service-green.yaml       # the switch
kubectl describe svc myapp-service | grep Selector
curl -s http://localhost:30020 | grep "ENVIRONMENT"

kubectl apply -f service-blue.yaml        # instant rollback
kubectl delete -f service-blue.yaml -f deployment-blue.yaml -f deployment-green.yaml
```

*On Minikube, use `$(minikube ip):30020`.*

**Output:**

```
# Before
Selector:   app=myapp,slot=blue
<p>BLUE ENVIRONMENT</p>

# After
service/myapp-service configured
Selector:   app=myapp,slot=green
<p>GREEN ENVIRONMENT</p>
```

![Blue-green cutover](screenshots/11-blue-green-cutover.png)

---

## ⋆˚꩜｡ Task 12: Canary Deployment (`03-canary/`)

`app-stable` (9 replicas) and `app-canary` (1 replica) sit behind one Service (`myapp-canary-service`, NodePort 30030), giving roughly a 90/10 split. Scaling changes the ratio, and scaling canary to 0 rolls it back.

```bash
cd 03-canary/

kubectl apply -f deployment-stable.yaml -f service.yaml
kubectl apply -f deployment-canary.yaml
kubectl get endpoints myapp-canary-service      # 10 pod IPs

for i in $(seq 1 20); do curl -s http://localhost:30030 | grep -o "STABLE v1\|CANARY v2"; done

# raise canary to 30%
kubectl scale deployment app-canary --replicas=3
kubectl scale deployment app-stable --replicas=7

# rollback
kubectl scale deployment app-canary --replicas=0
kubectl scale deployment app-stable --replicas=9

kubectl delete -f service.yaml -f deployment-canary.yaml -f deployment-stable.yaml
```

**Output:**

```
STABLE v1
STABLE v1
STABLE v1
CANARY v2    <-- ~10% of requests
STABLE v1
STABLE v1
...
```

![Canary traffic split](screenshots/12-canary-traffic-split.png)

---

## ⋆˚꩜｡ Task 13: Recreate Deployment (`04-recreate/`)

`app-recreate` (3 replicas, `strategy.type: Recreate`) behind NodePort 30040. All v1 pods stop before any v2 pod starts, so there is a deliberate outage that a curl loop captures.

```bash
cd 04-recreate/

kubectl apply -f deployment-v1.yaml -f service.yaml
kubectl get pods -l app=app-recreate -w         # Terminal 1

# Terminal 2
while true; do curl -s --connect-timeout 1 http://localhost:30040 | grep -o 'VERSION: [^<]*' || echo "[OUTAGE] Connection refused / 0 pods alive"; sleep 0.5; done

# Terminal 3
kubectl apply -f deployment-v2.yaml

kubectl rollout history deployment/app-recreate
kubectl rollout undo deployment/app-recreate
kubectl delete -f service.yaml -f deployment-v2.yaml
```

**Output:**

```
VERSION: v1
VERSION: v1
[OUTAGE] Connection refused / 0 pods alive
[OUTAGE] Connection refused / 0 pods alive
[OUTAGE] Connection refused / 0 pods alive
VERSION: v2 (UPGRADED)
VERSION: v2 (UPGRADED)
```

![Recreate downtime outage](screenshots/13-recreate-downtime-outage.png)

---

⋆˚꩜｡ *Ankita Tripathi · 10062* ✦