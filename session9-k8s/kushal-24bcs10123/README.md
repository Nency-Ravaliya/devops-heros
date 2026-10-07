# Session 9 – Kubernetes Fundamentals

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123  
**Environment:** kind v0.33.0 (Kubernetes v1.37.0, 1 control-plane + 2 worker nodes) running on Docker Desktop 29.0.1, macOS / Apple Silicon (arm64). `kubectl` v1.34.1.

Every command in these notes was actually run against this cluster; the unedited terminal output is in [`logs/`](logs) and the exact commands are in [`scripts/`](scripts).

```text
kushal-24bcs10123/
├── README.md                     # this write-up
├── kind-cluster.yaml             # the cluster definition (3 nodes + port mappings used by sessions 10-12)
├── scripts/
│   ├── 01-create-cluster.sh      # install check + kind create cluster
│   ├── 02-architecture.sh        # look at every control-plane / node component on the live cluster
│   ├── 03-trace-kubectl-apply.sh # follow one `kubectl apply` through apiserver -> etcd -> scheduler -> kubelet
│   └── 04-kubectl-basics.sh      # kubernetes.io "Kubernetes Basics" tutorial modules 2-6 + namespaces
└── logs/                         # one .txt per script, raw output
```

## 1. Why kind and not minikube

The resources link to minikube. I already had Docker Desktop from sessions 6–8, and kind (Kubernetes IN Docker) runs every Kubernetes node as a Docker container, so I get a **multi-node** cluster (which matters for DaemonSets, scheduling and NodePort demos in the next sessions) without a second VM. The one thing minikube gives for free – `minikube ip:<nodePort>` – I replaced with `extraPortMappings` in [`kind-cluster.yaml`](kind-cluster.yaml), so `curl http://localhost:30010` from the Mac lands on the control-plane node's NodePort.

Log: [logs/01-create-cluster.txt](logs/01-create-cluster.txt)

```text
$ kind create cluster --config kind-cluster.yaml
Creating cluster "kushal-lab" ...
 ✓ Ensuring node image (kindest/node:v1.37.0)
 ✓ Preparing nodes 📦 📦 📦
 ✓ Writing configuration
 ✓ Starting control-plane
 ✓ Installing CNI
 ✓ Installing StorageClass
 ✓ Joining worker nodes
Set kubectl context to "kind-kushal-lab"

$ docker ps --filter label=io.x-k8s.kind.cluster=kushal-lab --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
NAMES                      IMAGE                  PORTS
kushal-lab-control-plane   kindest/node:v1.37.0   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:30010->30010/tcp, ... 127.0.0.1:50863->6443/tcp
kushal-lab-worker2         kindest/node:v1.37.0
kushal-lab-worker          kindest/node:v1.37.0
```

Each "node" is a container running systemd, kubelet and containerd; the API server is published on `127.0.0.1:50863`, which is what `kubectl` talks to.

## 2. Architecture, read off the running cluster

Log: [logs/02-architecture.txt](logs/02-architecture.txt)

```text
                         kubectl  ──HTTPS──▶  kube-apiserver :6443  ◀──▶  etcd :2379
                                                   ▲      ▲
                                 watches / writes  │      │  watches / writes
                                                   │      │
                              kube-scheduler ──────┘      └────── kube-controller-manager
                            (picks a node)                       (ReplicaSet, Deployment, Node ... controllers)

   ─────────────────────────────── every node ───────────────────────────────
   kubelet ──▶ containerd ──▶ containers        kube-proxy (iptables rules for Services)
   kindnet (CNI: pod network 10.244.x.x)        CoreDNS (only on control-plane here)
```

```text
$ kubectl get nodes -o wide
NAME                       STATUS   ROLES           VERSION   INTERNAL-IP   OS-IMAGE                       CONTAINER-RUNTIME
kushal-lab-control-plane   Ready    control-plane   v1.37.0   172.18.0.3    Debian GNU/Linux 13 (trixie)   containerd://2.3.4
kushal-lab-worker          Ready    <none>          v1.37.0   172.18.0.4    Debian GNU/Linux 13 (trixie)   containerd://2.3.4
kushal-lab-worker2         Ready    <none>          v1.37.0   172.18.0.2    Debian GNU/Linux 13 (trixie)   containerd://2.3.4

$ kubectl describe node kushal-lab-control-plane | grep -A1 '^Taints:'
Taints:             node-role.kubernetes.io/control-plane:NoSchedule      <- my workloads only land on the workers
```

### Control plane = four static pods on the control-plane node

