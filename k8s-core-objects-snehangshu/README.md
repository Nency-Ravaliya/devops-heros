# Session 10 — Kubernetes Pods, ReplicaSets & Deployments

**Name:** Snehangshu Roy
**Enrollment No:** 24BCS10155
**Topic:** Pods, ReplicaSets, Deployments, rolling updates, rollbacks, DaemonSets and
deployment strategies

Run against a real 3-node cluster (1 control plane + 2 workers). Every output block is
actual terminal output.

---

## 1. Pod — the smallest unit, and why you should not deploy one directly

```yaml
# 01-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: standalone-pod
  labels:
    app: standalone
spec:
  containers:
    - name: nginx
      image: nginx:1.27-alpine
      ports:
        - containerPort: 80
```

```bash
kubectl apply -f 01-pod.yaml
kubectl get pod standalone-pod -o wide
```

```
pod/standalone-pod created
pod/standalone-pod condition met
NAME             READY   STATUS    RESTARTS   AGE   IP           NODE
standalone-pod   1/1     Running   0          1s    10.244.1.5   devops-hw-worker2
```

### A bare pod is not self-healing

```bash
kubectl delete pod standalone-pod
kubectl get pods
```

```
pod "standalone-pod" deleted from default namespace
No resources found in default namespace.
```

**It is simply gone.** Nothing recreated it. This is the entire reason ReplicaSets and
Deployments exist: a pod is a mortal object, and if the node it runs on dies, so does the
pod. You almost never create bare pods outside of debugging.

---

## 2. ReplicaSet — keeping N pods alive

```yaml
# 02-replicaset.yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
      tier: frontend
  template:
    metadata:
      labels:
        app: web
        tier: frontend
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine
```

The `selector` must match the `template`'s labels — that is how a ReplicaSet knows which
pods are "its" pods. It does not track them by name; it **counts pods matching the label
selector** and creates or deletes pods until that count equals `replicas`.

```bash
kubectl apply -f 02-replicaset.yaml
kubectl get rs web-rs
kubectl get pods -l app=web -o wide
```

```
replicaset.apps/web-rs created
NAME     DESIRED   CURRENT   READY   AGE
web-rs   3         3         2       9s

NAME           READY   STATUS              RESTARTS   AGE   IP           NODE
web-rs-2ck6z   0/1     ContainerCreating   0          9s    <none>       devops-hw-worker
web-rs-nhlhf   1/1     Running             0          9s    10.244.1.6   devops-hw-worker2
web-rs-v5h2g   1/1     Running             0          9s    10.244.1.7   devops-hw-worker2
```

`DESIRED 3 / CURRENT 3 / READY 2` caught mid-rollout — the third pod is still
`ContainerCreating`. The scheduler also spread the pods across **both** worker nodes on its
own.

### 2.1 Self-healing — delete a pod and watch it come back

```bash
kubectl delete pod web-rs-2ck6z
kubectl get pods -l app=web
kubectl get rs web-rs
```

```
pod "web-rs-2ck6z" deleted from default namespace

--- ReplicaSet recreated it: ---
NAME           READY   STATUS    RESTARTS   AGE
web-rs-nhlhf   1/1     Running   0          20s
web-rs-v5h2g   1/1     Running   0          20s
web-rs-vpxrm   1/1     Running   0          11s     <-- NEW pod, 9 seconds younger

NAME     DESIRED   CURRENT   READY   AGE
web-rs   3         3         3       21s
```

A **new** pod (`web-rs-vpxrm`, note the different name and younger age) replaced the deleted
one within seconds. The ReplicaSet controller noticed the count had dropped to 2, compared
it to the desired 3, and closed the gap. This is the reconciliation loop in action.

### 2.2 Scaling

```bash
kubectl scale rs web-rs --replicas=5
kubectl get rs web-rs
```

```
replicaset.apps/web-rs scaled
NAME     DESIRED   CURRENT   READY   AGE
web-rs   5         5         5       27s
```

### 2.3 What a ReplicaSet cannot do

```bash
kubectl get pods -l app=web -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
```

```
web-rs-hwd5v	nginx:1.27-alpine
web-rs-nhlhf	nginx:1.27-alpine
web-rs-t5mk6	nginx:1.27-alpine
```

