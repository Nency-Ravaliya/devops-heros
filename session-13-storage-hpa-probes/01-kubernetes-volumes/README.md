# Kubernetes Volumes & Storage Fundamentals

This document provides in-depth technical documentation and examples for Kubernetes storage mechanisms.

---

## 1. Storage Types Comparison

| Volume Type | Lifecycle | Node-Specific? | Persistence Level | Primary Use Case |
|---|---|---|---|---|
| **emptyDir** | Tied to Pod lifecycle | Yes | Ephemeral (lost on pod termination) | Temporary cache, scratch space, inter-container file sharing |
| **hostPath** | Tied to Node filesystem | Yes | Node-persistent (lost if pod moves node) | DaemonSets inspecting host logs or docker socket |
| **PersistentVolume (PV)** | Independent cluster object | No (Cloud/NFS) | Fully Persistent across pod restarts & re-schedules | Stateful applications, databases (Postgres, Redis) |
| **PersistentVolumeClaim (PVC)** | User binding to a PV | No | Persistent | Pod volume mount request |
| **StorageClass** | Dynamic volume provisioner | Cloud/CSI managed | Fully Persistent | Automatic volume creation on-demand |

---

## 2. Practical Examples & Manifests

### 1. `emptyDir` Example
An `emptyDir` volume is initially empty. All containers in the Pod can read and write the same files in the `emptyDir` volume.
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-demo
spec:
  containers:
    - name: writer
      image: alpine
      command: ["/bin/sh", "-c", "echo 'Cached Data' > /cache/data.txt; sleep 3600"]
      volumeMounts:
        - mountPath: /cache
          name: shared-storage
    - name: reader
      image: alpine
      command: ["/bin/sh", "-c", "cat /cache/data.txt; sleep 3600"]
      volumeMounts:
        - mountPath: /cache
          name: shared-storage
  volumes:
    - name: shared-storage
      emptyDir: {}
```

---

### 2. `hostPath` Example
Mounts a file or directory from the host node's filesystem directly into your Pod.
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-demo
spec:
  containers:
    - name: node-log-inspector
      image: alpine
      command: ["tail", "-f", "/host-logs/syslog"]
      volumeMounts:
        - mountPath: /host-logs
          name: host-logs-volume
  volumes:
    - name: host-logs-volume
      hostPath:
        path: /var/log
        type: Directory
```

---

### 3. PersistentVolume (PV) & PersistentVolumeClaim (PVC)
* **PV (The Resource):** Represents a physical storage volume provisioned in the cluster.
* **PVC (The Request):** A developer's request for storage specifying size and access modes (`ReadWriteOnce`, `ReadOnlyMany`, `ReadWriteMany`).

#### Static PV Definition:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: static-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/data
```

#### PVC Definition:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```

---

### 4. StorageClass & Dynamic Provisioning
Without StorageClasses, cluster administrators must manually provision PVs beforehand (Static Provisioning).  
With a **StorageClass**, Kubernetes communicates with cloud storage APIs (AWS EBS, GCP PD, Azure Disk) or CSI provisioners to **automatically create** storage on the fly whenever a PVC is created (Dynamic Provisioning).

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ebs
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
```
