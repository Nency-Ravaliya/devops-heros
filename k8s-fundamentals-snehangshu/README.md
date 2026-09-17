# Session 9 — Kubernetes Fundamentals

**Name:** Snehangshu Roy
**Enrollment No:** 24BCS10155
**Topic:** Kubernetes architecture, cluster setup, pods and `kubectl` basics

A real 3-node Kubernetes cluster (1 control plane + 2 workers) was created locally and all
commands below were run against it. Every output block is actual terminal output.

---

## 1. Cluster setup

I used **kind** (Kubernetes IN Docker), which runs each Kubernetes node as a Docker
container — a genuine multi-node cluster rather than the single node `minikube` gives by
default, so pod scheduling across nodes is actually observable.

`kind-config.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 8090
        protocol: TCP
      - containerPort: 443
        hostPort: 8443
        protocol: TCP
  - role: worker
  - role: worker
```

```bash
kind create cluster --name devops-hw --config kind-config.yaml
```

```bash
kubectl version
```

```
Client Version: v1.34.1
Kustomize Version: v5.7.1
Server Version: v1.32.2
```

---

## 2. Kubernetes architecture

### 2.1 The control plane and the nodes

```bash
kubectl cluster-info
```

```
Kubernetes control plane is running at https://127.0.0.1:55301
CoreDNS is running at https://127.0.0.1:55301/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

```bash
kubectl get nodes -o wide
```

```
NAME                      STATUS   ROLES           AGE     VERSION   INTERNAL-IP   OS-IMAGE                         CONTAINER-RUNTIME
devops-hw-control-plane   Ready    control-plane   6m12s   v1.32.2   172.22.0.4    Debian GNU/Linux 12 (bookworm)   containerd://2.0.2
devops-hw-worker          Ready    <none>          6m      v1.32.2   172.22.0.2    Debian GNU/Linux 12 (bookworm)   containerd://2.0.2
devops-hw-worker2         Ready    <none>          6m      v1.32.2   172.22.0.3    Debian GNU/Linux 12 (bookworm)   containerd://2.0.2
```

Three nodes, all `Ready`. The `ROLES` column marks one as `control-plane`; the workers show
`<none>`, which just means they carry no special role label. Note the container runtime is
**containerd**, not Docker — Kubernetes removed the Docker shim in 1.24, and containerd is
what actually runs the containers now.

### 2.2 Seeing the control plane components as real pods

```bash
kubectl get pods -n kube-system -o wide
```

```
NAME                                              READY   STATUS    RESTARTS   AGE     IP           NODE
coredns-668d6bf9bc-cvrwm                          1/1     Running   0          6m5s    10.244.0.2   devops-hw-control-plane
coredns-668d6bf9bc-tvjk6                          1/1     Running   0          6m5s    10.244.0.4   devops-hw-control-plane
etcd-devops-hw-control-plane                      1/1     Running   0          6m11s   172.22.0.4   devops-hw-control-plane
kindnet-jfwmg                                     1/1     Running   0          6m1s    172.22.0.3   devops-hw-worker2
kindnet-r4ngw                                     1/1     Running   0          6m6s    172.22.0.4   devops-hw-control-plane
kindnet-rm8cz                                     1/1     Running   0          6m1s    172.22.0.2   devops-hw-worker
kube-apiserver-devops-hw-control-plane            1/1     Running   0          6m10s   172.22.0.4   devops-hw-control-plane
kube-controller-manager-devops-hw-control-plane   1/1     Running   0          6m11s   172.22.0.4   devops-hw-control-plane
kube-proxy-b9xjz                                  1/1     Running   0          6m1s    172.22.0.2   devops-hw-worker
kube-proxy-dt8dz                                  1/1     Running   0          6m6s    172.22.0.4   devops-hw-control-plane
kube-proxy-mhs7c                                  1/1     Running   0          6m1s    172.22.0.3   devops-hw-worker2
kube-scheduler-devops-hw-control-plane            1/1     Running   0          6m10s   172.22.0.4   devops-hw-control-plane
```

This single output is the architecture diagram made concrete. Reading it:

**Control plane components — all on `devops-hw-control-plane`:**

| Component | Role |
|---|---|
| `kube-apiserver` | The **front door**. Every `kubectl` command, every controller and every kubelet talks only to the API server. It authenticates, validates and persists. |
| `etcd` | The **only** stateful component — a distributed key-value store holding the entire cluster state. Lose etcd and you lose the cluster; this is what you back up. |
| `kube-scheduler` | Watches for pods with no node assigned and picks a node based on resource requests, affinity rules, taints and tolerations. It only *decides* — it does not start anything. |
| `kube-controller-manager` | Runs the reconciliation loops (Deployment, ReplicaSet, Node, Job controllers…). Each loop compares **desired state** to **actual state** and acts to close the gap. |
| `coredns` | Cluster DNS — resolves Service names to ClusterIPs. Two replicas for availability. |

**Node components — one copy on every node** (notice `kube-proxy` and `kindnet` appear
three times each, once per node, because they are DaemonSets):

| Component | Role |
|---|---|
| `kubelet` | The agent on each node. Takes pod specs from the API server and tells the container runtime to make them real. *(Runs as a host process, not a pod, which is why it does not appear in this list.)* |
| `kube-proxy` | Programs iptables/IPVS rules so Service ClusterIPs actually load-balance to pod IPs. |
| `kindnet` | The CNI network plugin — gives every pod a routable IP. (In a cloud cluster this would be Calico, Cilium, etc.) |

### 2.3 The key idea — declarative reconciliation

Every write goes through the API server into etcd, and controllers watch for changes and
continuously drive actual state toward desired state. That is why `kubectl apply` describes
*what you want* rather than *what to do*, and why a deleted pod belonging to a Deployment
comes straight back — the controller notices the gap and closes it.

### 2.4 Node labels and roles

```bash
kubectl get nodes --show-labels
```

```
node-role.kubernetes.io/control-plane=
ingress-ready=true
```

The control-plane role is just a **label**, and `ingress-ready=true` is the custom label
from my kind config that the ingress controller uses for node selection. Labels are how
Kubernetes targets things — for pods, nodes and services alike.

---

## 3. Namespaces

```bash
kubectl get namespaces
```

```
NAME                 STATUS   AGE
default              Active   6m13s
ingress-nginx        Active   5m29s
kube-node-lease      Active   6m13s
kube-public          Active   6m13s
kube-system          Active   6m13s
local-path-storage   Active   6m8s
```

| Namespace | Purpose |
|---|---|
| `default` | Where your objects land if you do not specify one |
| `kube-system` | Kubernetes' own components |
| `kube-public` | World-readable cluster info |
| `kube-node-lease` | Node heartbeat leases used for failure detection |
| `ingress-nginx` | The ingress controller I installed |
| `local-path-storage` | kind's default storage provisioner |

Namespaces are **logical partitions** for names, RBAC and resource quotas — not a security
boundary at the network level (that needs NetworkPolicies).

```yaml
# 03-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: devops-hw
```

```bash
kubectl apply -f 03-namespace.yaml
```

---

## 4. Namespaced API resources

```bash
kubectl api-resources --namespaced=true -o name
```

```
bindings
configmaps
endpoints
events
limitranges
persistentvolumeclaims
pods
podtemplates
replicationcontrollers
resourcequotas
secrets
serviceaccounts
services
controllerrevisions.apps
daemonsets.apps
deployments.apps
replicasets.apps
statefulsets.apps
```

Everything in Kubernetes is an **API object**. `kubectl api-resources` is genuinely useful —
it is how you find the right `kind`, its short name and its API group without guessing.

---

## 5. Creating the first pod

```yaml
# 01-first-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello-pod
  labels:
    app: hello
    session: "9"
