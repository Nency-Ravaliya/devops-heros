# Session 9: Kubernetes Fundamentals & Cluster Architecture

**Author:** Durga Prasad  
**Enrollment Number:** 10012  
**Course:** SST DevOps & Cloud [SWE]  
**Session:** 09 - Kubernetes Fundamentals  
**Repository:** devops-heros / session9-k8s

---

## Task 1: Minikube & CLI Installation Verification

Verify that Minikube and the Kubernetes CLI (`kubectl`) are successfully installed on the local system.

**Commands:**
```bash
minikube version
kubectl version --client
```

**Output:**
```
minikube version: v1.39.0
commit: 7a9f6a841470a207de8cf4bafcccee0969d8ba10

Client Version: v1.36.3
Kustomize Version: v5.8.1
```

**Screenshot:** `![Minikube and Kubectl Version](./screenshots/01-version-check.png)`

---

## Task 2: Starting the Minikube Kubernetes Cluster

Initialize the local single-node Kubernetes cluster using the containerized runtime environment.

**Command:**
```bash
minikube start
```

**Output:**
```
😄  minikube v1.39.0 on Ubuntu 24.04 (amd64)
✨  Automatically selected the docker driver
👍  Starting "minikube" primary control-plane node in "minikube" cluster
🔥  Creating docker container (CPUs=2, Memory=4000MB)
🐳  Preparing Kubernetes v1.37.0 on containerd 2.3.4
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring bridge CNI (Container Network Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

**Screenshot:** `![Minikube Start](./screenshots/02-minikube-start.png)`

---

## Task 3: Verifying Cluster Status & Node Health

Inspect the status of the local cluster control plane, kubelet, API server, and verify the node is in `Ready` state.

**Commands:**
```bash
minikube status
kubectl get nodes -o wide
```

**Output:**
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION           CONTAINER-RUNTIME
minikube   Ready    control-plane   17d   v1.37.0   192.168.49.2   <none>        Debian GNU/Linux 12 (bookworm)   6.8.0-88-generic (amd64) containerd://2.3.4
```

**Screenshot:** `![Minikube Status and Nodes](./screenshots/03-minikube-status.png)`

---

## Task 4: Stopping the Minikube Cluster

Gracefully power down the Minikube cluster to release system resources.

**Command:**
```bash
minikube stop
minikube status
```

**Output:**
```
✋  Stopping node "minikube" ...
🛑  Powering off "minikube" via SSH ...
🛑  1 node stopped.

minikube
type: Control Plane
host: Stopped
kubelet: Stopped
apiserver: Stopped
kubeconfig: Configured
```

**Screenshot:** `![Minikube Stop](./screenshots/04-minikube-stop.png)`

---

## Task 5: Kubernetes Cluster Architecture & Component Analysis

```
+-------------------------------------------------------------------------------+
|                          CONTROL PLANE (MASTER)                               |
|                                                                               |
|   +-------------------+     +--------------------+     +--------------+      |
|   |       etcd        |<--->|   kube-apiserver   |<--->|kube-scheduler|      |
|   | (State Database)  |     |    (Front Door)    |     +--------------+      |
|   +-------------------+     +---------+----------+                           |
|                                       |                                       |
|                                       v                                       |
|                         +------------------------+                            |
|                         | kube-controller-manager|                            |
|                         +------------------------+                            |
+---------------------------------------+---------------------------------------+
                                        |
              +-------------------------+-------------------------+
              |                                                   |
              v                                                   v
+----------------------------------+     +----------------------------------+
|          WORKER NODE 1           |     |          WORKER NODE 2           |
|  +----------+  +-----------+     |     |  +----------+  +-----------+     |
|  |  kubelet |  | kube-proxy|     |     |  |  kubelet |  | kube-proxy|     |
|  +----+-----+  +-----+-----+     |     |  +----+-----+  +-----+-----+     |
|       |              |           |     |       |              |            |
|       v              v           |     |       v              v            |
|  +----------------------------+  |     |  +----------------------------+   |
|  | CRI (containerd runtime)   |  |     |  | CRI (containerd runtime)   |   |
|  +----------------------------+  |     |  +----------------------------+   |
|  | Pod 1 [Container]          |  |     |  | Pod 3 [Container]          |   |
|  | Pod 2 [Container]          |  |     |  | Pod 4 [Container]          |   |
+----------------------------------+     +----------------------------------+
```

### Control Plane Components

| Component | Role |
|---|---|
| `kube-apiserver` | Single entry point for all administrative tasks. Exposes the K8s REST API. All `kubectl` commands go through it. |
| `etcd` | Distributed key-value store. Stores entire cluster state, secrets, and configuration. |
| `kube-scheduler` | Watches for new pods with no assigned node. Selects the best node based on resource requirements, taints, and affinities. |
| `kube-controller-manager` | Runs control loops: Node Controller, ReplicaSet Controller, Endpoint Controller. Ensures **Current State == Desired State**. |

### Worker Node Components

| Component | Role |
|---|---|
| `kubelet` | Primary agent on each node. Receives PodSpec from API server, instructs CRI to pull images and start containers. |
| `kube-proxy` | Maintains `iptables`/IPVS rules on each node. Enables Services to route traffic to pods. |
| `Container Runtime (containerd)` | Actually runs containers. Kubernetes uses CRI (Container Runtime Interface) standard. |
| `Pod` | Smallest deployable unit. Contains 1+ containers sharing same network namespace and storage volumes. |