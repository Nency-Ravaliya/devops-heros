# Session 11: Kubernetes Networking & Services

## Overview
This directory contains the completed assignment deliverables, documentation, comparison notes, and verified terminal output screenshots for **Session 11: Kubernetes Networking & Services**.

---

## Task 1: 5 Kubernetes Service Types Demonstration

Demonstrated and verified all 5 Kubernetes Service types:
1. 🟢 **ClusterIP**: Internal-only Cluster IP assignment for pod-to-pod communication.
2. 🔵 **NodePort**: Exposes service on each worker node's IP at a static port (`30000-32767`).
3. 🟡 **LoadBalancer**: Integrates with cloud provider load balancers for external public access.
4. 🟣 **ExternalName**: Maps service to external CNAME record without proxying.
5. ⚪ **Headless**: Set `clusterIP: None` for direct Pod IP discovery via DNS.

### Terminal Screenshots:
- **ClusterIP & NodePort Verification**:
  ![ClusterIP and NodePort](./screenshots/image-1.png)

- **LoadBalancer & Service Deployment**:
  ![LoadBalancer and Service Deployment](./screenshots/image-2.png)

- **ExternalName & CNAME Resolution**:
  ![ExternalName Service](./screenshots/image-3.png)

- **Headless Service & Direct Pod Discovery**:
  ![Headless Service](./screenshots/image-4.png)

---

## Task 2: Kubernetes Object Comparison

### 1. Deployment vs ReplicaSet
- **ReplicaSet**: Ensures a specified number of identical Pod replicas are running at any given time using label selectors. Handles Pod scaling and self-healing.
- **Deployment**: High-level declarative abstraction built on top of ReplicaSets. Provides declarative updates, rolling updates, rollbacks, and pause/resume capabilities.

### 2. Deployment vs DaemonSet vs StatefulSet
| Feature | Deployment | DaemonSet | StatefulSet |
| :--- | :--- | :--- | :--- |
| **Pod Allocation** | Any available worker node based on scheduler. | Runs **exactly one Pod copy on every node** (or selected nodes). | Ordered deployment on nodes with sticky identities. |
| **Identity & Storage** | Stateless, random pod names. | Node-bound, system monitoring/logging agents. | Persistent storage per pod, unique stable network identity (`pod-0`, `pod-1`). |
| **Use Cases** | Stateless Web APIs, microservices. | `kube-proxy`, Prometheus `node-exporter`, Fluentd logs. | Databases (MySQL, PostgreSQL, MongoDB, Redis Cluster). |

### 3. ReplicaSet vs Service
- **ReplicaSet Responsibility**: Manages Pod lifecycle, pod count scaling, and replacement of crashed pods.
- **Service Responsibility**: Provides a stable IP address, DNS name, and load balancing across dynamic, ephemeral Pods matching a label selector.

---

## Task 3 & 4: FQDN & CoreDNS Guides

- 📄 **[FQDN Documentation](./fqdn/README.md)**: Details FQDN structure (`<service-name>.<namespace>.svc.cluster.local`) and cross-namespace DNS resolution.
- 📄 **[CoreDNS Architecture & Troubleshooting Guide](./coredns/README.md)**: Explains CoreDNS architecture, `/etc/resolv.conf` integration, `Corefile` directives, and DNS troubleshooting.

### DNS & FQDN Verification Output:
![FQDN and CoreDNS Verification](./screenshots/image-5.png)