spec:
  containers:
    - name: nginx
      image: nginx:1.27-alpine
      ports:
        - containerPort: 80
      resources:
        requests:
          cpu: 10m
          memory: 16Mi
        limits:
          cpu: 200m
          memory: 64Mi
```

```bash
kubectl apply -f 01-first-pod.yaml
kubectl wait --for=condition=Ready pod/hello-pod --timeout=90s
kubectl get pods -o wide
```

```
pod/hello-pod condition met
NAME        READY   STATUS    RESTARTS   AGE   IP           NODE
hello-pod   1/1     Running   0          19s   10.244.1.3   devops-hw-worker2
```

The scheduler placed the pod on **`devops-hw-worker2`** — I never said which node, which is
exactly the point. The pod got IP `10.244.1.3` from the cluster pod network (`10.244.0.0/16`),
separate from the node network (`172.22.0.0/16`).

### 5.1 `kubectl describe` — the first debugging command

```bash
kubectl describe pod hello-pod
```

```
Name:             hello-pod
Namespace:        default
Priority:         0
Service Account:  default
Node:             devops-hw-worker2/172.22.0.3
Start Time:       Fri, 18 Sep 2026 02:14:18 +0530
Labels:           app=hello
                  session=9
Status:           Running
IP:               10.244.1.3
Containers:
  nginx:
    Container ID:   containerd://60c89cc9f961f235c52f32648a44f71c1a6e8f73bd17a66ddd7a5e93f0052b2c
    Image:          nginx:1.27-alpine
    Image ID:       docker.io/library/nginx@sha256:65645c7bb6a0661892a8b03b89d0743208a18dd2f3f17a54ef4b76fb8e2f2a10
    Port:           80/TCP
    State:          Running
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     200m
      memory:  64Mi
    Requests:
      cpu:        10m
      memory:     16Mi
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-pf542 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
```

Two details worth noticing:

- The **image ID is a sha256 digest**, not just the tag — that is the immutable identity of
  what is really running, regardless of what `:1.27-alpine` points to today.
- A ServiceAccount token was auto-mounted at
  `/var/run/secrets/kubernetes.io/serviceaccount` — this is how a pod authenticates to the
  API server, and why RBAC on service accounts matters.

### 5.2 Events — the pod lifecycle, step by step

```bash
kubectl describe pod hello-pod   # Events section
```

```
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  20s   default-scheduler  Successfully assigned default/hello-pod to devops-hw-worker2
  Normal  Pulling    19s   kubelet            Pulling image "nginx:1.27-alpine"
  Normal  Pulled     1s    kubelet            Successfully pulled image "nginx:1.27-alpine" in 18.108s. Image size: 20984244 bytes.
  Normal  Created    1s    kubelet            Created container: nginx
  Normal  Started    1s    kubelet            Started container nginx
