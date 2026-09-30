# Kubernetes Volumes

## `emptyDir`

Created when a Pod starts and deleted with the Pod. All containers in that Pod can share it. See [`../01-volumes/emptydir-pod.yaml`](../01-volumes/emptydir-pod.yaml).

## `hostPath`

Mounts a path from the node. It is useful for node agents and local experiments but couples a Pod to node data and needs careful security controls. See [`../01-volumes/hostpath-pod.yaml`](../01-volumes/hostpath-pod.yaml).

## PersistentVolume and PersistentVolumeClaim

A PV represents storage capacity. A PVC is a workload's request for capacity, access mode, and optionally a StorageClass. Kubernetes binds a compatible claim and volume. The static examples are in [`../02-persistent-storage/`](../02-persistent-storage/).

## StorageClass and dynamic provisioning

A StorageClass describes a provisioner and its policy. With dynamic provisioning, creating a PVC causes the provisioner to create a matching PV automatically. The example claim in [`../03-storageclass/pvc.yaml`](../03-storageclass/pvc.yaml) uses the cluster's default StorageClass.

## Practical persistence result

The mini project mounted a `500Mi` ReadWriteOnce claim at `/data`. A file containing `Student: Anshal Kumar` remained available after deleting and recreating the Pod. See the [terminal evidence](../screenshots/pvc-persistence.png) and [mini-project guide](../mini-project/README.md).
