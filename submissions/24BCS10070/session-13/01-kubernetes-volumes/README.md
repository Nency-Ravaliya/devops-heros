# Kubernetes volumes

| Type | Lifetime and use | Limitation |
|---|---|---|
| emptyDir | Shared scratch space for containers in one Pod | Survives container restart, removed with Pod |
| hostPath | Mount a path from a node | Node-specific, host security risk; local labs only |
| PV | Cluster storage resource, provisioned manually or by a driver | Reclaim policy controls retain/delete behaviour |
| PVC | Namespaced request for capacity and access mode | Needs a compatible PV or provisioner |
| StorageClass | Describes provisioner and storage parameters | Driver and class must exist |
| Dynamic provisioning | Creates a PV after a claim requests a class | May allocate chargeable cloud storage |

Our mini-project uses a 500Mi PVC from the cluster's default StorageClass and
mounts it at `/data`. On single-node Minikube the two replicas can share an RWO
volume on that node. RWO means one node, not necessarily one Pod. For replicas
spread across nodes, use RWX storage or separate claims rather than sharing RWO.

An emptyDir example is `volumes: [{name: cache, emptyDir: {}}]` plus a matching
container volumeMount. A local hostPath example is `{name: local, hostPath:
{path: /tmp/student-lab, type: DirectoryOrCreate}}`; do not use that as portable storage.
