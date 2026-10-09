# Module 02: Persistent Storage (PV, PVC & Workloads)

## Overview
Enterprise production applications require state to outlive Pod deletions, node failures, and cluster upgrades. Kubernetes solves this by decoupling storage administration from application deployment through **PersistentVolumes (PV)** and **PersistentVolumeClaims (PVC)**.

---

## Important Theoretical Concepts

### 1. The Separation of Concerns
- **Cluster Administrator Role**: Provisions actual physical or cloud storage resources (AWS EBS, Google PD, Ceph, SAN) as **PersistentVolumes (PV)**.
- **Developer / Application Role**: Declares how much storage is needed and required access modes using a **PersistentVolumeClaim (PVC)** without needing to know cloud vendor details.
- **Kubernetes Control Plane Role**: Automatically evaluates PVC requests and binds them to matching available PVs.

### 2. The Mental Model
- **PV**: The actual physical apartment building owned by the landlord (*"1 GiB disk on host"*).
- **PVC**: The tenant's rental lease application (*"I request 500 MiB of disk with RWO access"*).
- **Pod**: The tenant who signs the lease, receives the keys, and stores data in `/data`.

### 3. Access Modes (Must Know for Exams & Interviews)
| Access Mode | Acronym | Node Mount Capability | Supported Backend Examples |
| :--- | :--- | :--- | :--- |
| **ReadWriteOnce** | `RWO` | Mounted as read-write by **a single node** | AWS EBS, Google Persistent Disk, Azure Disk, local hostPath |
| **ReadOnlyMany** | `ROX` | Mounted as read-only by **many nodes simultaneously** | Read-only NFS, immutable asset mounts |
| **ReadWriteMany** | `RWX` | Mounted as read-write by **many nodes simultaneously** | AWS EFS, NFS, CephFS, GlusterFS |
| **ReadWriteOncePod** | `RWOP` | Mounted as read-write by **a single Pod** across the entire cluster | CSI drivers (Kubernetes v1.22+) |

> **Critical Distinction**: `ReadWriteOnce` means **one node**. If two Pods are scheduled on the *same* worker node, both can mount an RWO volume simultaneously.

### 4. Reclaim Policies (`persistentVolumeReclaimPolicy`)
- `Retain`: When a PVC is deleted, the PV remains in `Released` status. The data is preserved on disk, but no other PVC can bind to it until an administrator manually cleans it.
- `Delete`: When the PVC is deleted, the PV and the underlying cloud disk (e.g., AWS EBS volume) are automatically deleted.
- `Recycle` (Deprecated): Runs a basic scrub (`rm -rf /volume/*`) to allow re-binding.

---

## Code Manifests in This Directory

| File | Resource Kind | Purpose |
| :--- | :--- | :--- |
| [`pv.yaml`](file:///Users/nensiravaliya/Downloads/scaler-devops-session/devops-course/sessions/session-13-storage-hpa-probes/02-persistent-storage/pv.yaml) | `PersistentVolume` | Defines 1Gi host storage with `ReadWriteOnce` and `Retain` policy |
| [`pvc.yaml`](file:///Users/nensiravaliya/Downloads/scaler-devops-session/devops-course/sessions/session-13-storage-hpa-probes/02-persistent-storage/pvc.yaml) | `PersistentVolumeClaim` | Requests 500Mi of `ReadWriteOnce` storage |
| [`pod.yaml`](file:///Users/nensiravaliya/Downloads/scaler-devops-session/devops-course/sessions/session-13-storage-hpa-probes/02-persistent-storage/pod.yaml) | `Pod` | Mounts `student-pvc` into `/data` using `nginx:1.27` |

---

## Step-by-Step Hands-on Commands & Expected Outputs

### Step 1: Create the PersistentVolume
```bash
kubectl apply -f pv.yaml
kubectl get pv
```
Expected output:
```text
persistentvolume/student-pv created
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   AGE
student-pv   1Gi        RWO            Retain           Available                          6s
```
Notice `STATUS: Available` (the volume is waiting for a matching claim).

### Step 2: Create the PersistentVolumeClaim
```bash
kubectl apply -f pvc.yaml
kubectl get pvc
kubectl get pv
```
Expected output:
```text
persistentvolumeclaim/student-pvc created
NAME          STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS   AGE
student-pvc   Bound    student-pv   1Gi        RWO                           5s

NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   AGE
student-pv   1Gi        RWO            Retain           Bound    default/student-pvc                   25s
```
Notice both resources transitioned to `STATUS: Bound`.

### Step 3: Run the Pod and Write Persistent Data
```bash
kubectl apply -f pod.yaml
kubectl get pod storage-demo
```
Write a test message:
```bash
kubectl exec -it storage-demo -- bash -c "echo 'Kubernetes Storage' > /data/message.txt"
kubectl exec storage-demo -- cat /data/message.txt
```
Expected output:
```text
Kubernetes Storage
```

### Step 4: The Crucial Test — Pod Deletion & Data Verification
```bash
# Delete the pod completely
kubectl delete pod storage-demo

# Recreate the pod
kubectl apply -f pod.yaml
kubectl get pod storage-demo

# Read the file again
kubectl exec storage-demo -- cat /data/message.txt
```
Expected output:
```text
Kubernetes Storage
```
**Conclusion**: The Pod was terminated and wiped from the cluster, but the data survived completely intact on the PersistentVolume!

---

## Common Mistakes & Troubleshooting
1. **PVC stuck in `Pending`**:
   - Cause: Requested capacity exceeds available PVs, access modes do not match, or storage class mismatch.
   - Debug: `kubectl describe pvc student-pvc` -> inspect `Events:` block.
2. **PV stuck in `Released` status**:
   - Cause: The PVC was deleted, but reclaim policy is `Retain`. The PV cannot bind to a new PVC until manually scrubbed and its `spec.claimRef` is cleared.
