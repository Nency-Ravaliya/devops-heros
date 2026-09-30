# CoreDNS in Kubernetes

CoreDNS provides cluster DNS and service discovery. It watches Kubernetes Services and EndpointSlices through the API and answers queries for names under `cluster.local`.

## Resolution flow

1. An application requests `web-service.default.svc.cluster.local`.
2. The Pod sends the query to the DNS Service listed in `/etc/resolv.conf`.
3. CoreDNS finds the Service record through its `kubernetes` plugin.
4. A normal Service returns its ClusterIP; a headless Service returns ready endpoint IPs.
5. Queries outside the cluster domain are forwarded to an upstream resolver.

The CoreDNS configuration is stored in the `coredns` ConfigMap:

```bash
kubectl -n kube-system get configmap coredns -o yaml
```

## Troubleshooting checklist

```bash
kubectl -n kube-system get pods -l k8s-app=kube-dns
kubectl -n kube-system logs -l k8s-app=kube-dns
kubectl get service web-service
kubectl get endpointslices -l kubernetes.io/service-name=web-service
kubectl exec dns-test-client -- cat /etc/resolv.conf
kubectl exec dns-test-client -- nslookup web-service.default.svc.cluster.local
```

If the name resolves but HTTP fails, inspect the Service port, targetPort, ready endpoints, and NetworkPolicies. If the FQDN is `NXDOMAIN`, verify the Service name and namespace, CoreDNS health, and the Pod search domains.
