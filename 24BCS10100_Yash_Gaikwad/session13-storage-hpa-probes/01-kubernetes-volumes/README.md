# Kubernetes Volumes

Author: Yash Gaikwad (24BCS10100) | Session 13 - Storage, HPA and Probes

A container's filesystem is thrown away when the container restarts, and nothing in it is shared with other containers. Kubernetes **volumes** solve two problems: data that must survive a container restart, and data that must be shared between containers in a Pod. On top of that, **PersistentVolumes** solve a third problem: data that must outlive the Pod itself.

Everything in this document was written for a single-node minikube cluster using the docker driver, and every example manifest is in the [`examples/`](examples/) folder.

| File | What it demonstrates |
|---|---|
| [`examples/01-emptydir.yaml`](examples/01-emptydir.yaml) | `emptyDir` shared by two containers |
| [`examples/02-hostpath.yaml`](examples/02-hostpath.yaml) | `hostPath` with `type: DirectoryOrCreate` |
| [`examples/03-pv-pvc.yaml`](examples/03-pv-pvc.yaml) | Static PV, PVC bound to it, Pod using the PVC |
| [`examples/04-dynamic-pvc.yaml`](examples/04-dynamic-pvc.yaml) | Dynamic provisioning through the default StorageClass |

All object names are different (`vol-...` prefix), so the four files can be applied together in the `default` namespace:

```bash
kubectl apply -f examples/
```

---

## 1. Volume basics

A volume is declared in two places in a Pod spec:

```yaml
spec:
  containers:
  - name: app
    volumeMounts:            # where it appears inside the container
    - name: my-volume
      mountPath: /data
  volumes:                   # what the volume actually is
  - name: my-volume
    emptyDir: {}
```

The lifetime of a regular volume is tied to the **Pod** (not the container), so data survives container crashes and restarts. What happens when the Pod is deleted depends on the volume type.

---

## 2. emptyDir

An `emptyDir` is created empty when the Pod is assigned to a node and lives exactly as long as the Pod stays on that node.

- Survives container crashes and restarts (the Pod is still there).
- Deleted for good when the Pod is deleted or evicted.
- Shared by every container in the Pod that mounts it.
- Stored on the node's disk by default; `medium: Memory` backs it with tmpfs (RAM) instead, which counts against the container's memory limit.

Typical uses: scratch space, a cache, a checkpoint for a long computation, handing files between a main container and a sidecar (for example an app writing logs and a sidecar shipping them).

```yaml
volumes:
- name: cache
  emptyDir:
    medium: Memory       # optional: RAM-backed
    sizeLimit: 64Mi      # optional: Pod is evicted if usage goes over the limit
```

**Example:** [`examples/01-emptydir.yaml`](examples/01-emptydir.yaml) has a `writer` container appending timestamps to `/shared/log.txt` and a `reader` container following the same file through the same emptyDir.

```bash
kubectl apply -f examples/01-emptydir.yaml
kubectl get pod vol-emptydir-demo
kubectl logs vol-emptydir-demo -c reader
kubectl exec vol-emptydir-demo -c writer -- cat /shared/log.txt
kubectl delete pod vol-emptydir-demo       # the data is gone with the Pod
```

---

## 3. hostPath

A `hostPath` volume mounts a file or directory **from the node's filesystem** into the Pod.

- Data lives on the node, so it survives Pod deletion, but only that one node has it. If the Pod is rescheduled to a different node it sees different (or empty) content.
- It breaks the isolation between Pod and node and is a security risk (a Pod could read or modify host files). Production clusters usually restrict it through Pod Security admission. Legitimate uses are node-level agents (log collectors, monitoring) and single-node development clusters.

The `type` field controls the checks made before mounting:

| `type` | Behaviour |
|---|---|
| (empty) | No check |
| `DirectoryOrCreate` | Create an empty directory (mode 0755, owned by root) if nothing exists at the path |
| `Directory` | Must already exist as a directory |
| `FileOrCreate` | Create an empty file if nothing exists |
| `File` | Must already exist as a file |
| `Socket`, `CharDevice`, `BlockDevice` | Must exist as that kind of object |

**Important for minikube:** with the docker driver the "node" is the minikube container, so `/data/hostpath-demo` is a path *inside that container*, not on my Windows/Linux machine.

