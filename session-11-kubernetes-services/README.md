# Kubernetes Networking & Services

**Name:** Shreyas S
**Enrollment number:** 10401
**GitHub:** [NeuralSynth](https://github.com/NeuralSynth)

> **Execution status:** Manifests and exercises prepared. Cluster execution and actual output are pending because Docker Desktop / Minikube is stopped. This page does not claim a successful cluster run.

[services.yaml](services.yaml) creates a two-replica Nginx Deployment, a BusyBox client and five Service configurations.

| Service | Behaviour | Exercise |
| --- | --- | --- |
| `web-clusterip` | Stable virtual IP inside the cluster | Resolve DNS, request HTTP, inspect EndpointSlices |
| `web-nodeport` | Also exposes an allocated node port | Request the node's InternalIP and allocated NodePort |
| `web-loadbalancer` | Requests an external load balancer | Inspect status and request its internal Service address |
| `external-docs` | DNS CNAME to `kubernetes.io` | Inspect DNS; no proxy or selector is created |
| `web-headless` | `clusterIP: None`, DNS returns Pod addresses | Compare DNS results to the ClusterIP Service |

## Exercise

The runner checks DNS and HTTP from the client Pod, verifies the NodePort path, deliberately changes the ClusterIP selector so no Pods match, verifies empty EndpointSlices, then restores the original selector in a `finally` block.

```bash
kubectl --context devops-homework -n rudray-devops-hw get svc -o wide
kubectl --context devops-homework -n rudray-devops-hw get endpointslices -l kubernetes.io/service-name=web-clusterip
kubectl --context devops-homework -n rudray-devops-hw exec network-client -- nslookup web-clusterip.rudray-devops-hw.svc.cluster.local
kubectl --context devops-homework -n rudray-devops-hw exec network-client -- wget -qO- http://web-clusterip
```

A Service's `port` is the client-facing port, `targetPort` selects the container port, and `nodePort` is the node-level listener. Selectors and readiness determine the ready endpoints. Service names resolve through CoreDNS; short names search the caller's namespace.

## Local LoadBalancer access

Minikube has no cloud load balancer by default, so the external IP can remain `<pending>`. `minikube tunnel -p devops-homework` supplies local routing and may request administrator access. The automated exercise checks the internal Service and NodePort paths; this alone is **not evidence of an externally provisioned load balancer**. On Docker Desktop for macOS, node addresses are inside a VM; `minikube service web-nodeport -n rudray-devops-hw -p devops-homework --url` can provide a host-accessible tunnel.

An ExternalName is only a DNS alias. HTTPS still needs a hostname matching the remote certificate, and HTTP services may require the original Host header. A headless Service does not allocate a virtual IP; a StatefulSet can use it for stable per-Pod DNS.

## Run and capture actual output

From the repository root, after Docker Desktop is running:

```bash
minikube start -p devops-homework --driver=docker --cpus=2 --memory=3072
minikube addons enable ingress -p devops-homework
python3 scripts/run-kubernetes-labs.py --context devops-homework --topic 11
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
