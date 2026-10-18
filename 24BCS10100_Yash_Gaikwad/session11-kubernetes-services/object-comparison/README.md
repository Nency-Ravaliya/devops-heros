# Kubernetes Object Comparison

Author: Yash Gaikwad (24BCS10100) | Session 11 - Kubernetes Services

When I started with Kubernetes the workload objects looked very similar: they all have a `selector`, a Pod `template` and they all end up creating Pods. These notes are my attempt to pin down what each object is actually responsible for, and where the boundaries between them are.

Contents:

1. [Deployment vs ReplicaSet](#1-deployment-vs-replicaset)
2. [Deployment vs DaemonSet vs StatefulSet](#2-deployment-vs-daemonset-vs-statefulset)
3. [ReplicaSet vs Service](#3-replicaset-vs-service)

---

## 1. Deployment vs ReplicaSet

### Purpose

- **ReplicaSet** has one job: keep the number of running Pods that match its label selector equal to `spec.replicas`. If a Pod dies it creates another one, if there are too many it deletes some.
- **Deployment** is a higher level object that manages ReplicaSets on my behalf. It adds the *lifecycle* features: rolling updates, rollback, pause/resume and revision history.

### Comparison

| Aspect | ReplicaSet | Deployment |
|---|---|---|
| Main purpose | Maintain N identical Pods | Declarative updates for Pods through ReplicaSets |
| Pod management | Creates/deletes Pods directly | Creates and scales ReplicaSets, which create the Pods |
| Scaling | `kubectl scale rs <name> --replicas=N` | `kubectl scale deploy <name> --replicas=N` (Deployment pushes the number into the active ReplicaSet) |
| Rolling update | Not supported. Changing the Pod template does not touch Pods that already exist | Supported (`strategy.type: RollingUpdate`, controlled by `maxSurge` and `maxUnavailable`) |
| Rollback | No history | `kubectl rollout undo` using stored revisions |
| Typical usage | Almost never created by hand | The normal way to run stateless apps |
| API version | `apps/v1` | `apps/v1` |

An important detail: if I edit the Pod template of a bare ReplicaSet, the old Pods keep running with the old spec. Only Pods created afterwards (after a delete or a crash) get the new template. That is exactly the gap a Deployment fills.

### Relationship between them

A Deployment **owns** its ReplicaSets, and each ReplicaSet owns its Pods. The chain is recorded in `metadata.ownerReferences`, so deleting the Deployment garbage-collects the ReplicaSets and Pods below it.

```
Deployment  web
 |-- ReplicaSet  web-6d4cf56db6   (revision 2, current, replicas: 3)
 |     |-- Pod web-6d4cf56db6-abcde
 |     |-- Pod web-6d4cf56db6-fghij
 |     `-- Pod web-6d4cf56db6-klmno
 `-- ReplicaSet  web-7c9b8d5f4    (revision 1, old, replicas: 0)
```

Key points I want to remember:

- **One ReplicaSet per revision.** Whenever `spec.template` changes (new image, new env var, ...) the Deployment creates a new ReplicaSet. A change to only `replicas` does *not* create a new revision.
- **`pod-template-hash`.** The Deployment controller hashes the Pod template and adds the label `pod-template-hash=<hash>` to the ReplicaSet and to the Pods it creates. The ReplicaSet name is `<deployment-name>-<hash>`. The hash is added to the ReplicaSet selector as well, which is why two ReplicaSets of the same Deployment never fight over each other's Pods.
- **`revisionHistoryLimit`.** Old ReplicaSets are kept (scaled to 0) so I can roll back. The default is 10; setting it to 0 means no rollback is possible.
- **Rolling update.** The Deployment scales the new ReplicaSet up and the old one down in small steps, staying inside the limits `maxSurge` (extra Pods allowed above the desired count) and `maxUnavailable` (Pods allowed to be missing). Both default to 25%.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        ports:
        - containerPort: 80
```

Commands to watch the relationship:

```bash
kubectl apply -f web-deployment.yaml
kubectl get deploy,rs,pods -l app=web --show-labels
kubectl set image deployment/web nginx=nginx:1.27-alpine
kubectl rollout status deployment/web
kubectl get rs -l app=web                  # old RS stays with 0 replicas
kubectl rollout history deployment/web
kubectl rollout undo deployment/web
kubectl get rs web-<hash> -o jsonpath='{.metadata.ownerReferences[0].kind}'
```

If I manually run `kubectl scale rs <name>` on a ReplicaSet that belongs to a Deployment, the Deployment controller notices the drift and puts the number back. The Deployment is the source of truth, so scaling should always be done on the Deployment.

---

## 2. Deployment vs DaemonSet vs StatefulSet

All three create Pods from a template, but they answer different questions:

- Deployment: "run N interchangeable copies somewhere in the cluster".
- DaemonSet: "run one copy on every node (or every matching node)".
- StatefulSet: "run N copies that each have their own identity and their own disk".

### Comparison table

| Aspect | Deployment | DaemonSet | StatefulSet |
|---|---|---|---|
| Use case | Stateless apps: web servers, REST APIs, workers | Node-level agents: log shippers, monitoring exporters, CNI/storage plugins | Stateful apps: databases, message brokers, anything that needs stable identity |
| Pod creation | Via a ReplicaSet; all Pods created in parallel, any node the scheduler picks | One Pod per eligible node, created automatically when a node joins and removed when it leaves | Created one at a time in order `0, 1, 2, ...` (default `OrderedReady`; `Parallel` is optional) and each waits for the previous to be Ready |
| Pod names | Random suffix (`web-6d4cf56db6-abcde`) | Random suffix (`fluent-bit-x7k2p`) | Stable ordinal (`mysql-0`, `mysql-1`, ...) |
| Replica count | `spec.replicas` | No `replicas` field. Count equals number of matching nodes (control it with `nodeSelector`, affinity, tolerations) | `spec.replicas` |
| Scaling | Up or down freely, any Pod can be removed | Scales automatically with the node count | Scale up in ascending order, scale down in descending order (highest ordinal removed first) |
| Updates | RollingUpdate or Recreate | RollingUpdate (default) or OnDelete | RollingUpdate (reverse ordinal order, supports `partition`) or OnDelete |
| Networking | Normal ClusterIP Service load-balances over Pods; Pod IP and name change on replacement | Often uses `hostNetwork`/`hostPort` or is only scraped; usually no load-balanced Service | Needs a **headless Service** (`clusterIP: None`, named in `spec.serviceName`) which gives each Pod a stable DNS name: `<pod>.<svc>.<ns>.svc.cluster.local` |
| Storage | Shared PVC or ephemeral volumes; Pods are interchangeable | Typically `hostPath` to read node files (`/var/log`, `/proc`) | `volumeClaimTemplates` create one PVC per Pod (`data-mysql-0`, `data-mysql-1`); the same PVC is re-attached when the Pod is rescheduled |
| Identity after restart | New Pod, new name, new IP | New Pod on the same node | Same name, same DNS name, same PVC (IP may still change) |
| Example | Nginx / Node.js web app, 3 replicas | `fluent-bit`, `node-exporter` | MySQL, PostgreSQL, Kafka, Cassandra, ZooKeeper |

### Small examples

**DaemonSet** running a log collector on every node (the toleration lets it also run on tainted control-plane nodes):

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
spec:
  selector:
    matchLabels:
      app: fluent-bit
  template:
    metadata:
      labels:
        app: fluent-bit
    spec:
      tolerations:
      - operator: Exists
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:3.1
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
```

**StatefulSet** with a headless Service and a PVC per Pod. This is only the Kubernetes side: the StatefulSet gives identity and storage, but it does not configure MySQL replication between the Pods. That part is the application's (or an operator's) job.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  clusterIP: None          # headless
  selector:
    app: mysql
  ports:
  - name: mysql
    port: 3306
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql       # must match the headless Service
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.4
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```

Things to remember about this StatefulSet:

- Pods are named `mysql-0`, `mysql-1`, `mysql-2` and are reachable at `mysql-0.mysql.<namespace>.svc.cluster.local` and so on.
- PVCs are named `data-mysql-0`, `data-mysql-1`, `data-mysql-2`.
- Scaling down or deleting the StatefulSet does **not** delete the PVCs by default (to protect data). Newer Kubernetes versions have `persistentVolumeClaimRetentionPolicy` to change this per StatefulSet.
- Deleting a StatefulSet does not guarantee an orderly shutdown of Pods; scale it to 0 first if order matters.

### When to choose which

If the app keeps no state that matters on local disk and any replica can serve any request, I use a **Deployment**; this covers most web and API workloads and it gives rolling updates and easy scaling. If the thing I am running is really *about the node* (collect that node's logs, export that node's metrics, set up that node's networking) I use a **DaemonSet**, because I want exactly one per node no matter how big the cluster is. If each replica must know who it is (database primary/replica, Kafka broker id, quorum member) or must get the same disk back after a restart, I use a **StatefulSet**, accepting slower ordered rollouts in exchange for stable names and storage.

---

## 3. ReplicaSet vs Service

These two are not alternatives. They solve different halves of the problem and are almost always used together.

### Responsibilities

| | ReplicaSet | Service |
|---|---|---|
| Question it answers | "Are enough Pods alive?" | "How do clients reach those Pods?" |
| What it manages | Pod lifecycle (create, delete, replace) | A stable virtual IP and DNS name plus load balancing |
| Selector use | Decides which Pods it **owns** and counts | Decides which Pods receive **traffic** |
| Lives on | Control plane (controller manager) | Control plane objects + data-plane rules written by kube-proxy on each node |
| Does it care about Pod health? | Counts Pods that exist/are available | Only Pods that are **Ready** receive traffic (readiness probe) |

### Why a Service is required

Pod IPs are ephemeral. Every time a Pod is replaced (crash, rolling update, node drain, scale event) the new Pod gets a different IP. The ReplicaSet happily keeps the *count* right, but a client that hard-coded the old IP is now talking to nothing. A Service gives clients one address that does not change for the life of the Service:

- a stable ClusterIP (a virtual IP, no network interface actually owns it),
- a stable DNS name such as `web-svc.default.svc.cluster.local`,
- load balancing over whichever Pods currently match.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  type: ClusterIP
  selector:
    app: web          # same label the Deployment/ReplicaSet Pods carry
  ports:
  - port: 80          # port of the Service
    targetPort: 80    # port on the Pod
```

### How traffic reaches the Pods

```
client Pod
   |  curl http://web-svc          (DNS -> ClusterIP, e.g. 10.96.45.12)
   v
Service ClusterIP 10.96.45.12:80   (virtual, exists only in rules)
   |  kube-proxy rules on the node where the client runs
   |  (iptables or IPVS: DNAT the ClusterIP to one endpoint)
   v
Pod IP 10.244.1.7:80   or   10.244.2.4:80   or   10.244.1.9:80
```

Step by step:

1. The Service has a **label selector** (`app: web`).
2. The EndpointSlice controller (part of kube-controller-manager) watches Pods matching that selector and writes their IPs and ports into **EndpointSlice** objects. Only Pods that are Ready are listed as ready endpoints. The older `Endpoints` object still works for reading but the Endpoints API is deprecated in recent versions in favour of EndpointSlice.
3. **kube-proxy** runs on every node, watches Services and EndpointSlices, and programs the node's packet rules: **iptables** (default on most clusters), **IPVS**, or nftables on newer versions.
4. When a Pod sends a packet to the ClusterIP, the rules on that node rewrite (DNAT) the destination to one of the endpoint Pod IPs, chosen pseudo-randomly (iptables) or by the IPVS scheduler.
5. The packet is delivered to the Pod IP over the cluster network (CNI). Replies are translated back through connection tracking.

When the ReplicaSet replaces a Pod, nothing about the Service changes. The EndpointSlice is updated, kube-proxy refreshes its rules, and clients keep using the same name.

```bash
kubectl get pods -l app=web -o wide                          # Pod IPs
kubectl get svc web-svc                                      # ClusterIP
kubectl get endpointslices -l kubernetes.io/service-name=web-svc
kubectl get endpoints web-svc                                # legacy view, same IPs
kubectl delete pod <one-web-pod>                             # ReplicaSet creates a replacement
kubectl get endpointslices -l kubernetes.io/service-name=web-svc   # list updates, Service IP unchanged
```

### Summary of the three comparisons

- Deployment sits above ReplicaSet: ReplicaSet keeps the count, Deployment adds versioned rollouts.
- Deployment, DaemonSet and StatefulSet are three different Pod-management strategies: interchangeable replicas, one per node, and stable identity with storage.
- ReplicaSet (Pod count) and Service (stable access and load balancing) are complementary: a ReplicaSet without a Service has no stable address, and a Service without a controller has no one to replace dead Pods.