```text
$ kubectl get pods -n kube-system -o wide
NAME                                               READY   STATUS    IP           NODE
coredns-559f6c778d-5gr9q                           1/1     Running   10.244.0.3   kushal-lab-control-plane
coredns-559f6c778d-rk8fg                           1/1     Running   10.244.0.4   kushal-lab-control-plane
etcd-kushal-lab-control-plane                      1/1     Running   172.18.0.3   kushal-lab-control-plane
kindnet-dvds7 / kindnet-ff7q6 / kindnet-ktxnx      1/1     Running   (one per node)
kube-apiserver-kushal-lab-control-plane            1/1     Running   172.18.0.3   kushal-lab-control-plane
kube-controller-manager-kushal-lab-control-plane   1/1     Running   172.18.0.3   kushal-lab-control-plane
kube-proxy-g6pcp / -jj27f / -nnnhg                 1/1     Running   (one per node)
kube-scheduler-kushal-lab-control-plane            1/1     Running   172.18.0.3   kushal-lab-control-plane

$ docker exec kushal-lab-control-plane ls /etc/kubernetes/manifests
etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml
```

The four control-plane components are **static pods**: the kubelet on that node starts them straight from `/etc/kubernetes/manifests`, before there is any API server to talk to. They share the node's network namespace (their IP is the node IP `172.18.0.3`, not a pod IP), unlike CoreDNS which is an ordinary Deployment on the pod network `10.244.0.x`.

### kube-apiserver – the only thing anybody talks to

```text
$ kubectl get --raw='/livez?verbose' | head -4
[+]ping ok
[+]log ok
[+]loopback-serving-certificate ok
[+]etcd ok

$ kubectl api-resources | wc -l
      72                                   <- 71 resource types on a fresh cluster (pods, deployments, ...)
```

### etcd – the cluster's only database

```text
$ $ETCD endpoint status -w table          # etcdctl inside the etcd pod, with the cluster's own certs
│ ENDPOINT               │ VERSION │ DB SIZE │ IS LEADER │ RAFT TERM │
│ https://127.0.0.1:2379 │   3.7.0 │  1.5 MB │      true │         2 │

$ $ETCD get /registry/namespaces --prefix --keys-only
/registry/namespaces/default
/registry/namespaces/kube-node-lease
/registry/namespaces/kube-public
/registry/namespaces/kube-system
/registry/namespaces/local-path-storage

$ $ETCD get /registry --prefix --keys-only | wc -l
     818                                   <- every object in the cluster is one key under /registry/<kind>/<ns>/<name>
```

### scheduler and controller-manager elect a leader through Lease objects

```text
$ kubectl -n kube-system get leases
NAME                      HOLDER
kube-controller-manager   kushal-lab-control-plane_e19e4ac1-...
kube-scheduler            kushal-lab-control-plane_f3d22c22-...
```

### Node components

```text
$ docker exec kushal-lab-worker systemctl is-active kubelet containerd
active
active

$ kubectl get daemonset -n kube-system
NAME         DESIRED   CURRENT   READY   NODE SELECTOR
kindnet      3         3         3       kubernetes.io/os=linux     <- CNI plugin, one per node
kube-proxy   3         3         3       kubernetes.io/os=linux     <- Service -> pod routing, one per node

$ kubectl -n kube-system get cm kube-proxy -o jsonpath='{.data.config\.conf}' | grep -E '^mode'
mode: iptables

$ kubectl -n kube-system get svc kube-dns
NAME       TYPE        CLUSTER-IP   PORT(S)
kube-dns   ClusterIP   10.96.0.10   53/UDP,53/TCP,9153/TCP   <- every pod's /etc/resolv.conf points here
```

## 3. Following one `kubectl apply` through the system

Log: [logs/03-trace-kubectl-apply.txt](logs/03-trace-kubectl-apply.txt)

```text
kubectl apply -f pod.yaml
   │ 1. GET  /api/v1/namespaces/default/pods/trace-me  -> 404 (does it exist?)
   │ 2. POST /api/v1/namespaces/default/pods           -> 201 Created
   ▼
kube-apiserver ── authn/authz/admission ──▶ etcd: /registry/pods/default/trace-me
   │
   ├─ kube-scheduler (watching pods with no nodeName) ──▶ picks kushal-lab-worker, writes the binding
   │
   └─ kubelet on kushal-lab-worker (watching pods bound to it) ──▶ containerd pulls nginx:1.25-alpine, starts container
```

