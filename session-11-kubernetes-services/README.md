# Session 11: Kubernetes Networking & Services

This index maps every assignment deliverable to its implementation and the terminal evidence captured from Minikube.

## Service demonstrations

| Service type | YAML and commands | Result |
|---|---|---|
| ClusterIP | [`01-clusterip/`](01-clusterip/) | Deployment `3/3`, EndpointSlice with three Pod IPs, HTTP 200 ([evidence](screenshots/service-clusterip.png)) |
| NodePort | [`02-nodeport/`](02-nodeport/) | Service exposed on node port `30080`, local tunnel returned HTTP 200 ([evidence](screenshots/service-nodeport.png)) |
| LoadBalancer | [`03-loadbalancer/`](03-loadbalancer/) | Local Minikube behavior and verification commands documented |
| ExternalName | [`04-externalname/`](04-externalname/) | Service DNS returned a CNAME for the external target |
| Headless | [`05-headless/`](05-headless/) | DNS returned the StatefulSet Pod IPs directly and HTTP 200 ([evidence](screenshots/service-dns.png)) |

## Written deliverables

- [Kubernetes Service guide](service.md)
- [Deployment, ReplicaSet, DaemonSet, StatefulSet, and Service comparisons](comparisons/README.md)
- [FQDN and namespace DNS](fqdn/README.md)
- [CoreDNS and DNS troubleshooting](coredns/README.md)

The Service selector troubleshooting example is in [`troubleshooting/empty-endpoints.yaml`](troubleshooting/empty-endpoints.yaml).
