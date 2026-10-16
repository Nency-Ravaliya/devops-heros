# Session 09 - Kubernetes Fundamentals

| | |
|---|---|
| **Student** | Ujjawal Prabhat |
| **Enrollment No.** | 24BCS10267 |
| **Session** | 09 - Kubernetes Fundamentals (cluster setup, architecture, basic objects, Kubernetes Basics tutorial) |

## Task checklist

- [x] Local cluster setup (kind instead of Minikube, Minikube equivalents documented)
- [x] Verify cluster status (`cluster-info`, `get nodes -o wide`, `get pods -A`, `componentstatuses`, `/readyz?verbose`)
- [x] Architecture notes - control-plane and node components, shown running in `kube-system`
- [x] Basic objects and everyday `kubectl` commands
- [x] Kubernetes Basics tutorial hands-on: create deployment, explore, expose, scale, rolling update, rollback

All terminal output below is real output captured on my machine (macOS, Apple Silicon / arm64, Docker Desktop, kind v0.33.0).
Everything I created lives in namespace `s09`.

## Folder contents

```
24BCS10267-ujjawal-prabhat/
├── README.md
├── manifests/
│   ├── kind-config.yaml      # kind cluster definition (1 CP + 2 workers, ingress port mappings)
│   └── nginx-pod.yaml        # simple Pod used in the "basic objects" section
└── bootcamp-app/
    ├── Dockerfile            # arm64 re-build of the tutorial's kubernetes-bootcamp app
    └── server.js
```

---

## 1. Cluster setup - kind (instead of Minikube)

The course doc uses **Minikube**. I used **kind** (Kubernetes IN Docker): every "node" is a Docker container running
`kubelet` + `containerd`, and the control plane is bootstrapped with `kubeadm`. It is lightweight, supports
multi-node clusters, and is what CI systems commonly use.

Cluster definition: [`manifests/kind-config.yaml`](manifests/kind-config.yaml)

- 1 control-plane + 2 worker nodes
- control-plane labelled `ingress-ready=true` (ingress-nginx "kind" flavour is pinned to it)
- `extraPortMappings`: host `8081 -> 80` and `8443 -> 443` (ingress), host `30080 -> 30080` (a NodePort)

```bash
kind create cluster --name devops-heros --config manifests/kind-config.yaml --image kindest/node:v1.37.0
# ingress controller (kind provider manifest) + metrics-server were then installed
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Proof the running cluster matches that config (the node label and the port mappings):

```
$ kubectl get nodes --show-labels | tr ',' '\n' | grep -E "ingress|node-role"
ingress-ready=true
node-role.kubernetes.io/control-plane=

$ docker ps --filter name=devops-heros --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
NAMES                        IMAGE                  PORTS
devops-heros-control-plane   kindest/node:v1.37.0   0.0.0.0:30080->30080/tcp, 0.0.0.0:8081->80/tcp, 0.0.0.0:8443->443/tcp, 127.0.0.1:51416->6443/tcp
devops-heros-worker          kindest/node:v1.37.0
devops-heros-worker2         kindest/node:v1.37.0
```

### Minikube equivalents (what the course doc uses)

| Goal | kind | Minikube |
|---|---|---|
| Create cluster | `kind create cluster --name devops-heros --config kind-config.yaml` | `minikube start --driver=docker --nodes=3` |
| List clusters / status | `kind get clusters` | `minikube status` / `minikube profile list` |
| Ingress controller | apply ingress-nginx *kind* manifest | `minikube addons enable ingress` |
| Metrics | apply metrics-server manifest | `minikube addons enable metrics-server` |
| Load a local image | `kind load docker-image img:tag --name devops-heros` | `minikube image load img:tag` |
| Reach a NodePort service | `extraPortMappings` / `docker exec <node> curl <nodeIP>:<port>` | `minikube service <svc> --url` |
| LoadBalancer IPs | `cloud-provider-kind` | `minikube tunnel` |
| Dashboard | (install manually) | `minikube dashboard` |
| Delete | `kind delete cluster --name devops-heros` | `minikube delete` |

---

## 2. Verify cluster status

```
$ kind get clusters
devops-heros

$ kubectl config current-context
kind-devops-heros

$ kubectl version
Client Version: v1.36.1
Kustomize Version: v5.8.1
Server Version: v1.37.0

$ kubectl cluster-info
Kubernetes control plane is running at https://127.0.0.1:51416
CoreDNS is running at https://127.0.0.1:51416/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

