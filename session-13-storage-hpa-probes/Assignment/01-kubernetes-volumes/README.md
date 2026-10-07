# Kubernetes Volumes

## What is a Volume?

****A Kubernetes Volume provides storage that can be mounted inside a Pod.****

By default, data stored inside a container can be lost when the container is removed or recreated.

Volumes allow containers to:
- Store data
- Share data between containers
- Persist data beyond container restarts
- Use external or dynamically provisioned storage

Basic flow:

```
Pod 
 ↓ 
Volume 
 ↓ 
Storage
```

---

## emptyDir

****emptyDir creates a temporary directory when a Pod starts****

The directory is shared between containers inside the same Pod.

Example:

volumes:
 name: shared-data
 emptyDir: {}

Characteristics:
- Created when Pod starts
- Empty initially 
- Can be shared between containers
- Data remains while the Pod exists
- Data is deleted when the Pod is removed

Common use cases:
- Temporary files
- Caching
- Sharing data between containers

Example:

```
Container A 
    ↓ 
emptyDir 
    ↑ 
Container B
```

---

## hostPath

****hostPath mounts a directory or file from the Kubernetes node into a Pod****

Example:

volumes:
 name: host-data
 hostPath:
    path: /data

Flow:

```
Kubernetes Node 
      ↓ 
    /data 
      ↓ 
    Pod
```

Characteristics:
- Uses storage from the node
- Data can survive Pod deletion
- Data is tied to that specific node
- Can cause problems when Pods move to another node

Common use cases:

- Node-level applications
- Logging agents
- Developement/testing


hostPath should generally be avoided for portable production workloads

---

## Persistent Storage

### PersistentVolume

****PV = PersistentVolume****
****A PersistentVolume is a piece of storage available to Kubernetes for persistent data****

The storage exists independently of a Pod

Example:

```
Pod 
 ↓ 
PVC 
 ↓ 
PV 
 ↓ 
Storage
```

A PV can represent storage such as:
- AWS EBS
- NFS
- Cloud Storage
- Local storage

Example:

apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce

---

### PersistentVolumeClaim

****PVC = PersistentVolumeClaim****
****A PVC is a request for storage made by a user or application****

Instead of directly using a PV, a Pod requests storage through a PVC.

Example:

```
Pod
 ↓
PVC
 ↓
PV
 ↓
Storage
```

Example:

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-aws
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi

The PVC specifies requirements such as:

- Storage size
- Access mode
- Storage class

Basic Idea:

PV = Provides Storage

PVC = Requests Storage

---

## Access Modes

****Access modes define how a volume can be mounted****

Common modes:

ReadWriteOnce (RWO):
-> Volume can be mounted read-write by one node

ReadOnlyMany (ROX):
-> Volume can be mounted read-only by multiple nodes

ReadWriteMany (RWX):
-> VOlume can be mounted read-write by mulitple nodes

Support depends on the storage backend

---

## StorageClass

****A StorageClass defined how Kubernetes should provision storage****

It allows different types of storage to be configured

Example:

```
StorageClass 
    ↓ 
Storage Provisioner 
    ↓ 
Storage
```

A StorageClass can define:
- Provisioner
- Storage type
- Parameters
- Reclaim policy
- Volume biniding behavior

Example:

apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage

A PVC can request a specific StorageClass:

storageClassName: fast-storage

Common use cases:

- Fast SSD storage
- Standard storage
- Clound block storage
- Different storage types for different workloads

---

## Dynamic Provisioning

****Dynamic provisioning automatically creates a PV when a PVC requestts storage****

Without dynamic provisioning:

```
Admin
 ↓
Create PV
 ↓
PVC
 ↓
Pod
```

With dynamic provisioning;

```
PVC
 ↓ 
StorageClass 
 ↓ 
Provisioner 
 ↓ 
PV automatically created 
 ↓ 
Pod
```

Example:

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage
spec:
  storageClassName: fast-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi

Kubernetes uses the StorageClass to automatically provision the required storage

---

## PV vs PVC vs StorageClass

**StorageClass => Defines how storage is created**
**PV => Actual storage available to Kubernetes**
**PVC => Request for storage**
**Pod => Uses PVC***

In simple terms:

- emptyDir -> Temporary Pod Storage
- hostPath -> Storage from Kubernetes node
- PV -> Persistent storage resource
- PVC -> Request for persistent storage
- StorageClass -> Defines how storage is provisioned
- Dynamic Provisioning -> Automatically create storage for PVC

### Common Architecture

```
        StorageClass 
              ↓ 
             PVC 
              ↓ 
             PV 
              ↓ 
        Actual Storage 
              ↑ 
             Pod
```
---