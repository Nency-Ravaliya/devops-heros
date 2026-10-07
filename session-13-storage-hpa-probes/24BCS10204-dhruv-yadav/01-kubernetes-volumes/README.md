# Task 1 - Kubernetes Volumes and Storage

**Dhruv Yadav - 24BCS10204 - Session 13 (Storage, HPA & Probes)**

Everything here ran on the kind cluster `kind-devops-heros` in my namespace `s13-storage`. The YAML files in this folder are exactly the manifests I applied.

| File | Concept |
|---|---|
| `emptydir-shared.yaml` | `emptyDir` shared by two containers in one Pod |
| `hostpath-pod.yaml` | `hostPath` - a directory on the node |
| `static-pv-pvc.yaml` + `static-pv-pod.yaml` | Static provisioning: a hand-made PV bound by a PVC |
| `dynamic-pvc.yaml` + `pvc-writer-pod.yaml` | Dynamic provisioning through the `standard` StorageClass, and data surviving Pod deletion |
| `storageclass-retain.yaml` | A custom StorageClass with `reclaimPolicy: Retain` |

## Why volumes?

A container's filesystem is **ephemeral**. When the container restarts or the Pod is deleted, everything it wrote is lost. Containers in the same Pod also cannot see each other's files. A **volume** is a directory that Kubernetes mounts into containers. Its lifetime depends on its type:

| Type | Lives as long as | Shared by | Typical use |
|---|---|---|---|
| `emptyDir` | the **Pod** | containers of the same Pod | scratch space, cache, sidecar hand-off |
| `hostPath` | the **node** | Pods scheduled on that node | node agents, log collectors (risky for apps) |
| PV / PVC | **independent** of Pods | whoever claims it (per access mode) | databases, uploads, any state |

---

## 1. emptyDir - shared between two containers

`emptyDir` is created empty when the Pod starts on a node, and it is deleted when the Pod is removed. Here a busybox **writer** appends to `/shared/index.html` every 5 seconds. An **nginx** container mounts the same volume as its web root and serves that file.

```console
$ kubectl create namespace s13-storage
namespace/s13-storage created
$ kubectl apply -f emptydir-shared.yaml
pod/emptydir-shared created
$ kubectl get pod emptydir-shared -n s13-storage
NAME READY STATUS RESTARTS AGE
emptydir-shared 2/2 Running 0 24s
$ kubectl exec -n s13-storage emptydir-shared -c writer -- cat /shared/index.html
written by writer at Tue Oct 6 10:59:06 UTC 2026
written by writer at Tue Oct 6 10:59:11 UTC 2026
written by writer at Tue Oct 6 10:59:16 UTC 2026
$ kubectl exec -n s13-storage emptydir-shared -c web -- curl -s localhost/index.html
written by writer at Tue Oct 6 10:59:06 UTC 2026
written by writer at Tue Oct 6 10:59:11 UTC 2026
written by writer at Tue Oct 6 10:59:16 UTC 2026
$ kubectl exec -n s13-storage emptydir-shared -c web -- df -h /usr/share/nginx/html
Filesystem Size Used Avail Use% Mounted on
/dev/vda1 911G 19G 846G 3% /usr/share/nginx/html
```

The writer container writes the file and the web container serves it, so both see the same data. `df` shows the emptyDir is just a directory on the node's disk. `emptyDir: { medium: Memory }` would back it with tmpfs (RAM) instead.

## 2. hostPath - a directory on the node

`hostPath` mounts a path from the node's own filesystem. I pinned the Pod to `devops-heros-worker` and then checked the file **from the node itself**. A kind node is a Docker container, so `docker exec` gets onto the node.

```console
$ kubectl apply -f hostpath-pod.yaml
pod/hostpath-demo created
$ kubectl get pod hostpath-demo -n s13-storage -o wide
NAME READY STATUS RESTARTS AGE IP NODE NOMINATED NODE READINESS GATES
hostpath-demo 1/1 Running 0 1s 10.244.2.11 devops-heros-worker <none> <none>
$ kubectl exec -n s13-storage hostpath-demo -- cat /data/hello.txt
hello from pod hostpath-demo
$ docker exec devops-heros-worker ls -l /tmp/24bcs10204-hostpath
total 4
-rw-r--r-- 1 root root 29 Oct 6 10:59 hello.txt
$ docker exec devops-heros-worker cat /tmp/24bcs10204-hostpath/hello.txt
hello from pod hostpath-demo
```

