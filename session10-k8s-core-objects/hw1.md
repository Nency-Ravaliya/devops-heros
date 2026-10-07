# Kubernetes Workload Controllers



### What is a ReplicaSet?
A **ReplicaSet (RS)** ensures that a specified number of identical Pod replicas are running at any given time.
* **Mechanism:** Uses set-based selectors (`matchLabels` / `matchExpressions`) to acquire and monitor pods. If a pod crashes or is terminated, the ReplicaSet creates a replacement.
* **Real-world usage:** You rarely manage ReplicaSets directly. Instead, you define **Deployments**, which manage ReplicaSets automatically under the hood to handle rollouts and rollbacks.

### What is a Deployment?
A **Deployment** provides declarative updates for Pods and ReplicaSets.
* **Mechanism:** When you update a Deployment spec (e.g., updating a container image), the Deployment controller creates a *new* ReplicaSet, scales it up, and progressively scales down the *old* ReplicaSet (using rolling updates by default).
* **Key Features:** Rolling updates, zero-downtime rollouts, instant rollbacks (`kubectl rollout undo`), pausing, and scaling.
* **Best for:** Stateless applications (web servers, REST APIs, microservices).

### What is a DaemonSet?
A **DaemonSet (DS)** ensures that **all (or selected) worker nodes run exactly one copy of a Pod**.
* **Mechanism:** As nodes are added to the cluster, the DaemonSet controller creates pods on them. As nodes are removed, those pods are garbage collected.
* **Scheduling:** Respects node taints, tolerations, and node affinity rules.
* **Best for:** Infrastructure/host-level background services:
  * Log shippers (e.g., `fluentd`, `Fluent Bit`, `promtail`).
  * Node metrics collectors (e.g., `node-exporter`, `Datadog agent`).
  * Cluster networking plugins (e.g., `calico-node`, `cilium`, `kube-proxy`).

### What is a StatefulSet?
A **StatefulSet (STS)** manages stateful applications that require stable identities and persistent, dedicated storage.
* **Key Characteristics:**
  * **Stable, unique network identity:** Pods are named sequentially: `<statefulset-name>-0`, `<statefulset-name>-1`, `<statefulset-name>-2`.
  * **Ordered deployment and scaling:** Pods deploy from `0` to `N-1` and terminate in reverse order (`N-1` down to `0`).
  * **Dedicated Persistent Volume Claims (`volumeClaimTemplates`):** Each pod receives its own distinct PersistentVolume that survives pod restarts or rescheduling.
  * **Headless Service:** Requires a headless service (`clusterIP: None`) for direct pod-to-pod DNS addressing (e.g., `<pod-name>.<service-name>.<namespace>.svc.cluster.local`).

### Where are StatefulSets Used?
StatefulSets are used when workloads cannot tolerate arbitrary host assignment or interchangeable storage:
* **Distributed Databases:** Cassandra, MongoDB clusters, CockroachDB, PostgreSQL with primary/read-replica replication.
* **Distributed Message Brokers & Consensus:** Apache Kafka, Apache ZooKeeper, RabbitMQ clusters, etcd.
* **Caching with Persistence / Sharding:** Redis Cluster (where each node has a defined shard identity).


