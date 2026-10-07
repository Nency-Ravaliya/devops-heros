# 01 — Kubernetes Volumes

**Submitted by:** Piyush Bansal

A container's filesystem is thrown away when the container restarts. Volumes are how a Pod
keeps or shares data. I went through the main types one by one and ran a small example of
each on my Docker Desktop cluster (single node `desktop-control-plane`, StorageClass
`standard` backed by `rancher.io/local-path`). Everything ran in namespace `p13-vol`.
All output below is real.

| File | What it shows |
|---|---|
| [emptydir-pod.yaml](emptydir-pod.yaml) | Two containers sharing one `emptyDir` |
| [hostpath-pod.yaml](hostpath-pod.yaml) | A node directory mounted into a Pod |
| [static-pv-pvc.yaml](static-pv-pvc.yaml) | A PV I create by hand, a PVC bound to it, and a Pod using it |
| [dynamic-pvc.yaml](dynamic-pvc.yaml) | A PVC with `storageClassName: standard`, PV created automatically |

## Quick summary

| Type | Lives as long as | Who creates the storage | Good for |
|---|---|---|---|
| `emptyDir` | the Pod | kubelet, empty at Pod start | scratch space, sharing files between containers in one Pod |
| `hostPath` | the node directory | already on the node | node agents, logs, local testing. Not for apps |
| PersistentVolume (PV) | independent of Pods | admin (static) or provisioner (dynamic) | the actual piece of storage |
| PersistentVolumeClaim (PVC) | until deleted | the app/developer | a request for storage that a Pod mounts |
| StorageClass | cluster object | admin | "type" of storage + which provisioner creates it |
| Dynamic provisioning | — | the provisioner, when a PVC appears | no admin needed to pre-create PVs |

## 1. emptyDir

An `emptyDir` is created empty when the Pod is scheduled and deleted when the Pod goes away.
All containers in the Pod can mount it, so it is the simplest way to pass files between them.
It survives a *container* restart, but not a *Pod* delete.

My Pod has a `writer` (busybox) that appends the date every 5 s, and `web` (nginx) that
mounts the same volume as its html folder:

```text
$ kubectl apply -f emptydir-pod.yaml
pod/emptydir-demo created
$ kubectl get pod emptydir-demo -n p13-vol
NAME            READY   STATUS    RESTARTS   AGE
emptydir-demo   2/2     Running   0          96s
$ kubectl exec -n p13-vol emptydir-demo -c web -- cat /usr/share/nginx/html/index.html
Wed Oct  7 14:47:53 UTC 2026
Wed Oct  7 14:47:58 UTC 2026
Wed Oct  7 14:48:04 UTC 2026
Wed Oct  7 14:48:10 UTC 2026
Wed Oct  7 14:48:16 UTC 2026
Wed Oct  7 14:48:21 UTC 2026
Wed Oct  7 14:48:26 UTC 2026
Wed Oct  7 14:48:31 UTC 2026
Wed Oct  7 14:48:37 UTC 2026
Wed Oct  7 14:48:42 UTC 2026
Wed Oct  7 14:48:47 UTC 2026
Wed Oct  7 14:48:52 UTC 2026
Wed Oct  7 14:48:57 UTC 2026
Wed Oct  7 14:49:02 UTC 2026
Wed Oct  7 14:49:07 UTC 2026
Wed Oct  7 14:49:12 UTC 2026
Wed Oct  7 14:49:17 UTC 2026
$ kubectl exec -n p13-vol emptydir-demo -c writer -- ls -l /out
total 4
-rw-r--r--    1 root     root           493 Oct  7 14:49 index.html
```

The file written by `writer` at `/out` is read by `web` at `/usr/share/nginx/html`, same volume.
Now delete the Pod and create it again:

```text
$ kubectl delete pod emptydir-demo -n p13-vol
pod "emptydir-demo" deleted from p13-vol namespace
$ kubectl apply -f emptydir-pod.yaml
pod/emptydir-demo created
$ kubectl exec -n p13-vol emptydir-demo -c web -- cat /usr/share/nginx/html/index.html
Wed Oct  7 14:49:55 UTC 2026
```

Only one line: the old history is gone because the new Pod got a fresh empty directory.

## 2. hostPath

`hostPath` mounts a file or directory from the node's own filesystem. Data stays after the Pod is
deleted, but only on that node. If the Pod moves to another node it sees a different (empty)
directory. It also gives the Pod access to the node, which is a security risk, so it is mostly
used by system DaemonSets (log collectors, CNI) and for local testing.

```text
$ kubectl apply -f hostpath-pod.yaml
pod/hostpath-demo created
$ kubectl exec -n p13-vol hostpath-demo -- sh -c 'echo written-by-pod-1 > /data/note.txt'
$ kubectl get pod hostpath-demo -n p13-vol -o wide
NAME            READY   STATUS    RESTARTS   AGE   IP            NODE                    NOMINATED NODE   READINESS GATES
hostpath-demo   1/1     Running   0          5s    10.244.0.21   desktop-control-plane   <none>           <none>
$ docker exec desktop-control-plane cat /tmp/p13-hostpath-data/note.txt
written-by-pod-1
```

