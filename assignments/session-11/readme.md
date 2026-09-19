# Session 11: Kubernetes Services

## All Services and Pods Overview

![Services & Pods Overview](./screenshots/image-1.png)

---

## 1. ClusterIP Service & Endpoints

ClusterIP is the default Kubernetes Service type. It provides a stable virtual IP and DNS name reachable from inside the cluster.

![ClusterIP & NodePort Services](./screenshots/image-2.png)

---

## 2. LoadBalancer Service

LoadBalancer exposes the Service externally using a cloud provider's load balancer or local tunnel.

![LoadBalancer Service](./screenshots/image-3.png)

---

## 3. ExternalName Service

ExternalName maps a Service to an external DNS name (CNAME record).

![ExternalName Service](./screenshots/image-4.png)

---

## 4. Headless Service

Headless Service (`clusterIP: None`) provides direct DNS resolution to individual Pod IPs without assigning a virtual IP.

![Headless Service DNS Lookup](./screenshots/image-5.png)
