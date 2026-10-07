# Kubernetes Architecture & Core Components

Kubernetes (K8s) is an orchestration system designed to automate deploying, scaling, and managing containerized applications. A Kubernetes cluster is split into two major parts:
1. **Control Plane (Master Node):** The "Brain" that makes decisions.
2. **Worker Nodes:** The site where your applications (containers) actually run.

---

## 1. Control Plane Components (The Brain)

### kube-apiserver
* **What it does:** The front door to the cluster. Every command (from `kubectl`, UI, or other components) must go through the API server.
* **Key Role:** It authenticates requests (who are you?), authorizes them (are you allowed to do this?), and validates data before writing to storage.
* **Interview Note:** *It is the only component that directly talks to `etcd`.*

### etcd 
* **What it does:** A distributed, highly consistent key-value store.
* **Key Role:** Holds the entire cluster state, configuration, and secrets. If it's not saved in `etcd`, Kubernetes doesn't know it exists.
* **Interview Note:** Always backed up in production. If `etcd` is lost without backups, your cluster is gone.

### kube-scheduler 
* **What it does:** Watches for newly created Pods that don't have a node assigned yet.
* **Key Role:** Evaluates worker nodes based on resource limits (CPU/RAM), taints, tolerations, and affinity rules, then assigns the Pod to the best-suited node.
* **Interview Note:** The scheduler *only decides* where the pod goes; it does not actually launch the container.

### kube-controller-manager 
* **What it does:** Runs continuous control loops (the reconciliation loop).
* **Key Role:** Constantly compares the **current state** with the **desired state**. If a node dies, or if you requested 3 replicas of a pod and only 2 are running, it triggers actions to bring the count back to 3.
* **Interview Note:** Groups controllers together into one binary (Node Controller, Replication Controller, Endpoints Controller, etc.).

---

## 2. Worker Node Components 

### kubelet 
* **What it does:** An agent running on every single worker node.
* **Key Role:** Takes Pod specifications (`PodSpec`) sent by the API server and tells the container runtime to start/stop the containers. It continuously checks pod health and reports status back to the API server.
* **Interview Note:** Kubelet does not manage containers directly; it issues commands to the container runtime via CRI (Container Runtime Interface).

### kube-proxy 
* **What it does:** Runs on each node to manage network routing and rules.
* **Key Role:** Maintains network rules on host OS (using `iptables` or `IPVS`) so that internal cluster traffic gets routed correctly to pods behind a Kubernetes Service.

### Container Runtime
* **What it does:** The underlying software that downloads images and runs containers (e.g., `containerd`, `CRI-O`).

---

## minikube basics tutorial

![Minikube Screenshot 1](screenshots/Screenshot%20(16).png)

![Minikube Screenshot 2](screenshots/Screenshot%20(17).png)

![Minikube Screenshot 3](screenshots/Screenshot%20(18).png)

![Minikube Screenshot 4](screenshots/Screenshot%20(19).png)

![Minikube Screenshot 5](screenshots/Screenshot%20(20).png)

![Minikube Screenshot 6](screenshots/Screenshot%20(21).png)

![Minikube Screenshot 7](screenshots/Screenshot%20(22).png)

![Minikube Screenshot 8](screenshots/Screenshot%20(23).png)

![Minikube Screenshot 9](screenshots/Screenshot%20(24).png)

![Minikube Screenshot 10](screenshots/Screenshot%20(25).png)

![Minikube Screenshot 11](screenshots/Screenshot%20(26).png)

![Minikube Screenshot 12](screenshots/Screenshot%20(27).png)

