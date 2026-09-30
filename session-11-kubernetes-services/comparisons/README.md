# Kubernetes Object Comparisons

## Deployment vs ReplicaSet

| Area | Deployment | ReplicaSet |
|---|---|---|
| Purpose | Declares an application rollout and desired replica count | Keeps a fixed number of matching Pods running |
| Pod management | Creates and owns ReplicaSets | Creates and owns Pods directly |
| Scaling | Updates the desired replicas through its active ReplicaSet | Can scale Pods, but has no release strategy |
| Updates | Supports rolling updates, pause/resume, history, and rollback | Replaces Pods only when its Pod template changes through another controller |
| Relationship | Higher-level controller | A Deployment creates a new ReplicaSet for each Pod-template revision |

Use a Deployment for stateless applications. Creating a ReplicaSet directly is mainly useful for learning because it lacks rollout management.

## Deployment vs DaemonSet vs StatefulSet

| Area | Deployment | DaemonSet | StatefulSet |
|---|---|---|---|
| Use case | Stateless APIs and web applications | One agent per eligible node, such as logging or monitoring | Databases and clustered systems needing identity |
| Pod creation | Desired replica count placed on available nodes | One Pod on each matching node | Ordered Pods named `name-0`, `name-1`, and so on |
| Scaling | Manual or HPA | Follows the number of eligible nodes | Explicit replicas, ordered scale operations |
| Networking | Interchangeable Pods normally reached through a Service | Usually node-local or reached through a Service | Stable DNS identities through a headless Service |
| Storage | Shared or per-Pod volumes without stable Pod identity | Often hostPath for node data | `volumeClaimTemplates` give each ordinal its own persistent claim |
| Example | Frontend deployment | Fluent Bit log agent | PostgreSQL or Kafka cluster |

## ReplicaSet vs Service

A ReplicaSet controls **how many Pods exist**. A Service controls **how clients reach ready Pods**. The Service selects Pods by labels and exposes a stable virtual IP and DNS name while the selected Pod IPs can change. Traffic resolves the Service name through CoreDNS, reaches the Service ClusterIP, and is forwarded to a ready endpoint by Kubernetes networking rules.
