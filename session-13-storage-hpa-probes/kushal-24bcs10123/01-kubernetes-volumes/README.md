# Task 1 – Kubernetes Volumes

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123  
**Cluster:** kind `kushal-lab` (Kubernetes v1.37.0, 3 nodes), default StorageClass `standard` = `rancher.io/local-path`.

Every example below was applied on the cluster with the professor's manifests from `01-volumes/`, `02-persistent-storage/` and `03-storageclass/`. The script is [`../scripts/01-volumes.sh`](../scripts/01-volumes.sh), the raw output is [`../logs/01-volumes.txt`](../logs/01-volumes.txt). Commands run in the namespace `s13-volumes`.

## Why volumes

A container's filesystem is a writable layer on top of the image. When the container is replaced (crash, restart, new pod) that layer is thrown away. A volume is a directory that is mounted into the container from *outside* its filesystem, so its lifetime is decided by something other than the container. The question for every volume type is simply: **what is its lifetime tied to?**

| Type | Lifetime tied to | Shared between pods? | Survives pod delete? | Survives node change? |
|---|---|---|---|---|
| `emptyDir` | the Pod | containers of the same pod | no | no |
| `hostPath` | the Node's directory | pods on that node | yes, if the next pod lands on the same node | no |
| `PersistentVolume` + `PersistentVolumeClaim` | the PV object (and its reclaim policy) | whoever binds the claim (access mode) | yes | depends on the backing storage |
| `StorageClass` (dynamic) | the PVC – the PV is created and deleted for it | same as PV/PVC | yes | depends on the provisioner |

## 1. emptyDir

```yaml
volumes:
  - name: app-storage
    emptyDir: {}
```

An empty directory created on the node when the pod is scheduled, deleted when the pod is deleted. It survives *container* restarts inside the pod, which I checked by killing PID 1 (nginx) and reading the file from the restarted container:

```text
$ kubectl -n s13-volumes exec emptydir-demo -- sh -c 'echo "Hello Kubernetes" > /data/message.txt'
$ kubectl -n s13-volumes exec emptydir-demo -- df -h /data | tail -1
/dev/vda1       126G   30G   90G  25% /data                  <- just a directory on the node's root disk

$ kubectl -n s13-volumes exec emptydir-demo -- sh -c 'kill 1'; sleep 8; kubectl -n s13-volumes get pod emptydir-demo
emptydir-demo   1/1     Running   1 (8s ago)   9s             <- RESTARTS 1, same pod
$ kubectl -n s13-volumes exec emptydir-demo -- cat /data/message.txt
Hello Kubernetes                                              <- still there

$ kubectl -n s13-volumes delete pod emptydir-demo
$ kubectl -n s13-volumes apply -f 01-volumes/emptydir-pod.yaml
$ kubectl -n s13-volumes exec emptydir-demo -- cat /data/message.txt
cat: /data/message.txt: No such file or directory             <- new pod = new, empty directory
```

Use it for scratch space, caches, and for two containers in one pod that need to exchange files (`emptyDir.medium: Memory` makes it a tmpfs).

## 2. hostPath

```yaml
volumes:
  - name: host-storage
    hostPath:
      path: /tmp/hostpath-data
      type: DirectoryOrCreate
```

Mounts a directory of the **node** into the pod. The data outlives the pod – but only on that node. I proved both halves by forcing the second pod onto the other worker with `nodeName`:

```text
$ kubectl -n s13-volumes exec hostpath-demo -- sh -c 'echo "written by pod on $(hostname)" > /data/node-file.txt'
pod runs on node: kushal-lab-worker
$ docker exec kushal-lab-worker cat /tmp/hostpath-data/node-file.txt        # the file is visible on the node itself
written by pod on hostpath-demo

$ kubectl -n s13-volumes delete pod hostpath-demo
# same manifest + nodeName: kushal-lab-worker2
new pod runs on node: kushal-lab-worker2
$ kubectl -n s13-volumes exec hostpath-demo -- cat /data/node-file.txt
cat: /data/node-file.txt: No such file or directory
-> file missing: hostPath is a directory of ONE node
$ docker exec kushal-lab-worker2 ls -la /tmp/hostpath-data/
total 0                                                                       <- DirectoryOrCreate made an empty dir here

# same manifest + nodeName: kushal-lab-worker
$ kubectl -n s13-volumes exec hostpath-demo -- cat /data/node-file.txt
written by pod on hostpath-demo                                               <- back on the original node, the data is back
```

