# Kubernetes volumes

## emptyDir

An emptyDir is created when the Pod is scheduled and deleted when the Pod is removed. It is shared by containers in that Pod. Use it for a cache or a scratch space. A container restart keeps the data. A Pod recreate does not.

## hostPath

A hostPath mounts a file or directory from the node into the Pod. It survives Pod restarts on that same node and is how some system agents read `/var/log`. It pins you to one node, breaks when the Pod moves, and is a security risk if the path is the host root. Avoid it for application data.

## PersistentVolume

A PV is a piece of storage in the cluster: a disk, an NFS export, or a cloud volume. An administrator can create it by hand, or a provisioner can create it when a claim asks for storage.

## PersistentVolumeClaim

A PVC is a request: size, access mode (`ReadWriteOnce`, `ReadWriteMany`, `ReadOnlyMany`), and optional StorageClass. The Pod mounts the claim, not the underlying disk. The binder matches the claim to a PV.

## StorageClass

A StorageClass names a provisioner and its parameters (`gp3`, `standard`, `csi.example.com`). The claim's `storageClassName` selects it. The default class is used when the claim omits the name and a default is marked.

## Dynamic provisioning

With a StorageClass, creating a PVC is enough. The provisioner creates the cloud disk, creates the PV, and binds the claim. You do not pre-create PVs. The Session 13 mini project does this with `web-data` (500Mi, `ReadWriteOnce`, class `standard` on Minikube hostPath).

```bash
kubectl apply -f ../../../session-13-storage-hpa-probes/mini-project/pvc.yaml
kubectl get pvc,pv
```

The HPA lab for this session is [../hpa.yaml](../hpa.yaml). The production mini project manifests already live in `session-13-storage-hpa-probes/mini-project/`.
