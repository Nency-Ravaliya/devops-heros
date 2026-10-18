# CoreDNS

CoreDNS is the usual cluster DNS server. The Kubernetes plugin answers Service
and Pod DNS queries from Kubernetes state. The Corefile controls plugins such as
`kubernetes`, `forward`, `cache`, and `errors`. External queries are usually
forwarded to upstream resolvers. Pods normally use the kube-dns Service IP.

```bash
kubectl -n kube-system get deploy,pods,svc -l k8s-app=kube-dns
kubectl -n kube-system get configmap coredns -o yaml
kubectl -n kube-system logs deployment/coredns
kubectl -n student11 exec dns -- cat /etc/resolv.conf
kubectl -n student11 exec dns -- nslookup kubernetes.default.svc.cluster.local
kubectl -n student11 get svc,endpointslices
```

Check spelling and namespace first, then resolver/search settings, DNS Pod health,
Service endpoints, NetworkPolicy allowances for TCP/UDP 53, and upstream DNS.
Do not change the cluster-wide Corefile just to fix a mistyped Service name.
