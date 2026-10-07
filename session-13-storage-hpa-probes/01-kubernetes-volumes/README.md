# Kubernetes Volumes & Storage

Container filesystems are temporary: when a container restarts, anything it wrote is lost. Volumes give a Pod storage that lasts longer than the container.

Run all the commands below from `session-13-storage-hpa-probes/`.

| Type | Lifetime | Use case | Example in this repo |
|---|---|---|---|
| `emptyDir` | Lasts as long as the Pod | Scratch space, cache, sharing files between containers | [`01-volumes/emptydir-pod.yaml`](../01-volumes/emptydir-pod.yaml) |
| `hostPath` | Lasts as long as the node | Node-level files, single-node dev clusters | [`01-volumes/hostpath-pod.yaml`](../01-volumes/hostpath-pod.yaml) |
| PersistentVolume (PV) | Independent of any Pod | A piece of storage in the cluster, created by an admin | [`02-persistent-storage/pv.yaml`](../02-persistent-storage/pv.yaml) |
| PersistentVolumeClaim (PVC) | Independent of any Pod | A Pod's request for storage (size + access mode) | [`02-persistent-storage/pvc-static.yaml`](../02-persistent-storage/pvc-static.yaml) |
| StorageClass | Cluster-wide | Describes how volumes get provisioned (`standard` on minikube) | `kubectl get storageclass` |
| Dynamic provisioning | — | The PV gets created automatically when a PVC asks for a StorageClass | [`03-storageclass/pvc.yaml`](../03-storageclass/pvc.yaml) |

---

## emptyDir
Created empty when the Pod starts and deleted when the Pod is removed. It survives container restarts.
```yaml
volumes:
  - name: app-storage
    emptyDir: {}
```
```bash
kubectl apply -f 01-volumes/emptydir-pod.yaml
kubectl exec emptydir-demo -- sh -c 'echo hello > /data/hello.txt && cat /data/hello.txt'
```

## hostPath
Mounts a directory from the node into the Pod. On minikube the "node" is the minikube VM/container, not your Mac.
```yaml
volumes:
  - name: host-storage
    hostPath:
      path: /tmp/hostpath-data
      type: DirectoryOrCreate
```
```bash
kubectl apply -f 01-volumes/hostpath-pod.yaml
kubectl exec hostpath-demo -- sh -c 'echo from-pod > /data/host.txt'
minikube ssh -- cat /tmp/hostpath-data/host.txt
```
⚠️ The data is tied to one node. If the Pod gets scheduled on another node it won't see the data, so don't use hostPath for production apps.

## PersistentVolume (PV)
Storage in the cluster that an admin creates ahead of time (**static provisioning**).
```yaml
kind: PersistentVolume
spec:
  capacity: { storage: 1Gi }
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  hostPath: { path: /tmp/student-data }
```

## PersistentVolumeClaim (PVC)
A Pod asks for storage through a PVC, and Kubernetes binds the claim to a PV that matches it. The Pod then refers to the claim by name (`claimName: student-pvc`).
```bash
kubectl apply -f 02-persistent-storage/pv.yaml
kubectl apply -f 02-persistent-storage/pvc-static.yaml   # storageClassName: "" -> binds to student-pv
kubectl apply -f 02-persistent-storage/pod.yaml
kubectl get pv,pvc
```
Note: the original `pvc.yaml` has no `storageClassName`. On minikube that means it gets the default `standard` class, so it's **dynamically provisioned** and `student-pv` stays `Available`. `pvc-static.yaml` sets `storageClassName: ""` so the claim binds to the static PV instead.

Access modes: `ReadWriteOnce` (RWO, one node), `ReadOnlyMany` (ROX), `ReadWriteMany` (RWX), `ReadWriteOncePod` (RWOP).
Reclaim policy: `Retain` keeps the data after the PVC is deleted. `Delete` removes the volume along with the PVC.

## StorageClass
A StorageClass is a template for creating volumes. It names a provisioner and its parameters. minikube ships a default class called `standard` that uses the `k8s.io/minikube-hostpath` provisioner.
```bash
kubectl get storageclass
```

## Dynamic Provisioning
The PVC names a StorageClass and the provisioner creates a matching PV automatically. No admin has to create the PV first.
```yaml
kind: PersistentVolumeClaim
spec:
  storageClassName: standard
  resources: { requests: { storage: 500Mi } }
```
```bash
kubectl apply -f 03-storageclass/pvc.yaml
kubectl get pvc dynamic-pvc     # Bound
kubectl get pv                  # a new pvc-<uid> volume appears automatically
```