**Example:** [`examples/02-hostpath.yaml`](examples/02-hostpath.yaml)

```bash
kubectl apply -f examples/02-hostpath.yaml
kubectl logs vol-hostpath-demo
minikube ssh -- cat /data/hostpath-demo/hello.txt      # look at it on the node

kubectl delete pod vol-hostpath-demo
kubectl apply -f examples/02-hostpath.yaml              # new Pod, same node, same file
minikube ssh -- cat /data/hostpath-demo/hello.txt
```

---

## 4. PersistentVolume (PV)

A **PersistentVolume** is a piece of cluster storage represented as an API object. It is a **cluster-scoped** resource (no namespace), created by an administrator or by a dynamic provisioner. It captures the details of the storage: size, access mode, reclaim policy, and the backend (NFS, cloud disk, CSI driver, hostPath for testing).

The idea is to separate **providing** storage (admin) from **consuming** it (developer), so applications don't need to know whether the disk is an EBS volume or an NFS share.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: vol-static-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /data/vol-static-pv
    type: DirectoryOrCreate
```

---

## 5. PersistentVolumeClaim (PVC)

A **PersistentVolumeClaim** is a *request* for storage by a user. It is **namespaced** and states the size, access mode and (optionally) the StorageClass needed. Kubernetes finds a PV that satisfies the claim and **binds** them one-to-one. The Pod then references the PVC, never the PV:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: vol-static-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 500Mi
---
# in the Pod spec:
# volumes:
# - name: storage
#   persistentVolumeClaim:
#     claimName: vol-static-pvc
```

Matching rules I noted:

- The PV must have **at least** the requested capacity. A 500Mi claim can bind to a 1Gi PV, and then the claim shows 1Gi capacity; the whole PV is reserved, the leftover cannot be given to someone else.
- The PV must offer the requested access modes and have the same `storageClassName`.
- A PVC is namespaced but binds to a cluster-scoped PV; the Pod must be in the same namespace as the PVC.
- A PVC that is in use cannot be deleted immediately. A protection finalizer keeps it `Terminating` until no Pod uses it.

**Example (static provisioning):** [`examples/03-pv-pvc.yaml`](examples/03-pv-pvc.yaml) creates the PV, PVC and a Pod in one file.

```bash
kubectl apply -f examples/03-pv-pvc.yaml
kubectl get pv vol-static-pv
kubectl get pvc vol-static-pvc
kubectl describe pvc vol-static-pvc
kubectl logs vol-static-pvc-pod
minikube ssh -- cat /data/vol-static-pv/hello.txt
```

A gotcha that tripped me while planning this: minikube has a **default StorageClass** (`standard`). A PVC that does not mention `storageClassName` gets that default class assigned and is dynamically provisioned, so it would never bind to my hand-made PV. That is why the static PV and PVC both say `storageClassName: manual`. (Setting `storageClassName: ""` on a PVC also means "no class, bind to a static PV only".)

---

## 6. Access modes

Declared on both PV and PVC; the PV must support the mode the claim asks for.

| Mode | Short | Meaning |
|---|---|---|
| `ReadWriteOnce` | RWO | Read-write by **one node** at a time. Several Pods on that same node can still mount it. |
| `ReadOnlyMany` | ROX | Read-only by **many nodes** at once. |
| `ReadWriteMany` | RWX | Read-write by **many nodes** at once (needs a backend that supports it: NFS, CephFS, EFS, ...). |
| `ReadWriteOncePod` | RWOP | Read-write by a **single Pod** in the whole cluster (needs a CSI volume). |

The mode describes what the *storage backend* can do, not something Kubernetes enforces on file contents. A cloud block disk (EBS, GCE PD) is normally RWO only. The minikube hostpath provisioner and my hostPath PV work with RWO.

---

## 7. Reclaim policies

`persistentVolumeReclaimPolicy` decides what happens to the PV **after its PVC is deleted**.

| Policy | Result |
|---|---|
| `Retain` | PV and the data on it are kept. The PV goes to `Released` and must be cleaned or recycled manually by an admin. Safest for important data. |
| `Delete` | PV object **and** the backing storage asset are deleted (for example the cloud disk). Default for dynamically provisioned volumes in most StorageClasses. |
| `Recycle` | Old, deprecated "rm -rf" mode. Removed in favour of dynamic provisioning; do not use. |

