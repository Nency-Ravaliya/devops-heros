# CoreDNS in Kubernetes

## 1. What is CoreDNS?
CoreDNS is a flexible, extensible DNS server written in Go that serves as the default cluster DNS server for Kubernetes.

## 2. Why Kubernetes Uses CoreDNS
- Provides automatic internal Service Discovery.
- Replaces legacy Kube-DNS with a fast, modular plugin architecture.
- Reconciles Service endpoints dynamically as Pods scale or restart.

## 3. How DNS Queries Are Resolved
1. A Pod makes a DNS request for `backend-svc`.
2. `/etc/resolv.conf` inside the Pod directs the query to `kube-dns` Service IP (e.g. `10.96.0.10:53`).
3. CoreDNS matches the service name against Kubernetes API endpoints.
4. CoreDNS responds with the Service ClusterIP (or Pod IPs for Headless services).

## 4. CoreDNS Configuration (`Corefile`)
Configured via `coredns` ConfigMap in `kube-system`:

```text
.:53 {
    errors
    health
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
    }
    prometheus :9153
    forward . /etc/resolv.conf
    cache 30
    loop
    reload
    loadbalance
}
```

## 5. Troubleshooting DNS Issues
- Check CoreDNS pods: `kubectl get pods -n kube-system -l k8s-app=kube-dns`
- Check CoreDNS logs: `kubectl logs -n kube-system -l k8s-app=kube-dns`
- Run diagnostic container: `kubectl run dnsutils --image=tutum/dnsutils -i --tty --rm -- nslookup kubernetes.default`
