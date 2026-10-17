# Fully qualified domain names

A FQDN identifies a complete DNS name. With the common `cluster.local` domain,
a Service name is `<service>.<namespace>.svc.cluster.local`.
Example: `web-clusterip.student11.svc.cluster.local`.

Within student11, `web-clusterip` is enough because the resolver uses search
suffixes. From another namespace use `web-clusterip.student11`, or the full name.
The cluster domain is configurable, so cluster.local is an example, not a constant.
Normal Services resolve to a virtual IP; headless Services resolve to selected
Pod IPs. A Pod can call a Service by DNS without tracking individual Pod changes.

```bash
kubectl -n student11 run dns --image=busybox:1.36 --restart=Never -- sleep 3600
kubectl -n student11 exec dns -- nslookup web-clusterip.student11.svc.cluster.local
kubectl -n student11 exec dns -- nslookup web-headless
```

Reference: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