A PV created by dynamic provisioning inherits `reclaimPolicy` from its StorageClass. I can change the policy of an existing PV:

```bash
kubectl patch pv <pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

---

## 8. PV and PVC lifecycle

```
          create PV                     PVC matches PV                 PVC deleted
 (none) -------------> Available ---------------------> Bound ------------------> Released
                                                                                      |
                                              Retain: stays Released (manual cleanup)
                                              Delete: PV and storage are removed
                                              failed cleanup: Failed
```

| PV phase | Meaning |
|---|---|
| `Available` | Free, not yet bound to any claim |
| `Bound` | Bound to a PVC |
| `Released` | The PVC is gone but the PV has not been reclaimed yet. Not available for new claims because it still holds `claimRef` to the old claim and may contain old data |
| `Failed` | Automatic reclamation failed |

PVC phases are `Pending` (not yet bound), `Bound` and `Lost` (the PV behind it disappeared).

To reuse a `Retain`ed PV after cleaning its data, clear the stale claim reference so it returns to `Available`:

```bash
kubectl patch pv vol-static-pv -p '{"spec":{"claimRef":null}}'
```

To watch the lifecycle with the static example:

```bash
kubectl get pv vol-static-pv            # Bound once the PVC exists
kubectl delete pod vol-static-pvc-pod   # delete the Pod first (the PVC is protected while in use)
kubectl delete pvc vol-static-pvc
kubectl get pv vol-static-pv            # Released (Retain keeps the PV and the data)
minikube ssh -- ls /data/vol-static-pv  # data is still on the node
```

---

## 9. StorageClass

A **StorageClass** describes a *kind* of storage ("fast SSD", "cheap HDD", "replicated") and says how to create it on demand. It is cluster-scoped. Its fields:

| Field | Purpose |
|---|---|
| `provisioner` | Which plugin or CSI driver creates volumes (for example `ebs.csi.aws.com`, `k8s.io/minikube-hostpath`) |
| `parameters` | Backend-specific options (disk type, IOPS, filesystem) |
| `reclaimPolicy` | Reclaim policy given to PVs it creates (`Delete` by default) |
| `volumeBindingMode` | `Immediate` or `WaitForFirstConsumer` (below) |
| `allowVolumeExpansion` | If `true`, a PVC can later be edited to a bigger size |

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

One class can be marked as the **default** with the annotation `storageclass.kubernetes.io/is-default-class: "true"`. PVCs that do not set `storageClassName` use it.

### volumeBindingMode

- **`Immediate`**: the PV is provisioned and bound as soon as the PVC is created, before any Pod uses it. For topology-limited storage (a disk that exists in one availability zone) this can create the disk in a zone where the Pod cannot be scheduled.
- **`WaitForFirstConsumer`**: binding and provisioning are delayed until a Pod using the PVC is scheduled. The scheduler first picks a node, then the volume is created in a matching location. This is the recommended mode for zonal or node-local storage. A PVC in this mode stays `Pending` until a Pod uses it, which is expected, not an error.

minikube's `standard` class normally uses `Immediate`, and I can check it on my cluster:

```bash
kubectl get storageclass
kubectl describe storageclass standard
```

---

## 10. Dynamic provisioning

With static provisioning an admin has to create PVs ahead of time. With **dynamic provisioning** the PV is created automatically when a PVC asks for it:

1. User creates a PVC (with a `storageClassName`, or none so that the default class is used).
2. The class's provisioner creates the real storage (disk, directory, share) and a matching PV object.
3. The PV is bound to the PVC. The Pod mounts the PVC.
4. When the PVC is deleted, the reclaim policy (usually `Delete`) removes the PV and the storage.

**Example:** [`examples/04-dynamic-pvc.yaml`](examples/04-dynamic-pvc.yaml). The PVC has no `storageClassName`, so minikube's default `standard` class (hostpath provisioner) creates the volume.

```bash
kubectl apply -f examples/04-dynamic-pvc.yaml
kubectl get storageclass
kubectl get pvc vol-dynamic-pvc
kubectl get pv                                   # an auto-named pvc-<uid> volume appears
kubectl logs vol-dynamic-pvc-pod
kubectl get pv -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.hostPath.path}{"\n"}{end}'
```

To prove the data outlives the Pod (the PVC is what keeps it):

```bash
kubectl delete pod vol-dynamic-pvc-pod
kubectl apply -f examples/04-dynamic-pvc.yaml     # re-creates only the Pod
kubectl logs vol-dynamic-pvc-pod                  # hello.txt now holds earlier lines too
```

I must not write `storageClassName: ""` in that PVC: an empty string explicitly disables dynamic provisioning and the claim would wait forever for a matching static PV.

---

## 11. Volume type comparison

| Volume type | Lifetime | Shared between Pods? | Survives Pod deletion? | Survives node loss? | Typical use |
|---|---|---|---|---|---|
| `emptyDir` | Pod | No (only containers in the same Pod) | No | No | Scratch space, cache, sidecar sharing |
| `emptyDir` (`medium: Memory`) | Pod | No | No | No | Fast temporary files (counts against memory) |
| `hostPath` | Node | Only Pods on the same node | Yes (data stays on that node) | No | Node agents, single-node dev clusters |
| `configMap` / `secret` | Object in the API | Yes (read-only files) | Yes (it is just API data) | Yes | Configuration and credentials as files |
| `persistentVolumeClaim` (static PV) | PV, managed by an admin | Depends on access mode | Yes | Depends on backend (cloud disk or NFS: yes; hostPath: no) | Pre-provisioned disks, NFS shares |
| `persistentVolumeClaim` (dynamic) | Until PVC deleted (with `Delete` policy) | Depends on access mode | Yes | Depends on backend | Databases and any stateful workload on demand |
| `nfs` / CSI-backed volumes | External system | Yes with RWX capable backends | Yes | Yes (data is off the node) | Shared storage across nodes |

---

## 12. Cleanup

```bash
kubectl delete -f examples/ --ignore-not-found   # skips objects already deleted while experimenting
kubectl get pv,pvc                               # confirm nothing of mine remains

