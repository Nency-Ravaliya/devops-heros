# Task 2 - Workload & Service Comparisons

**Ujjawal Prabhat - 24BCS10267 - Session 11**

All outputs below are from namespace `s11` on my kind cluster. Manifests used: [`../common/web-deployment.yaml`](../common/web-deployment.yaml)
(Deployment `web`), [`daemonset.yaml`](daemonset.yaml), [`statefulset-with-storage.yaml`](statefulset-with-storage.yaml),
[`../05-headless/headless.yaml`](../05-headless/headless.yaml) (StatefulSet `web-sts`).

---

## A. Deployment vs ReplicaSet

| | ReplicaSet | Deployment |
|---|---|---|
| **Purpose** | Keep N identical pods running (self-healing) | Declarative releases of a stateless app: owns ReplicaSets and manages versions |
| **Pod management** | Creates/deletes pods directly to match `replicas` and `selector` | Never touches pods directly. It creates/scales ReplicaSets, and they manage the pods |
| **Scaling** | `kubectl scale rs` works only if nothing owns the RS | `kubectl scale deploy`. The Deployment sets `replicas` on its current RS |
| **Rolling updates** | **None.** Changing the template does not affect existing pods | `strategy` (RollingUpdate/Recreate), `maxSurge`, `maxUnavailable`, rollout history, `rollout undo`, pause/resume |
| **Relationship** | Owned by a Deployment (`ownerReferences`) | Owner: Deployment -> ReplicaSet (one per template revision) -> Pods |

**Ownership chain (real `ownerReferences`):**

```
$ kubectl -n s11 get deploy,rs,pods -l app=web
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   3/3     3            3           3m20s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/web-7bdcf85c86   3         3         3       3m20s

NAME                       READY   STATUS    RESTARTS   AGE
pod/web-7bdcf85c86-58dx6   1/1     Running   0          3m20s
pod/web-7bdcf85c86-8rl6d   1/1     Running   0          3m20s
pod/web-7bdcf85c86-qq9t8   1/1     Running   0          3m20s

$ kubectl -n s11 get rs web-7bdcf85c86 -o jsonpath='{.metadata.ownerReferences}' | python3 -m json.tool
[
    {
        "apiVersion": "apps/v1",
        "blockOwnerDeletion": true,
        "controller": true,
        "kind": "Deployment",
        "name": "web",
        "uid": "26d3b90e-7499-491e-88bf-ec78137334c2"
    }
]

$ kubectl -n s11 get pod web-7bdcf85c86-58dx6 -o jsonpath='{.metadata.ownerReferences}' | python3 -m json.tool
[
    {
        "apiVersion": "apps/v1",
        "blockOwnerDeletion": true,
        "controller": true,
        "kind": "ReplicaSet",
        "name": "web-7bdcf85c86",
        "uid": "c1b7fdb7-ccec-4193-96c3-14b7997d2f12"
    }
]

$ kubectl -n s11 get pods -l app=web -o custom-columns=POD:.metadata.name,OWNER-KIND:.metadata.ownerReferences[0].kind,OWNER:.metadata.ownerReferences[0].name
POD                    OWNER-KIND   OWNER
web-7bdcf85c86-58dx6   ReplicaSet   web-7bdcf85c86
web-7bdcf85c86-8rl6d   ReplicaSet   web-7bdcf85c86
web-7bdcf85c86-qq9t8   ReplicaSet   web-7bdcf85c86
```

**Who controls scaling?** I scaled the ReplicaSet directly to 5, and the Deployment controller put it back to 3 at once.
Scaling has to be done through the Deployment:

```
$ kubectl -n s11 scale rs web-7bdcf85c86 --replicas=5
replicaset.apps/web-7bdcf85c86 scaled

$ kubectl -n s11 get rs web-7bdcf85c86
NAME             DESIRED   CURRENT   READY   AGE
web-7bdcf85c86   3         3         3       3m24s

$ kubectl -n s11 scale deploy web --replicas=4
deployment.apps/web scaled

$ kubectl -n s11 get deploy web
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
web    4/4     4            4           3m28s

$ kubectl -n s11 get rs -l app=web
NAME             DESIRED   CURRENT   READY   AGE
web-7bdcf85c86   4         4         4       3m28s
```