```text
$ kubectl apply -f /tmp/s9-pod.yaml -v=6 2>&1 | grep -E 'GET|POST|Response Status'
"Response" verb="GET"  url="https://<apiserver>/api/v1/namespaces/default/pods/trace-me" status="404 Not Found"
"Response" verb="POST" url="https://<apiserver>/api/v1/namespaces/default/pods?fieldManager=kubectl-client-side-apply&fieldValidation=Strict" status="201 Created"

$ $ETCD get /registry/pods/default/trace-me --keys-only
/registry/pods/default/trace-me

$ kubectl get events --field-selector involvedObject.name=trace-me -o custom-columns='SOURCE:.source.component,REASON:.reason,MESSAGE:.message'
SOURCE              REASON      MESSAGE
default-scheduler   Scheduled   Successfully assigned default/trace-me to kushal-lab-worker
kubelet             Pulling     Pulling image "nginx:1.25-alpine"
kubelet             Pulled      Successfully pulled image "nginx:1.25-alpine" in 10.236s ...
kubelet             Created     Container created
kubelet             Started     Container started

$ docker exec kushal-lab-worker crictl ps --name web
CONTAINER       IMAGE           STATE     NAME   POD        NAMESPACE
1c1c194f3f7e3   9d6767b714bf1   Running   web    trace-me   default
```

`kubectl` never talks to a node. It only does REST calls to the API server; the scheduler and the kubelet each notice the new object through a **watch** on the API server and do their part. That is the whole "declarative + controllers" model.

## 4. Kubernetes Basics tutorial with kubectl

Log: [logs/04-kubectl-basics.txt](logs/04-kubectl-basics.txt)

| Module | Command | What I saw |
|---|---|---|
| Deploy | `kubectl create deployment hello-k8s --image=nginx:1.25-alpine --replicas=2` | Deployment → ReplicaSet `hello-k8s-6bb5f98d5f` → 2 pods, one on each worker |
| Explore | `kubectl describe deployment`, `kubectl logs`, `kubectl exec ... nginx -v` | `RollingUpdateStrategy: 25% max unavailable, 25% max surge` is the default; the container's hostname is the pod name |
| Expose | `kubectl expose deployment hello-k8s --type=NodePort --port=80` | ClusterIP `10.96.59.18`, NodePort `30574`; a one-shot curl pod got `<title>Welcome to nginx!</title>` via the name `hello-k8s` |
| Scale | `kubectl scale deployment/hello-k8s --replicas=4` … `--replicas=2` | Endpoints went from 2 → 4 → 2 addresses automatically |
| Update | `kubectl set image deployment/hello-k8s nginx=nginx:1.27-alpine` | New ReplicaSet `774d79f5bf`, old pods replaced one at a time |
| Bad update | `kubectl set image ... nginx=nginx:does-not-exist` | New pod stuck in `ErrImagePull`, the two good pods kept running, `rollout status` timed out |
| Rollback | `kubectl rollout undo deployment/hello-k8s` | Back on `nginx:1.27-alpine`, rollout history has revisions 1–3 |
| Namespaces | `kubectl create namespace team-a` | pods in `team-a` are invisible to a plain `kubectl get pods` |

```text
$ kubectl set image deployment/hello-k8s nginx=nginx:does-not-exist
$ kubectl get pods -l app=hello-k8s
NAME                         READY   STATUS         RESTARTS   AGE
hello-k8s-558b45678d-d4t7k   0/1     ErrImagePull   0          15s       <- the surge pod
hello-k8s-774d79f5bf-7p6jj   1/1     Running        0          31s       <- old pods untouched
hello-k8s-774d79f5bf-c5qcp   1/1     Running        0          30s

$ kubectl rollout undo deployment/hello-k8s
deployment.apps/hello-k8s rolled back
```

## What I understood

* **Everything is an object in etcd, and every component is a controller** that watches the API server and moves the world towards what the objects say. Nothing pushes commands to nodes.
* The **control plane is itself just pods** (static pods started by the kubelet from `/etc/kubernetes/manifests`), which is why `kubectl get pods -n kube-system` shows it.
* **Pods are disposable**; the Deployment → ReplicaSet → Pod chain is what gives self-healing, scaling and rollouts, and a broken rollout stops itself without taking the old pods down.
* A `Service` gives a stable name and IP in front of changing pod IPs; kube-proxy turns it into iptables rules on every node, CoreDNS turns the name into the ClusterIP.
* On a Mac, `kind` is closer to a real cluster than minikube's single VM: separate node containers, a real taint on the control plane, and a CNI plugin I can look at.
