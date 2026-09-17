# Session 9: Kubernetes Fundamentals & Cluster Architecture

**Author:** Isha Patel
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
![alt text](image.png)

## Task 2: Starting the Minikube Kubernetes Cluster

Initialize the local single-node Kubernetes cluster using the containerized runtime environment.

**Command:**

```bash
minikube start
```

**Output:**
![alt text](image-1.png)


---

## Task 3: Verifying Cluster Status & Node Health

Inspect the status of the local cluster control plane, kubelet, API server, and verify the node is in `Ready` state.

**Commands:**

```bash
minikube status
kubectl get nodes -o wide
kubectl cluster-info
```

**Output:**

![alt text](image-2.png)

---

## Task 4: Stopping the Minikube Cluster

Gracefully power down the Minikube cluster VM/container to release system resources.

**Command:**

```bash
minikube stop
minikube status
```

**Output:**

![alt text](image-3.png)

---

## Task 5: Kubernetes Cluster Architecture & Component Analysis

# Kubernetes Architecture

Kubernetes follows a client-server architecture and is mainly divided into two parts:

1. **Control Plane**
2. **Worker Nodes**

The Control Plane manages the cluster, while Worker Nodes run the applications inside containers. Both parts work together to maintain the desired state of the application.

---

## Control Plane

The Control Plane acts as the brain of a Kubernetes cluster. It receives instructions from the user, makes decisions about where applications should run, and keeps track of the overall cluster state.

### Main Components

#### 1. kube-apiserver

The `kube-apiserver` is the main communication point of the cluster. Whenever we use commands such as `kubectl get pods` or `kubectl create`, the request is sent to the API server.

It validates the request and communicates with other Kubernetes components when necessary.

#### 2. etcd

`etcd` is the database used by Kubernetes to store important cluster information. This includes configuration, node details, Pod information, and the desired state of resources.

In simple terms, etcd helps Kubernetes remember how the cluster is supposed to look.

#### 3. kube-scheduler

The `kube-scheduler` decides which Worker Node should run a newly created Pod.

It considers factors such as available resources, node conditions, and scheduling requirements before assigning the Pod to a node.

#### 4. kube-controller-manager

The `kube-controller-manager` runs different controllers that continuously monitor the cluster.

For example, if a Deployment requires three replicas but only two Pods are running, the controller notices the difference and works toward creating the missing Pod.

#### 5. cloud-controller-manager

The `cloud-controller-manager` is used when Kubernetes interacts with a cloud provider.

It manages cloud-specific resources such as load balancers, cloud-based networks, and cloud nodes. This component may not be required in a basic local Minikube setup.

---

## Worker Node

Worker Nodes are the machines where the actual application workloads run. A cluster can have one or more Worker Nodes depending on its size and requirements.

Applications are deployed inside units called Pods, and these Pods run on Worker Nodes.

### Main Components

#### 1. kubelet

The `kubelet` is an agent that runs on every Worker Node. Its responsibility is to make sure that the containers described in the Pod specification are running properly.

It communicates with the Control Plane and reports the status of Pods and containers.

#### 2. Container Runtime

The container runtime is responsible for creating and running containers.

Examples include containerd and CRI-O. In this assignment, Docker is being used as the Minikube driver, which allows Minikube to run the local Kubernetes environment using Docker.

#### 3. kube-proxy

`kube-proxy` manages network-related rules on the node. It helps route traffic to the correct Pods and allows Kubernetes Services to communicate with application workloads.

#### 4. Pods

A Pod is the smallest deployable unit in Kubernetes. It usually contains one application container, although it can contain multiple closely related containers.

Containers inside the same Pod share the same network namespace and can communicate with each other through `localhost`.

---

## How the Control Plane and Worker Nodes Work Together

The different Kubernetes components work together in the following way:

1. The user sends a command using `kubectl`.
2. The request reaches the `kube-apiserver`.
3. The API server validates the request and stores the updated cluster state in `etcd`.
4. If a new Pod needs to be created, the `kube-scheduler` selects a suitable Worker Node.
5. The `kubelet` on that Worker Node receives the Pod instructions.
6. The container runtime starts the required container or containers.
7. `kube-proxy` helps manage the networking required to access the application.
8. The kubelet continuously monitors the Pod and reports its status to the API server.
9. Controllers compare the actual state with the desired state and take corrective action whenever there is a difference.

For example, if we request three replicas of an application, Kubernetes continuously tries to ensure that three Pods remain available. If one Pod fails, Kubernetes can create another one to maintain the desired state.

---

## Simple Architecture Diagram

```text
                    User / kubectl
                           |
                           v
                    kube-apiserver
                           |
          -------------------------------------
          |                |                  |
          v                v                  v
        etcd       kube-scheduler     controller-manager
                           |
                           v
                    Worker Node
          --------------------------------
          |              |               |
        kubelet       kube-proxy    Container Runtime
          |                              |
          v                              v
                         Pods
                  [Application Containers]
```

---