```

This is the architecture in motion, and you can see the handoff between components:
**`default-scheduler`** assigned the pod to a node, then **`kubelet`** on that node pulled
the image, created the container and started it. Two different components, two different
`From` values.

Events are where the real answer lives when a pod is stuck — `ImagePullBackOff`,
`FailedScheduling` (insufficient resources), `CrashLoopBackOff` all show up here with a
reason.

### 5.3 Logs

```bash
kubectl logs hello-pod
```

```
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
```

### 5.4 Exec into the pod

```bash
kubectl exec hello-pod -- sh -c 'hostname; nginx -v; ls /usr/share/nginx/html'
```

```
hello-pod
nginx version: nginx/1.27.5
50x.html
index.html
```

The container's hostname is the **pod name** — Kubernetes sets it, which is what makes
StatefulSet pods individually addressable.

```bash
kubectl exec hello-pod -- wget -qO- http://localhost:80
```

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

The app serves correctly from inside the pod.

---

## 6. Multi-container pod (the sidecar pattern)

```yaml
# 02-multi-container-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-pod
spec:
  volumes:
    - name: shared-data
      emptyDir: {}
  containers:
    - name: writer
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args: ["while true; do date >> /data/log.txt; sleep 5; done"]
      volumeMounts:
        - name: shared-data
          mountPath: /data
    - name: reader
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args: ['while true; do echo "reader sees $(wc -l < /data/log.txt) lines"; sleep 10; done']
      volumeMounts:
        - name: shared-data
          mountPath: /data
```

```bash
kubectl apply -f 02-multi-container-pod.yaml
kubectl get pod sidecar-pod
```

```
NAME          READY   STATUS    RESTARTS   AGE
sidecar-pod   2/2     Running   0          10s
```

**`2/2`** — two containers in one pod.

### Proof 1 — they share a volume

```bash
kubectl logs sidecar-pod -c reader
kubectl exec sidecar-pod -c reader -- tail -3 /data/log.txt
```

```
reader sees 1 lines
reader sees 3 lines

Thu Sep 17 20:45:18 UTC 2026
Thu Sep 17 20:45:23 UTC 2026
Thu Sep 17 20:45:28 UTC 2026
```

```bash
kubectl exec sidecar-pod -c writer -- wc -l /data/log.txt
kubectl exec sidecar-pod -c reader -- wc -l /data/log.txt
```

```
9 /data/log.txt
9 /data/log.txt
```

The `writer` container appends timestamps; the `reader` container sees the identical file.
Same line count from both — one `emptyDir` volume, two containers.

### Proof 2 — they share a network namespace

```bash
kubectl exec sidecar-pod -c writer -- ip -4 addr show eth0
kubectl exec sidecar-pod -c reader -- ip -4 addr show eth0
```

```
    inet 10.244.1.4/24 brd 10.244.1.255 scope global eth0
    inet 10.244.1.4/24 brd 10.244.1.255 scope global eth0
