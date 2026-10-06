# Kubernetes FQDN

An FQDN is a fully qualified domain name: the complete name from the host label out to the DNS root. In Kubernetes the cluster domain is usually `cluster.local`.

## Service DNS

Every Service gets a DNS name:

```text
<service>.<namespace>.svc.cluster.local
```

Examples:

```text
web-clusterip.default.svc.cluster.local
kubernetes.default.svc.cluster.local
kube-dns.kube-system.svc.cluster.local
```

From a Pod in the same namespace, `web-clusterip` is enough. The search domain `default.svc.cluster.local` is appended. From another namespace, use the FQDN or at least `web-clusterip.default`.

## Namespace-based names

```text
<pod-ip-with-dashes>.<namespace>.pod.cluster.local
<headless-service>.<namespace>.svc.cluster.local
<pod-name>.<headless-service>.<namespace>.svc.cluster.local
```

A headless Service (Session 11 `web-headless`) has no single virtual IP. DNS answers with the Pod IPs. StatefulSet Pods also get a stable name such as `db-0.db.default.svc.cluster.local`.

## Pod to Service

1. The app calls `http://web-clusterip`.
2. CoreDNS answers with the Service ClusterIP.
3. kube-proxy or the CNI sends the packet to a ready Pod endpoint.
4. The Pod IP can change. Callers keep using the Service name.