$ kubectl get nodes -o wide
NAME                         STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION            CONTAINER-RUNTIME
devops-heros-control-plane   Ready    control-plane   7m40s   v1.37.0   172.18.0.3    <none>        Debian GNU/Linux 13 (trixie)   7.0.12-linuxkit (arm64)   containerd://2.3.4
devops-heros-worker          Ready    <none>          7m26s   v1.37.0   172.18.0.4    <none>        Debian GNU/Linux 13 (trixie)   7.0.12-linuxkit (arm64)   containerd://2.3.4
devops-heros-worker2         Ready    <none>          7m26s   v1.37.0   172.18.0.2    <none>        Debian GNU/Linux 13 (trixie)   7.0.12-linuxkit (arm64)   containerd://2.3.4
```

`kubectl get pods -A -o wide` (trimmed to the system namespaces; the cluster is shared, other namespaces omitted with `...`):

```
$ kubectl get pods -A -o wide
NAMESPACE            NAME                                                  READY   STATUS      RESTARTS        AGE     IP           NODE                         NOMINATED NODE   READINESS GATES
ingress-nginx        ingress-nginx-admission-create-49x7g                  0/1     Completed   0               7m24s   10.244.1.4   devops-heros-worker2         <none>           <none>
ingress-nginx        ingress-nginx-admission-patch-5xggt                   0/1     Completed   2 (6m16s ago)   7m24s   10.244.1.3   devops-heros-worker2         <none>           <none>
ingress-nginx        ingress-nginx-controller-7c467b649f-4q7rm             1/1     Running     0               7m24s   10.244.0.5   devops-heros-control-plane   <none>           <none>
kube-system          coredns-559f6c778d-9v66h                              1/1     Running     0               7m29s   10.244.0.4   devops-heros-control-plane   <none>           <none>
kube-system          coredns-559f6c778d-jrrhj                              1/1     Running     0               7m29s   10.244.0.3   devops-heros-control-plane   <none>           <none>
kube-system          etcd-devops-heros-control-plane                       1/1     Running     0               7m38s   172.18.0.3   devops-heros-control-plane   <none>           <none>
kube-system          kindnet-25tps                                         1/1     Running     0               7m26s   172.18.0.2   devops-heros-worker2         <none>           <none>
kube-system          kindnet-8q6g4                                         1/1     Running     0               7m29s   172.18.0.3   devops-heros-control-plane   <none>           <none>
kube-system          kindnet-8w7xh                                         1/1     Running     0               7m26s   172.18.0.4   devops-heros-worker          <none>           <none>
kube-system          kube-apiserver-devops-heros-control-plane             1/1     Running     0               7m38s   172.18.0.3   devops-heros-control-plane   <none>           <none>
kube-system          kube-controller-manager-devops-heros-control-plane    1/1     Running     0               7m38s   172.18.0.3   devops-heros-control-plane   <none>           <none>
kube-system          kube-proxy-2p59f                                      1/1     Running     0               7m26s   172.18.0.4   devops-heros-worker          <none>           <none>
kube-system          kube-proxy-79h6j                                      1/1     Running     0               7m29s   172.18.0.3   devops-heros-control-plane   <none>           <none>
kube-system          kube-proxy-96bfc                                      1/1     Running     0               7m26s   172.18.0.2   devops-heros-worker2         <none>           <none>
kube-system          kube-scheduler-devops-heros-control-plane             1/1     Running     0               7m38s   172.18.0.3   devops-heros-control-plane   <none>           <none>
kube-system          metrics-server-84c99cb944-xn88w                       1/1     Running     0               7m23s   10.244.1.2   devops-heros-worker2         <none>           <none>
local-path-storage   local-path-provisioner-75f7fc7dc5-9w6c4               1/1     Running     0               7m29s   10.244.0.2   devops-heros-control-plane   <none>           <none>
...
```

Component health. `componentstatuses` is deprecated (note the warning), the modern way is the API server's
`/readyz` and `/livez` endpoints:

```
$ kubectl get componentstatuses
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE   ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-0               Healthy   ok

$ kubectl get --raw='/readyz?verbose'
[+]ping ok
[+]log ok
[+]etcd ok
[+]etcd-readiness ok
[+]informer-sync ok
[+]poststarthook/start-apiserver-admission-initializer ok
[+]poststarthook/generic-apiserver-start-informers ok
[+]poststarthook/priority-and-fairness-config-consumer ok
[+]poststarthook/priority-and-fairness-filter ok
[+]poststarthook/storage-object-count-tracker-hook ok
[+]poststarthook/start-apiextensions-informers ok
[+]poststarthook/start-apiextensions-controllers ok
[+]poststarthook/crd-informer-synced ok
...   (24 more poststarthook checks, all "ok")
[+]autoregister-completion ok
[+]poststarthook/apiservice-openapi-controller ok
[+]poststarthook/apiservice-openapiv3-controller ok
[+]shutdown ok
readyz check passed

