# Session 9: Kubernetes fundamentals

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

Install Minikube and kubectl using the official instructions for your platform:
https://minikube.sigs.k8s.io/docs/start/

```bash
minikube start --driver=docker
minikube status
kubectl cluster-info
kubectl get nodes -o wide
kubectl create namespace student9
kubectl -n student9 apply -f web.yaml -f service.yaml
kubectl -n student9 rollout status deployment/intro-web
kubectl -n student9 get pods,deploy,rs,svc -o wide
kubectl -n student9 describe deployment intro-web
kubectl -n student9 logs deployment/intro-web
kubectl -n student9 scale deployment intro-web --replicas=3
kubectl -n student9 set image deployment/intro-web web=nginx:alpine
kubectl -n student9 rollout status deployment/intro-web
kubectl -n student9 rollout undo deployment/intro-web
kubectl -n student9 port-forward svc/intro-web 18090:80
# In another terminal: curl http://127.0.0.1:18090
# Clean up: kubectl delete namespace student9
```

These steps follow the Kubernetes Basics sequence: create a cluster, deploy,
inspect, expose, scale, and update. Reference: https://kubernetes.io/docs/tutorials/kubernetes-basics/

```text
kubectl → API server → etcd (desired state)
                   → controllers (reconcile)
                   → scheduler (choose node)
worker: kubelet → container runtime → containers in Pods
        network plugin + service routing → Pod connectivity
```

A Pod is the smallest scheduling unit. A ReplicaSet maintains a replica count.
A Deployment manages ReplicaSets and rollouts. A Service provides discovery and
a stable endpoint for selected Pods. A namespace scopes names and helps isolate exercises.
`get` is a summary, `describe` includes detailed state/events, and `logs` reads container output.
Cluster execution is pending; see the verification notes below.

## Verification

Manifest syntax checked.

Minikube installation, cluster creation and hands-on tutorial need downloads and a cluster.
