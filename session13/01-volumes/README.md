# Module 01: Kubernetes Volumes & Ephemeral Storage

## Overview
By default, container filesystems are strictly ephemeral. When a container crashes, is terminated, or is rescheduled, all files written inside its writable layer are permanently lost.

Kubernetes **Volumes** provide a way for containers within a Pod to access storage that outlives individual container restarts within that Pod's lifecycle.

---

## Important Theoretical Concepts

### 1. The Container Ephemeral Layer Problem
- A container's filesystem is constructed from read-only image layers plus a thin read-write container layer (UnionFS / OverlayFS).
- When a container restarts (`RestartCount++`), the runtime discards the container layer and creates a fresh one from the base image.
- A **Volume** mounts external or host-level storage into a specific directory path inside the container (`volumeMounts`), bypassing the ephemeral container layer.

### 2. `emptyDir` Volume
- **Lifecycle**: Created when a Pod is assigned to a Node. It exists for as long as that Pod is running on that specific node.
- **Persistence**: Survives container crashes/restarts within the Pod, but is **permanently destroyed** when the Pod is deleted or evicted.
- **Storage Medium**: Stored on the node's backing medium (disk, SSD) or RAM (if configured with `medium: Memory`).
- **Primary Use Cases**:
  - Temporary scratchpad space (e.g., sort buffers, temporary video transcoding files).
  - Checkpointing long computations for crash recovery.
  - Sharing files between multiple containers running inside the same Pod (e.g., sidecar pattern).

### 3. `hostPath` Volume
- **Lifecycle**: Mounts a file or directory from the host worker node's filesystem directly into the Pod.
- **Persistence**: Survives Pod deletion as long as subsequent Pods are scheduled on the exact same worker node.
- **Gotchas / Anti-Patterns**:
  - **Node Mobility Failure**: If Pod is rescheduled to Node 2, it cannot see files located on Node 1.
  - **Security Hazard**: Grants containers root-level or unrestricted visibility into host node system directories (`/var/run/docker.sock`, `/etc/kubernetes`).
- **Primary Use Cases**:
  - DaemonSets needing host node telemetry (e.g., Promtail reading `/var/log`, cAdvisor).
  - Single-node local development clusters (Minikube, Kind).

---

## Code Manifests in This Directory

| File | Purpose | Key Spec Fields |
| :--- | :--- | :--- |
| [`emptydir-pod.yaml`](file:///Users/nensiravaliya/Downloads/scaler-devops-session/devops-course/sessions/session-13-storage-hpa-probes/01-volumes/emptydir-pod.yaml) | Pod demonstrating `emptyDir` scratch storage | `volumes[].emptyDir: {}`, `volumeMounts[].mountPath: /data` |
| [`hostpath-pod.yaml`](file:///Users/nensiravaliya/Downloads/scaler-devops-session/devops-course/sessions/session-13-storage-hpa-probes/01-volumes/hostpath-pod.yaml) | Pod demonstrating host filesystem binding | `volumes[].hostPath.path: /tmp/hostpath-data`, `type: DirectoryOrCreate` |

---

## Step-by-Step Hands-on Commands & Expected Outputs

### Step 1: Deploy Pod with `emptyDir`
```bash
kubectl apply -f emptydir-pod.yaml
kubectl get pod emptydir-demo
```
Expected output:
```text
pod/emptydir-demo created
NAME            READY   STATUS    RESTARTS   AGE
emptydir-demo   1/1     Running   0          8s
```

### Step 2: Write Data to the `emptyDir` Volume
```bash
kubectl exec -it emptydir-demo -- bash
# Inside the container:
echo "Hello Kubernetes" > /data/message.txt
cat /data/message.txt
exit
```
Expected output:
```text
Hello Kubernetes
```

### Step 3: Delete and Recreate Pod (The Proof of Ephemerality)
```bash
kubectl delete pod emptydir-demo
kubectl apply -f emptydir-pod.yaml
kubectl exec emptydir-demo -- cat /data/message.txt
```
Expected output:
```text
cat: /data/message.txt: No such file or directory
```
*Takeaway*: `emptyDir` belongs to the Pod lifecycle. When the Pod was deleted, the storage was destroyed.

### Step 4: Deploy and Verify `hostPath` Volume
```bash
kubectl apply -f hostpath-pod.yaml
kubectl exec hostpath-demo -- sh -c 'echo "Host persistent" > /data/host.txt'
kubectl delete pod hostpath-demo
kubectl apply -f hostpath-pod.yaml
kubectl exec hostpath-demo -- cat /data/host.txt
```
Expected output:
```text
Host persistent
```
*Takeaway*: Data survived on the single node, but in a multi-node cluster, scheduling on another node breaks this completely.

---

## Common Mistakes & Troubleshooting
1. **Directory vs File error with `hostPath`**:
   - Error: `PathDoesNotExist` or mount failure.
   - Solution: Use `type: DirectoryOrCreate` so Kubernetes creates the directory on the host if it does not already exist.
2. **Expecting `emptyDir` to persist across Pod updates**:
   - Common misconception: Students assume `emptyDir` works like Docker volumes. In Kubernetes, a volume is tied to the Pod object definition.