A ReplicaSet keeps a fixed pod template running. If you edit the image in the template,
**existing pods are not updated** — the new image only appears on pods created afterwards.
There is no rollout, no versioning and no rollback. That gap is exactly what a Deployment
fills, which is why you rarely write a ReplicaSet by hand.

```bash
kubectl delete rs web-rs
kubectl get pods -l app=web
```

```
replicaset.apps "web-rs" deleted from default namespace
No resources found in default namespace.
```

Deleting the ReplicaSet garbage-collects its pods too, through the owner reference shown in
section 3.1.

---

## 3. Deployment — the object you actually use

```yaml
# 03-deployment-v1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
spec:
  replicas: 4
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:1.26-alpine
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet: { path: /, port: 80 }
            initialDelaySeconds: 2
            periodSeconds: 3
          livenessProbe:
            httpGet: { path: /, port: 80 }
            initialDelaySeconds: 5
            periodSeconds: 10
```

The **readinessProbe** matters more than it looks: during a rolling update Kubernetes will
not send traffic to a new pod, or continue the rollout, until that pod reports ready. Without
it a rollout can happily replace working pods with broken ones.

```bash
kubectl apply -f 03-deployment-v1.yaml
kubectl rollout status deploy/web-deploy
```

```
deployment.apps/web-deploy created
Waiting for deployment "web-deploy" rollout to finish: 0 of 4 updated replicas are available...
Waiting for deployment "web-deploy" rollout to finish: 1 of 4 updated replicas are available...
Waiting for deployment "web-deploy" rollout to finish: 2 of 4 updated replicas are available...
Waiting for deployment "web-deploy" rollout to finish: 3 of 4 updated replicas are available...
deployment "web-deploy" successfully rolled out
```

### 3.1 A Deployment does not manage pods — it manages a ReplicaSet

```bash
kubectl get deploy web-deploy
kubectl get rs -l app=web
kubectl get pods -l app=web -o wide
```

```
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
web-deploy   4/4     4            4           15s

NAME                    DESIRED   CURRENT   READY   AGE
web-deploy-56d49f6466   4         4         4       16s

NAME                          READY   STATUS    RESTARTS   AGE   IP           NODE
web-deploy-56d49f6466-2w6rr   1/1     Running   0          16s   10.244.1.9   devops-hw-worker2
web-deploy-56d49f6466-69s79   1/1     Running   0          16s   10.244.2.7   devops-hw-worker
web-deploy-56d49f6466-f69bc   1/1     Running   0          16s   10.244.1.8   devops-hw-worker2
web-deploy-56d49f6466-srl5b   1/1     Running   0          16s   10.244.2.8   devops-hw-worker
```

Look at the names: the Deployment created a ReplicaSet `web-deploy-56d49f6466`, and the pods
are named after **that ReplicaSet**. The hash `56d49f6466` is derived from the pod template —
change the template and you get a different hash, and therefore a different ReplicaSet.

### 3.2 The ownership chain, confirmed

```bash
kubectl get pod <pod> -o jsonpath='{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}'
```

```
pod:        web-deploy-56d49f6466-2w6rr
owned by:   ReplicaSet/web-deploy-56d49f6466
which is owned by: Deployment/web-deploy
```

**Deployment → ReplicaSet → Pod.** These `ownerReferences` are real fields on the objects,
and they drive garbage collection: delete the Deployment and the whole chain goes with it.

### 3.3 Scaling a Deployment

```bash
kubectl scale deploy/web-deploy --replicas=6
kubectl get deploy web-deploy
```

```
deployment.apps/web-deploy scaled
Waiting for deployment "web-deploy" rollout to finish: 4 of 6 updated replicas are available...
Waiting for deployment "web-deploy" rollout to finish: 5 of 6 updated replicas are available...
deployment "web-deploy" successfully rolled out

NAME         READY   UP-TO-DATE   AVAILABLE   AGE
web-deploy   6/6     6            6           21s
```

---

## 4. Rolling update

Current version:

```bash
kubectl get deploy web-deploy -o jsonpath='{.spec.template.spec.containers[0].image}'
```

