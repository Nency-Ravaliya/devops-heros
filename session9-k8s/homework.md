# Kubernetes Fundamentals

Kubernetes (K8s) is a container orchestration platform used to deploy, manage, scale, and maintain containerized applications.

## Core Concepts

- Cluster: A group of machines running Kubernetes.
- Node: A machine (VM or physical) that runs workloads.
- Pod: The smallest deployable unit; usually contains one container.
- Deployment: Manages Pods and ensures the desired number of replicas are running.
- Service: Provides a stable network endpoint to access Pods.
- Namespace: Provides logical isolation within a cluster.
- ConfigMap: Stores non-sensitive configuration.
- Secret: Stores sensitive configuration such as passwords and tokens.
- Volume: Provides storage to Pods.
- Ingress: Routes external HTTP/HTTPS traffic to Services.
- Kubernetes Architecture

## A cluster has two main parts

### Control Plane

Responsible for managing the cluster.

- API Server: Entry point for all Kubernetes operations.
- etcd: Stores the cluster's state and configuration.
- Scheduler: Decides which Node should run a new Pod.
- Controller Manager: Continuously makes the actual cluster state match the desired state.
  
### Worker Node

Runs application workloads.

- Kubelet: Communicates with the API Server and manages Pods on the Node.
- Container Runtime: Runs containers, e.g. containerd.
- Kube-proxy: Handles networking and Service traffic.
- Pods: Run the actual application containers.