$ kubectl get --raw='/livez'
ok
```

---

## 3. Architecture

```
                    ┌──────────────── Control plane (devops-heros-control-plane) ───────────────┐
 kubectl ──HTTPS──▶ │ kube-apiserver ◀──▶ etcd                                                 │
                    │      ▲    ▲                                                               │
                    │      │    └── kube-scheduler          (picks a node for unscheduled pods) │
                    │      └─────── kube-controller-manager (Deployment/RS/Node/... loops)      │
                    │               cloud-controller-manager (only with a cloud provider)       │
                    └──────────────────────────────▲────────────────────────────────────────────┘
                                                   │ watch / status updates
             ┌──────────── worker node ────────────┴─────┐   (same on every node)
             │ kubelet ──CRI──▶ containerd ──▶ pods      │
             │ kube-proxy (Service VIP -> pod iptables)  │
             │ kindnet (CNI: pod networking)             │
             └───────────────────────────────────────────┘
```

### Control-plane components

| Component | Role |
|---|---|
| **kube-apiserver** | Front door of the cluster. Every client (kubectl, kubelet, controllers) talks only to it via REST. Does authn/authz/admission and is the only component that writes to etcd. |
| **etcd** | Consistent, distributed key-value store holding the entire cluster state (desired + observed). |
| **kube-scheduler** | Watches for pods with no `nodeName`, filters/scores nodes (resources, taints, affinity) and binds the pod to a node. |
| **kube-controller-manager** | Runs the reconciliation loops (Deployment, ReplicaSet, Node, Job, EndpointSlice, ServiceAccount, ...) that drive actual state toward desired state. |
| **cloud-controller-manager** | Cloud-specific loops (LoadBalancers, node lifecycle, routes). Not present in kind - there is no cloud. |

### Node components

| Component | Role |
|---|---|
| **kubelet** | Agent on every node. Receives pod specs from the API server, asks the runtime to start containers, runs probes, reports status. Also starts the *static pods* in `/etc/kubernetes/manifests`. |
| **kube-proxy** | Programs iptables/IPVS so that Service ClusterIPs/NodePorts load-balance to pod endpoints. Runs as a DaemonSet. |
| **Container runtime** | `containerd` here (shown in the `CONTAINER-RUNTIME` column). Pulls images and runs containers through the CRI. |
| (CNI plugin) | `kindnet` gives every pod an IP from `10.244.0.0/16` and routes between nodes. |

### Seeing them run

```
$ kubectl get pods -n kube-system -l tier=control-plane -o custom-columns=NAME:.metadata.name,COMPONENT:.metadata.labels.component,NODE:.spec.nodeName,STATUS:.status.phase
NAME                                                 COMPONENT                 NODE                         STATUS
etcd-devops-heros-control-plane                      etcd                      devops-heros-control-plane   Running
kube-apiserver-devops-heros-control-plane            kube-apiserver            devops-heros-control-plane   Running
kube-controller-manager-devops-heros-control-plane   kube-controller-manager   devops-heros-control-plane   Running
kube-scheduler-devops-heros-control-plane            kube-scheduler            devops-heros-control-plane   Running

$ docker exec devops-heros-control-plane ls /etc/kubernetes/manifests
etcd.yaml
kube-apiserver.yaml
kube-controller-manager.yaml
kube-scheduler.yaml

$ kubectl get ds -n kube-system
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kindnet      3         3         3       3            3           kubernetes.io/os=linux   7m47s
kube-proxy   3         3         3       3            3           kubernetes.io/os=linux   7m48s
```

The control-plane components are **static pods** (the kubelet reads the YAML files above directly, no scheduler
involved). `kube-proxy` and `kindnet` are **DaemonSets** - one pod per node (3/3).

`kubelet` and `containerd` are not pods; they are systemd services inside each node container:

```
$ docker exec devops-heros-worker systemctl is-active kubelet containerd
active
active

$ docker exec devops-heros-worker crictl ps --name kube-proxy
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID              POD                 NAMESPACE
3ecb20eb4d0d7       550b682d81d41       7 minutes ago       Running             kube-proxy          0                   d038cdc9941ae       kube-proxy-2p59f    kube-system

$ kubectl get --raw /api/v1/nodes/devops-heros-worker/proxy/healthz
ok

