# Kubernetes Fundamentals

This guide covers Kubernetes architecture, Minikube installation, cluster verification, and essential CLI commands for the Kubernetes Fundamentals homework tasks.

---

## 1. Overview & Official Resources

* **Kubernetes Basics Tutorial:** [https://kubernetes.io/docs/tutorials/kubernetes-basics/](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
* **Minikube Installation Guide:** [https://minikube.sigs.k8s.io/docs/start/](https://minikube.sigs.k8s.io/docs/start/)
* **Kubernetes Architecture:** [https://kubernetes.io/docs/concepts/architecture/](https://kubernetes.io/docs/concepts/architecture/)
* **Course Repository:** [https://github.com/Nency-Ravaliya/Kubernetes](https://github.com/Nency-Ravaliya/Kubernetes)

---

## 2. Kubernetes Architecture Notes

Kubernetes follows a **Master-Worker (Control Plane - Worker Node)** architecture:

```text
                  +-------------------------------------------------+
                  |               CONTROL PLANE (MASTER)            |
                  |                                                 |
                  |   +-----------------+     +-----------------+   |
                  |   |   kube-apiserver| <-> |      etcd       |   |
                  |   +--------+--------+     +-----------------+   |
                  |            |                                    |
                  |   +--------+--------+     +-----------------+   |
                  |   |  kube-scheduler |     | kube-controller |   |
                  |   +-----------------+     |     manager     |   |
                  |                           +-----------------+   |
                  +-----------------------+-------------------------+
                                          |
                      +-------------------+-------------------+
                      |                                       |
                      v                                       v
        +---------------------------+           +---------------------------+
        |        WORKER NODE 1      |           |        WORKER NODE 2      |
        |                           |           |                           |
        |  +---------------------+  |           |  +---------------------+  |
        |  |       kubelet       |  |           |  |       kubelet       |  |
        |  +----------+----------+  |           |  +----------+----------+  |
        |             |             |           |             |             |
        |  +----------v----------+  |           |  +----------v----------+  |
        |  |     kube-proxy      |  |           |  |     kube-proxy      |  |
        |  +---------------------+  |           |  +---------------------+  |
        |                           |           |                           |
        |  +---------------------+  |           |  +---------------------+  |
        |  |  Container Runtime  |  |           |  |  Container Runtime  |  |
        |  |   (containerd/CRI)  |  |           |  |   (containerd/CRI)  |  |
        |  +----------+----------+  |           |  +----------+----------+  |
        |             |             |           |             |             |
        |      +------v------+      |           |      +------v------+      |
        |      | [Pod] [Pod] |      |           |      | [Pod] [Pod] |      |
        |      +-------------+      |           |      +-------------+      |
        +---------------------------+           +---------------------------+
```

### Control Plane Components
1. **kube-apiserver**: Front door of the cluster; exposes the Kubernetes API and validates/configures data for objects.
2. **etcd**: Consistent and highly-available key-value store holding all cluster state and configuration.
3. **kube-scheduler**: Watches for unscheduled pods and assigns them to optimal worker nodes based on resource requirements.
4. **kube-controller-manager**: Runs controller processes that continuously reconcile current state to desired state (Node Lifecycle, ReplicaSet, Endpoints).

### Worker Node Components
1. **kubelet**: Agent running on every node; ensures containers described in PodSpecs are running and healthy.
2. **kube-proxy**: Network proxy maintaining network rules to route incoming traffic across pods.
3. **Container Runtime**: The underlying software that executes containers (e.g., containerd, CRI-O).

---

## 3. Hands-on Tasks & Commands

### Task 1: Install and Configure Minikube
```bash
# 1. Download and install Minikube binary (Linux amd64)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# 2. Start Minikube cluster using Docker driver
minikube start --driver=docker
```

### Task 2: Verify Cluster Status
```bash
# Check Minikube status
minikube status

# Check Kubernetes cluster info
kubectl cluster-info

# List active cluster nodes
kubectl get nodes -o wide
```

### Task 3: Basic Kubernetes Objects & Commands
```bash
# Run a test Nginx Pod
kubectl run test-nginx --image=nginx:alpine --port=80

# Verify Pod status
kubectl get pods -o wide

# Describe Pod details
kubectl describe pod test-nginx

# Expose Pod via NodePort Service
kubectl expose pod test-nginx --type=NodePort --port=80

# List services
kubectl get svc

# View pod logs
kubectl logs test-nginx

# Clean up
kubectl delete pod test-nginx
kubectl delete svc test-nginx
```

---

## 4. Deliverables & Screenshot Evidence

> [!NOTE]
> Add your execution screenshots into `screenshots/` and link them in the sections below:

### Screenshot 1: Minikube Start & Cluster Status
*Command:* `minikube status && kubectl cluster-info`  
*(Insert Screenshot Below)*  
<!-- Add screenshot: ![Minikube Status](screenshots/minikube-status.png) -->

### Screenshot 2: Node Verification
*Command:* `kubectl get nodes -o wide`  
*(Insert Screenshot Below)*  
<!-- Add screenshot: ![Kubectl Nodes](screenshots/kubectl-nodes.png) -->

### Screenshot 3: Pod Deployment & Verification
*Command:* `kubectl get pods -o wide && kubectl describe pod test-nginx`  
*(Insert Screenshot Below)*  
<!-- Add screenshot: ![Pod Verification](screenshots/pod-verification.png) -->