```
nginx:1.26-alpine
```

Now apply v2, which changes the image to `nginx:1.27-alpine`:

```bash
kubectl apply -f 04-deployment-v2.yaml
kubectl rollout status deploy/web-deploy
```

```
deployment.apps/web-deploy configured
Waiting for deployment "web-deploy" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "web-deploy" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "web-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "web-deploy" rollout to finish: 3 of 4 updated replicas are available...
deployment "web-deploy" successfully rolled out
```

You can read the whole rolling-update algorithm in that output: new replicas are created a
few at a time, old ones are terminated as new ones become ready, and the two sets overlap so
the service is never fully down.

```bash
kubectl get deploy web-deploy
kubectl get rs -l app=web
kubectl get deploy web-deploy -o jsonpath='{.spec.template.spec.containers[0].image}'
```

```
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
web-deploy   4/4     4            4           32s

NAME                    DESIRED   CURRENT   READY   AGE
web-deploy-56d49f6466   0         0         0       33s     <-- old RS, scaled to zero
web-deploy-648f47fdc7   4         4         4       11s     <-- new RS, now serving

nginx:1.27-alpine
```

**This is how a Deployment actually performs an update.** It does not modify the old
ReplicaSet — it creates a *second* ReplicaSet with the new template hash, then scales the new
one up and the old one down. The old ReplicaSet is kept at 0 replicas, which is what makes an
instant rollback possible.

> One honest note on the numbers: replicas went from 6 back to 4 here. That is not a bug —
> `04-deployment-v2.yaml` declares `replicas: 4`, and `kubectl apply` is declarative, so it
> reset the count I had set imperatively with `kubectl scale`. It is a good illustration of
> why mixing `kubectl scale` with `kubectl apply` causes surprises, and why production setups
> either keep replicas in the manifest or hand that field to a HorizontalPodAutoscaler.

### 4.1 Rollout history

```bash
kubectl rollout history deploy/web-deploy
```

```
deployment.apps/web-deploy
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

Two revisions, one per ReplicaSet. `CHANGE-CAUSE` is `<none>` because I did not annotate the
change; in practice you set it with
`kubectl annotate deploy/web-deploy kubernetes.io/change-cause="upgrade nginx to 1.27"` so
the history is readable later.

---

## 5. Rollback

```bash
kubectl rollout undo deploy/web-deploy
kubectl rollout status deploy/web-deploy
```

```
deployment.apps/web-deploy rolled back
Waiting for deployment "web-deploy" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "web-deploy" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "web-deploy" rollout to finish: 1 old replicas are pending termination...
deployment "web-deploy" successfully rolled out

image after rollback: nginx:1.26-alpine
```

```bash
kubectl get rs -l app=web
```

```
NAME                    DESIRED   CURRENT   READY   AGE
web-deploy-56d49f6466   4         4         4       44s     <-- back to 4
web-deploy-648f47fdc7   0         0         0       22s     <-- scaled to zero
```

The two ReplicaSets simply **swapped roles**. Nothing was rebuilt and no image was pulled
again — the rollback is just a scale-up of the old ReplicaSet and a scale-down of the new
one, which is why it completes in seconds. This is the single most valuable operational
property of a Deployment.

`revisionHistoryLimit: 5` in the manifest controls how many old ReplicaSets are kept
available to roll back to.

```bash
kubectl rollout undo deploy/web-deploy --to-revision=2   # roll forward to a specific revision
```

---

## 6. Deployment strategies

```bash
kubectl get deploy web-deploy -o jsonpath='strategy={.spec.strategy.type} maxSurge={.spec.strategy.rollingUpdate.maxSurge} maxUnavailable={.spec.strategy.rollingUpdate.maxUnavailable}'
```

```
strategy=RollingUpdate maxSurge=1 maxUnavailable=1
```

### 6.1 RollingUpdate (the default)

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1          # at most 1 pod ABOVE the desired count during the rollout
    maxUnavailable: 1    # at most 1 pod BELOW the desired count during the rollout
```

With `replicas: 4`, those settings mean the pod count stays between 3 and 5 throughout.
Zero downtime, but **both versions run at the same time** — so the new version must be
backward-compatible with the old one's database schema and API contracts.

