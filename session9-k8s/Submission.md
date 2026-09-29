# Session 9 – Kubernetes Workload Controllers

Notes on the four controllers that manage Pods, and when each one is the right choice.

## Deployment
- Used for stateless apps where any replica can serve any request.
- Keeps the requested number of Pods running via a ReplicaSet it owns.
- Supports rolling updates and `kubectl rollout undo` for instant rollback.
- Typical use: web frontends, REST APIs, workers that keep no local state.

## ReplicaSet
- Guarantees N identical Pods exist at all times; recreates any that die.
- Rarely created by hand – a Deployment creates and versions ReplicaSets for you.
- Typical use: the "keep 3 copies alive" layer underneath a Deployment.

## DaemonSet
- Runs exactly one Pod on every node (or every node matching a selector).
- New nodes automatically get the Pod; removed nodes lose it.
- Typical use: log shippers, metrics agents, CNI/network plugins, node monitoring.

## StatefulSet
- For apps that need a stable identity: fixed Pod names (`web-0`, `web-1`), stable DNS, and a PersistentVolume per Pod.
- Pods start and stop in order, so leader/follower setups work.
- Typical use: databases (PostgreSQL, MySQL, MongoDB), Kafka, ZooKeeper.

## Comparison

| Controller  | Guarantees                               | Scaling      | Storage            | Use for              |
| ----------- | ---------------------------------------- | ------------ | ------------------ | -------------------- |
| Deployment  | N replicas, rolling update + rollback    | Any count    | Shared / none      | Stateless services   |
| ReplicaSet  | N identical replicas                     | Any count    | Shared / none      | Building block       |
| DaemonSet   | One Pod per node                         | = node count | Usually hostPath   | Node-level agents    |
| StatefulSet | Ordered, named Pods with own volume each | Any count    | One PVC per Pod    | Databases, brokers   |
