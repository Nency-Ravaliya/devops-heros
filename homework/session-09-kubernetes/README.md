# Session 9 — Kubernetes fundamentals

Student: Viraj Bhanage, roll 24BCS10274

## Architecture

A cluster has a control plane and worker nodes.

- **API server** is the front door. `kubectl` talks to it.
- **etcd** stores cluster state.
- **scheduler** picks a node for each new Pod.
- **controller manager** reconciles Deployments, ReplicaSets, Jobs, and other objects toward the spec.
- **kubelet** on each node starts containers through the runtime (containerd).
- **kube-proxy** (or the CNI equivalent) programs Service routing.

A Pod is the smallest object you run. A Service gives Pods a stable virtual IP and DNS name. A Deployment keeps a desired replica count and rolls out new Pod templates.

## Install Minikube on this Mac

`minikube` is not installed yet. Docker Desktop is installed. Either enable Kubernetes in Docker Desktop (Settings → Kubernetes → Enable) or install Minikube:

```bash
brew install minikube kubectl
minikube start --driver=docker
minikube status
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
minikube addons enable metrics-server
minikube addons enable ingress
```

## Commands to capture for the screenshot set

```bash
kubectl get nodes -o wide
kubectl get ns
kubectl explain pod
kubectl explain deployment.spec.replicas
kubectl run hello --image=nginx:1.27-alpine --port=80
kubectl get pods -o wide
kubectl expose pod hello --port=80 --type=NodePort
minikube service hello --url
kubectl delete pod hello
```

Paste that output into this file after the cluster is up. The later session YAML in `homework/session-10-deployments` through `session-15-helm` is what you apply on this cluster.
