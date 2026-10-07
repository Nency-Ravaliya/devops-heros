# Session 13 - Task 1: Kubernetes Volumes Deep Dive

**Author:** Shivansh Singh  
**Course:** SST DevOps & Cloud [SWE]  
**Topic:** Kubernetes Volumes, Persistent Storage, StorageClass & Dynamic Provisioning  

---

## 1. Executive Summary & Overview

Kubernetes containers are inherently ephemeral and stateless. When a container crashes or is restarted by the Kubelet, any data written to its local writable layer is discarded. To solve this problem, Kubernetes introduces **Volumes**, abstracting storage systems to decouple data lifecycle from container lifecycle.

```text
+-----------------------------------------------------------------------------------+
|                                  Kubernetes Node                                  |
|                                                                                   |
|  +-------------------------------------+       +-------------------------------+  |
|  |             Pod                     |       |      Physical / Node Disk     |  |
|  |  +-------------------------------+  |       |                               |  |
|  |  | Container: App                |  |       |  /var/log/audit (hostPath)    |  |
|  |  | mountPath: /data ------------+---+-------+-> /mnt/data/storage           |  |
|  |  +-------------------------------+  |       |                               |  |
|  |  +-------------------------------+  |       |  /var/lib/kubelet/pods/...    |  |
|  |  | Container: Sidecar Log Reader |  |       |  (emptyDir storage root)      |  |
|  |  | mountPath: /data ------------+---+---+   +-------------------------------+  |
|  |  +-------------------------------+  |   |                                      |
|  |                                     |   |                                      |
|  |   Volume: shared-volume             |<--+                                      |
|  +-------------------------------------+                                          |
+-----------------------------------------------------------------------------------+
```

---

## 2. Storage Types Detailed Breakdown

### 2.1 `emptyDir`

#### Concept & Lifecycle
An `emptyDir` volume is created at the moment a Pod is assigned to a Node, and it initially begins empty. Containers running within the same Pod can all read and write to the same files in the `emptyDir` volume, though that volume can be mounted at identical or differing mount paths in each container.
- **Persistence**: Strictly tied to the Pod's lifecycle.
  - If a container inside the Pod crashes: Data is **retained**!
  - If the Pod is evicted, deleted, or rescheduled: Data is **permanently destroyed**.
- **Storage Medium**: Can be backed by the node’s standard medium (SSD/HDD) or memory via tmpfs (`medium: "Memory"`).

#### Use Cases
1. Scratch space for sorting, hash computations, or temp file caching.
2. Checkpointing long-running computations.
3. Multi-container Pod communication (e.g., content generator container writing HTML, and an NGINX web server container serving it).

#### Practical Manifest (`01-emptydir.yaml`)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-demo
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args:
        - while true; do date >> /cache/timestamp.txt; sleep 5; done
      volumeMounts:
        - name: shared-cache
          mountPath: /cache
    - name: reader
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args:
        - while true; do cat /cache/timestamp.txt 2>/dev/null; sleep 10; done
      volumeMounts:
        - name: shared-cache
          mountPath: /cache
  volumes:
    - name: shared-cache
      emptyDir: {}
```

#### Verification CLI Output
```bash
$ kubectl apply -f 01-emptydir.yaml
pod/emptydir-demo created

$ kubectl get pod emptydir-demo
NAME            READY   STATUS    RESTARTS   AGE
emptydir-demo   2/2     Running   0          12s