$ kubectl get pods -n kube-system | grep -i cloud-controller || echo 'no cloud-controller-manager pod (kind runs without a cloud provider)'
no cloud-controller-manager pod (kind runs without a cloud provider)
```

---

## 4. Basic objects and commands

| Object | What it is |
|---|---|
| **Pod** | Smallest deployable unit: one or more containers sharing network namespace (one IP) and volumes. |
| **ReplicaSet** | Keeps N identical pods running (self-healing). |
| **Deployment** | Manages ReplicaSets; adds rolling updates, history and rollback. |
| **Service** | Stable virtual IP + DNS name that load-balances to pods selected by labels. |
| **Namespace** | Virtual cluster / scope for names, quotas and RBAC. |
| **Labels / selectors** | Key-value tags; how Services and ReplicaSets find their pods. |

```
$ kubectl api-resources --api-group='' | head -20
NAME                     SHORTNAMES   APIVERSION   NAMESPACED   KIND
bindings                              v1           true         Binding
componentstatuses        cs           v1           false        ComponentStatus
configmaps               cm           v1           true         ConfigMap
endpoints                ep           v1           true         Endpoints
events                   ev           v1           true         Event
limitranges              limits       v1           true         LimitRange
namespaces               ns           v1           false        Namespace
nodes                    no           v1           false        Node
persistentvolumeclaims   pvc          v1           true         PersistentVolumeClaim
persistentvolumes        pv           v1           false        PersistentVolume
pods                     po           v1           true         Pod
podtemplates                          v1           true         PodTemplate
replicationcontrollers   rc           v1           true         ReplicationController
resourcequotas           quota        v1           true         ResourceQuota
secrets                               v1           true         Secret
serviceaccounts          sa           v1           true         ServiceAccount
services                 svc          v1           true         Service
```

Imperative pod (`kubectl run`) vs declarative pod ([`manifests/nginx-pod.yaml`](manifests/nginx-pod.yaml), `kubectl apply`):

```
$ kubectl create ns s09
namespace/s09 created

$ kubectl run quick-busybox -n s09 --image=busybox:1.36 --restart=Never -- sh -c 'echo hello from $(hostname); sleep 3600'
pod/quick-busybox created

$ kubectl apply -f nginx-pod.yaml
pod/nginx-pod created

$ kubectl -n s09 wait --for=condition=Ready pod/nginx-pod pod/quick-busybox --timeout=120s
pod/nginx-pod condition met
pod/quick-busybox condition met

$ kubectl -n s09 get pods -o wide --show-labels
NAME                                   READY   STATUS    RESTARTS   AGE   IP            NODE                   NOMINATED NODE   READINESS GATES   LABELS
kubernetes-bootcamp-74584c75cf-jwd8t   1/1     Running   0          96s   10.244.1.60   devops-heros-worker2   <none>           <none>            app=kubernetes-bootcamp,pod-template-hash=74584c75cf
kubernetes-bootcamp-74584c75cf-vmn6s   1/1     Running   0          96s   10.244.2.44   devops-heros-worker    <none>           <none>            app=kubernetes-bootcamp,pod-template-hash=74584c75cf
nginx-pod                              1/1     Running   0          0s    10.244.1.67   devops-heros-worker2   <none>           <none>            app=nginx,owner=24bcs10267
quick-busybox                          1/1     Running   0          0s    10.244.2.48   devops-heros-worker    <none>           <none>            run=quick-busybox

$ kubectl -n s09 get pods -l app=nginx
NAME        READY   STATUS    RESTARTS   AGE
nginx-pod   1/1     Running   0          1s

$ kubectl -n s09 logs quick-busybox
hello from quick-busybox

$ kubectl -n s09 exec nginx-pod -- nginx -v
nginx version: nginx/1.27.5

$ kubectl -n s09 exec quick-busybox -- wget -qO- http://$(kubectl -n s09 get pod nginx-pod -o jsonpath='{.status.podIP}') | head -4
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>

$ kubectl -n s09 get pod nginx-pod -o jsonpath='{.status.phase} {.status.podIP} {.spec.nodeName}{"\n"}'
Running 10.244.1.67 devops-heros-worker2

$ kubectl -n s09 describe pod nginx-pod | grep -A10 '^Events'
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  1s    default-scheduler  Successfully assigned s09/nginx-pod to devops-heros-worker2
  Normal  Pulled     1s    kubelet            spec.containers{nginx}: Container image "nginx:1.27-alpine" already present on machine and can be accessed by the pod
  Normal  Created    1s    kubelet            spec.containers{nginx}: Container created
  Normal  Started    1s    kubelet            spec.containers{nginx}: Container started
```

The events show the architecture at work: **scheduler** assigns the node, then the **kubelet** on that node pulls,
creates and starts the container.

Generating YAML instead of writing it by hand, and looking up fields:

```
$ kubectl create deployment web --image=nginx:1.27-alpine --replicas=2 -n s09 --dry-run=client -o yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: web
  name: web
  namespace: s09
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  strategy: {}
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - image: nginx:1.27-alpine
        name: nginx
        resources: {}
status: {}

$ kubectl explain pod.spec.restartPolicy
KIND:       Pod
VERSION:    v1

FIELD: restartPolicy <string>
ENUM:
    Always
    Never
    OnFailure

DESCRIPTION:
    Restart policy for all containers within the pod. One of Always, OnFailure,
    Never. In some contexts, only a subset of those values may be permitted.
    Default to Always. More info:
    https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy
    ...

