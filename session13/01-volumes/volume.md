# Kubernetes Volumes

## What will we learn?

* What is a Kubernetes Volume?
* Why do containers need volumes?
* What is `emptyDir`?
* How does storage behave when a container or Pod restarts?
* Basic idea of `hostPath`

---

## 1. Why Do We Need Volumes?

Normally, data written inside a container belongs to the container's filesystem.

If the container is removed, that data can be lost.

A volume gives the container another place to store data.

### Simple idea:

```text
Container
    │
    │ writes data
    ▼
 Volume
```

---

## 2. `emptyDir`

`emptyDir` creates an empty directory when the Pod starts.

The containers inside the same Pod can use it.

### Example structure:

```text
Pod
 │
 ├── Container
 │
 └── emptyDir
       │
       └── /data
```

### The important point:

* `emptyDir` exists as long as the Pod exists.
* If the Pod is deleted and recreated, the old `emptyDir` data is gone.

---

## 3. Run `emptyDir` Example

Apply the YAML:

```bash
kubectl apply -f emptydir-pod.yaml
```

Check the Pod:

```bash
kubectl get pods
```

Expected output:

```text
NAME            READY   STATUS    RESTARTS   AGE
emptydir-demo   1/1     Running   0          10s
```

---

## 4. Create a File

Enter the container:

```bash
kubectl exec -it emptydir-demo -- bash
```

Inside the container, create a file:

```bash
echo "Hello Kubernetes" > /data/message.txt
```

Read it:

```bash
cat /data/message.txt
```

Output:

```text
Hello Kubernetes
```

Exit:

```bash
exit
```

---

## 5. Delete the Pod

Delete the running Pod:

```bash
kubectl delete pod emptydir-demo
```

Create it again:

```bash
kubectl apply -f emptydir-pod.yaml
```

Try reading the old file:

```bash
kubectl exec emptydir-demo -- cat /data/message.txt
```

Output:

```text
cat: /data/message.txt: No such file or directory
```

You should get an error because the old Pod and its `emptyDir` storage were deleted.

---

## 6. `hostPath`

`hostPath` mounts a directory from the Kubernetes node into the Pod.

### Example snippet:

```yaml
volumes:
  - name: storage
    hostPath:
      path: /tmp/student-data
```

The Pod can access that directory.

### Important:

`hostPath` is mainly useful for:

* Learning
* Local testing
* Special node-level use cases

It is generally not the first choice for persistent application storage in a production cluster.

---

## Useful Commands

```bash
kubectl get pods
kubectl describe pod emptydir-demo
kubectl exec -it emptydir-demo -- bash
kubectl delete pod emptydir-demo
```

---

## Key Learning

Remember:

```text
Volume
   │
   └── gives storage to containers

emptyDir
   │
   ├── temporary storage
   └── lifetime is linked to the Pod
```

---

## Reference

* **Kubernetes Volumes:**  
  https://kubernetes.io/docs/concepts/storage/volumes/