**Rolling updates exist only on the Deployment.** Compare the spec fields. A ReplicaSet has no `strategy`, `revisionHistoryLimit`, `paused` or
`progressDeadlineSeconds`:

```
$ kubectl explain deployment.spec --recursive=false | grep -E '^  (strategy|revisionHistoryLimit|paused|progressDeadlineSeconds|replicas|selector|template|minReadySeconds)'
  minReadySeconds	<integer>
  paused	<boolean>
  progressDeadlineSeconds	<integer>
  replicas	<integer>
  revisionHistoryLimit	<integer>
  selector	<LabelSelector> -required-
  strategy	<DeploymentStrategy>
  template	<PodTemplateSpec> -required-

$ kubectl explain replicaset.spec --recursive=false | grep -E '^  [a-zA-Z]'
  minReadySeconds	<integer>
  replicas	<integer>
  selector	<LabelSelector> -required-
  template	<PodTemplateSpec>
```

An image update on the Deployment creates a **new ReplicaSet** and scales the old one to 0:

```
$ kubectl -n s11 set image deploy/web whoami=traefik/whoami:v1.11
deployment.apps/web image updated

$ kubectl -n s11 rollout status deploy/web --timeout=120s
Waiting for deployment "web" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "web" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "web" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "web" rollout to finish: 1 old replicas are pending termination...
deployment "web" successfully rolled out

$ kubectl -n s11 get rs -l app=web -o wide
NAME             DESIRED   CURRENT   READY   AGE     CONTAINERS   IMAGES                 SELECTOR
web-774ccbcbbc   4         4         4       8s      whoami       traefik/whoami:v1.11   app=web,pod-template-hash=774ccbcbbc
web-7bdcf85c86   0         0         0       3m36s   whoami       traefik/whoami:v1.10   app=web,pod-template-hash=7bdcf85c86

$ kubectl -n s11 scale deploy web --replicas=3
deployment.apps/web scaled
```

---

## B. Deployment vs DaemonSet vs StatefulSet

| | Deployment | DaemonSet | StatefulSet |
|---|---|---|---|
| **Use case** | Stateless apps: web servers, APIs, workers | One agent per node: log shippers (Fluent Bit), monitoring (node-exporter), CNI (kindnet), kube-proxy | Stateful apps needing stable identity/storage: databases, Kafka, ZooKeeper, Elasticsearch |
| **Pod creation** | Through a ReplicaSet, all at once, random names (`web-774ccbcbbc-854tp`) | One pod per matching node, created when a node joins, random suffix (`node-agent-2vpkb`) | Directly by the StatefulSet, **in order** 0,1,2 (`OrderedReady`), sticky names (`db-0`, `db-1`) |
| **Scaling** | `replicas: N`, any order | No `replicas` field. Follows the node count (and nodeSelector / tolerations) | `replicas: N`. Scales up 0->N-1 and down N-1->0, one at a time |
| **Networking** | Pods are interchangeable behind a normal ClusterIP Service | Often `hostNetwork`/`hostPort`, or reached through the node | Needs a **headless Service** (`serviceName`), so each pod gets its own DNS name `db-0.db.s11.svc.cluster.local` |
| **Storage** | All replicas share the same volume spec (usually none, or a shared RWX volume) | Usually `hostPath` to read node data (`/var/log`) | `volumeClaimTemplates` -> **one PVC per pod** (`data-db-0`), re-attached to the same pod after rescheduling |
| **Updates** | RollingUpdate (`maxSurge/maxUnavailable`) or Recreate | RollingUpdate (node by node) or OnDelete | RollingUpdate in reverse ordinal order (with `partition`) or OnDelete |
| **Examples in this cluster** | `coredns`, `ingress-nginx-controller`, `web` | `kube-proxy`, `kindnet`, my `node-agent` | my `db` and `web-sts` |

### DaemonSet: one pod per schedulable node