```

**The same IP address from both containers.** This is the defining property of a pod: the
containers inside it share one network namespace, so they reach each other over
`localhost` and cannot both bind the same port.

### Why this matters

A pod — not a container — is the smallest deployable unit in Kubernetes precisely because
of this shared namespace. It is what makes sidecars work: log shippers, metrics exporters,
service-mesh proxies (Istio's Envoy) and config reloaders all run beside the app container
in the same pod.

---

## 7. Imperative vs declarative

```bash
kubectl run imperative-pod --image=nginx:alpine --restart=Never
kubectl get pod imperative-pod
kubectl delete pod imperative-pod
```

```
pod/imperative-pod created
NAME             READY   STATUS              RESTARTS   AGE
imperative-pod   0/1     ContainerCreating   0          0s
pod "imperative-pod" deleted from default namespace
```

`kubectl run` is fine for a quick throwaway test, but **declarative YAML + `kubectl apply`**
is the real workflow: the YAML is reviewable, version-controlled and reproducible. A useful
middle ground is to generate the YAML and then edit it:

```bash
kubectl run mypod --image=nginx --dry-run=client -o yaml > pod.yaml
```

---

## 8. Cluster state overview

```bash
kubectl get all
```

```
NAME              READY   STATUS    RESTARTS   AGE
pod/hello-pod     1/1     Running   0          45s
pod/sidecar-pod   2/2     Running   0          24s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   6m56s
```

The `kubernetes` Service is created automatically — it is the in-cluster endpoint pods use
to reach the API server.

```bash
kubectl top nodes
```

```
error: Metrics API not available
```

Recorded as-is: `kubectl top` needs the **metrics-server** add-on, which a kind cluster does
not ship by default. The error is the expected behaviour without it, not a cluster fault.

---

## `kubectl` command reference

| Command | Purpose |
|---|---|
| `kubectl cluster-info` | Control plane endpoints |
| `kubectl get nodes -o wide` | Nodes, versions, IPs, runtime |
| `kubectl get pods -A` | Pods in every namespace |
| `kubectl get all` | Common resources in the current namespace |
| `kubectl apply -f <file>` | Create/update declaratively |
| `kubectl delete -f <file>` | Delete what the file defines |
| `kubectl describe <kind>/<name>` | Full detail **plus events** — first stop when debugging |
| `kubectl logs <pod> [-c <container>]` | Container logs (`-f` to follow, `--previous` for a crashed one) |
| `kubectl exec -it <pod> -- sh` | Shell inside a container |
| `kubectl get <kind> <name> -o yaml` | The live object as stored in etcd |
| `kubectl api-resources` | Every resource type and its short name |
| `kubectl explain pod.spec` | Built-in schema documentation |
| `kubectl run <name> --image=<img> --dry-run=client -o yaml` | Generate a manifest to edit |

## Debugging order that works

1. `kubectl get pods` — what is the STATUS and how many RESTARTS?
2. `kubectl describe pod <name>` — read the **Events** at the bottom first.
3. `kubectl logs <name>` (add `--previous` if it already crashed).
4. `kubectl exec -it <name> -- sh` — look from inside.
5. `kubectl get events --sort-by=.lastTimestamp` — cluster-wide picture.

---

## Files in this folder

| File | Purpose |
|---|---|
| `kind-config.yaml` | 3-node cluster definition |
| `01-first-pod.yaml` | Single-container nginx pod |
| `02-multi-container-pod.yaml` | Sidecar pod sharing a volume and a network namespace |
| `03-namespace.yaml` | Custom namespace |
| `kubernetes-fundamentals-transcript.txt` | Full terminal transcript |

## Summary

| Item | Status |
|---|---|
| Real multi-node cluster created (1 control plane + 2 workers, all Ready) | Done |
| Architecture studied on the live cluster — apiserver, etcd, scheduler, controller-manager, coredns, kube-proxy, CNI | Done |
| Namespaces and API resources explored | Done |
| First pod created, described, logged into and exec'd | Done |
| Pod lifecycle traced through real scheduler and kubelet events | Done |
| Multi-container pod — shared volume and shared network namespace both proven | Done |
| Imperative vs declarative compared | Done |