$ kubectl logs emptydir-demo -c reader
Wed Oct  7 10:15:02 UTC 2026
Wed Oct  7 10:15:07 UTC 2026
Wed Oct  7 10:15:12 UTC 2026
```

---

### 2.2 `hostPath`

#### Concept & Lifecycle
A `hostPath` volume mounts a file or directory from the host node's filesystem directly into your Pod.
- **Persistence**: If the Pod is deleted, the data on the node's disk **remains intact**.
- **Caveat**: If the Pod gets rescheduled on a *different* node, it will access that new node's local disk, not the original node's data.

#### Security & Operational Risks
- Pods with `hostPath` mounts can expose sensitive host files (`/etc`, `/var/run/docker.sock`).
- Compromised containers could escalate privileges to the underlying host OS.
- Generally restricted or forbidden in production multi-tenant clusters via Pod Security Admission (PSA).

#### Common Use Cases
1. Running system/monitoring agents (e.g., Prometheus node-exporter reading `/proc` or `/sys`).
2. DaemonSets collecting container logs from `/var/log/pods`.
3. Local development and single-node clusters (Minikube / Kind).

#### Practical Manifest (`02-hostpath.yaml`)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-demo
spec:
  containers:
    - name: node-logger
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args:
        - echo "Host audit logged at $(date)" >> /host-logs/app-audit.log; sleep 3600
      volumeMounts:
        - name: node-log-dir
          mountPath: /host-logs
  volumes:
    - name: node-log-dir
      hostPath:
        path: /var/log/custom-audit
        type: DirectoryOrCreate
```

---

### 2.3 `PersistentVolume` (PV)

#### Concept
A `PersistentVolume` (PV) is a piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using Storage Classes. It is a cluster-level resource (non-namespaced) just like a Node.

#### Lifecycle Phases
1. **Available**: Free resource not yet bound to a claim.
2. **Bound**: Successfully reserved by a PersistentVolumeClaim.
3. **Released**: Claim was deleted, but resource not yet reclaimed by cluster.
4. **Failed**: Automatic reclamation failed.

#### Reclaim Policies
- **Retain**: Manual reclamation. When the PVC is deleted, the PV remains with its data; an admin must manually clean up or recover the storage.
- **Delete**: Automatic removal. Both the PV object and the external storage asset (e.g., AWS EBS volume or GCP Persistent Disk) are deleted.
- **Recycle** *(Deprecated)*: Performs basic scrub (`rm -rf /thevolume/*`) to make it available for another claim.

#### Access Modes
| Mode | Code | Meaning |
| :--- | :--- | :--- |
| **ReadWriteOnce** | `RWO` | Volume can be mounted read-write by a single node. |
| **ReadOnlyMany** | `ROX` | Volume can be mounted read-only by many nodes simultaneously. |
| **ReadWriteMany** | `RWX` | Volume can be mounted read-write by many nodes (e.g. NFS, Ceph, EFS). |
| **ReadWriteOncePod** | `RWOP` | Volume can be mounted read-write by a single Pod across the entire cluster. |

#### Practical Manifest (`03-pv.yaml`)
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv-storage
  labels:
    type: local
spec:
  capacity:
    storage: 2Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data/local-pv-storage
```

---

### 2.4 `PersistentVolumeClaim` (PVC)

#### Concept
A `PersistentVolumeClaim` (PVC) is a request for storage by a user/developer. While Pods consume CPU and Memory resources on Nodes, PVCs consume Storage capacity and Access Modes on PVs. It is a **namespaced** resource.

#### Matching & Binding Flow
1. Developer specifies requested size (e.g. `1Gi`) and access mode (`ReadWriteOnce`).
2. The control plane watches for PVCs and searches for a PV with matching capacity, access modes, and storage class.
3. Once found, the control plane binds the PVC to the PV (1-to-1 relationship).

#### Practical Manifest (`04-pvc.yaml`)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 1Gi
```

#### Verification CLI Output
```bash
$ kubectl apply -f 03-pv.yaml
persistentvolume/local-pv-storage created

$ kubectl get pv
NAME               CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   AGE
local-pv-storage   2Gi        RWO            Retain           Available           manual         5s

$ kubectl apply -f 04-pvc.yaml
persistentvolumeclaim/app-data-pvc created

$ kubectl get pvc
NAME           STATUS   VOLUME             CAPACITY   ACCESS MODES   STORAGECLASS   AGE
app-data-pvc   Bound    local-pv-storage   2Gi        RWO            manual         3s
```