```
$ kubectl apply -f daemonset.yaml -f statefulset-with-storage.yaml
daemonset.apps/node-agent created
service/db created
statefulset.apps/db created

$ kubectl -n s11 get ds node-agent
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-agent   2         2         2       2            2           <none>          10s

$ kubectl -n s11 get pods -l app=node-agent -o wide
NAME               READY   STATUS    RESTARTS   AGE   IP             NODE                   NOMINATED NODE   READINESS GATES
node-agent-2vpkb   1/1     Running   0          10s   10.244.1.151   devops-heros-worker2   <none>           <none>
node-agent-wjf6q   1/1     Running   0          10s   10.244.2.115   devops-heros-worker    <none>           <none>

$ kubectl describe node devops-heros-control-plane | grep -A1 Taints
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
Unschedulable:      false

$ kubectl -n s11 logs -l app=node-agent --prefix
[pod/node-agent-2vpkb/agent] agent on node devops-heros-worker2
[pod/node-agent-wjf6q/agent] agent on node devops-heros-worker
```

The DaemonSet wants **2**, not 3, pods. The control-plane has a `NoSchedule` taint, and my DaemonSet has no matching toleration.
System DaemonSets like `kube-proxy` include that toleration and run on all 3 nodes (`3/3`, see session 9).

### StatefulSet: ordered, stable names, per-pod storage

```
$ kubectl -n s11 get sts db web-sts
NAME      READY   AGE
db        2/2     10s
web-sts   3/3     2m23s

$ kubectl -n s11 get pods -l 'app in (db,web-sts)' -o wide
NAME        READY   STATUS    RESTARTS   AGE     IP             NODE                   NOMINATED NODE   READINESS GATES
db-0        1/1     Running   0          10s     10.244.1.153   devops-heros-worker2   <none>           <none>
db-1        1/1     Running   0          7s      10.244.2.117   devops-heros-worker    <none>           <none>
web-sts-0   1/1     Running   0          2m18s   10.244.1.146   devops-heros-worker2   <none>           <none>
web-sts-1   1/1     Running   0          2m23s   10.244.2.111   devops-heros-worker    <none>           <none>
web-sts-2   1/1     Running   0          2m22s   10.244.1.145   devops-heros-worker2   <none>           <none>

$ kubectl -n s11 get pvc
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
data-db-0   Bound    pvc-4e955029-cd29-4697-8fd8-2714e41ac59b   64Mi       RWO            standard       <unset>                 10s
data-db-1   Bound    pvc-241dcb39-aa5f-4b07-863d-fbd635f2db8e   64Mi       RWO            standard       <unset>                 7s

$ kubectl -n s11 exec db-0 -- cat /data/id
created by db-0 at 11:49:39

$ kubectl -n s11 exec db-1 -- cat /data/id
created by db-1 at 11:49:44

$ kubectl -n s11 delete pod db-0
pod "db-0" deleted from s11 namespace

$ kubectl -n s11 get pod db-0 -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP             NODE                   NOMINATED NODE   READINESS GATES
db-0   1/1     Running   0          0s    10.244.1.155   devops-heros-worker2   <none>           <none>

$ kubectl -n s11 exec db-0 -- cat /data/id
created by db-0 at 11:49:39
```

Before the delete, `db-0` had written `created by db-0 at 11:49:39` to its own PVC. After I deleted the pod it was recreated with the **same name**
and **re-attached to the same PVC `data-db-0`**, so the file still says `11:49:39`. A Deployment pod would get a new name
and, without a PVC, an empty disk.

### Who owns the pods, and how each one updates

```
$ kubectl -n s11 get pods -l app=node-agent -o custom-columns=POD:.metadata.name,OWNER-KIND:.metadata.ownerReferences[0].kind,OWNER:.metadata.ownerReferences[0].name
POD                OWNER-KIND   OWNER
node-agent-2vpkb   DaemonSet    node-agent
node-agent-wjf6q   DaemonSet    node-agent

$ kubectl -n s11 get pods -l app=db -o custom-columns=POD:.metadata.name,OWNER-KIND:.metadata.ownerReferences[0].kind,OWNER:.metadata.ownerReferences[0].name
POD    OWNER-KIND    OWNER
db-0   StatefulSet   db
db-1   StatefulSet   db

$ kubectl -n s11 get deploy web -o jsonpath='{.spec.strategy}{"\n"}'
{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"}

$ kubectl -n s11 get sts db -o jsonpath='{.spec.updateStrategy} podManagementPolicy={.spec.podManagementPolicy}{"\n"}'
{"rollingUpdate":{"maxUnavailable":1,"partition":0},"type":"RollingUpdate"} podManagementPolicy=OrderedReady

$ kubectl -n s11 get ds node-agent -o jsonpath='{.spec.updateStrategy}{"\n"}'
{"rollingUpdate":{"maxSurge":0,"maxUnavailable":1},"type":"RollingUpdate"}
```

