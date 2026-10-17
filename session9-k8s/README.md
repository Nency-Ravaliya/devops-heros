# Kubernetes Fundamentals

**Name:** Shreyas S
**Enrollment number:** 10401
**GitHub:** [NeuralSynth](https://github.com/NeuralSynth)

> **Execution status:** Manifests and exercises prepared. Cluster execution and actual output are pending because Docker Desktop / Minikube is stopped. This page does not claim a successful cluster run.

Kubernetes reconciles a desired state stored through its API. The API server accepts requests, etcd stores cluster state, the scheduler assigns Pods to nodes, and controllers continuously reconcile objects. Each node runs a kubelet and container runtime; cluster networking and DNS let Pods find services.

A Pod is the smallest scheduling unit. Containers in one Pod share networking and can share volumes. A Deployment adds replica management and controlled updates. A namespace groups namespaced resources; it does not itself enforce network isolation.

## Files and exercise

- [namespace.yaml](namespace.yaml) creates the dedicated `rudray-devops-hw` namespace.
- [pod.yaml](pod.yaml) runs Nginx with a readiness probe and resource requests/limits.
- The runner checks client version, cluster information, nodes and system Pods, then creates the Pod, waits for readiness, requests its web page and reads its logs.

## Commands to practise

```bash
kubectl --context devops-homework cluster-info
kubectl --context devops-homework get nodes -o wide
kubectl --context devops-homework get pods -n kube-system
kubectl --context devops-homework -n rudray-devops-hw describe pod hello-kubernetes
kubectl --context devops-homework -n rudray-devops-hw logs hello-kubernetes
```

`get` lists state, `describe` adds events and configuration, `logs` reads container stdout/stderr, and `exec` runs a command in a container. A Pod being `Running` does not guarantee it is `Ready`; readiness determines whether it should receive Service traffic.

## Run and capture actual output

From the repository root, after Docker Desktop is running:

```bash
minikube start -p devops-homework --driver=docker --cpus=2 --memory=3072
minikube addons enable ingress -p devops-homework
python3 scripts/run-kubernetes-labs.py --context devops-homework --topic 09
```

The runner saves commands, actual stdout/stderr and exit codes to `OUTPUT.md` in this folder. It marks success only after the checks finish. All resources are limited to the `rudray-devops-hw` namespace; the ingress addon is cluster-wide in this dedicated Minikube profile.

After finishing all four topics, remove the assignment resources:

```bash
kubectl --context devops-homework delete namespace rudray-devops-hw
```

## References

- [Instructor course repository](https://github.com/Nency-Ravaliya/devops-heros)
- [Kubernetes concepts](https://kubernetes.io/docs/concepts/)
- [Submission index](../../README.md)