- `maxUnavailable: 0` → never drop below full capacity (needs spare room to surge).
- `maxSurge: 0` → never exceed the replica count (useful under a hard resource quota).

### 6.2 Recreate

```yaml
strategy:
  type: Recreate
```

Kills **all** old pods first, then creates the new ones. There is a real gap in service, but
the two versions never coexist. The right choice when versions cannot run side by side — a
breaking database migration, or a singleton that must hold an exclusive lock.

### 6.3 Blue-Green

Two complete environments, `blue` (live) and `green` (new), both fully deployed. A Service
selector points at `version: blue`; to release, you flip it to `version: green`:

```bash
kubectl patch service web-svc -p '{"spec":{"selector":{"version":"green"}}}'
```

The cutover is instant and the rollback is the same one-line patch back to `blue`. The cost
is running double the infrastructure during the switchover. Kubernetes has no built-in
`BlueGreen` strategy — you build it out of two Deployments and a Service selector.

### 6.4 Canary

Run a small number of new-version pods alongside the stable ones, behind the **same**
Service, so only a fraction of traffic hits the new version:

```yaml
# stable: 9 replicas, labels: app=web, version=stable
# canary: 1 replica,  labels: app=web, version=canary
# Service selector: app=web  -> matches BOTH, so ~10% of traffic reaches the canary
```

Watch error rates and latency, then scale the canary up and the stable down if it looks
healthy. The naive version ties the traffic split to the replica ratio; a service mesh or an
ingress with traffic-splitting annotations gives you precise percentages instead.

### 6.5 Strategy comparison

| Strategy | Downtime | Both versions live | Extra resources | Rollback speed | Use when |
|---|---|---|---|---|---|
| RollingUpdate | None | Yes | ~`maxSurge` | Fast | The normal default |
| Recreate | Yes | No | None | Redeploy needed | Versions are incompatible |
| Blue-Green | None | Yes (idle) | 2× | Instant | High-risk releases needing instant rollback |
| Canary | None | Yes | +1 small set | Fast | You want real-traffic validation first |

---

## 7. DaemonSet — one pod per node

```yaml
# 05-daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-agent
spec:
  selector:
    matchLabels:
      app: node-agent
  template:
    metadata:
      labels:
        app: node-agent
    spec:
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
          effect: NoSchedule
      containers:
        - name: agent
          image: busybox:1.36
          command: ["/bin/sh", "-c", "while true; do echo agent alive on $NODE_NAME; sleep 30; done"]
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
```

Two details worth calling out:

- The **toleration** lets the agent also run on the control-plane node, which carries a
  `NoSchedule` taint by default. Without it you would get 2 pods, not 3.
- The **downward API** (`fieldRef: spec.nodeName`) injects the node's name into the
  container as an environment variable, so each agent knows where it is running.

```bash
kubectl apply -f 05-daemonset.yaml
kubectl get ds node-agent
kubectl get pods -l app=node-agent -o wide
```

```
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-agent   3         3         3       3            3           <none>          12s

NAME               READY   STATUS    RESTARTS   AGE   IP            NODE
node-agent-tnb6v   1/1     Running   0          12s   10.244.1.15   devops-hw-worker2
node-agent-vzmw4   1/1     Running   0          12s   10.244.0.6    devops-hw-control-plane
node-agent-xbrpk   1/1     Running   0          12s   10.244.2.14   devops-hw-worker
```

Notice there is **no `replicas` field** — a DaemonSet has no replica count. `DESIRED 3` was
derived from the number of eligible nodes. Add a node to the cluster and a fourth pod
appears automatically.

```bash
kubectl get pods -l app=node-agent -o jsonpath='{range .items[*]}{.metadata.name}{" on "}{.spec.nodeName}{"\n"}{end}'
```

```
node-agent-tnb6v on devops-hw-worker2
node-agent-vzmw4 on devops-hw-control-plane
node-agent-xbrpk on devops-hw-worker

nodes in cluster: 3
node-agent pods : 3
```

**Exactly one pod per node, no duplicates.**

```bash
kubectl logs -l app=node-agent --tail=1 --prefix=true
```