On Docker Desktop the node is a container named `desktop-control-plane`, so I could read the file
straight from the node. Deleting and recreating the Pod keeps the data:

```text
$ kubectl delete pod hostpath-demo -n p13-vol
pod "hostpath-demo" deleted from p13-vol namespace
$ kubectl apply -f hostpath-pod.yaml
pod/hostpath-demo created
$ kubectl exec -n p13-vol hostpath-demo -- cat /data/note.txt
written-by-pod-1
```

## 3. PersistentVolume and PersistentVolumeClaim (static provisioning)

- A **PersistentVolume (PV)** is a cluster-wide object describing a real piece of storage
  (size, access mode, reclaim policy, and the backend such as hostPath, NFS, EBS).
- A **PersistentVolumeClaim (PVC)** lives in a namespace and asks for storage
  ("I need 500Mi, ReadWriteOnce"). Kubernetes binds it to a matching PV. The Pod only refers to the PVC,
  so the app does not need to know where the disk actually is.

Access modes: `ReadWriteOnce` (one node read-write), `ReadOnlyMany`, `ReadWriteMany`, `ReadWriteOncePod`.
Reclaim policy decides what happens to the PV when the PVC is deleted: `Retain` keeps it and the data,
`Delete` removes it.

### Something I hit first

I first applied the session's `02-persistent-storage/pvc.yaml` as it is (renamed so it would not clash).
It did **not** bind to the hand-made PV. It picked up the default StorageClass instead:

```text
$ sed 's/student-pvc/course-pvc/' ../../02-persistent-storage/pvc.yaml | kubectl apply -n p13-vol -f -
persistentvolumeclaim/course-pvc created
$ kubectl get pvc course-pvc -n p13-vol
NAME         STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
course-pvc   Pending                                      standard       <unset>                 4s
$ kubectl describe pvc course-pvc -n p13-vol | sed -n '/^Events/,$p'
Events:
  Type    Reason                Age              From                         Message
  ----    ------                ----             ----                         -------
  Normal  WaitForFirstConsumer  0s (x2 over 5s)  persistentvolume-controller  waiting for first consumer to be created before binding
```

A PVC with no `storageClassName` gets the default class (`standard`) filled in. So for static binding
I set `storageClassName: ""` on both the PV and the PVC (and `volumeName` to pin the PVC to my PV).

### Static PV + PVC run

```text
$ kubectl apply -f static-pv-pvc.yaml
persistentvolume/p13-student-pv created
persistentvolumeclaim/student-pvc created
pod/storage-demo created
$ kubectl get pv p13-student-pv
NAME             CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
p13-student-pv   1Gi        RWO            Retain           Bound    p13-vol/student-pvc                  <unset>                          9s
$ kubectl get pvc student-pvc -n p13-vol
NAME          STATUS   VOLUME           CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
student-pvc   Bound    p13-student-pv   1Gi        RWO                           <unset>                 9s
```

The PVC asked for 500Mi but shows 1Gi: it gets the whole PV it was bound to.

Data survives the Pod being deleted:

```text
$ kubectl exec -n p13-vol storage-demo -- sh -c 'echo hello-from-pvc > /data/file.txt'
$ kubectl delete pod storage-demo -n p13-vol
pod "storage-demo" deleted from p13-vol namespace
$ kubectl apply -f static-pv-pvc.yaml
persistentvolume/p13-student-pv configured
persistentvolumeclaim/student-pvc unchanged
pod/storage-demo created
$ kubectl exec -n p13-vol storage-demo -- cat /data/file.txt
hello-from-pvc
```

`Retain` in action: deleting the PVC leaves the PV `Released` and the data still on disk:

```text
$ kubectl delete pod storage-demo -n p13-vol
pod "storage-demo" deleted from p13-vol namespace
$ kubectl delete pvc student-pvc -n p13-vol
persistentvolumeclaim "student-pvc" deleted from p13-vol namespace
$ kubectl get pv p13-student-pv
NAME             CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                 STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
p13-student-pv   1Gi        RWO            Retain           Released   p13-vol/student-pvc                  <unset>                          2m15s
$ docker exec desktop-control-plane cat /tmp/p13-student-data/file.txt
hello-from-pvc
```

A `Released` PV is not reused automatically. An admin has to clean it up (or remove `claimRef`) first.

## 4. StorageClass

A StorageClass describes a kind of storage and names the **provisioner** that can create it.
Important fields: `provisioner`, `reclaimPolicy`, `volumeBindingMode`, `allowVolumeExpansion`,
and the `is-default-class` annotation.

