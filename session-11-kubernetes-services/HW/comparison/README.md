# Kubernetes Object Comparison

**Name:** Smit Rupani  
**Enrollment:** 24bcs10256  

---

## 1. Deployment vs ReplicaSet

| Feature | ReplicaSet | Deployment |
| :--- | :--- | :--- |
| **Purpose** | Ensures a specified number of identical Pod replicas are running at any given time. | Declarative management of Pods and ReplicaSets; handles rollouts, updates, and rollbacks. |
| **Pod Management** | Directly creates and monitors Pods via selector matching. | Higher-level abstraction that creates and manages underlying ReplicaSets. |
| **Scaling** | Can scale Pods up or down manually via `replicas` field. | Scales by instructing its active ReplicaSet to increase/decrease replicas. |
| **Rolling Updates** | Does not support rolling updates or rollback mechanisms. | Native zero-downtime rolling updates, revision history, and instant rollback support. |
| **Relationship** | Low-level controller managed by a Deployment. | Manages ReplicaSets (creates a new ReplicaSet on spec change and scales down old ones). |

### Summary
Never deploy naked ReplicaSets in production. Always manage Pods through a **Deployment**, which gives you automated release strategies and rollbacks.

---

## 2. Deployment vs DaemonSet vs StatefulSet

| Feature | Deployment | DaemonSet | StatefulSet |
| :--- | :--- | :--- | :--- |
| **Use Cases** | Stateless web applications, APIs, microservices. | Node-level background agents (Fluentd, Promtail, Node Exporter, kube-proxy). | Stateful clustered applications (MySQL, PostgreSQL, MongoDB, Kafka, Redis, Elasticsearch). |
| **Pod Creation** | Pods are fungible, named with random hash suffixes (e.g. `web-7bb5d84c-xyz`). | Runs exactly one Pod copy per target node across the cluster. | Ordered, deterministic pod naming (`db-0`, `db-1`, `db-2`) with ordinal index. |
| **Scaling** | Scales arbitrarily based on load and replica count. | Scales automatically with the addition/removal of cluster nodes. | Scales strictly sequentially (`0 -> 1 -> 2`, scales down in reverse `2 -> 1 -> 0`). |
| **Networking** | Shared ClusterIP or load balancer; any pod can handle any incoming request. | Typically uses hostPort or node-level binding. | Headless Service provides dedicated, stable DNS hostname per individual Pod (`db-0.db-svc`). |
| **Storage** | Ephemeral or shared ReadWriteMany volumes. | Local hostPath volumes or emptyDir. | Dedicated PersistentVolumeClaim per Pod created via `volumeClaimTemplates` that persist across rescheduling. |

---

## 3. ReplicaSet vs Service

| Feature | ReplicaSet | Service |
| :--- | :--- | :--- |
| **Responsibility** | Lifecycle management: keeps the desired number of Pods alive. Replaces dead Pods. | Networking abstraction: provides a single, stable IP address and DNS name to reach Pods. |
| **Target** | Pod instances and health states. | Pod endpoints via label selectors (`spec.selector`). |
| **Why Service is Required** | Pods are ephemeral; their internal IPs change every time they die or reschedule. | Clients cannot rely on ephemeral Pod IPs. A Service offers an immutable cluster IP and balances traffic across matching Pods. |
| **Traffic Routing Flow** | Client → Service IP/DNS → kube-proxy/iptables rules → Endpoints controller → Pod `targetPort`. |
