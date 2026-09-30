# Kubernetes FQDN

An FQDN is the complete DNS name of a resource. A Kubernetes Service normally receives this name:

```text
<service>.<namespace>.svc.cluster.local
```

For example, `web-service` in namespace `production` is reachable as `web-service.production.svc.cluster.local`.

Pods in the same namespace can use the short name `web-service`. A Pod in another namespace should use `web-service.production` or the complete FQDN. Kubernetes writes namespace search suffixes and the CoreDNS Service IP into each Pod's `/etc/resolv.conf`, allowing applications to resolve short names.

Typical communication flow:

```text
frontend Pod -> CoreDNS -> web-service ClusterIP -> ready backend Pod
```

Headless Services are different: their FQDN resolves directly to Pod IP addresses. StatefulSet members can also receive stable names such as `web-stateful-0.web-service-headless.default.svc.cluster.local`.

Hands-on DNS and HTTP results are captured in [`../screenshots/service-dns.png`](../screenshots/service-dns.png). A longer explanation is available in [`../fqdn.md`](../fqdn.md).
