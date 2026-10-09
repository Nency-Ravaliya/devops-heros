# Session 13: Kubernetes Storage, HPA & Probes

This session covers storage persistence, dynamic horizontal auto-scaling, and health check diagnostics in Kubernetes.

---

## Task 1: Kubernetes Volumes
Comprehensive documentation on `emptyDir`, `hostPath`, `PersistentVolume`, `PersistentVolumeClaim`, `StorageClass`, and dynamic provisioning with examples:
* **Documentation File:** [01-kubernetes-volumes/README.md](file:///home/akshanshsinha/DevOps/devops-heros/session-13-storage-hpa-probes/01-kubernetes-volumes/README.md)
* **Manifests Directory:** [`01-volumes/`](file:///home/akshanshsinha/DevOps/devops-heros/session-13-storage-hpa-probes/01-volumes)

---

## Task 2: Horizontal Pod Autoscaler (HPA) Hands-on

### 1. Requirements Checklist
- [x] Deploy sample application with CPU resource requests/limits
- [x] Configure HorizontalPodAutoscaler targeting CPU utilization (e.g. 50%)
- [x] Deploy load generator (busybox container generating HTTP traffic)
- [x] Observe CPU spike and automatic pod scaling
- [x] Verify scale down when load stops

### 2. Execution Commands
```bash
# 1. Ensure Metrics Server is running
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 2. Deploy sample app with CPU requests & limits
kubectl apply -f hpa/app-deployment.yaml

# 3. Create HPA resource (scales 1 to 5 replicas based on 50% CPU)
kubectl apply -f hpa/hpa.yaml

# 4. Verify initial HPA state
kubectl get hpa
kubectl describe hpa web-app-hpa

# 5. Run a load generator in a separate terminal
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://web-service; done"

# 6. Monitor pod scaling and resource utilization
kubectl top pods
kubectl get hpa -w
kubectl get pods -w
```

### 3. Screenshot Evidence & Deliverables
* **Screenshot A: Initial HPA Status (`kubectl get hpa`)**  
  <!-- Add screenshot: ![HPA Initial](screenshots/hpa-initial.png) -->

* **Screenshot B: Resource Spike (`kubectl top pods`)**  
  <!-- Add screenshot: ![Pods CPU](screenshots/pods-cpu.png) -->

* **Screenshot C: Scaled Replicas (`kubectl get pods` showing replica increase)**  
  <!-- Add screenshot: ![HPA Scaled](screenshots/hpa-scaled.png) -->

---

## Task 3: Production Mini-Project
Production-grade deployment combining Persistent Storage (PVC), Autoscaling (HPA), and Health Diagnostics (Startup, Readiness, and Liveness probes).
* **Project Documentation:** [mini-project/README.md](file:///home/akshanshsinha/DevOps/devops-heros/session-13-storage-hpa-probes/mini-project/README.md)
* **Manifests Directory:** [`mini-project/`](file:///home/akshanshsinha/DevOps/devops-heros/session-13-storage-hpa-probes/mini-project)
