# Module 03: StorageClass & Dynamic Storage Provisioning

## Overview
Static provisioning (manually creating `kind: PersistentVolume` YAML for every single storage need) does not scale in modern production environments. 

A **StorageClass** enables **Dynamic Provisioning**: when a developer submits a `PersistentVolumeClaim`, Kubernetes talks directly to the underlying cloud provider or storage backend (AWS, GCP, Azure, Ceph, HostPath) and provisions the physical disk and the `PersistentVolume` object automatically on-demand.

---

## Important Theoretical Concepts

### 1. Static vs Dynamic Provisioning Comparison

```text
STATIC PROVISIONING (Manual, slow):
Cluster Admin -> Manually writes PV YAML -> PV Available -> Dev writes PVC -> Bound

DYNAMIC PROVISIONING (Automated, cloud-native):
Dev writes PVC -> StorageClass intercepts -> Storage Plugin calls Cloud API -> PV created & bound!
```

### 2. Anatomy of a StorageClass Object
- `provisioner`: Specifies the volume plugin responsible for creating disks (e.g., `ebs.csi.aws.com`, `pd.csi.storage.gke.io`, `k8s.io/minikube-hostpath`).
- `parameters`: Backend-specific settings (e.g., `type: gp3`, `iops: "3000"`, `encrypted: "true"`).
- `reclaimPolicy`: Default reclaim policy applied to dynamically created PVs (typically `Delete`).
- `volumeBindingMode`:
  - `Immediate`: PV is provisioned the exact instant the PVC is applied, even if no Pod is scheduled yet.
  - `WaitForFirstConsumer`: PV is provisioned **only when a Pod referencing the PVC is scheduled**. This is crucial for multi-availability-zone cloud clusters (prevents provisioning an EBS disk in `us-east-1a` when the Pod is scheduled to run on a node in `us-east-1b`).

### 3. Default StorageClass
When a PVC does not explicitly state a `storageClassName`, the Kubernetes admission controller automatically assigns the cluster's default StorageClass (marked with the annotation `storageclass.kubernetes.io/is-default-class: "true"`).

---

## Code Manifests in This Directory

| File | Resource Kind | Purpose |
| :--- | :--- | :--- |
| [`pvc.yaml`](file:///Users/nensiravaliya/Downloads/scaler-devops-session/devops-course/sessions/session-13-storage-hpa-probes/03-storageclass/pvc.yaml) | `PersistentVolumeClaim` | Requests 500Mi using the `standard` StorageClass dynamically |

---

## Step-by-Step Hands-on Commands & Expected Outputs

### Step 1: Inspect Cluster StorageClasses
```bash
kubectl get storageclass
```
Expected output (Minikube):
```text
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate           false                  2d
```
Inspect detailed provisioner configuration:
```bash
kubectl describe storageclass standard
```

### Step 2: Apply Dynamic PVC
Manifest: `pvc.yaml`
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
      storage: 500Mi
```

Apply:
```bash
kubectl apply -f pvc.yaml
kubectl get pvc dynamic-pvc
```
Expected output:
```text
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
dynamic-pvc   Bound    pvc-87df45b1-0982-411a-ba73-1289192419a1   500Mi      RWO            standard       4s
```

### Step 3: Verify the Automatically Generated PV
```bash
kubectl get pv
```
Expected output:
```text
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS   AGE
pvc-87df45b1-0982-411a-ba73-1289192419a1   500Mi      RWO            Delete           Bound    default/dynamic-pvc   standard       15s
```
Notice: We **never** wrote a `kind: PersistentVolume` file for `dynamic-pvc`! The StorageClass provisioner created it for us with an automated UUID name and bound it instantly.

---

## Common Mistakes & Troubleshooting
1. **PVC stuck in `Pending` when using `WaitForFirstConsumer`**:
   - Symptom: PVC remains `Pending` after `kubectl apply`.
   - Explanation: This is expected behavior! The provisioner is waiting for a Pod to reference the PVC so it knows which availability zone/node to create the disk in.
   - Fix: Create and schedule the Pod referencing the PVC.
2. **Typo in `storageClassName`**:
   - If you specify `storageClassName: fast-disk` but no StorageClass with that name exists in the cluster, the PVC will hang in `Pending` indefinitely.
