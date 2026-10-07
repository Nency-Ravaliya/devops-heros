# Task 1: Kubernetes Volumes

This document outlines the core concepts of Kubernetes storage and volume management, detailing how data persistence, sharing, and provisioning are handled within a cluster.

---

### 1. emptyDir
An `emptyDir` volume is created when a Pod is assigned to a Node. As the name implies, it is initially empty. All containers in the Pod can read and write to the same files in the `emptyDir` volume. 
* **Lifecycle:** Tied strictly to the Pod. When a Pod is removed from a node for any reason, the data in the `emptyDir` is deleted permanently. 
* **Use Cases:** Scratch space (e.g., for a disk-based merge sort), checkpointing a long computation for recovery from crashes, or sharing files between a sidecar container and a main application container.

**Practical Example:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-pod
spec:
  containers:
  - name: data-writer
    image: busybox
    command: ["/bin/sh", "-c", "echo 'Hello from writer' > /shared/data.txt; sleep 3600"]
    volumeMounts:
    - mountPath: /shared
      name: shared-storage
  - name: data-reader
    image: busybox
    command: ["/bin/sh", "-c", "cat /shared/data.txt; sleep 3600"]
    volumeMounts:
    - mountPath: /shared
      name: shared-storage
  volumes:
  - name: shared-storage
    emptyDir: {}
```

---

### 2. hostPath
A `hostPath` volume mounts a file or directory directly from the host node's filesystem into your Pod.
* **Lifecycle:** Data persists on the specific node's disk, but if the Pod is rescheduled to a different node, it will not have access to the same data.
* **Use Cases:** Running containerized system-level agents (like DaemonSets for log forwarding or monitoring) that need access to node-level directories like `/var/log` or Docker internals.
* **Warning:** Presents significant security risks if not strictly controlled, as it can allow Pods to modify the underlying host OS.

**Practical Example:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-pod
spec:
  containers:
  - name: node-logger
    image: busybox
    command: ["/bin/sh", "-c", "tail -f /var/log/syslog"]
    volumeMounts:
    - mountPath: /var/log/syslog
      name: node-syslog
  volumes:
  - name: node-syslog
    hostPath:
      path: /var/log/syslog
      type: File
```

---

### 3. PersistentVolume (PV)
A PersistentVolume is a piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned. It is a cluster-scoped resource (like a Node) that captures the details of the implementation of the storage, be it NFS, cloud provider-specific storage (AWS EBS, GCP Persistent Disk), or a local disk.
* **Purpose:** Decouples storage provisioning from Pod lifecycles. Data on a PV persists independently of any individual Pod.

### 4. PersistentVolumeClaim (PVC)
A PersistentVolumeClaim is a request for storage by a user/Pod. It is a namespace-scoped resource. If a PV is the "actual disk", a PVC is a "voucher" requesting a disk of a certain size and access mode.
* **Binding:** Kubernetes automatically searches for an available PV that matches the PVC's requested capacity and access modes, and binds them together in a 1-to-1 relationship.

**Practical Example (Static Provisioning):**
```yaml
# 1. The Administrator creates the PV
apiVersion: v1
kind: PersistentVolume
metadata:
  name: manual-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"

---
# 2. The User creates the PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```

---

### 5. StorageClass
A StorageClass provides a way for administrators to describe the "classes" of storage they offer (e.g., standard HDD, premium SSD, geographically replicated). It contains a `provisioner` (the volume plugin acting behind the scenes) and `parameters` (configurations like disk type or IOPS).
* **Purpose:** It eliminates the need for cluster administrators to manually pre-provision PersistentVolumes.

### 6. Dynamic Provisioning
When a StorageClass is configured, Kubernetes can perform **Dynamic Provisioning**. Instead of an admin creating PVs in advance (Static Provisioning), a user simply creates a PVC referencing a StorageClass. The cluster automatically detects the request, calls the specified provisioner (e.g., the AWS EBS provisioner), creates the physical cloud disk, and generates the PV object on the fly to bind with the user's PVC.

**Practical Example (Dynamic Provisioning):**
```yaml
# 1. Administrator defines the StorageClass (often pre-installed by cloud providers)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
reclaimPolicy: Delete

---
# 2. User creates a PVC referencing the StorageClass
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  storageClassName: fast-ssd
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi

---
# 3. User mounts the PVC in a Pod (Kubernetes handles the PV creation automatically)
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - mountPath: /usr/share/nginx/html
      name: web-data
  volumes:
  - name: web-data
    persistentVolumeClaim:
      claimName: dynamic-pvc
```
---

# Task 2: HPA Demo Screenshots

![HPA Screenshot 1](screenshots/Screenshot%202026-10-06%20225029.png)

![HPA Screenshot 2](screenshots/Screenshot%20(40).png)

![HPA Screenshot 3](screenshots/Screenshot%20(39).png)

![HPA Screenshot 4](screenshots/Screenshot%202026-10-06%20225458.png)

![HPA Screenshot 5](screenshots/Screenshot%202026-10-06%20225505.png)

![HPA Screenshot 6](screenshots/Screenshot%202026-10-06%20225635.png)

![HPA Screenshot 7](screenshots/Screenshot%202026-10-06%20225715.png)


---

# Task 3: Mini Project

![Mini Project Screenshot 1](screenshots/Screenshot%202026-10-07%20214850.png)

![Mini Project Screenshot 2](screenshots/Screenshot%202026-10-07%20214113.png)

![Mini Project Screenshot 3](screenshots/Screenshot%202026-10-07%20215840.png)
