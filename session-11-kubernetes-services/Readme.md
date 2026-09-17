# Session 11 - Kubernetes Networking & Services Homework

## Task 1: Run all 5 Service type demos

### ClusterIP (`01-clusterip/`)
```bash
kubectl apply -f 01-clusterip/app-deployment.yaml
kubectl apply -f 01-clusterip/service.yaml
kubectl apply -f 01-clusterip/client-pod.yaml
kubectl get endpoints web-service-clusterip
```
```text
NAME                    ENDPOINTS
web-service-clusterip   10.244.0.10:80,10.244.0.19:80,10.244.0.8:80
```
Verified from inside the cluster (only place it's reachable — that's the whole point of ClusterIP):
```bash
kubectl exec -it curl-client -- curl -s http://web-service-clusterip:8080
kubectl exec -it curl-client -- curl -s http://web-service-clusterip.default.svc.cluster.local:8080
```
Both returned `<title>Welcome to nginx!</title>` — service-name and FQDN both resolve to the same VIP.

### NodePort (`02-nodeport/`)
```bash
kubectl apply -f 02-nodeport/app-deployment.yaml
kubectl apply -f 02-nodeport/service.yaml
```
```text
NAME                   TYPE       CLUSTER-IP      PORT(S)
web-service-nodeport   NodePort   10.99.171.166   80:30080/TCP
```
Verified it's reachable on the **node's** IP on the high port (not just from inside the cluster like ClusterIP):
```bash
kubectl run nptest --image=curlimages/curl --restart=Never --rm -i -- curl -s http://192.168.49.2:30080
```
Returned `<title>Welcome to nginx!</title>`. Also confirmed via `kubectl port-forward svc/web-service-nodeport 18040:80` from the host.

### LoadBalancer (`03-loadbalancer/`)
```bash
kubectl apply -f 03-loadbalancer/app-deployment.yaml
kubectl apply -f 03-loadbalancer/service.yaml
```
```text
NAME                       TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)
web-service-loadbalancer   LoadBalancer   10.102.101.176   127.0.0.1     80:31809/TCP
```
On Minikube there's no real cloud load balancer, so `minikube tunnel` (or `minikube service`) is required to actually populate `EXTERNAL-IP`; verified the service itself is correctly wired via `kubectl port-forward svc/web-service-loadbalancer` — same `Welcome to nginx!` response. On a real cloud provider (EKS/GKE/AKS), the `cloud-controller-manager` provisions an actual external load balancer for this `EXTERNAL-IP` automatically.

### ExternalName (`04-externalname/`)
```bash
kubectl apply -f 04-externalname/service.yaml
kubectl apply -f 04-externalname/client-pod.yaml
kubectl exec -it dns-test-client -- nslookup external-database-service
```
```text
external-database-service.default.svc.cluster.local  canonical name = nencyravaliya.me
```
No selector, no pods, no ClusterIP — it's a pure DNS-level CNAME redirect. Used when a workload inside the cluster needs to reach something **outside** the cluster (an external DB, a third-party API) through an internal, in-cluster-style name.

### Headless (`05-headless/`)
```bash
kubectl apply -f 05-headless/service.yaml       # clusterIP: None
kubectl apply -f 05-headless/app-statefulset.yaml
kubectl get pods -l app=web-headless
```
```text
NAME             READY   STATUS
web-stateful-0   1/1     Running
web-stateful-1   1/1     Running
web-stateful-2   1/1     Running
```
Note the **ordered, stable pod names** (`-0`, `-1`, `-2`) — this is what a StatefulSet gives you that a Deployment doesn't.

```bash
kubectl apply -f 05-headless/client-pod.yaml
kubectl exec -it headless-dns-client -- nslookup web-service-headless
```
```text
Name: web-service-headless.default.svc.cluster.local   Address: 10.244.0.87
Name: web-service-headless.default.svc.cluster.local   Address: 10.244.0.85
Name: web-service-headless.default.svc.cluster.local   Address: 10.244.0.86
```
This is the key difference from every other Service type above: a normal Service's DNS name resolves to **one** virtual IP that kube-proxy load-balances behind. A **headless** Service's DNS name resolves directly to **all** matching pod IPs (3 separate A records) — no VIP, no load balancing.

Each pod also gets its own individually addressable name:
```bash
kubectl exec -it headless-dns-client -- nslookup web-stateful-0.web-service-headless.default.svc.cluster.local
# Name: web-stateful-0.web-service-headless.default.svc.cluster.local   Address: 10.244.0.85
```
This is why headless Services are paired with StatefulSets — a client (or the pods themselves) can talk to a *specific* replica by name (`web-stateful-0`), which matters for things like a database primary vs replicas, or Kafka broker peer discovery.

---

## Task 2: Compare the 5 Service types

| Type | ClusterIP allocated? | Reachable from | DNS resolves to | Typical use |
|---|---|---|---|---|
| **ClusterIP** (default) | Yes | Inside cluster only | 1 virtual IP (load-balanced) | Internal microservice-to-microservice traffic, internal DBs |
| **NodePort** | Yes | Any cluster node's IP, on a high port (30000-32767) | Same VIP as ClusterIP (NodePort is ClusterIP + an extra external entry point) | Dev/test external access, or as the backing layer under an Ingress/LoadBalancer |
| **LoadBalancer** | Yes | Public internet, via a cloud provider's real load balancer | Same VIP internally; externally via the provisioned LB's IP | Production internet-facing services on a cloud provider |
| **ExternalName** | No | N/A — it's a DNS CNAME, not a proxy | The external hostname you configured (no pods/selector at all) | Referencing an external service (managed DB, SaaS API) by an internal-looking name |
| **Headless** (`clusterIP: None`) | No | Inside cluster only | **All** matching pod IPs directly, no load balancing | StatefulSets — clients need to reach a specific, stable pod by name |

---

## Task 3: Troubleshooting — `empty-endpoints.yaml`

```bash
kubectl apply -f troubleshooting/empty-endpoints.yaml
kubectl get endpoints broken-backend-service
```
```text
NAME                     ENDPOINTS   AGE
broken-backend-service   <none>      3s
```
Root cause: the Service's `selector.app: wrong-backend-name` didn't match any running pod's label (the actual backend pods carry `app: yatri-backend`), so kube-proxy had nothing to route to — `<none>` endpoints means the Service exists but is silently dropping all traffic.

**Fix** (`troubleshooting/empty-endpoints-fixed.yaml`): corrected the selector to `app: yatri-backend`.
```bash
kubectl apply -f troubleshooting/empty-endpoints-fixed.yaml
kubectl get endpoints broken-backend-service
```
```text
NAME                     ENDPOINTS
broken-backend-service   10.244.0.80:5000,10.244.0.81:5000,10.244.0.82:5000
```

This is the single most common real-world Service bug — always check `kubectl get endpoints <svc>` first when a Service "isn't working"; if it's empty, it's a label/selector mismatch, not a networking problem.

---

## Task 4: FQDN & CoreDNS research

Full write-up already in [fqdn.md](./fqdn.md) — covers what an FQDN is (`<service>.<namespace>.svc.cluster.local`), how CoreDNS resolves it, `/etc/resolv.conf` inside a pod, short-name vs cross-namespace lookups, and Service vs Pod FQDNs. Verified hands-on above with `nslookup` against both a regular ClusterIP service and a headless service.

---

## Resources
- [fqdn.md](./fqdn.md) — FQDN & CoreDNS deep dive
- [service.md](./service.md) — Service types deep dive
- https://kubernetes.io/docs/concepts/services-networking/service/
- https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