$ kubectl -n s09 delete pod nginx-pod quick-busybox
pod "nginx-pod" deleted from s09 namespace
pod "quick-busybox" deleted from s09 namespace
```

---

## 5. Kubernetes Basics tutorial (hands-on)

Tutorial: <https://kubernetes.io/docs/tutorials/kubernetes-basics/>

### Problem I hit first: the tutorial image does not run on arm64

The tutorial's `gcr.io/k8s-minikube/kubernetes-bootcamp:v1` no longer exists, and the replacement
`gcr.io/google-samples/kubernetes-bootcamp:v1` (and `jocatalin/kubernetes-bootcamp:v2`) are **amd64-only** images.
My kind nodes are arm64 (Apple Silicon), so the containers crash immediately:

```
$ kubectl -n s09 describe pod -l app=kubernetes-bootcamp | tail -8
  ...
  Warning  Failed     29s (x2 over 58s)  kubelet            spec.containers{kubernetes-bootcamp}: Failed to pull image "gcr.io/k8s-minikube/kubernetes-bootcamp:v1": rpc error: code = NotFound desc = failed to pull and unpack image "gcr.io/k8s-minikube/kubernetes-bootcamp:v1": failed to resolve reference "gcr.io/k8s-minikube/kubernetes-bootcamp:v1": gcr.io/k8s-minikube/kubernetes-bootcamp:v1: not found

# with gcr.io/google-samples/kubernetes-bootcamp:v1 instead:
$ kubectl -n s09 logs kubernetes-bootcamp-5cc66bcc9b-2kcnx
exec /bin/sh: exec format error

$ kubectl -n s09 get pods -o wide
NAME                                   READY   STATUS   RESTARTS        AGE    IP            NODE                   NOMINATED NODE   READINESS GATES
kubernetes-bootcamp-5cc66bcc9b-9mx62   0/1     Error    6 (3m5s ago)    6m6s   10.244.1.23   devops-heros-worker2   <none>           <none>
kubernetes-bootcamp-5cc66bcc9b-l6q6r   0/1     Error    6 (3m16s ago)   6m6s   10.244.1.22   devops-heros-worker2   <none>           <none>
```

`exec format error` = the binary's CPU architecture does not match the node. **Fix:** I re-created the
tutorial app (same Node.js `server.js` behaviour: prints `Hello Kubernetes bootcamp! | Running on: <pod> | v=<n>`)
in [`bootcamp-app/`](bootcamp-app/), built it natively for arm64 as `v1` and `v2`, and loaded it into the kind nodes
(kind's equivalent of `minikube image load`). I also added a SIGTERM handler: `node` running as PID 1 ignores
SIGTERM, which made old pods hang in `Terminating` for the full 30 s grace period.

```
$ docker build -t 24bcs10267/kubernetes-bootcamp:v1 --build-arg APP_VERSION=1 bootcamp-app/
$ docker build -t 24bcs10267/kubernetes-bootcamp:v2 --build-arg APP_VERSION=2 bootcamp-app/

$ docker image inspect 24bcs10267/kubernetes-bootcamp:v1 --format '{{.Os}}/{{.Architecture}}'
linux/arm64

$ kind load docker-image 24bcs10267/kubernetes-bootcamp:v1 24bcs10267/kubernetes-bootcamp:v2 --name devops-heros
Image: "24bcs10267/kubernetes-bootcamp:v1" with ID "sha256:14a52e1f123e..." not yet present on node "devops-heros-control-plane", loading...
Image: "24bcs10267/kubernetes-bootcamp:v1" with ID "sha256:14a52e1f123e..." not yet present on node "devops-heros-worker", loading...
...
```

### Module 2 - Create a Deployment

```
$ kubectl -n s09 create deployment kubernetes-bootcamp --image=24bcs10267/kubernetes-bootcamp:v1
deployment.apps/kubernetes-bootcamp created

$ kubectl -n s09 annotate deployment kubernetes-bootcamp kubernetes.io/change-cause='create v1'
deployment.apps/kubernetes-bootcamp annotated

$ kubectl -n s09 rollout status deployment/kubernetes-bootcamp --timeout=180s
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 0 of 1 updated replicas are available...
deployment "kubernetes-bootcamp" successfully rolled out

$ kubectl -n s09 get deployments
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1/1     1            1           0s
```

### Module 3 - Explore the app (pods, nodes, logs, exec)

```
$ kubectl -n s09 get pods -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP            NODE                   NOMINATED NODE   READINESS GATES
kubernetes-bootcamp-74965b87bb-hszvf   1/1     Running   0          0s    10.244.1.58   devops-heros-worker2   <none>           <none>

$ kubectl -n s09 describe pod kubernetes-bootcamp-74965b87bb-hszvf | sed -n '1,25p'
Name:             kubernetes-bootcamp-74965b87bb-hszvf
Namespace:        s09
Priority:         0
Service Account:  default
Node:             devops-heros-worker2/172.18.0.2
Start Time:       Tue, 06 Oct 2026 19:15:39 +0800
Labels:           app=kubernetes-bootcamp
                  pod-template-hash=74965b87bb
