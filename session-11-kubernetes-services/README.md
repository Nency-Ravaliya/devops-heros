# Session 11 - Kubernetes Networking and Services

I deployed all five Service types in Minikube and tested them from inside or outside the cluster as appropriate.

| Service | My test result |
|---|---|
| ClusterIP | Three ready endpoints and HTTP 200 from an in-cluster client. [Files](01-clusterip/) · [Screenshot](screenshots/service-clusterip.png) |
| NodePort | Exposed port `30080`; the Minikube tunnel URL returned HTTP 200. [Files](02-nodeport/) · [Screenshot](screenshots/service-nodeport.png) |
| LoadBalancer | The Service and three endpoints worked inside the cluster. `EXTERNAL-IP` stayed pending because Minikube did not have a cloud load balancer. [Files](03-loadbalancer/) · [Screenshot](screenshots/service-loadbalancer.png) |
| ExternalName | DNS returned a CNAME for the configured external name. [Files](04-externalname/) |
| Headless | DNS returned the individual StatefulSet Pod IPs, and the Pod hostname responded with HTTP 200. [Files](05-headless/) · [Screenshot](screenshots/service-dns.png) |

The LoadBalancer result was useful because `<pending>` did not mean the Service itself was broken. It meant my local cluster had no cloud provider to allocate a public address.

My written notes are split into the [Service guide](service.md), [object comparisons](comparisons/README.md), [FQDN notes](fqdn/README.md), and [CoreDNS notes](coredns/README.md). I also kept a broken-selector example in [`troubleshooting/`](troubleshooting/) to show why a Service can have no endpoints.