```
[pod/node-agent-tnb6v/agent] agent alive on devops-hw-worker2
[pod/node-agent-vzmw4/agent] agent alive on devops-hw-control-plane
[pod/node-agent-xbrpk/agent] agent alive on devops-hw-worker
```

Each agent correctly reports its own node. Real-world DaemonSets: log collectors
(Fluent Bit), metrics agents (node-exporter), CNI plugins and storage drivers — in fact
`kube-proxy` and the CNI in this very cluster are DaemonSets.

---

## 8. Final state

```bash
kubectl get all -l app=web
kubectl get ds
```

```
NAME                              READY   STATUS    RESTARTS   AGE
pod/web-deploy-56d49f6466-d95t5   1/1     Running   0          19s
pod/web-deploy-56d49f6466-d9jhr   1/1     Running   0          19s
pod/web-deploy-56d49f6466-dhrng   1/1     Running   0          24s
pod/web-deploy-56d49f6466-hwcqt   1/1     Running   0          24s

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web-deploy   4/4     4            4           57s

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/web-deploy-56d49f6466   4         4         4       57s
replicaset.apps/web-deploy-648f47fdc7   0         0         0       35s

NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-agent   3         3         3       3            3           <none>          13s
```

---

## Object comparison

| | Pod | ReplicaSet | Deployment | DaemonSet |
|---|---|---|---|---|
| Self-healing | No | Yes | Yes | Yes |
| Replica count | 1 | Fixed `replicas` | Fixed `replicas` | One per node, automatic |
| Rolling updates | No | **No** | **Yes** | Yes |
| Rollback | No | No | **Yes** | Yes |
| Revision history | No | No | Yes | Yes |
| Write it by hand? | Only for debugging | Rarely | **Usually** | For per-node agents |

---

## Command reference

```bash
# create / update
kubectl apply -f <file>
kubectl set image deploy/web-deploy web=nginx:1.27-alpine

# inspect
kubectl get deploy,rs,pods -l app=web
kubectl describe deploy web-deploy
kubectl get pod <p> -o jsonpath='{.metadata.ownerReferences[0].kind}'

# scale
kubectl scale deploy/web-deploy --replicas=6
kubectl autoscale deploy/web-deploy --min=2 --max=10 --cpu-percent=80

# rollout
kubectl rollout status  deploy/web-deploy
kubectl rollout history deploy/web-deploy
kubectl rollout undo    deploy/web-deploy
kubectl rollout undo    deploy/web-deploy --to-revision=2
kubectl rollout restart deploy/web-deploy     # restart pods without changing the spec
kubectl rollout pause / resume deploy/web-deploy

# annotate so rollout history is readable
kubectl annotate deploy/web-deploy kubernetes.io/change-cause="upgrade nginx to 1.27"
```

---

## Files in this folder

| File | Purpose |
|---|---|
| `01-pod.yaml` | Standalone pod (used to show it is not self-healing) |
| `02-replicaset.yaml` | ReplicaSet with 3 replicas |
| `03-deployment-v1.yaml` | Deployment v1 (`nginx:1.26-alpine`) with probes and a RollingUpdate strategy |
| `04-deployment-v2.yaml` | Deployment v2 (`nginx:1.27-alpine`) for the rolling update |
| `05-daemonset.yaml` | DaemonSet with a control-plane toleration and the downward API |
| `k8s-core-objects-transcript.txt` | Full terminal transcript |

## Summary

| Item | Status |
|---|---|
| Pod created, and shown not to be self-healing when deleted | Done |
| ReplicaSet created, self-healing proven by deleting a pod, scaled, and its limitation shown | Done |
| Deployment created; Deployment → ReplicaSet → Pod ownership chain verified from real `ownerReferences` | Done |
| Deployment scaled | Done |
| Rolling update performed and the two-ReplicaSet mechanism observed | Done |
| Rollout history inspected and rollback performed, with the ReplicaSets swapping roles | Done |
| Deployment strategies — RollingUpdate, Recreate, Blue-Green, Canary — explained and compared | Done |
| DaemonSet deployed, one pod per node across all 3 nodes verified | Done |
