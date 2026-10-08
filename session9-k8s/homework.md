# Kubernetes Architecture & Core Components

Kubernetes (K8s) is a container orchestration platform used to **deploy, scale, and manage containerized applications**.

A Kubernetes cluster has two main parts:

* **Control Plane:** Makes decisions and manages the cluster.
* **Worker Nodes:** Run the application Pods and containers.

## 1. Control Plane

### kube-apiserver

The **entry point** to the cluster. Handles authentication, authorization, validation, and communication with `etcd`.

**Key point:** The API server is the only component that directly communicates with `etcd`.

### etcd

A distributed key-value store containing the **cluster's state, configuration, and secrets**.

**Key point:** It acts as Kubernetes' source of truth and should be backed up.

### kube-scheduler

Finds suitable worker nodes for newly created Pods based on resources, taints, affinity, and other constraints.

**Key point:** It decides *where* a Pod runs but doesn't start it.

### kube-controller-manager

Runs control loops that continuously compare the **desired state** with the **actual state** and take corrective action.

---

## 2. Worker Node Components

### kubelet

Agent running on each worker node. Ensures Pods are running and communicates with the container runtime through **CRI**.

### kube-proxy

Maintains networking rules that route traffic from Kubernetes **Services** to the appropriate Pods.

### Container Runtime

Software responsible for **pulling images and running containers**.

Examples:

* `containerd`
* `CRI-O`

---

## Quick Summary

| Component              | Main Responsibility        |
| ---------------------- | -------------------------- |
| **API Server**         | Cluster entry point        |
| **etcd**               | Stores cluster state       |
| **Scheduler**          | Assigns Pods to nodes      |
| **Controller Manager** | Maintains desired state    |
| **Kubelet**            | Manages Pods on nodes      |
| **kube-proxy**         | Handles Service networking |
| **Container Runtime**  | Runs containers            |

![Minikube start and status](<Screenshot 2026-09-17 at 10.58.14 PM.png>)