The data survives the Pod, but **only on that one node**. If the Pod is rescheduled to another node, it sees a different, empty directory. hostPath also gives the Pod access to the host filesystem, which is a security risk. So it is used for node-level agents, not for application data.

## 3. PersistentVolume + PersistentVolumeClaim (static provisioning)

- A **PersistentVolume (PV)** is a piece of storage in the cluster. It is a cluster-scoped object, created by an admin or by a provisioner.
- A **PersistentVolumeClaim (PVC)** is a namespaced request for storage: "I need 500Mi, ReadWriteOnce, of class X". Kubernetes **binds** the claim to a matching PV, and Pods then mount the PVC, never the PV directly.

This lets developers ask for storage without knowing where it comes from. `storageClassName: manual` makes sure the PVC binds to my hand-made PV, so the default StorageClass does not provision a new one.

```console
$ kubectl apply -f static-pv-pvc.yaml
persistentvolume/s13-static-pv created
persistentvolumeclaim/static-pvc created
$ kubectl get pv s13-static-pv
NAME CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM STORAGECLASS VOLUMEATTRIBUTESCLASS REASON AGE
s13-static-pv 1Gi RWO Retain Available manual <unset> 0s
$ kubectl get pvc static-pvc -n s13-storage
NAME STATUS VOLUME CAPACITY ACCESS MODES STORAGECLASS VOLUMEATTRIBUTESCLASS AGE
static-pvc Pending manual <unset> 0s
$ kubectl apply -f static-pv-pod.yaml
pod/static-pv-consumer created
$ kubectl get pv s13-static-pv
NAME CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM STORAGECLASS VOLUMEATTRIBUTESCLASS REASON AGE
s13-static-pv 1Gi RWO Retain Bound s13-storage/static-pvc manual <unset> 12s
$ kubectl get pvc static-pvc -n s13-storage
NAME STATUS VOLUME CAPACITY ACCESS MODES STORAGECLASS VOLUMEATTRIBUTESCLASS AGE
static-pvc Bound s13-static-pv 1Gi RWO manual <unset> 12s
$ kubectl get pod static-pv-consumer -n s13-storage -o wide
NAME READY STATUS RESTARTS AGE IP NODE NOMINATED NODE READINESS GATES
static-pv-consumer 1/1 Running 0 12s 10.244.2.13 devops-heros-worker <none> <none>
$ docker exec devops-heros-worker cat /tmp/24bcs10204-static-pv/note.txt
stored on a static PV
```

Observations:
- At `0s` the PV was `Available` and the PVC was still `Pending`, because the PV controller had not run its binding loop yet. About a second later both were `Bound` to each other.
- The PVC asked for 500Mi but shows **1Gi** capacity. A claim binds to a whole PV that is at least as large as requested, so it gets the full 1Gi.
- The PV has a `nodeAffinity` for `devops-heros-worker`, because a hostPath-backed PV only exists on one node. The scheduler therefore placed the Pod there.

**Access modes:** `ReadWriteOnce` (RWO, read-write by one node), `ReadOnlyMany` (ROX), `ReadWriteMany` (RWX, many nodes, needs NFS/CephFS-type storage), `ReadWriteOncePod` (RWOP, exactly one Pod).

## 4. StorageClass

A **StorageClass** describes a *kind* of storage and **which provisioner creates it**. kind ships `standard`, backed by Rancher's `local-path` provisioner, and marks it as the default class.

```console
$ kubectl get storageclass
NAME PROVISIONER RECLAIMPOLICY VOLUMEBINDINGMODE ALLOWVOLUMEEXPANSION AGE
standard (default) rancher.io/local-path Delete WaitForFirstConsumer false 11m
$ kubectl describe storageclass standard
Name: standard
IsDefaultClass: Yes
Annotations: kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"},"name":"standard"},"provisioner":"rancher.io/local-path","reclaimPolicy":"Delete","volumeBindingMode":"WaitForFirstConsumer"}
,storageclass.kubernetes.io/is-default-class=true
Provisioner: rancher.io/local-path
Parameters: <none>
AllowVolumeExpansion: <unset>
MountOptions: <none>
ReclaimPolicy: Delete
VolumeBindingMode: WaitForFirstConsumer
Events: <none>
```