So hostPath "persists" only by accident of scheduling. It is for node-level things (log collectors reading `/var/log`, CNI/CSI plugins, the `local-path` provisioner itself), not for application data. It also gives the pod a view of the host filesystem, which is a security concern.

## 3. PersistentVolume and PersistentVolumeClaim (static provisioning)

The PV is the *supply* (a piece of storage the admin registered in the cluster, cluster-scoped), the PVC is the *demand* (a namespaced request: size + access mode). Kubernetes binds a claim to a volume that satisfies it; the pod only references the claim, so the pod manifest never knows where the data really lives.

```yaml
# pv.yaml                                   # pvc.yaml                      # pod.yaml
kind: PersistentVolume                      kind: PersistentVolumeClaim     volumes:
spec:                                       spec:                             - name: persistent-storage
  capacity: { storage: 1Gi }                  accessModes: [ReadWriteOnce]      persistentVolumeClaim:
  accessModes: [ReadWriteOnce]                resources:                          claimName: student-pvc
  persistentVolumeReclaimPolicy: Retain         requests: { storage: 500Mi }
  hostPath: { path: /tmp/student-data }
```

### The trap I ran into first

```text
$ kubectl apply -f 02-persistent-storage/pv.yaml
student-pv   1Gi   RWO   Retain   Available
$ kubectl -n s13-volumes apply -f 02-persistent-storage/pvc.yaml
$ kubectl -n s13-volumes get pvc student-pvc
student-pvc   Pending   ...   STORAGECLASS standard                     <- ??? it did not bind to student-pv
$ kubectl -n s13-volumes get pvc student-pvc -o jsonpath='storageClassName={.spec.storageClassName}'
storageClassName=standard
```

The PVC has no `storageClassName`, so the admission controller filled in the cluster **default** class (`standard`). A claim with a class only binds to PVs of that class, and my hand-made PV has none, so the claim waits for *dynamic* provisioning instead (and on my first attempt it was indeed satisfied by a brand-new local-path volume, not by `student-pv`). To use a pre-created PV on a cluster that has a default StorageClass the claim must say `storageClassName: ""` explicitly:

```text
$ awk '/^spec:/{print; print "  storageClassName: \"\""; next}1' 02-persistent-storage/pvc.yaml | kubectl -n s13-volumes apply -f -
$ kubectl -n s13-volumes get pvc student-pvc
student-pvc   Bound    student-pv   1Gi        RWO
$ kubectl get pv student-pv
student-pv   1Gi   RWO   Retain   Bound   s13-volumes/student-pvc              <- CLAIM column filled
```

### Data survives the pod

```text
$ kubectl -n s13-volumes exec storage-demo -- sh -c 'echo "Student: Kushal Talati 24BCS10123" > /data/student-data.txt'
$ kubectl -n s13-volumes delete pod storage-demo
$ kubectl -n s13-volumes apply -f 02-persistent-storage/pod.yaml
$ kubectl -n s13-volumes exec storage-demo -- cat /data/student-data.txt
Student: Kushal Talati 24BCS10123                                            <- survived the pod deletion

$ kubectl -n s13-volumes get pvc student-pvc -o jsonpath='requested={.spec.resources.requests.storage} got={.status.capacity.storage}'
requested=500Mi got=1Gi                                                      <- binding is whole-PV: you get all of it
```

### Reclaim policy `Retain`

