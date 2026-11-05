# Kubernetes Volumes & Storage

**Name:** Smit Rupani  
**Enrollment:** 24bcs10256  

---

## 1. emptyDir
An `emptyDir` volume is initially empty and is created when a Pod is assigned to a Node. It exists for the lifetime of that Pod.
- **Use Cases:** Temporary scratch space, cache, inter-container file sharing in a multi-container Pod.
- **Lifecycle:** Deleted permanently when the Pod is removed or crashes out of the node.
- **Example:**
```yaml
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir: {}
```

![Emptydir](emptydir.png)

---

## 2. hostPath
A `hostPath` volume mounts a file or directory from the host node's filesystem directly into your Pod.
- **Use Cases:** Running containerized agents that need access to Docker socket (`/var/run/docker.sock`) or node log files (`/var/log`).
- **Limitation:** Security risk and breaks Pod portability across multi-node clusters.
- **Example:**
```yaml
volumes:
- name: node-logs
  hostPath:
    path: /var/log
    type: Directory
```

---

## 3. PersistentVolume (PV)
A `PersistentVolume` is a cluster-level storage resource provisioned by an administrator or dynamically provisioned via Storage Classes.
- Exists independently of any Pod lifecycle.
- Specifies capacity, access modes (`ReadWriteOnce`, `ReadOnlyMany`, `ReadWriteMany`), and reclaim policy (`Retain`, `Delete`).

---

## 4. PersistentVolumeClaim (PVC)
A `PersistentVolumeClaim` is a storage request made by a user or application Pod.
- Pods request storage size (e.g. `10Gi`) and access modes.
- Kubernetes matches and binds the PVC to a suitable PV.
- **Example:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

---

## 5. StorageClass & Dynamic Provisioning
`StorageClass` enables administrators to define the "classes" of storage offered (e.g., standard, fast-ssd, gp3) and provisions storage on-demand.
- **Dynamic Provisioning:** Instead of cluster admins manually creating hundreds of static PVs, the CSI storage provisioner automatically creates cloud disks (e.g. AWS EBS, GCP PD) the moment a PVC requests that StorageClass.
