# Task 1: Kubernetes Volumes Deep Dive

## Overview
This document covers key concepts and practical hands-on examples of Kubernetes Volume management, comparing transient and persistent storage mechanisms.

---

## 1. `emptyDir`
- **Definition**: An `emptyDir` volume is created when a Pod is assigned to a Node, and exists as long as that Pod is running on that node.
- **Lifecycle**: Tied directly to the Pod lifetime. If the container crashes, data persists; but if the Pod is deleted or rescheduled, all data inside `emptyDir` is permanently deleted.
- **Use Cases**: Temporary scratch space, disk-based cache, checkpointing long computations.

### Practical Example (`emptydir-pod.yaml`)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-demo
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: cache-volume
      mountPath: /data
  volumes:
  - name: cache-volume
    emptyDir: {}
```

---

## 2. `hostPath`
- **Definition**: A `hostPath` volume mounts a file or directory from the host node's filesystem directly into your Pod.
- **Lifecycle**: Tied to the host node's filesystem. Data persists even if the Pod is deleted, as long as the replacement Pod lands on the exact same worker node.
- **Use Cases**: Running cluster components (like CNI plugins or log collectors like Fluentd) that require direct access to host OS `/var/log` or `/var/lib/docker`.

### Practical Example (`hostpath-pod.yaml`)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-demo
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: host-logs
      mountPath: /app-logs
  volumes:
  - name: host-logs
    hostPath:
      path: /var/log
      type: Directory
```

---

## 3. PersistentVolume (PV) & PersistentVolumeClaim (PVC)
- **PersistentVolume (PV)**: A piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using StorageClasses. It is a cluster-level resource independent of any individual Pod.
- **PersistentVolumeClaim (PVC)**: A request for storage by a user/Pod. It specifies storage size, access modes (`ReadWriteOnce`, `ReadOnlyMany`, `ReadWriteMany`), and optionally a `StorageClass`.

### Practical Example (`pv-pvc.yaml`)
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

---

## 4. StorageClass & Dynamic Provisioning
- **StorageClass**: Provides a way for administrators to describe the "classes" of storage offered (e.g., standard HDD, fast SSD, cloud managed disk like AWS EBS or GCP Persistent Disk).
- **Dynamic Provisioning**: Eliminates the need for cluster admins to pre-provision PVs manually. When a user creates a PVC referencing a `StorageClass`, Kubernetes automatically provisions the underlying storage volume in real-time.

### Practical Example (`sc-pvc.yaml`)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 5Gi
```
