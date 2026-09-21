# Kubernetes Cluster Architecture

A Kubernetes cluster has two main parts:

## 1. Control Plane (Master Node)

The Control Plane manages the whole Kubernetes cluster.

* **kube-apiserver – “Front Door”**

  * Main communication point of Kubernetes.
  * `kubectl` and other components communicate through it.
  * It receives requests and passes them to the required component.

* **etcd – “Database”**

  * Stores the cluster's information and current state.
  * It keeps details about Pods, Services, Secrets, configurations, etc.

* **kube-scheduler – “Pod Planner”**

  * Decides **which Worker Node should run a new Pod**.
  * Checks CPU, memory, and other requirements before choosing a node.

* **kube-controller-manager – “State Manager”**

  * Continuously checks whether the cluster is in the desired state.
  * For example, if 3 Pods are required but only 2 are running, it helps create another Pod.

## 2. Worker Nodes (Data Plane)

Worker Nodes are the machines where applications actually run.

* **kubelet – “Node Manager”**

  * Runs on every Worker Node.
  * Gets instructions from the API Server.
  * Starts and monitors Pods and containers.

* **kube-proxy – “Network Manager”**

  * Handles network communication between Services and Pods.
  * Helps route traffic to the correct Pod.

* **Container Runtime – “Container Runner”**

  * Actually runs the containers.
  * Common runtimes include **containerd** and **CRI-O**.
  * Kubernetes communicates with the runtime using CRI (Container Runtime Interface).

* **Pod – “Smallest Deployable Unit”**

  * The basic unit that runs applications in Kubernetes.
  * A Pod can contain one or more containers.
  * Containers inside a Pod share networking and storage.

### Simple Flow

**User → kube-apiserver → Scheduler/Controllers → Worker Node → kubelet → Container Runtime → Pod**

In short, **Control Plane manages the cluster, while Worker Nodes run the applications.**