# The static PV used Retain and hostPath directories stay on the node:
minikube ssh -- sudo rm -rf /data/vol-static-pv /data/hostpath-demo
```

Deleting the files in `examples/` removes the Pods and PVCs, and the PV `vol-static-pv` because it is also defined there, but the data directories on the node are not touched (that is what `Retain` and `hostPath` mean), so they are removed separately above.

---

## 13. Summary

- `emptyDir`: temporary, tied to the Pod's life, great for sharing between containers.
- `hostPath`: node's disk, persistent on that node only, risky and node-specific.
- `PV`: the storage (cluster-scoped, admin or provisioner side). `PVC`: the request (namespaced, user side). Pods use the PVC.
- `StorageClass`: template + provisioner for on-demand storage; the default class lets a PVC be satisfied with no PV written by hand.
- Access modes (RWO/ROX/RWX/RWOP) describe how many nodes or Pods may mount; reclaim policy (Retain/Delete) decides what happens to data when the claim is deleted; `volumeBindingMode` decides when the volume is created.

## Hands-on output

All the examples in [`examples/`](examples/) were applied to my Minikube cluster (Kubernetes v1.37.0). Every block below is real output.

### The cluster's storage setup

_Minikube ships a default StorageClass called `standard` (provisioner `k8s.io/minikube-hostpath`, reclaim policy Delete). That is what makes dynamic provisioning work below._

```console
$ kubectl get storageclass
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate           false                  64m
```

### 1. emptyDir: shared scratch space that lives and dies with the Pod

_A Pod with two containers: `writer` appends the date to a file every 5 s, `reader` tails the same file._

```console
$ kubectl apply -f examples/01-emptydir.yaml && kubectl wait --for=condition=Ready pod/vol-emptydir-demo --timeout=120s && sleep 12
pod/vol-emptydir-demo created
pod/vol-emptydir-demo condition met
```

_The reader container sees what the writer wrote: both mount the same emptyDir._

```console
$ kubectl logs vol-emptydir-demo -c reader --tail=3
Sun Oct 18 14:06:57 UTC 2026
Sun Oct 18 14:07:02 UTC 2026
Sun Oct 18 14:07:07 UTC 2026
```

_The file now has a few lines._

```console
$ kubectl exec vol-emptydir-demo -c writer -- wc -l /shared/log.txt
3 /shared/log.txt
```

_**The data is gone with the Pod**: after deleting and recreating it the file starts again from zero. emptyDir only survives container restarts, not Pod deletion._

```console
$ kubectl delete pod vol-emptydir-demo && kubectl apply -f examples/01-emptydir.yaml && kubectl wait --for=condition=Ready pod/vol-emptydir-demo --timeout=120s && sleep 7 && kubectl exec vol-emptydir-demo -c writer -- wc -l /shared/log.txt
pod "vol-emptydir-demo" deleted from default namespace
pod/vol-emptydir-demo created
pod/vol-emptydir-demo condition met
2 /shared/log.txt
```

_Cleanup._

```console
$ kubectl delete pod vol-emptydir-demo --wait=false
pod "vol-emptydir-demo" deleted from default namespace
```

### 2. hostPath: a folder of the node

_The Pod writes a line into `/data/hostpath-demo` of the **node**._

```console
$ kubectl apply -f examples/02-hostpath.yaml && kubectl wait --for=condition=Ready pod/vol-hostpath-demo --timeout=120s && sleep 2 && kubectl logs vol-hostpath-demo
pod/vol-hostpath-demo created
pod/vol-hostpath-demo condition met
written by vol-hostpath-demo at Sun Oct 18 14:07:52 UTC 2026
```

_The file really is on the node filesystem (I looked inside the Minikube node)._

```console
$ minikube ssh -- "ls -l /data/hostpath-demo && cat /data/hostpath-demo/hello.txt"
total 4
-rw-r--r-- 1 root root 61 Oct 18 14:07 hello.txt
written by vol-hostpath-demo at Sun Oct 18 14:07:52 UTC 2026
```

_**The data survives the Pod**: the recreated Pod finds the old line and appends a second one. The catch: it only works if the new Pod lands on the **same node**, and it exposes the node filesystem (a security risk), so hostPath is for single-node demos and system agents, not for applications._

```console
$ kubectl delete pod vol-hostpath-demo --wait=true && kubectl apply -f examples/02-hostpath.yaml && kubectl wait --for=condition=Ready pod/vol-hostpath-demo --timeout=120s && sleep 2 && kubectl logs vol-hostpath-demo
pod "vol-hostpath-demo" deleted from default namespace
pod/vol-hostpath-demo created
pod/vol-hostpath-demo condition met
written by vol-hostpath-demo at Sun Oct 18 14:07:52 UTC 2026
written by vol-hostpath-demo at Sun Oct 18 14:08:29 UTC 2026
```

_Cleanup._

```console
$ kubectl delete pod vol-hostpath-demo --wait=false
pod "vol-hostpath-demo" deleted from default namespace
```

### 3. PersistentVolume + PersistentVolumeClaim (static provisioning)

An administrator creates the **PV** (the storage), a developer asks for storage with a **PVC**, and Kubernetes **binds** them by matching size, access mode and storage class.

_**Bound**: the claim found the matching PV (STATUS Bound on both sides, CLAIM column shows default/vol-static-pvc)._

```console
$ kubectl apply -f examples/03-pv-pvc.yaml && kubectl wait --for=condition=Ready pod/vol-static-pvc-pod --timeout=120s && kubectl get pv vol-static-pv && kubectl get pvc vol-static-pvc
persistentvolume/vol-static-pv created
persistentvolumeclaim/vol-static-pvc created
pod/vol-static-pvc-pod created
pod/vol-static-pvc-pod condition met
NAME            CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                    STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
vol-static-pv   1Gi        RWO            Retain           Bound    default/vol-static-pvc   manual         <unset>                          3s
NAME             STATUS   VOLUME          CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
vol-static-pvc   Bound    vol-static-pv   1Gi        RWO            manual         <unset>                 3s
```

_The Pod wrote through the claim._

```console
$ kubectl logs vol-static-pvc-pod
static PV test, written by vol-static-pvc-pod at Sun Oct 18 14:08:35 UTC 2026
```

_**Data outlives the Pod:** a new Pod using the same claim sees the earlier line plus a new one._

```console
$ kubectl delete pod vol-static-pvc-pod --wait=true && kubectl apply -f examples/03-pv-pvc.yaml 2>&1 | grep -v unchanged; kubectl wait --for=condition=Ready pod/vol-static-pvc-pod --timeout=120s && sleep 2 && kubectl logs vol-static-pvc-pod
pod "vol-static-pvc-pod" deleted from default namespace
pod/vol-static-pvc-pod created
pod/vol-static-pvc-pod condition met
static PV test, written by vol-static-pvc-pod at Sun Oct 18 14:08:35 UTC 2026
static PV test, written by vol-static-pvc-pod at Sun Oct 18 14:09:09 UTC 2026
```

_**Lifecycle:** after the PVC is deleted the PV is not freed: with `persistentVolumeReclaimPolicy: Retain` it moves to **Released** and keeps its data until an admin cleans it up._

```console
$ kubectl delete pod vol-static-pvc-pod --wait=true && kubectl delete pvc vol-static-pvc && kubectl get pv vol-static-pv
pod "vol-static-pvc-pod" deleted from default namespace
persistentvolumeclaim "vol-static-pvc" deleted from default namespace
NAME            CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                    STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
vol-static-pv   1Gi        RWO            Retain           Released   default/vol-static-pvc   manual         <unset>                          71s
```

_Remove the PV manually (the data folder on the node stays until removed)._

```console
$ kubectl delete pv vol-static-pv && kubectl get pv
persistentvolume "vol-static-pv" deleted
No resources found
```

### 4. StorageClass and dynamic provisioning

The claim names no PV and no class, so the **default StorageClass** (`standard`) creates the volume automatically.

_**A PV appeared by itself** (its name `pvc-<uuid>` was generated) and is already Bound to my claim, with STORAGECLASS standard._

```console
$ kubectl apply -f examples/04-dynamic-pvc.yaml && kubectl wait --for=condition=Ready pod/vol-dynamic-pvc-pod --timeout=120s && kubectl get pvc vol-dynamic-pvc && kubectl get pv
persistentvolumeclaim/vol-dynamic-pvc created
pod/vol-dynamic-pvc-pod created
pod/vol-dynamic-pvc-pod condition met
NAME              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
vol-dynamic-pvc   Bound    pvc-39fa3999-49ec-4d73-a09b-f2bf08c0406f   1Gi        RWO            standard       <unset>                 1s
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                     STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-39fa3999-49ec-4d73-a09b-f2bf08c0406f   1Gi        RWO            Delete           Bound    default/vol-dynamic-pvc   standard       <unset>                          2s
```

_The claim details and the provisioning event._

```console
$ kubectl describe pvc vol-dynamic-pvc | grep -E "StorageClass|Status|Volume:|Capacity|Access Modes|ProvisioningSucceeded|provisioned"
StorageClass:  standard
Status:        Bound
Volume:        pvc-39fa3999-49ec-4d73-a09b-f2bf08c0406f
Capacity:      1Gi
Access Modes:  RWO
  Type     Status  LastProbeTime                     LastTransitionTime                Reason        Message
  Normal  ProvisioningSucceeded  2s    k8s.io/minikube-hostpath_minikube_a86a1a48-b5bc-46b9-bff7-e6b26905c882  Successfully provisioned volume pvc-39fa3999-49ec-4d73-a09b-f2bf08c0406f
