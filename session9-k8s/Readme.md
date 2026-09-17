# Session 9 - Kubernetes Fundamentals Homework

## Task 1: Install Minikube and verify the cluster

```bash
minikube start
```

Output:
```text
* minikube v1.39.0 on Darwin 27.0 (arm64)
* Using the docker driver based on existing profile
* Starting "minikube" primary control-plane node in "minikube" cluster
* Pulling base image v0.0.51 ...
* Preparing Kubernetes v1.37.0 on containerd 2.3.4 ...
* Verifying Kubernetes components...
  - Using image gcr.io/k8s-minikube/storage-provisioner:v5
* Enabled addons: default-storageclass, storage-provisioner
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

```bash
minikube status
```

Output:
```text
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

```bash
kubectl get nodes
```

Output:
```text
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   10d   v1.37.0
```

```bash
kubectl get pods -n kube-system
```

Output:
```text
NAME                               READY   STATUS    RESTARTS   AGE
coredns-559f6c778d-br8ff           1/1     Running   4          10d
etcd-minikube                      1/1     Running   4          10d
kindnet-shsrg                      1/1     Running   4          10d
kube-apiserver-minikube            1/1     Running   4          10d
kube-controller-manager-minikube   1/1     Running   4          10d
kube-proxy-8td68                   1/1     Running   4          10d
kube-scheduler-minikube            1/1     Running   4          10d
storage-provisioner                1/1     Running   7          10d
```

`minikube stop` shuts the cluster down again once done (not run here so the cluster stays up for the next session's homework).

---

## Task 2: Kubernetes cluster architecture

A Kubernetes cluster is split into a **control plane** (the "master") and one or more **worker nodes**.

### Control plane components

| Component | Role |
|---|---|
| **etcd** | Key-value store that holds the entire state of the cluster — every object (pods, deployments, secrets, configmaps, ...) and its current status is persisted here. If etcd is lost, the cluster's state is lost. |
| **kube-apiserver** | The front door of the cluster. Every `kubectl` command, and every other component, talks to the cluster only through the API server — nothing talks to etcd directly. It validates and processes REST requests and updates etcd. |
| **kube-scheduler** | Watches for newly created pods that have no node assigned yet, and decides which worker node they should run on based on available resources (CPU/memory), taints/tolerations, affinity rules, etc. It only *decides* — it does not actually start the pod. |
| **kube-controller-manager** | Runs the various controllers that keep the cluster in its desired state. E.g. the **node controller** watches whether nodes are up, the **replicaset controller** makes sure the number of running pod replicas matches what's declared (if I ask for 5 pods and only 3 are running, it creates 2 more; if there are 7, it kills 2). |
| **cloud-controller-manager** | Same idea as the controller manager, but for controllers that are specific to a cloud provider (e.g. provisioning a cloud load balancer for a `LoadBalancer` service). Not used when running locally on Minikube. |

### Node (worker) components

| Component | Role |
|---|---|
| **kubelet** | The agent that runs on every worker node. It talks to the API server, receives instructions on what containers should be running on this node, and makes sure they actually are — it also sends a periodic heartbeat back to the API server reporting each container/pod's health. |
| **kube-proxy** | Handles the networking side on each node — implements the Service abstraction (ClusterIP/NodePort/etc.) via IP tables/IPVS rules, so traffic to a Service gets routed to the correct pod. |
| **Container runtime (CRI)** | The actual software that pulls images and runs containers on the node. Minikube uses `containerd` by default. |

### How it fits together (example: `kubectl get pods`)

1. `kubectl` sends the request to the **API server**.
2. API server authenticates/validates it and reads/writes the result from/to **etcd**.
3. When a new pod is created, the **scheduler** picks a node for it and writes that decision back through the API server.
4. The **kubelet** on that node sees (via the API server) that it now owns a new pod, and asks the **container runtime** to actually start the container.
5. The kubelet keeps sending heartbeats to the API server so the **controllers** know the pod is alive and can react (e.g. recreate it) if it isn't.

The **Pod** is the smallest deployable unit in Kubernetes — it wraps one or more containers that share networking/storage.

### Resources
- https://kubernetes.io/docs/tutorials/kubernetes-basics/
- https://kubernetes.io/docs/concepts/architecture/
- https://minikube.sigs.k8s.io/docs/start/?arch=%2Fmacos%2Farm64%2Fstable%2Fbinary+download
- https://github.com/Nency-Ravaliya/Kubernetes