```text
$ kubectl -n s13-volumes delete pvc student-pvc
$ kubectl get pv student-pv
student-pv   1Gi   RWO   Retain   Released   s13-volumes/student-pvc           <- not Available
$ kubectl -n s13-volumes apply -f <same pvc>; kubectl -n s13-volumes get pvc student-pvc
student-pvc   Pending                                                        <- a Released PV is never re-bound automatically
```

`Retain` keeps the data and the PV object but marks it `Released`; it still remembers the old claim (`claimRef`). An admin has to either delete the PV (data stays on disk) or clear `spec.claimRef` to make it `Available` again. That is the safe default for real data. `Delete` (what the dynamic class below uses) removes the backing storage with the claim.

## 4. StorageClass and dynamic provisioning

With a StorageClass nobody creates PVs by hand: the PVC names a class, the class names a provisioner, the provisioner creates a PV sized for the claim.

```text
$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false
```

```yaml
kind: PersistentVolumeClaim
metadata: { name: dynamic-pvc }
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: standard
  resources: { requests: { storage: 500Mi } }
```

```text
$ kubectl -n s13-volumes apply -f 03-storageclass/pvc.yaml
$ kubectl -n s13-volumes get pvc dynamic-pvc
dynamic-pvc   Pending   ...   standard
$ kubectl -n s13-volumes describe pvc dynamic-pvc | grep -A3 '^Events'
  Normal  WaitForFirstConsumer  3s  persistentvolume-controller  waiting for first consumer to be created before binding
```

`VolumeBindingMode: WaitForFirstConsumer` means the volume is not provisioned until a pod actually uses the claim – for node-local storage the provisioner has to know on which node the pod will run. As soon as a pod referenced the claim:

```text
$ kubectl -n s13-volumes get pvc dynamic-pvc
dynamic-pvc   Bound    pvc-82f130ab-c094-4373-a6ea-db57afc48578   500Mi   RWO   standard
$ kubectl get pv | grep dynamic-pvc
pvc-82f130ab-...   500Mi   RWO   Delete   Bound   s13-volumes/dynamic-pvc   standard        <- created for me, named pvc-<uid>
$ kubectl -n local-path-storage logs deploy/local-path-provisioner | grep dynamic-pvc
... "Volume pvc-82f130ab-... has been created on kushal-lab-worker:/var/local-path-provisioner/pvc-82f130ab-..._s13-volumes_dynamic-pvc"
```

The provisioner is itself a pod (`local-path-provisioner` in `local-path-storage`) that watches PVCs and creates a directory under `/var/local-path-provisioner/` on the chosen node, then a PV pointing at it. Data survived a pod delete/re-create exactly like the static PV (`dynamic` was read back). Reclaim policy is `Delete`:

```text
$ kubectl -n s13-volumes delete pvc dynamic-pvc
$ kubectl get pv pvc-82f130ab-c094-4373-a6ea-db57afc48578
Error from server (NotFound): persistentvolumes "pvc-82f130ab-..." not found             <- PV (and the directory) gone with the claim
```

This is how cloud clusters work too: the class is `gp3` / `standard-rwo` / `managed-csi`, the provisioner is the cloud CSI driver, and the PV is an EBS / Persistent Disk / Azure Disk created on demand.

## What I understood

* The pod never owns storage; it mounts something whose lifetime is defined elsewhere. `emptyDir` → pod, `hostPath` → node, PVC → PV object.
* PV/PVC is the abstraction that separates "I need 500Mi RWO" from "it is a hostPath on worker 1" or "it is an EBS volume". That is what lets the same Deployment YAML run on kind and on EKS.
* A default StorageClass silently changes what a PVC means: a claim without `storageClassName` is a request for *dynamic* storage, and will not bind to a hand-made PV unless `storageClassName: ""` is set.
* `WaitForFirstConsumer` + `Pending` is normal, not an error – the claim binds when a pod needs it.
* Reclaim policy is the question "when the claim is gone, is the data gone?": `Retain` (Released, manual cleanup) for data you care about, `Delete` for disposable volumes.
* `ReadWriteOnce` is per node, not per pod: in the mini project both replicas mounted the same RWO local-path PVC because the scheduler put them on the same node.