Annotations:      <none>
Status:           Running
IP:               10.244.1.58
IPs:
  IP:           10.244.1.58
Controlled By:  ReplicaSet/kubernetes-bootcamp-74965b87bb
Containers:
  kubernetes-bootcamp:
    Container ID:   containerd://653979fe232f8352477d0e093c187f8b8798c1059fe51ee3875165a1b5fac17b
    Image:          24bcs10267/kubernetes-bootcamp:v1
    Image ID:       docker.io/library/import-2026-10-06@sha256:14d1b0fd6f4141fd549952148d1359cade65317d491473c56a2b93d08ac7ce2b
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Tue, 06 Oct 2026 19:15:39 +0800
    Ready:          True
    Restart Count:  0

$ kubectl -n s09 exec kubernetes-bootcamp-74965b87bb-hszvf -- env | grep -E 'HOSTNAME|KUBERNETES_SERVICE_HOST|APP_VERSION'
HOSTNAME=kubernetes-bootcamp-74965b87bb-hszvf
APP_VERSION=1
KUBERNETES_SERVICE_HOST=10.96.0.1

$ kubectl -n s09 exec kubernetes-bootcamp-74965b87bb-hszvf -- curl -s http://localhost:8080
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74965b87bb-hszvf | v=1

$ kubectl -n s09 logs kubernetes-bootcamp-74965b87bb-hszvf
Kubernetes Bootcamp App Started At: 2026-10-06T11:15:39.592Z | Running On:  kubernetes-bootcamp-74965b87bb-hszvf

Running On: kubernetes-bootcamp-74965b87bb-hszvf | Total Requests: 1 | App Uptime: 0.233 seconds | Log Time: 2026-10-06T11:15:39.825Z
```

Note `Controlled By: ReplicaSet/...` - the Deployment created a ReplicaSet, which created the Pod.

### Module 4 - Expose the app with a Service (and use labels)

```
$ kubectl -n s09 expose deployment/kubernetes-bootcamp --type=NodePort --port=8080
service/kubernetes-bootcamp exposed

$ kubectl -n s09 get services
NAME                  TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kubernetes-bootcamp   NodePort   10.96.115.99   <none>        8080:30468/TCP   0s

$ kubectl -n s09 describe services/kubernetes-bootcamp
Name:                     kubernetes-bootcamp
Namespace:                s09
Labels:                   app=kubernetes-bootcamp
Annotations:              <none>
Selector:                 app=kubernetes-bootcamp
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.96.115.99
IPs:                      10.96.115.99
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  30468/TCP
Endpoints:                10.244.1.58:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>

# NodePort 30468 is open on every node; call it via the node IP of worker2 from inside the worker node
$ docker exec devops-heros-worker curl -s http://172.18.0.2:30468
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74965b87bb-hszvf | v=1

$ kubectl -n s09 label pods kubernetes-bootcamp-74965b87bb-hszvf version=v1
pod/kubernetes-bootcamp-74965b87bb-hszvf labeled

$ kubectl -n s09 get pods -l version=v1 --show-labels
NAME                                   READY   STATUS    RESTARTS   AGE   LABELS
kubernetes-bootcamp-74965b87bb-hszvf   1/1     Running   0          6s    app=kubernetes-bootcamp,pod-template-hash=74965b87bb,version=v1

$ kubectl -n s09 get services -l app=kubernetes-bootcamp
NAME                  TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kubernetes-bootcamp   NodePort   10.96.115.99   <none>        8080:30468/TCP   6s
```

(On Minikube the tutorial uses `curl http://$(minikube ip):$NODE_PORT`; on kind the node IPs are Docker-network IPs,
so I curl from inside a node container. Only port 30080 is mapped to the Mac host itself.)

### Module 5 - Scale

```
$ kubectl -n s09 get rs
NAME                             DESIRED   CURRENT   READY   AGE
kubernetes-bootcamp-74965b87bb   1         1         1       6s

$ kubectl -n s09 scale deployments/kubernetes-bootcamp --replicas=4
deployment.apps/kubernetes-bootcamp scaled

$ kubectl -n s09 rollout status deployment/kubernetes-bootcamp --timeout=180s
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 of 4 updated replicas are available...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 of 4 updated replicas are available...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 3 of 4 updated replicas are available...
deployment "kubernetes-bootcamp" successfully rolled out

$ kubectl -n s09 get deployments
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   4/4     4            4           6s

$ kubectl -n s09 get pods -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP            NODE                   NOMINATED NODE   READINESS GATES
kubernetes-bootcamp-74965b87bb-hszvf   1/1     Running   0          7s    10.244.1.58   devops-heros-worker2   <none>           <none>
kubernetes-bootcamp-74965b87bb-jmtqp   1/1     Running   0          1s    10.244.2.43   devops-heros-worker    <none>           <none>
kubernetes-bootcamp-74965b87bb-pwcsq   1/1     Running   0          1s    10.244.1.59   devops-heros-worker2   <none>           <none>
kubernetes-bootcamp-74965b87bb-w79qb   1/1     Running   0          1s    10.244.2.42   devops-heros-worker    <none>           <none>

$ kubectl -n s09 get endpointslices -l kubernetes.io/service-name=kubernetes-bootcamp -o wide
NAME                        ADDRESSTYPE   PORTS   ENDPOINTS                                         AGE
kubernetes-bootcamp-qnhgn   IPv4          8080    10.244.1.58,10.244.2.42,10.244.1.59 + 1 more...   10s

$ for i in 1 2 3 4 5 6 7 8; do docker exec devops-heros-worker curl -s http://172.18.0.2:30468; done
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74965b87bb-hszvf | v=1
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74965b87bb-hszvf | v=1
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74965b87bb-hszvf | v=1
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74965b87bb-w79qb | v=1
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74965b87bb-jmtqp | v=1
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74965b87bb-pwcsq | v=1
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74965b87bb-jmtqp | v=1
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74965b87bb-pwcsq | v=1
```

