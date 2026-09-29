# Session 11 – Kubernetes Service Types (run on minikube)

## ClusterIP
Three nginx Pods behind `web-service-clusterip` on port 8080. The service only has a cluster-internal IP, so I test it from the `curl-client` Pod inside the cluster.

![clusterip service and in-cluster curl](/assets/s11-services-01.png)

## NodePort, LoadBalancer, ExternalName, Headless
All five service types side by side. NodePort exposes 30080 on the node; LoadBalancer stays `<pending>` on minikube because there is no cloud load balancer; ExternalName has no ClusterIP and just returns a CNAME; the headless service has `CLUSTER-IP: None`.

![all service types, pods, and NodePort reachable from the host](/assets/s11-services-02.png)

## DNS behaviour and the empty-endpoints drill
- `nslookup external-database-service` resolves to a CNAME for the external hostname.
- `nslookup web-service-headless` returns the individual Pod IPs of the StatefulSet instead of one virtual IP.
- `broken-backend-service` has a selector typo, so `kubectl get endpoints` shows `<none>` – the first thing to check when a service returns connection refused.

![dns lookups, broken endpoints troubleshooting, cleanup](/assets/s11-services-03.png)
