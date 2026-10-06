# CoreDNS

CoreDNS is the default DNS server in Kubernetes. It runs as a Deployment in `kube-system` and is exposed by the `kube-dns` Service. Every Pod's `/etc/resolv.conf` points at that Service IP.

## Why Kubernetes uses it

Pods and Services appear and disappear. A static hosts file cannot track them. CoreDNS watches the API and answers names for Services, Pods, and headless records as soon as the objects exist.

## How a query is resolved

1. The application looks up `web-clusterip.default.svc.cluster.local`.
2. The query goes to the CoreDNS ClusterIP.
3. The `kubernetes` plugin reads Services and Endpoints from the API and returns the ClusterIP, or the Pod IPs for a headless Service.
4. Names outside the cluster (`github.com`) are forwarded to the upstream resolver from the node.

## Configuration

The `Corefile` lives in a ConfigMap named `coredns` in `kube-system`. A typical lab Corefile loads `errors`, `health`, `kubernetes`, `forward`, and `cache`. Changing upstream DNS is a ConfigMap edit followed by a CoreDNS rollout.

## Troubleshooting

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
kubectl exec deploy/web -- nslookup web-clusterip
kubectl exec deploy/web -- cat /etc/resolv.conf
kubectl get endpoints web-clusterip
```

If CoreDNS is down, in-cluster names fail and `describe` on a new Pod may show image pulls still working (those use node DNS). If Endpoints are empty, DNS can still return the ClusterIP, but connections fail because no Pod is selected. Check the Service selector against the Pod labels.