The Service load-balances across all 4 pods (4 different hostnames in the responses).
Scale back down:

```
$ kubectl -n s09 scale deployments/kubernetes-bootcamp --replicas=2
deployment.apps/kubernetes-bootcamp scaled

$ kubectl -n s09 get deployments
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   2/2     2            2           18s

$ kubectl -n s09 get pods -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP            NODE                   NOMINATED NODE   READINESS GATES
kubernetes-bootcamp-74965b87bb-hszvf   1/1     Running   0          18s   10.244.1.58   devops-heros-worker2   <none>           <none>
kubernetes-bootcamp-74965b87bb-jmtqp   1/1     Running   0          12s   10.244.2.43   devops-heros-worker    <none>           <none>
```

### Module 6 - Rolling update and rollback

```
$ kubectl -n s09 set image deployments/kubernetes-bootcamp kubernetes-bootcamp=24bcs10267/kubernetes-bootcamp:v2
deployment.apps/kubernetes-bootcamp image updated

$ kubectl -n s09 annotate deployment kubernetes-bootcamp kubernetes.io/change-cause='update to v2'
deployment.apps/kubernetes-bootcamp annotated

$ kubectl -n s09 rollout status deployments/kubernetes-bootcamp --timeout=240s
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
deployment "kubernetes-bootcamp" successfully rolled out

$ kubectl -n s09 get pods
NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-74584c75cf-jwd8t   1/1     Running   0          9s
kubernetes-bootcamp-74584c75cf-vmn6s   1/1     Running   0          9s

$ kubectl -n s09 get rs -o wide
NAME                             DESIRED   CURRENT   READY   AGE   CONTAINERS            IMAGES                              SELECTOR
kubernetes-bootcamp-74584c75cf   2         2         2       9s    kubernetes-bootcamp   24bcs10267/kubernetes-bootcamp:v2   app=kubernetes-bootcamp,pod-template-hash=74584c75cf
kubernetes-bootcamp-74965b87bb   0         0         0       27s   kubernetes-bootcamp   24bcs10267/kubernetes-bootcamp:v1   app=kubernetes-bootcamp,pod-template-hash=74965b87bb

$ for i in 1 2 3 4; do docker exec devops-heros-worker curl -s http://172.18.0.2:30468; done
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74584c75cf-jwd8t | v=2
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74584c75cf-jwd8t | v=2
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74584c75cf-vmn6s | v=2
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74584c75cf-jwd8t | v=2
```

The rolling update created a **new ReplicaSet** (`74584c75cf`, v2) and scaled the old one (`74965b87bb`, v1) to 0.
The old ReplicaSet is kept so it can be rolled back to.

Now a **bad update** (tag `v10` does not exist):