```

_The Pod wrote to the dynamically created volume._

```console
$ kubectl logs vol-dynamic-pvc-pod
dynamic PVC test, written by vol-dynamic-pvc-pod at Sun Oct 18 14:09:45 UTC 2026
```

_**Reclaim policy Delete:** when the claim is deleted, the dynamically provisioned PV and its data are removed automatically ("No resources found")._

```console
$ kubectl delete pod vol-dynamic-pvc-pod --wait=true && kubectl delete pvc vol-dynamic-pvc && sleep 5 && kubectl get pv 2>&1
pod "vol-dynamic-pvc-pod" deleted from default namespace
persistentvolumeclaim "vol-dynamic-pvc" deleted from default namespace
No resources found
```

### What the experiments proved

| Volume | Survives container restart | Survives Pod deletion | Survives node loss | Created by |
|---|---|---|---|---|
| `emptyDir` | yes | **no** (data gone, shown in 1) | no | the Pod itself |
| `hostPath` | yes | **yes**, same node only (shown in 2) | no | the Pod, on the node disk |
| static PV + PVC | yes | **yes** (shown in 3; PV kept as Released) | depends on the backend | admin + developer |
| dynamic PVC | yes | **yes** while the claim exists (shown in 4) | depends on the backend | StorageClass provisioner |