- **provisioner**: the plugin that creates the actual volume. On cloud clusters this would be something like `ebs.csi.aws.com` or `pd.csi.storage.gke.io`.
- **reclaimPolicy**: what happens to the PV when its PVC is deleted. `Delete` removes it. `Retain` keeps it, with the data, for an admin to handle.
- **volumeBindingMode**: `Immediate` creates the volume as soon as the PVC exists. `WaitForFirstConsumer` waits until a Pod using the PVC is scheduled, so the volume is created on the node where the Pod will run. This matters for node-local storage like local-path.
- **is-default-class**: a PVC with no `storageClassName` gets this class.

## 5. Dynamic provisioning + data surviving Pod deletion

With dynamic provisioning **nobody writes a PV**. The PVC names a StorageClass, and that class's provisioner creates a PV on demand.

```console
$ kubectl apply -f dynamic-pvc.yaml
persistentvolumeclaim/dynamic-pvc created
$ kubectl get pvc dynamic-pvc -n s13-storage
NAME STATUS VOLUME CAPACITY ACCESS MODES STORAGECLASS VOLUMEATTRIBUTESCLASS AGE
dynamic-pvc Pending standard <unset> 0s
$ kubectl describe pvc dynamic-pvc -n s13-storage | tail -5
Used By: <none>
Events:
Type Reason Age From Message
---- ------ ---- ---- -------
Normal WaitForFirstConsumer 0s persistentvolume-controller waiting for first consumer to be created before binding
```

The PVC stays `Pending` on purpose (`WaitForFirstConsumer`) until a Pod uses it:

```console
$ kubectl apply -f pvc-writer-pod.yaml
pod/pvc-writer created
$ kubectl get pvc dynamic-pvc -n s13-storage
NAME STATUS VOLUME CAPACITY ACCESS MODES STORAGECLASS VOLUMEATTRIBUTESCLASS AGE
dynamic-pvc Bound pvc-78bc42fc-b4ea-4847-a53d-c4b04ae6f217 500Mi RWO standard <unset> 4s
$ kubectl get pv $(kubectl get pvc dynamic-pvc -n s13-storage -o jsonpath='{.spec.volumeName}')
NAME CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM STORAGECLASS VOLUMEATTRIBUTESCLASS REASON AGE
pvc-78bc42fc-b4ea-4847-a53d-c4b04ae6f217 500Mi RWO Delete Bound s13-storage/dynamic-pvc standard <unset> 2s
$ kubectl describe pvc dynamic-pvc -n s13-storage | tail -8
Unused False Mon, 01 Jan 0001 00:00:00 +0000 Tue, 06 Oct 2026 19:00:35 +0800 PodUsingPVC A pod is currently referencing this PVC
Events:
Type Reason Age From Message
---- ------ ---- ---- -------
Normal WaitForFirstConsumer 5s persistentvolume-controller waiting for first consumer to be created before binding
Normal ExternalProvisioning 5s persistentvolume-controller Waiting for a volume to be created either by the external provisioner 'rancher.io/local-path' or manually by the system administrator. If volume creation is delayed, please verify that the provisioner is running and correctly registered.
Normal Provisioning 5s rancher.io/local-path_local-path-provisioner-75f7fc7dc5-9w6c4_715d9aff-6c88-4e79-8feb-879bf7305f85 External provisioner is provisioning volume for claim "s13-storage/dynamic-pvc"
Normal ProvisioningSucceeded 2s rancher.io/local-path_local-path-provisioner-75f7fc7dc5-9w6c4_715d9aff-6c88-4e79-8feb-879bf7305f85 Successfully provisioned volume pvc-78bc42fc-b4ea-4847-a53d-c4b04ae6f217
```

The events show the full dynamic-provisioning chain: WaitForFirstConsumer, then ExternalProvisioning, then Provisioning by `rancher.io/local-path`, then ProvisioningSucceeded. The PV is named `pvc-<uid>` and is exactly 500Mi.

**Data survives Pod deletion:**