Deployment pods are owned by a **ReplicaSet**. DaemonSet and StatefulSet pods are owned **directly** by their controller.

---

## C. ReplicaSet vs Service

They are often confused because **both use label selectors**, but they do different jobs:

| | ReplicaSet | Service |
|---|---|---|
| **Job** | *Keeps pods running* (controller, desired count) | *Routes traffic to pods* (stable virtual IP + DNS name) |
| **Creates pods?** | Yes | Never |
| **Selector used for** | Counting and owning pods (adds `ownerReferences`) | Building the EndpointSlice list of ready pod IPs |
| **Selector scope** | Includes `pod-template-hash`, so one revision only | Usually only `app=...`, so it spans revisions during a rolling update |
| **Stable identity** | No IP / DNS | ClusterIP + `svc.cluster.local` DNS name |
| **Without the other** | Pods run but have no stable address | Service exists but has **no endpoints** (as in the course's `troubleshooting/empty-endpoints.yaml`) |

```
$ kubectl -n s11 get rs -l app=web -o custom-columns=NAME:.metadata.name,SELECTOR:.spec.selector.matchLabels,DESIRED:.spec.replicas
NAME             SELECTOR                                    DESIRED
web-774ccbcbbc   map[app:web pod-template-hash:774ccbcbbc]   3
web-7bdcf85c86   map[app:web pod-template-hash:7bdcf85c86]   0

$ kubectl -n s11 get svc web-clusterip -o custom-columns=NAME:.metadata.name,SELECTOR:.spec.selector,CLUSTER-IP:.spec.clusterIP
NAME            SELECTOR       CLUSTER-IP
web-clusterip   map[app:web]   10.96.213.135

$ kubectl -n s11 get endpointslices -l kubernetes.io/service-name=web-clusterip -o jsonpath='{range .items[0].endpoints[*]}{.addresses[0]}  {.targetRef.name}  ready={.conditions.ready}{"\n"}{end}'
10.244.1.149  web-774ccbcbbc-854tp  ready=true
10.244.1.150  web-774ccbcbbc-l7b6l  ready=true
10.244.2.113  web-774ccbcbbc-s4trk  ready=true
```

**Experiment - a pod nobody owns:** I started a stray pod with label `app=web`. The ReplicaSet ignores it, because its selector also requires
`pod-template-hash` (it stays `DESIRED 3 / CURRENT 3`). The Service selects only `app=web`, so it **adds the pod to its endpoints**
and would send it real traffic:

```
$ kubectl -n s11 run stray --image=traefik/whoami:v1.10 --labels=app=web,stray=true
pod/stray created

$ kubectl -n s11 get pods -l app=web
NAME                   READY   STATUS    RESTARTS   AGE
stray                  1/1     Running   0          3s
web-774ccbcbbc-854tp   1/1     Running   0          76s
web-774ccbcbbc-l7b6l   1/1     Running   0          70s
web-774ccbcbbc-s4trk   1/1     Running   0          76s

$ kubectl -n s11 get rs -l app=web
NAME             DESIRED   CURRENT   READY   AGE
web-774ccbcbbc   3         3         3       76s
web-7bdcf85c86   0         0         0       4m44s

$ kubectl -n s11 get endpointslices -l kubernetes.io/service-name=web-clusterip -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}  {.targetRef.name}{"\n"}{end}'
10.244.2.119  stray
10.244.1.149  web-774ccbcbbc-854tp
10.244.1.150  web-774ccbcbbc-l7b6l
10.244.2.113  web-774ccbcbbc-s4trk

$ kubectl -n s11 exec curl -- sh -c 'for i in $(seq 1 12); do curl -s web-clusterip:8080 | grep Hostname; done | sort | uniq -c'
      1 Hostname: web-774ccbcbbc-854tp
      6 Hostname: web-774ccbcbbc-l7b6l
      5 Hostname: web-774ccbcbbc-s4trk

$ kubectl -n s11 delete pod stray
pod "stray" deleted from s11 namespace
```

The EndpointSlice now has 4 addresses, including `stray`. In this 12-request sample the random choice happened to skip it, but it is a
valid backend. This is why Service selectors must be specific: any pod with matching labels gets traffic, whoever created it.
