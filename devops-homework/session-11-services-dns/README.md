# Session 11: Services, DNS, and object comparisons

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

```bash
kubectl create namespace student11
kubectl -n student11 apply -f services/
kubectl -n student11 rollout status deployment/service-web
kubectl -n student11 get svc,endpointslices,pods -o wide
kubectl -n student11 run client --image=busybox:1.36 --restart=Never -- sleep 3600
kubectl -n student11 exec client -- wget -qO- http://web-clusterip
kubectl -n student11 exec client -- wget -qO- http://web-headless
kubectl -n student11 exec client -- nslookup external-docs
minikube service web-nodeport -n student11 --url
minikube tunnel
# In another terminal inspect web-loadbalancer and curl its external IP.
```

ClusterIP is internal. NodePort exposes a port on node addresses. LoadBalancer
requests an external load balancer; it can remain Pending without an implementation.
ExternalName is a DNS alias, not an HTTP proxy; Host headers and TLS names still
matter. A headless Service is a Service with `clusterIP: None`, rather than a
separate value for `type`. It returns endpoint addresses directly.

| Object | Purpose | Scaling / updates | Network and storage example |
|---|---|---|---|
| Deployment | Manage interchangeable Pods through ReplicaSets | Desired replicas; rolling update/rollback | Stateless API behind a Service |
| ReplicaSet | Keep matching Pod count | Replica count; no Deployment rollout history by itself | Owned by a Deployment |
| DaemonSet | Run a Pod on each eligible node | Follows eligible nodes | Node log collector; host access as needed |
| StatefulSet | Stable identities and per-replica storage | Ordinals; ordered changes by default | Database members with headless DNS and individual PVCs |
| Service | Discover and route to selected ready endpoints | Does not create or scale Pods | Stable DNS/IP for Deployment Pods |

A Deployment changes its Pod template by creating or scaling ReplicaSets. A
ReplicaSet replaces missing Pods but does not provide a stable access address.
A Service matches Pod labels; cluster networking routes traffic to its ready
endpoints even as replicas change. See `fqdn/` and `coredns/` for DNS notes.
Cleanup: `kubectl delete namespace student11`.

## Verification

Manifest syntax checked; Service comparisons and DNS notes prepared.

Service connectivity and CoreDNS checks need a Kubernetes cluster.