```
$ kubectl -n s09 set image deployments/kubernetes-bootcamp kubernetes-bootcamp=24bcs10267/kubernetes-bootcamp:v10
deployment.apps/kubernetes-bootcamp image updated

$ kubectl -n s09 annotate deployment kubernetes-bootcamp kubernetes.io/change-cause='update to v10 (does not exist)'
deployment.apps/kubernetes-bootcamp annotated

# 60 s later
$ kubectl -n s09 get deployments
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   2/2     1            2           87s

$ kubectl -n s09 get pods
NAME                                   READY   STATUS         RESTARTS   AGE
kubernetes-bootcamp-58888f69fd-brtc2   0/1     ErrImagePull   0          60s
kubernetes-bootcamp-74584c75cf-jwd8t   1/1     Running        0          69s
kubernetes-bootcamp-74584c75cf-vmn6s   1/1     Running        0          69s

$ kubectl -n s09 describe pod kubernetes-bootcamp-58888f69fd-brtc2 | grep -A12 '^Events'
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  60s                default-scheduler  Successfully assigned s09/kubernetes-bootcamp-58888f69fd-brtc2 to devops-heros-worker2
  Normal   Pulling    16s (x3 over 59s)  kubelet            spec.containers{kubernetes-bootcamp}: Pulling image "24bcs10267/kubernetes-bootcamp:v10"
  Warning  Failed     14s (x3 over 57s)  kubelet            spec.containers{kubernetes-bootcamp}: Failed to pull image "24bcs10267/kubernetes-bootcamp:v10": failed to pull and unpack image "docker.io/24bcs10267/kubernetes-bootcamp:v10": failed to resolve reference "docker.io/24bcs10267/kubernetes-bootcamp:v10": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
  Warning  Failed     14s (x3 over 57s)  kubelet            spec.containers{kubernetes-bootcamp}: Error: ErrImagePull
  Normal   BackOff    1s (x3 over 56s)   kubelet            spec.containers{kubernetes-bootcamp}: Back-off pulling image "24bcs10267/kubernetes-bootcamp:v10"
  Warning  Failed     1s (x3 over 56s)   kubelet            spec.containers{kubernetes-bootcamp}: Error: ImagePullBackOff
```

Thanks to the rolling-update defaults (`maxUnavailable: 25%` -> rounds down to 0 of 2), Kubernetes never killed the
working v2 pods: the app stayed available (`READY 2/2`) while the broken pod was stuck. Roll back:

```
$ kubectl -n s09 rollout history deployment/kubernetes-bootcamp
deployment.apps/kubernetes-bootcamp
REVISION  CHANGE-CAUSE
1         create v1
2         update to v2
3         update to v10 (does not exist)

$ kubectl -n s09 rollout undo deployments/kubernetes-bootcamp
deployment.apps/kubernetes-bootcamp rolled back

$ kubectl -n s09 rollout status deployments/kubernetes-bootcamp --timeout=180s
deployment "kubernetes-bootcamp" successfully rolled out

$ kubectl -n s09 get pods
NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-74584c75cf-jwd8t   1/1     Running   0          75s
kubernetes-bootcamp-74584c75cf-vmn6s   1/1     Running   0          75s

$ kubectl -n s09 describe deployment kubernetes-bootcamp | grep -E 'Image|Replicas'
Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable
    Image:         24bcs10267/kubernetes-bootcamp:v2
  Available      True    MinimumReplicasAvailable

$ kubectl -n s09 rollout history deployment/kubernetes-bootcamp
deployment.apps/kubernetes-bootcamp
REVISION  CHANGE-CAUSE
1         create v1
3         update to v10 (does not exist)
4         update to v2

$ for i in 1 2 3; do docker exec devops-heros-worker curl -s http://172.18.0.2:30468; done
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74584c75cf-vmn6s | v=2
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74584c75cf-vmn6s | v=2
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-74584c75cf-vmn6s | v=2
```

`rollout undo` went back to the previous revision (v2). Revision 2 was re-numbered to **4** because the undo
re-applies that old template as the newest revision.

### Bonus - self-healing

```
$ kubectl -n s09 delete pod kubernetes-bootcamp-74584c75cf-jwd8t --wait=false
pod "kubernetes-bootcamp-74584c75cf-jwd8t" deleted from s09 namespace

$ kubectl -n s09 get pods
NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-74584c75cf-tl85z   1/1     Running   0          4s
kubernetes-bootcamp-74584c75cf-vmn6s   1/1     Running   0          2m20s

$ kubectl -n s09 get events --field-selector involvedObject.kind=ReplicaSet --sort-by=.lastTimestamp | tail -4
2m19s       Normal   SuccessfulDelete   replicaset/kubernetes-bootcamp-74965b87bb   Deleted pod: kubernetes-bootcamp-74965b87bb-jmtqp
2m11s       Normal   SuccessfulCreate   replicaset/kubernetes-bootcamp-58888f69fd   Created pod: kubernetes-bootcamp-58888f69fd-brtc2
70s         Normal   SuccessfulDelete   replicaset/kubernetes-bootcamp-58888f69fd   Deleted pod: kubernetes-bootcamp-58888f69fd-brtc2
4s          Normal   SuccessfulCreate   replicaset/kubernetes-bootcamp-74584c75cf   Created pod: kubernetes-bootcamp-74584c75cf-tl85z
```

The ReplicaSet controller (inside kube-controller-manager) noticed 1/2 pods and immediately created a replacement.

## Cleanup

```bash
kubectl delete ns s09
```

## Key takeaways

- The **API server** is the only entry point; everything else (scheduler, controllers, kubelets) watches it and reconciles.
- **Deployment -> ReplicaSet -> Pod** is the ownership chain; rolling updates are just "new RS up, old RS down".
- **Services** decouple clients from changing pod IPs using label selectors + EndpointSlices.
- Always check the **image architecture** on Apple Silicon - `exec format error` means amd64-only image on arm64 nodes.
