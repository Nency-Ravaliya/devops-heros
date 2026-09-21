# Kubernetes Persistent Storage


## What will we work with?

* PersistentVolume (`PV`)
* PersistentVolumeClaim (`PVC`)
* Pod
* Persistent storage

---

## 1. The Problem

Suppose our application stores:

* `student-data.txt`
* `database-data`
* `images`
* `logs`

inside a Pod.

If the Pod is deleted, we don't want our important data to disappear.

For this, Kubernetes provides persistent storage.

---

## 2. PersistentVolume

A PersistentVolume is a storage resource available to the Kubernetes cluster.

Think of it like:

> **PV = Storage available in the cluster**

Our example creates:

* Capacity: `1Gi`
* Access Mode: `ReadWriteOnce`

Check the PV:

```bash
kubectl get pv
```

---

## 3. PersistentVolumeClaim

A PersistentVolumeClaim is a request for storage.

Think of it like:

```text
PV
 │
 │ provides storage
 ▼
PVC
 │
 │ requests storage
 ▼
Pod
```

Our PVC requests:

* Capacity: `500Mi`
* Access Mode: `ReadWriteOnce`

---

## 4. Create the PV

Run:

```bash
kubectl apply -f pv.yaml
```

Check:

```bash
kubectl get pv
```

Expected output:

```text
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS
student-pv   1Gi        RWO            Retain           Available
```

---

## 5. Create the PVC

Run:

```bash
kubectl apply -f pvc.yaml
```

Check:

```bash
kubectl get pvc
```

Expected output:

```text
NAME          STATUS   VOLUME
student-pvc   Bound    student-pv
```

**Bound** means the PVC has been connected to a suitable PV.

---

## 6. Create the Pod

Run:

```bash
kubectl apply -f pod.yaml
```

Check:

```bash
kubectl get pods
```

Expected output:

```text
NAME            READY   STATUS
storage-demo    1/1     Running
```

---

## 7. Test Persistent Storage

Enter the Pod:

```bash
kubectl exec -it storage-demo -- bash
```

Create a file inside the mount path:

```bash
echo "Kubernetes Storage" > /data/message.txt
```

Read it:

```bash
cat /data/message.txt
```

Output:

```text
Kubernetes Storage
```

Exit:

```bash
exit
```

---

## 8. Delete the Pod

Delete the running Pod:

```bash
kubectl delete pod storage-demo
```

Create it again:

```bash
kubectl apply -f pod.yaml
```

Now check the file:

```bash
kubectl exec storage-demo -- cat /data/message.txt
```

Expected output:

```text
Kubernetes Storage
```

The Pod was deleted, but the data is still available.

---

## 9. Why Did The Data Stay?

Because the Pod was using:

```text
Pod
 │
 ▼
PVC
 │
 ▼
PV
 │
 ▼
Storage
```

The storage has a lifecycle independent of the individual Pod.

---

## 10. Access Modes

| Access Mode | Code | Description |
| :--- | :--- | :--- |
| **ReadWriteOnce** | `RWO` | Volume can be mounted read/write by **one node**. |
| **ReadOnlyMany** | `ROX` | Volume can be mounted read-only by **many nodes**. |
| **ReadWriteMany** | `RWX` | Volume can be mounted read/write by **many nodes**. |
| **ReadWriteOncePod** | `RWOP` | Volume can be mounted read/write by **a single Pod**. |

---

## Useful Commands

```bash
kubectl get pv
kubectl get pvc
kubectl describe pv student-pv
kubectl describe pvc student-pvc
kubectl get pods
kubectl describe pod storage-demo
```

---

## Key Learning

Remember:

* **PV** = storage
* **PVC** = request for storage
* **Pod** = uses the PVC

---

## Reference

* **Persistent Volumes:**  
  https://kubernetes.io/docs/concepts/storage/persistent-volumes/