```text
$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
hostpath             rancher.io/local-path   Delete          WaitForFirstConsumer   false                  147m
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  147m
$ kubectl get sc standard -o yaml | grep -E 'provisioner|reclaimPolicy|volumeBindingMode|is-default'
      {"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"},"name":"standard"},"provisioner":"rancher.io/local-path","reclaimPolicy":"Delete","volumeBindingMode":"WaitForFirstConsumer"}
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

`WaitForFirstConsumer` means the volume is not created until a Pod using the PVC is scheduled,
so the volume ends up on the same node as the Pod. That is why `course-pvc` above stayed `Pending`:
no Pod was using it. On a cloud cluster the class would point at e.g. `ebs.csi.aws.com` instead.

## 5. Dynamic provisioning

With a StorageClass I only write the PVC. The provisioner sees it and creates a matching PV.

```text
$ kubectl apply -f dynamic-pvc.yaml
persistentvolumeclaim/dynamic-pvc created
pod/dynamic-demo created
$ kubectl get pvc dynamic-pvc -n p13-vol
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
dynamic-pvc   Bound    pvc-e016409f-b81c-40f4-97c9-8fcd3fa15b83   500Mi      RWO            standard       <unset>                 17s
$ kubectl get pv | grep -E 'NAME|p13-vol/dynamic-pvc'
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                 STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-e016409f-b81c-40f4-97c9-8fcd3fa15b83   500Mi      RWO            Delete           Bound      p13-vol/dynamic-pvc   standard       <unset>                          4s
$ kubectl describe pvc dynamic-pvc -n p13-vol | sed -n '/^Events/,$p'
Events:
  Type    Reason                 Age               From                                                                                                Message
  ----    ------                 ----              ----                                                                                                -------
  Normal  WaitForFirstConsumer   17s               persistentvolume-controller                                                                         waiting for first consumer to be created before binding
  Normal  Provisioning           16s               rancher.io/local-path_local-path-provisioner-855c7b7774-vpq4c_f86a7179-4a22-4fe3-bc39-c248f685eb5b  External provisioner is provisioning volume for claim "p13-vol/dynamic-pvc"
  Normal  ExternalProvisioning   5s (x3 over 16s)  persistentvolume-controller                                                                         Waiting for a volume to be created either by the external provisioner 'rancher.io/local-path' or manually by the system administrator. If volume creation is delayed, please verify that the provisioner is running and correctly registered.
  Normal  ProvisioningSucceeded  4s                rancher.io/local-path_local-path-provisioner-855c7b7774-vpq4c_f86a7179-4a22-4fe3-bc39-c248f685eb5b  Successfully provisioned volume pvc-e016409f-b81c-40f4-97c9-8fcd3fa15b83
$ kubectl exec -n p13-vol dynamic-demo -- sh -c 'echo dynamic-data > /data/d.txt; df -h /data'
Filesystem                Size      Used Available Use% Mounted on
/dev/vda1               223.6G      7.5G    204.7G   4% /data
```

The events show the whole flow: wait for a Pod, provisioner creates `pvc-e016...`, claim binds.
(`df` shows the node disk size because local-path is just a folder on the node; the 500Mi is not
enforced by this provisioner.)

Because the class has `reclaimPolicy: Delete`, deleting the PVC removes the PV too:

```text
$ kubectl delete pod dynamic-demo -n p13-vol
pod "dynamic-demo" deleted from p13-vol namespace
$ kubectl delete pvc dynamic-pvc -n p13-vol
persistentvolumeclaim "dynamic-pvc" deleted from p13-vol namespace
$ kubectl get pv pvc-e016409f-b81c-40f4-97c9-8fcd3fa15b83
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                 STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-e016409f-b81c-40f4-97c9-8fcd3fa15b83   500Mi      RWO            Delete           Released   p13-vol/dynamic-pvc   standard       <unset>                          60s
$ kubectl get pv pvc-e016409f-b81c-40f4-97c9-8fcd3fa15b83
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS        CLAIM                 STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-e016409f-b81c-40f4-97c9-8fcd3fa15b83   500Mi      RWO            Delete           Terminating   p13-vol/dynamic-pvc   standard       <unset>                          3m33s
$ kubectl get pv pvc-e016409f-b81c-40f4-97c9-8fcd3fa15b83
Error from server (NotFound): persistentvolumes "pvc-e016409f-b81c-40f4-97c9-8fcd3fa15b83" not found
```

It went `Released` → `Terminating` → gone (local-path runs a small helper Pod to wipe the folder,
which took a few minutes on my busy cluster). Compare with the `Retain` PV in section 3, which stayed.

## Cleanup

```bash
kubectl delete ns p13-vol
kubectl delete pv p13-student-pv
```

## What I learned

- `emptyDir` is per Pod, `hostPath` is per node, PV/PVC is independent of both.
- Pods should use PVCs, not PVs directly. The PVC is the app's "ask", the PV is the actual disk.
- A PVC without `storageClassName` silently uses the default class. To bind to a hand-made PV
  I had to set `storageClassName: ""`.
- `WaitForFirstConsumer` keeps a PVC `Pending` until a Pod uses it. That is normal, not an error.
- Reclaim policy matters: `Retain` keeps my data after the PVC is gone, `Delete` (the default for
  dynamic volumes) wipes it.
