# Session 9: Kubernetes Fundamentals

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

## Tasks

| # | Task | Section |
|---|---|---|
| 1 | Install and configure Minikube | [1](#1-install-and-configure-minikube) |
| 2 | Verify Kubernetes cluster status | [2](#2-verify-the-cluster-status) |
| 3 | Explore Kubernetes architecture | [3](#3-kubernetes-architecture) |
| 4 | Learn the basic Kubernetes objects and commands | [4](#4-basic-kubernetes-objects-and-commands) |
| 5 | Kubernetes Basics tutorial, hands-on (all 6 modules) | [5](#5-kubernetes-basics-tutorial-hands-on) |

**Environment:** Windows 11, Docker Desktop (Docker 29) as the driver, Minikube v1.39.0, Kubernetes v1.37.0, `kubectl` v1.37.0, commands run in Git Bash. All output is real and copied from the terminal.

---

## 1. Install and configure Minikube

Minikube runs a single-node Kubernetes cluster on my laptop. It needs a driver (a container or VM runtime); I use the **Docker driver**, so the whole "node" is one Docker container.

### Installation (Windows, winget)

_Install Minikube with the Windows package manager._

```console
$ winget install --id Kubernetes.minikube -e
=== installing Kubernetes.minikube ===
Found Kubernetes - Minikube - A Local Kubernetes Development Environment [Kubernetes.minikube] Version 1.39.0
Downloading https://github.com/kubernetes/minikube/releases/download/v1.39.0/minikube-installer.exe
Successfully verified installer hash
Starting package install...
Successfully installed
```

### Check the tools

_Minikube version._

```console
$ minikube version
minikube version: v1.39.0
commit: 7a9f6a841470a207de8cf4bafcccee0969d8ba10
```

_kubectl is the command line client. Its version should be within one minor version of the cluster, so I use the kubectl v1.37 that Minikube downloads (`minikube kubectl`)._

```console
$ kubectl version --client
Client Version: v1.37.0
Kustomize Version: v5.8.1
```

_The Docker driver needs Docker running._

```console
$ docker --version
Docker version 29.1.5, build 0e6fee6
```

### Start (and configure) the cluster

```
minikube start --driver=docker --cpus=4 --memory=5000
```

| Flag | Meaning |
|---|---|
| `--driver=docker` | run the node as a Docker container |
| `--cpus=4`, `--memory=5000` | resources given to the node (MB for memory) |

_The real output of the first start (the image downloads took a few minutes):_

```console
$ minikube start --driver=docker --cpus=4 --memory=5000
* minikube v1.39.0 on Microsoft Windows 11 Home Single Language 25H2
* Using the docker driver based on user configuration
* Using Docker Desktop driver with root privileges
* Starting "minikube" primary control-plane node in "minikube" cluster
* Pulling base image v0.0.51 ...
* Downloading Kubernetes v1.37.0 preload ...
* Configuring CNI (Container Networking Interface) ...
* Verifying Kubernetes components...
  - Using image gcr.io/k8s-minikube/storage-provisioner:v5
* Enabled addons: storage-provisioner, default-storageclass

! C:\Program Files\Docker\Docker\resources\bin\kubectl.exe is version 1.34.1, which may have incompatibilities with Kubernetes 1.37.0.
  - Want kubectl v1.37.0? Try 'minikube kubectl -- get pods -A'
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

Minikube also wrote the connection details into `~/.kube/config` and made `minikube` the current context.

_The context points kubectl at the new cluster._

```console
$ kubectl config get-contexts
CURRENT   NAME       CLUSTER    AUTHINFO   NAMESPACE
*         minikube   minikube   minikube   default
```

---

## 2. Verify the cluster status

_host, kubelet, apiserver and kubeconfig should all be Running/Configured._

```console
$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

_The API server (control plane) and CoreDNS addresses._

```console
$ kubectl cluster-info
Kubernetes control plane is running at https://127.0.0.1:50417
CoreDNS is running at https://127.0.0.1:50417/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

_One node, Ready, with the control-plane role. The wide output shows its IP, OS, kernel and container runtime._

```console
$ kubectl get nodes -o wide
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION                             CONTAINER-RUNTIME
minikube   Ready    control-plane   25m   v1.37.0   192.168.49.2   <none>        Debian GNU/Linux 12 (bookworm)   6.6.87.2-microsoft-standard-WSL2 (amd64)   containerd://2.3.4
```

_Every system Pod in every namespace: these are the cluster components themselves._

```console
$ kubectl get pods -A
NAMESPACE     NAME                                   READY   STATUS        RESTARTS   AGE
default       kubernetes-bootcamp-5b97597885-5t72d   1/1     Terminating   0          42s
default       kubernetes-bootcamp-5b97597885-vld7z   1/1     Terminating   0          41s
kube-system   coredns-559f6c778d-tgv6l               1/1     Running       0          25m
kube-system   etcd-minikube                          1/1     Running       0          25m
kube-system   kindnet-mzghd                          1/1     Running       0          25m
kube-system   kube-apiserver-minikube                1/1     Running       0          25m
kube-system   kube-controller-manager-minikube       1/1     Running       0          25m
kube-system   kube-proxy-4dxwp                       1/1     Running       0          25m
kube-system   kube-scheduler-minikube                1/1     Running       0          25m
kube-system   storage-provisioner                    1/1     Running       0          25m
```

_The API server health endpoint lists each internal check as ok._

```console
$ kubectl get --raw='/readyz?verbose' | tail -n 8
[+]poststarthook/apiservice-registration-controller ok
[+]poststarthook/apiservice-discovery-controller ok
[+]poststarthook/kube-apiserver-autoregistration ok
[+]autoregister-completion ok
[+]poststarthook/apiservice-openapi-controller ok
[+]poststarthook/apiservice-openapiv3-controller ok
[+]shutdown ok
readyz check passed
```

_Namespaces that exist in a fresh cluster._

```console
$ kubectl get namespaces
NAME              STATUS   AGE
default           Active   25m
kube-node-lease   Active   25m
kube-public       Active   25m
kube-system       Active   25m
```

_Addons currently enabled (only the storage ones in a fresh cluster)._

```console
$ minikube addons list | sed "s/\x1b\[[0-9;]*m//g" | grep -E "ADDON|enabled"
│         ADDON NAME          │ PROFILE  │   STATUS   │               MAINTAINER               │
│ default-storageclass        │ minikube │ enabled ✅ │ Kubernetes                             │
│ storage-provisioner         │ minikube │ enabled ✅ │ minikube                               │
```

---

## 3. Kubernetes architecture

### Short notes

A Kubernetes **cluster** = a **control plane** that decides what should run + **worker nodes** that run it. In Minikube both live in the same node.

```
                    +---------------------- CONTROL PLANE ----------------------+
 kubectl / CI  ---> |  kube-apiserver  <--->  etcd (cluster state database)       |
 (REST over HTTPS)  |        ^   ^                                                |
                    |        |   +--- kube-scheduler (chooses a node for a Pod)   |
                    |        +------- kube-controller-manager (keeps actual state |
                    |                  equal to desired state: ReplicaSet, Node..)|
                    +--------------------------|---------------------------------+
                                               | watches / reports
        +-------------------- WORKER NODE (one or many) ---------------------+
        |  kubelet (starts Pods through the runtime, reports status)          |
        |  kube-proxy (Service networking rules)                              |
        |  container runtime (containerd / Docker)                            |
        |   [ Pod ][ Pod ][ Pod ]   +  CoreDNS (cluster DNS)  + CNI networking |
        +---------------------------------------------------------------------+
```

| Component | Where | What it does |
|---|---|---|
| **kube-apiserver** | control plane | The front door: every request (kubectl, controllers, kubelets) goes through this REST API; it validates and stores objects. |
| **etcd** | control plane | Consistent key-value store holding the whole cluster state. |
| **kube-scheduler** | control plane | Watches for unscheduled Pods and assigns each to a node based on resources and rules. |
| **kube-controller-manager** | control plane | Runs the control loops (Deployment, ReplicaSet, Node, Job...) that continuously drive actual state towards desired state. |
| **kubelet** | every node | Node agent: makes sure the containers of the Pods assigned to its node are running and healthy. |
| **kube-proxy** | every node | Programs iptables/IPVS rules so Service IPs reach the right Pods. |
| **Container runtime** | every node | Actually runs containers (containerd, CRI-O, Docker through cri-dockerd). |
| **CoreDNS** | addon | Cluster DNS: `service.namespace.svc.cluster.local`. |
| **CNI plugin** (kindnet in Minikube) | addon | Gives every Pod an IP and connects Pods across nodes. |

The core idea is the **declarative model**: I describe the **desired state** (for example "3 replicas of this image"), the API server stores it in etcd, and controllers keep working until reality matches it.

### The same components seen in my cluster

_The control-plane components run as Pods in kube-system on the node: etcd, kube-apiserver, kube-controller-manager, kube-scheduler, plus kube-proxy and coredns._

```console
$ kubectl get pods -n kube-system -o wide
NAME                               READY   STATUS    RESTARTS   AGE   IP             NODE       NOMINATED NODE   READINESS GATES
coredns-559f6c778d-tgv6l           1/1     Running   0          25m   10.244.0.2     minikube   <none>           <none>
etcd-minikube                      1/1     Running   0          25m   192.168.49.2   minikube   <none>           <none>
kindnet-mzghd                      1/1     Running   0          25m   192.168.49.2   minikube   <none>           <none>
kube-apiserver-minikube            1/1     Running   0          25m   192.168.49.2   minikube   <none>           <none>
kube-controller-manager-minikube   1/1     Running   0          25m   192.168.49.2   minikube   <none>           <none>
kube-proxy-4dxwp                   1/1     Running   0          25m   192.168.49.2   minikube   <none>           <none>
kube-scheduler-minikube            1/1     Running   0          25m   192.168.49.2   minikube   <none>           <none>
storage-provisioner                1/1     Running   0          25m   192.168.49.2   minikube   <none>           <none>
```

_The kubelet and runtime versions of the node._

```console
$ kubectl get node minikube -o jsonpath='kubelet={.status.nodeInfo.kubeletVersion}  runtime={.status.nodeInfo.containerRuntimeVersion}  os={.status.nodeInfo.osImage}  arch={.status.nodeInfo.architecture}{"\n"}'
kubelet=v1.37.0  runtime=containerd://2.3.4  os=Debian GNU/Linux 12 (bookworm)  arch=amd64
```

_The control-plane components are static Pods: the kubelet starts them straight from these manifest files._

```console
$ minikube ssh -- "sudo ls /etc/kubernetes/manifests"
etcd.yaml	     kube-controller-manager.yaml
kube-apiserver.yaml  kube-scheduler.yaml
```

_The actual processes inside the node._

```console
$ minikube ssh -- "ps -eo comm,args | grep -E \"^(kube|etcd|kubelet|containerd)\" | grep -v shim | cut -c1-70"
containerd      /usr/bin/containerd
etcd            etcd --advertise-client-urls=https://192.168.49.2:2379
kube-apiserver  kube-apiserver --advertise-address=192.168.49.2 --allo
kube-scheduler  kube-scheduler --authentication-kubeconfig=/etc/kubern
kube-controller kube-controller-manager --authentication-kubeconfig=/e
kubelet         /var/lib/minikube/binaries/v1.37.0/kubelet --bootstrap
kube-proxy      /usr/local/bin/kube-proxy --config=/var/lib/kube-proxy
```

_Node details: labels, addresses, capacity and allocatable CPU/memory the scheduler uses._

```console
$ kubectl describe node minikube | head -n 32
Name:               minikube
Roles:              control-plane
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=minikube
                    kubernetes.io/os=linux
                    minikube.k8s.io/commit=7a9f6a841470a207de8cf4bafcccee0969d8ba10
                    minikube.k8s.io/name=minikube
                    minikube.k8s.io/primary=true
                    minikube.k8s.io/updated_at=2026_10_18T18_31_59_0700
                    minikube.k8s.io/version=v1.39.0
                    node-role.kubernetes.io/control-plane=
                    node.kubernetes.io/exclude-from-external-load-balancers=
Annotations:        node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Sun, 18 Oct 2026 18:31:55 +0530
Taints:             <none>
Unschedulable:      false
Lease:
  HolderIdentity:  minikube
  AcquireTime:     <unset>
  RenewTime:       Sun, 18 Oct 2026 18:57:41 +0530
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Sun, 18 Oct 2026 18:56:16 +0530   Sun, 18 Oct 2026 18:31:54 +0530   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Sun, 18 Oct 2026 18:56:16 +0530   Sun, 18 Oct 2026 18:31:54 +0530   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Sun, 18 Oct 2026 18:56:16 +0530   Sun, 18 Oct 2026 18:31:54 +0530   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            True    Sun, 18 Oct 2026 18:56:16 +0530   Sun, 18 Oct 2026 18:32:33 +0530   KubeletReady                 kubelet is posting ready status
Addresses:
  InternalIP:  192.168.49.2
```

---

## 4. Basic Kubernetes objects and commands

### Objects

| Object | Purpose |
|---|---|
| **Pod** | Smallest unit: one or more containers sharing network and storage. |
| **ReplicaSet** | Keeps N identical Pods running. |
| **Deployment** | Manages ReplicaSets: rolling updates, rollback, scaling. |
| **Service** | Stable IP/DNS name and load balancing for a set of Pods (ClusterIP, NodePort, LoadBalancer). |
| **Namespace** | Virtual cluster for grouping and isolating objects. |
| **ConfigMap / Secret** | Configuration and sensitive data injected into Pods. |
| **PersistentVolume / PersistentVolumeClaim** | Storage that outlives a Pod. |
| **Ingress** | HTTP routing into the cluster. |
| **DaemonSet / StatefulSet / Job / CronJob** | One Pod per node / stable identity / run to completion / scheduled. |

### Commands

| Command | Purpose |
|---|---|
| `kubectl get <kind>` | List objects (`-o wide`, `-o yaml`, `-A` all namespaces, `-l label=x`) |
| `kubectl describe <kind> <name>` | Details and events |
| `kubectl apply -f file.yaml` | Create/update from a manifest (declarative) |
| `kubectl create deployment ...` / `run` | Create quickly (imperative) |
| `kubectl delete <kind> <name>` | Remove |
| `kubectl logs <pod>` / `exec -it <pod> -- sh` | Output / shell inside the container |
| `kubectl scale`, `set image`, `rollout status/undo` | Scale, update, roll back |
| `kubectl expose`, `port-forward` | Create a Service / reach a Pod from my machine |
| `kubectl explain <field>` | Built-in API documentation |

### Trying the basics

_The kinds of objects the cluster understands._

```console
$ kubectl api-resources --namespaced=true | head -n 12
NAME                        SHORTNAMES   APIVERSION                     NAMESPACED   KIND
bindings                                 v1                             true         Binding
configmaps                  cm           v1                             true         ConfigMap
endpoints                   ep           v1                             true         Endpoints
events                      ev           v1                             true         Event
limitranges                 limits       v1                             true         LimitRange
persistentvolumeclaims      pvc          v1                             true         PersistentVolumeClaim
pods                        po           v1                             true         Pod
podtemplates                             v1                             true         PodTemplate
replicationcontrollers      rc           v1                             true         ReplicationController
resourcequotas              quota        v1                             true         ResourceQuota
secrets                                  v1                             true         Secret
```

_kubectl explain documents any field of any object._

```console
$ kubectl explain pod.spec.containers.image
KIND:       Pod
VERSION:    v1

FIELD: image <string>


DESCRIPTION:
    Container image name. More info:
    https://kubernetes.io/docs/concepts/containers/images This field is optional
    to allow higher level config management to default or override container
    images in workload controllers like Deployments and StatefulSets.
    
```

_Create a Pod imperatively._

```console
$ kubectl run nginx-demo --image=nginx:alpine
pod/nginx-demo created
```

_Wait for it and look at it: status, restarts, the Pod IP and the node it was scheduled on._

```console
$ kubectl wait --for=condition=Ready pod/nginx-demo --timeout=120s && kubectl get pod nginx-demo -o wide
pod/nginx-demo condition met
NAME         READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
nginx-demo   1/1     Running   0          2s    10.244.0.43   minikube   <none>           <none>
```

_The Events at the bottom tell the story: Scheduled, Pulling, Pulled, Created, Started._

```console
$ kubectl describe pod nginx-demo | tail -n 12
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  2s    default-scheduler  Successfully assigned default/nginx-demo to minikube
  Normal  Pulled     1s    kubelet            spec.containers{nginx-demo}: Container image "nginx:alpine" already present on machine and can be accessed by the pod
  Normal  Created    1s    kubelet            spec.containers{nginx-demo}: Container created
  Normal  Started    1s    kubelet            spec.containers{nginx-demo}: Container started
```

_The container log._

```console
$ kubectl logs nginx-demo | head -n 4
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
```

_Run a command inside the container._

```console
$ kubectl exec nginx-demo -- nginx -v
nginx version: nginx/1.31.7
```

_The object as stored by the API server (desired spec, then status below)._

```console
$ kubectl get pod nginx-demo -o yaml | head -n 24
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2026-10-18T13:27:43Z"
  generation: 1
  labels:
    run: nginx-demo
  name: nginx-demo
  namespace: default
  resourceVersion: "3114"
  uid: 5f974a06-d6d9-430c-bb37-eda7e3808ea9
spec:
  containers:
  - image: nginx:alpine
    imagePullPolicy: IfNotPresent
    name: nginx-demo
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-s6zj5
      readOnly: true
  dnsPolicy: ClusterFirst
```

_Delete it._

```console
$ kubectl delete pod nginx-demo
pod "nginx-demo" deleted from default namespace
```

---

## 5. Kubernetes Basics tutorial (hands-on)

This follows the six modules of the official *Kubernetes Basics* tutorial (kubernetes.io), using the same sample app, `kubernetes-bootcamp`.

### Module 1: Create a cluster
Done in sections 1 and 2. The cluster is running and `kubectl` talks to it.

_Client, server and node._

```console
$ kubectl version; kubectl get nodes
Client Version: v1.37.0
Kustomize Version: v5.8.1
Server Version: v1.37.0
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   25m   v1.37.0
```

### Module 2: Deploy an application

A **Deployment** tells Kubernetes how to create and update instances of my app. The control plane schedules the instances onto nodes.

_Create the Deployment._

```console
$ kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
deployment.apps/kubernetes-bootcamp created
```

_Wait until it is ready: 1/1 means 1 Pod is running out of 1 wanted._

```console
$ kubectl rollout status deployment/kubernetes-bootcamp --timeout=180s && kubectl get deployments
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 0 of 1 updated replicas are available...
deployment "kubernetes-bootcamp" successfully rolled out
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1/1     1            1           1s
```

_Pods run on a private network. kubectl proxy opens a tunnel from my machine to the cluster API; here I ask the API for its version, then stop the proxy._

```console
$ kubectl proxy --port=8001 >/dev/null 2>&1 & PID=$!; sleep 3; curl -s http://localhost:8001/version; kill $PID
{
  "major": "1",
  "minor": "37",
  "emulationMajor": "1",
  "emulationMinor": "37",
  "minCompatibilityMajor": "1",
  "minCompatibilityMinor": "36",
  "gitVersion": "v1.37.0",
  "gitCommit": "f54c212e3a2f75d674b717a9b29052b20b60aefc",
  "gitTreeState": "clean",
  "buildDate": "2026-08-26T10:44:25Z",
  "goVersion": "go1.26.6",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```

_Through the same API proxy I can reach the app inside the Pod directly (it answers with its Pod name and version)._

```console
$ export POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'); echo "Name of the Pod: $POD_NAME"; kubectl proxy --port=8001 >/dev/null 2>&1 & PID=$!; sleep 3; curl -s http://localhost:8001/api/v1/namespaces/default/pods/$POD_NAME:8080/proxy/; kill $PID
Name of the Pod: kubernetes-bootcamp-5cc66bcc9b-7qxb9
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-7qxb9 | v=1
```

### Module 3: Explore the application

A **Pod** is a group of containers with shared storage and a shared IP; it is the unit Kubernetes schedules.

_List the Pods._

```console
$ kubectl get pods
NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-5cc66bcc9b-7qxb9   1/1     Running   0          8s
```

_Detailed Pod information: IP, node, container image, ports, state, conditions (the Events follow below; first lines shown)._

```console
$ kubectl describe pods | head -n 40
Name:             kubernetes-bootcamp-5cc66bcc9b-7qxb9
Namespace:        default
Priority:         0
Service Account:  default
Node:             minikube/192.168.49.2
Start Time:       Sun, 18 Oct 2026 18:57:48 +0530
Labels:           app=kubernetes-bootcamp
                  pod-template-hash=5cc66bcc9b
Annotations:      <none>
Status:           Running
IP:               10.244.0.44
IPs:
  IP:           10.244.0.44
Controlled By:  ReplicaSet/kubernetes-bootcamp-5cc66bcc9b
Containers:
  kubernetes-bootcamp:
    Container ID:   containerd://191c29dce5ba7f169dbc68655d55c7b486143ad6f3abccddead90be256755fd0
    Image:          gcr.io/google-samples/kubernetes-bootcamp:v1
    Image ID:       gcr.io/google-samples/kubernetes-bootcamp@sha256:0d6b8ee63bb57c5f5b6156f446b3bc3b3c143d233037f3a2f00e279c8fcc64af
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Sun, 18 Oct 2026 18:57:49 +0530
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-4xq4z (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-4xq4z:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
```

_Everything the app wrote to stdout is the container log._

```console
$ kubectl logs $(kubectl get pods -o jsonpath="{.items[0].metadata.name}")
Kubernetes Bootcamp App Started At: 2026-10-18T13:27:49.237Z | Running On:  kubernetes-bootcamp-5cc66bcc9b-7qxb9 

Running On: kubernetes-bootcamp-5cc66bcc9b-7qxb9 | Total Requests: 1 | App Uptime: 7.335 seconds | Log Time: 2026-10-18T13:27:56.572Z
```

_Run a command in the container: its environment variables (the Service variables appear later when Services exist)._

```console
$ kubectl exec deploy/kubernetes-bootcamp -- env | head -n 8
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=kubernetes-bootcamp-5cc66bcc9b-7qxb9
NPM_CONFIG_LOGLEVEL=info
NODE_VERSION=6.3.1
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
KUBERNETES_SERVICE_HOST=10.96.0.1
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_PORT_HTTPS=443
```

_The app answers on port 8080 from inside its own Pod. (An interactive shell is `kubectl exec -ti <pod> -- bash`.)_

```console
$ kubectl exec deploy/kubernetes-bootcamp -- curl -s localhost:8080
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-7qxb9 | v=1
```

### Module 4: Expose the application publicly

A **Service** gives a set of Pods one stable address and load-balances over them. It finds its Pods with **labels**.

_Only the built-in kubernetes Service exists so far._

```console
$ kubectl get services
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   26m
```

_Create a Service of type NodePort: Kubernetes opens a port on the node and forwards it to the app on 8080._

```console
$ kubectl expose deployment/kubernetes-bootcamp --type="NodePort" --port 8080
service/kubernetes-bootcamp exposed
```

_The new Service has a ClusterIP and a node port in the 30000-32767 range._

```console
$ kubectl get services
NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kubernetes            ClusterIP   10.96.0.1      <none>        443/TCP          26m
kubernetes-bootcamp   NodePort    10.105.97.43   <none>        8080:30748/TCP   0s
```

_Selector, endpoints (the Pod IPs behind the Service) and the NodePort._

```console
$ kubectl describe services/kubernetes-bootcamp
Name:                     kubernetes-bootcamp
Namespace:                default
Labels:                   app=kubernetes-bootcamp
Annotations:              <none>
Selector:                 app=kubernetes-bootcamp
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.105.97.43
IPs:                      10.105.97.43
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  30748/TCP
Endpoints:                10.244.0.44:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>
```

_On the Docker driver the node IP is not reachable from Windows, so minikube service opens a tunnel and prints a local URL. curl through it reaches the app._

```console
$ minikube service kubernetes-bootcamp --url > /tmp/svc-url.txt 2>&1 & PID=$!; sleep 6; cat /tmp/svc-url.txt | grep http; curl -s $(grep -m1 -o 'http://[0-9.:]*' /tmp/svc-url.txt); kill $PID 2>/dev/null
http://127.0.0.1:53265
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-7qxb9 | v=1
```

**Labels** are key/value pairs on objects; Services, Deployments and `kubectl -l` all use them.

_The Deployment was labelled automatically with app=kubernetes-bootcamp._

```console
$ kubectl describe deployment kubernetes-bootcamp | grep -A1 Labels
Labels:                 app=kubernetes-bootcamp
Annotations:            deployment.kubernetes.io/revision: 1
--
  Labels:  app=kubernetes-bootcamp
  Containers:
```

_Query Pods and Services by label._

```console
$ kubectl get pods -l app=kubernetes-bootcamp; kubectl get services -l app=kubernetes-bootcamp
NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-5cc66bcc9b-7qxb9   1/1     Running   0          18s
NAME                  TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kubernetes-bootcamp   NodePort   10.105.97.43   <none>        8080:30748/TCP   7s
```

_Add a new label and select by it._

```console
$ kubectl label pods $(kubectl get pods -o jsonpath="{.items[0].metadata.name}") version=v1 && kubectl get pods -l version=v1 --show-labels
pod/kubernetes-bootcamp-5cc66bcc9b-7qxb9 labeled
NAME                                   READY   STATUS    RESTARTS   AGE   LABELS
kubernetes-bootcamp-5cc66bcc9b-7qxb9   1/1     Running   0          19s   app=kubernetes-bootcamp,pod-template-hash=5cc66bcc9b,version=v1
```

_Delete the Service by label._

```console
$ kubectl delete service -l app=kubernetes-bootcamp && kubectl get services
service "kubernetes-bootcamp" deleted from default namespace
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   26m
```

_The app is still running inside its Pod; only the external route is gone._

```console
$ kubectl exec deploy/kubernetes-bootcamp -- curl -s localhost:8080
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-7qxb9 | v=1
```

### Module 5: Scale the application

Scaling changes the number of replicas of the Deployment. Kubernetes creates or removes Pods, and a Service load-balances across them.

_The ReplicaSet created by the Deployment: DESIRED 1, CURRENT 1, READY 1._

```console
$ kubectl get rs
NAME                             DESIRED   CURRENT   READY   AGE
kubernetes-bootcamp-5cc66bcc9b   1         1         1       20s
```

_Re-create the Service (I deleted it) and scale to 4 replicas, then wait for the rollout._

```console
$ kubectl expose deployment/kubernetes-bootcamp --type=NodePort --port 8080 && kubectl scale deployments/kubernetes-bootcamp --replicas=4 && kubectl rollout status deployment/kubernetes-bootcamp --timeout=180s
service/kubernetes-bootcamp exposed
deployment.apps/kubernetes-bootcamp scaled
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 of 4 updated replicas are available...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 of 4 updated replicas are available...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 3 of 4 updated replicas are available...
deployment "kubernetes-bootcamp" successfully rolled out
```

_Four Pods, each with its own IP._

```console
$ kubectl get deployments; kubectl get pods -o wide
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   4/4     4            4           22s
NAME                                   READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
kubernetes-bootcamp-5cc66bcc9b-7qxb9   1/1     Running   0          23s   10.244.0.44   minikube   <none>           <none>
kubernetes-bootcamp-5cc66bcc9b-lrxs9   1/1     Running   0          2s    10.244.0.45   minikube   <none>           <none>
kubernetes-bootcamp-5cc66bcc9b-mt86n   1/1     Running   0          2s    10.244.0.46   minikube   <none>           <none>
kubernetes-bootcamp-5cc66bcc9b-w2b7h   1/1     Running   0          2s    10.244.0.47   minikube   <none>           <none>
```

_The Deployment now wants 4 replicas._

```console
$ kubectl describe deployments/kubernetes-bootcamp | grep -E "Replicas|Image"
Replicas:               4 desired | 4 updated | 4 total | 4 available | 0 unavailable
    Image:         gcr.io/google-samples/kubernetes-bootcamp:v1
  Available      True    MinimumReplicasAvailable
```

_Load balancing: eight requests to the Service name (resolved by cluster DNS) are spread over different Pods ("Running on:" changes)._

```console
$ kubectl exec deploy/kubernetes-bootcamp -- sh -c "for i in 1 2 3 4 5 6 7 8; do curl -s kubernetes-bootcamp:8080 | head -n 2 | tr \"\\n\" \" \"; echo; done"
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-w2b7h | v=1 
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-7qxb9 | v=1 
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-w2b7h | v=1 
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-w2b7h | v=1 
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-mt86n | v=1 
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-7qxb9 | v=1 
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-lrxs9 | v=1 
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5cc66bcc9b-7qxb9 | v=1 
```

_Scale down to 2: the extra Pods terminate._

```console
$ kubectl scale deployments/kubernetes-bootcamp --replicas=2 && kubectl rollout status deployment/kubernetes-bootcamp --timeout=120s; sleep 4; kubectl get pods
deployment.apps/kubernetes-bootcamp scaled
deployment "kubernetes-bootcamp" successfully rolled out
NAME                                   READY   STATUS        RESTARTS   AGE
kubernetes-bootcamp-5cc66bcc9b-7qxb9   1/1     Running       0          28s
kubernetes-bootcamp-5cc66bcc9b-lrxs9   1/1     Terminating   0          7s
kubernetes-bootcamp-5cc66bcc9b-mt86n   1/1     Running       0          7s
kubernetes-bootcamp-5cc66bcc9b-w2b7h   1/1     Terminating   0          7s
```

### Module 6: Update the application (rolling update and rollback)

A **rolling update** replaces Pods one by one, so the app stays available.

_Current image: version 1._

```console
$ kubectl describe pods | grep Image: | sort -u
    Image:          gcr.io/google-samples/kubernetes-bootcamp:v1
```

_Update to version 2 and watch the rollout._

```console
$ kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=docker.io/jocatalin/kubernetes-bootcamp:v2 && kubectl rollout status deployments/kubernetes-bootcamp --timeout=240s
deployment.apps/kubernetes-bootcamp image updated
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
deployment "kubernetes-bootcamp" successfully rolled out
```

_New Pods run the v2 image._

```console
$ kubectl get pods; kubectl describe pods | grep Image: | sort -u
NAME                                   READY   STATUS        RESTARTS   AGE
kubernetes-bootcamp-5b97597885-j5p8k   1/1     Running       0          1s
kubernetes-bootcamp-5b97597885-x9kz9   1/1     Running       0          2s
kubernetes-bootcamp-5cc66bcc9b-7qxb9   1/1     Terminating   0          31s
kubernetes-bootcamp-5cc66bcc9b-lrxs9   1/1     Terminating   0          10s
kubernetes-bootcamp-5cc66bcc9b-mt86n   1/1     Terminating   0          10s
kubernetes-bootcamp-5cc66bcc9b-w2b7h   1/1     Terminating   0          10s
    Image:          docker.io/jocatalin/kubernetes-bootcamp:v2
    Image:          gcr.io/google-samples/kubernetes-bootcamp:v1
```

_The app now reports v=2._

```console
$ kubectl exec deploy/kubernetes-bootcamp -- curl -s localhost:8080
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5b97597885-x9kz9 | v=2
```

_Kubernetes keeps revisions so I can go back._

```console
$ kubectl rollout history deployments/kubernetes-bootcamp
deployment.apps/kubernetes-bootcamp 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

**A failed update and rollback.** I deliberately use an image tag that does not exist:

_The new Pod cannot pull the image (ErrImagePull / ImagePullBackOff). Because it is a rolling update, the old healthy Pods are NOT removed, so the app stays up._

```console
$ kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=gcr.io/google-samples/kubernetes-bootcamp:v10 && sleep 15 && kubectl get pods
deployment.apps/kubernetes-bootcamp image updated
NAME                                   READY   STATUS             RESTARTS   AGE
kubernetes-bootcamp-556487b4d4-wg7gx   0/1     ImagePullBackOff   0          15s
kubernetes-bootcamp-5b97597885-j5p8k   1/1     Running            0          17s
kubernetes-bootcamp-5b97597885-x9kz9   1/1     Running            0          18s
kubernetes-bootcamp-5cc66bcc9b-7qxb9   1/1     Terminating        0          47s
kubernetes-bootcamp-5cc66bcc9b-lrxs9   1/1     Terminating        0          26s
kubernetes-bootcamp-5cc66bcc9b-mt86n   1/1     Terminating        0          26s
kubernetes-bootcamp-5cc66bcc9b-w2b7h   1/1     Terminating        0          26s
```

_rollout undo returns to the previous working revision._

```console
$ kubectl rollout undo deployments/kubernetes-bootcamp && kubectl rollout status deployments/kubernetes-bootcamp --timeout=180s && kubectl get pods
deployment.apps/kubernetes-bootcamp rolled back
deployment "kubernetes-bootcamp" successfully rolled out
NAME                                   READY   STATUS        RESTARTS   AGE
kubernetes-bootcamp-556487b4d4-wg7gx   0/1     Terminating   0          16s
kubernetes-bootcamp-5b97597885-j5p8k   1/1     Running       0          18s
kubernetes-bootcamp-5b97597885-x9kz9   1/1     Running       0          19s
kubernetes-bootcamp-5cc66bcc9b-7qxb9   1/1     Terminating   0          48s
kubernetes-bootcamp-5cc66bcc9b-lrxs9   1/1     Terminating   0          27s
kubernetes-bootcamp-5cc66bcc9b-mt86n   1/1     Terminating   0          27s
kubernetes-bootcamp-5cc66bcc9b-w2b7h   1/1     Terminating   0          27s
```

_Still the v2 app._

```console
$ kubectl exec deploy/kubernetes-bootcamp -- curl -s localhost:8080
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5b97597885-x9kz9 | v=2
```

### Cleanup

_Delete the Service and the Deployment (its ReplicaSet and Pods go with it)._

```console
$ kubectl delete service kubernetes-bootcamp && kubectl delete deployment kubernetes-bootcamp && sleep 3 && kubectl get all
service "kubernetes-bootcamp" deleted from default namespace
deployment.apps "kubernetes-bootcamp" deleted from default namespace
NAME                                       READY   STATUS        RESTARTS   AGE
pod/kubernetes-bootcamp-5b97597885-j5p8k   1/1     Terminating   0          23s
pod/kubernetes-bootcamp-5b97597885-x9kz9   1/1     Terminating   0          24s
pod/kubernetes-bootcamp-5cc66bcc9b-7qxb9   1/1     Terminating   0          53s
pod/kubernetes-bootcamp-5cc66bcc9b-lrxs9   1/1     Terminating   0          32s
pod/kubernetes-bootcamp-5cc66bcc9b-mt86n   1/1     Terminating   0          32s
pod/kubernetes-bootcamp-5cc66bcc9b-w2b7h   1/1     Terminating   0          32s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   26m
```

---

## What I learned

- Minikube gives a real single-node cluster on my laptop; the Docker driver makes the node a container.
- The control plane (apiserver, etcd, scheduler, controller-manager) stores and drives the **desired state**; kubelet and kube-proxy on the node make it real.
- A **Deployment** owns a ReplicaSet, which owns Pods; a **Service** finds Pods by **labels** and load-balances across them.
- Scaling is just changing `replicas`; rolling updates replace Pods gradually, and a bad update can be undone with `kubectl rollout undo`.
- On the Docker driver, NodePort is not directly reachable from the host: `minikube service --url` or `kubectl port-forward` is needed.