---

### 2.5 `StorageClass`

#### Concept
A `StorageClass` provides a way for administrators to describe the "classes" of storage they offer (e.g. "fast" SSD vs "standard" HDD). It acts as a template defining which provisioner plugin handles the storage and which parameters to apply.

#### Key Properties
- **`provisioner`**: The CSI driver or internal plugin (e.g., `ebs.csi.aws.com`, `pd.csi.storage.gke.io`, `k8s.io/minikube-hostpath`).
- **`reclaimPolicy`**: Dynamically provisioned PVs will inherit this (`Delete` or `Retain`).
- **`volumeBindingMode`**:
  - `Immediate`: PV is provisioned as soon as the PVC is created.
  - `WaitForFirstConsumer`: PV provisioning is delayed until a Pod using the PVC is scheduled. This guarantees the volume is created in the exact Availability Zone/Node where the Pod lands.

#### Practical Manifest (`05-storageclass.yaml`)
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

---

### 2.6 Dynamic Provisioning

#### The Problem with Static Provisioning
In static provisioning, cluster administrators have to manually anticipate storage needs, create cloud volumes, and write `PersistentVolume` YAML files beforehand. If 50 developers submit claims, admins must create 50 PVs manually.

#### How Dynamic Provisioning Solves It
With Dynamic Provisioning:
1. Admin configures a `StorageClass` once.
2. Developers deploy a `PersistentVolumeClaim` specifying `storageClassName: <class-name>`.
3. Kubernetes automatically triggers the storage plugin to provision the underlying disk in the cloud/infrastructure.
4. Kubernetes automatically generates the `PersistentVolume` object and binds it instantly to the PVC.

```text
[ Developer ]
      │
      │ 1. Applies PVC (requests: 3Gi, storageClassName: fast-storage)
      ▼
[ K8s API Server ]
      │
      │ 2. Detects PVC needs volume
      ▼
[ StorageClass (fast-storage) ]
      │
      │ 3. Invokes CSI Driver / Provisioner Plugin
      ▼
[ Cloud / Host Storage Provider ] ── (Allocates 3Gi Disk)
      │
      │ 4. Auto-creates PV object & Binds
      ▼
[ PV (pvc-78f9...) ] <==========> [ PVC (dynamic-claim) ] Bound!
```

#### Practical Dynamic PVC (`06-dynamic-pvc.yaml`)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-storage
  resources:
    requests:
      storage: 3Gi
```

#### CLI Verification Output
```bash
$ kubectl apply -f 05-storageclass.yaml
storageclass.storage.k8s.io/fast-storage created

$ kubectl apply -f 06-dynamic-pvc.yaml
persistentvolumeclaim/dynamic-claim created

$ kubectl get sc
NAME                   PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
fast-storage           k8s.io/minikube-hostpath   Delete          WaitForFirstConsumer   true                   10s
standard (default)     k8s.io/minikube-hostpath   Delete          Immediate              false                  12d

$ kubectl get pvc dynamic-claim
NAME            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
dynamic-claim   Bound    pvc-89b21f44-6721-432d-94bb-12a149021890   3Gi        RWO            fast-storage   8s
```

---

## 3. Storage Type Comparison Matrix

| Storage Mechanism | Scope / Lifetime | Node Portability | Multi-Container Sharing | Production Usefulness | Typical Use Cases |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`emptyDir`** | Pod Lifetime | Same Node only | Yes (inside Pod) | High for caching | Temporary scratchpad, fast disk cache |
| **`hostPath`** | Host Disk Lifetime | Locked to single Node | Yes (on same node) | Low (Security risks) | Logging DaemonSets, system utilities |
| **`Static PV / PVC`** | Cluster Resource | Highly Portable | Depends on CSI driver | Medium | Pre-existing storage migration |
| **`Dynamic StorageClass`**| Cluster / Cloud Managed | Automatic per zone | Highly configurable | **Industry Standard** | Databases, microservice persistence |