```console
$ kubectl exec -n s13-storage pvc-writer -- sh -c 'echo "Dhruv Yadav 24BCS10204 - $(date)" > /data/proof.txt'
$ kubectl exec -n s13-storage pvc-writer -- cat /data/proof.txt
Dhruv Yadav 24BCS10204 - Tue Oct 6 11:00:37 UTC 2026
$ kubectl delete pod pvc-writer -n s13-storage
pod "pvc-writer" deleted from s13-storage namespace
$ kubectl get pvc dynamic-pvc -n s13-storage
NAME STATUS VOLUME CAPACITY ACCESS MODES STORAGECLASS VOLUMEATTRIBUTESCLASS AGE
dynamic-pvc Bound pvc-78bc42fc-b4ea-4847-a53d-c4b04ae6f217 500Mi RWO standard <unset> 37s
$ kubectl apply -f pvc-writer-pod.yaml
pod/pvc-writer created
$ kubectl get pod pvc-writer -n s13-storage
NAME READY STATUS RESTARTS AGE
pvc-writer 1/1 Running 0 0s
$ kubectl exec -n s13-storage pvc-writer -- cat /data/proof.txt
Dhruv Yadav 24BCS10204 - Tue Oct 6 11:00:37 UTC 2026
```

The Pod was deleted, but the PVC stayed `Bound` to the same PV. A brand-new Pod read back the same file with the same timestamp.

## 6. Reclaim policy: Retain vs Delete

`storageclass-retain.yaml` creates the class `s13-local-retain`. It uses the same provisioner with `reclaimPolicy: Retain`, plus a PVC and a Pod that use it. Then I deleted the claims of both classes:

```console
$ kubectl apply -f storageclass-retain.yaml
storageclass.storage.k8s.io/s13-local-retain created
persistentvolumeclaim/retain-pvc created
pod/retain-consumer created
$ kubectl get sc s13-local-retain
NAME PROVISIONER RECLAIMPOLICY VOLUMEBINDINGMODE ALLOWVOLUMEEXPANSION AGE
s13-local-retain rancher.io/local-path Retain WaitForFirstConsumer false 5s
$ kubectl get pvc retain-pvc -n s13-storage
NAME STATUS VOLUME CAPACITY ACCESS MODES STORAGECLASS VOLUMEATTRIBUTESCLASS AGE
retain-pvc Bound pvc-05eaaeb4-b840-402f-b2c1-1bc5e0ab2daf 200Mi RWO s13-local-retain <unset> 5s
$ kubectl delete pod retain-consumer -n s13-storage
pod "retain-consumer" deleted from s13-storage namespace
$ kubectl delete pvc retain-pvc -n s13-storage
persistentvolumeclaim "retain-pvc" deleted from s13-storage namespace
$ kubectl get pv pvc-05eaaeb4-b840-402f-b2c1-1bc5e0ab2daf
NAME CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM STORAGECLASS VOLUMEATTRIBUTESCLASS REASON AGE
pvc-05eaaeb4-b840-402f-b2c1-1bc5e0ab2daf 200Mi RWO Retain Released s13-storage/retain-pvc s13-local-retain <unset> 37s
```

(dynamic PV of standard class, reclaimPolicy Delete, is removed when its PVC is deleted:)

```console
$ kubectl delete pod pvc-writer -n s13-storage
pod "pvc-writer" deleted from s13-storage namespace
$ kubectl delete pvc dynamic-pvc -n s13-storage
persistentvolumeclaim "dynamic-pvc" deleted from s13-storage namespace
$ kubectl get pv pvc-78bc42fc-b4ea-4847-a53d-c4b04ae6f217
Error from server (NotFound): persistentvolumes "pvc-78bc42fc-b4ea-4847-a53d-c4b04ae6f217" not found
$ kubectl delete pv pvc-05eaaeb4-b840-402f-b2c1-1bc5e0ab2daf
persistentvolume "pvc-05eaaeb4-b840-402f-b2c1-1bc5e0ab2daf" deleted
```

- **Retain**: the PV moved to `Released`. It keeps its data and its reference to the old claim, and it is not reused automatically. An admin has to clean it up or re-bind it, as I did with the final `kubectl delete pv`.
- **Delete**: the PV and the underlying directory were removed together with the PVC.

## Summary

```text
Pod ──mounts──> PVC (namespaced request: size, access mode, class)
│ binds 1:1
▼
PV (cluster-scoped storage, reclaimPolicy)
▲ created by
┌───────────┴────────────┐
admin (static) StorageClass provisioner (dynamic)
```

| Concept | Scope | Key point |
|---|---|---|
| emptyDir | Pod | Shared by containers in the Pod, deleted with the Pod |
| hostPath | Node | Survives the Pod but is tied to one node, and a security risk |
| PV | Cluster | The actual storage, with capacity, access mode and reclaim policy |
| PVC | Namespace | A request for storage that binds to one PV |
| StorageClass | Cluster | Provisioner, reclaim policy and binding mode, used for dynamic provisioning |
