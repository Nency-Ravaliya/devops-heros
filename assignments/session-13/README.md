# Session 13: Kubernetes Storage, HPA & Probes

## Overview
This repository contains the complete hands-on implementations and comprehensive technical documentation for **Session 13: Kubernetes Storage, HPA & Probes**.

---

## Deliverables Summary
- **[Task 1: Volume Documentation](./01-kubernetes-volumes/README.md)**: Detailed comparison & practical YAML examples of `emptyDir`, `hostPath`, `PersistentVolume`, `PersistentVolumeClaim`, `StorageClass`, and Dynamic Provisioning.
- **[Task 2: HPA Hands-on](./02-hpa)**: Horizontal Pod Autoscaler configuration, deployment manifests, load generator script, and live CPU auto-scaling verification.
- **[Task 3: Mini Project](./03-mini-project)**: Production web application architecture combining dynamic storage (PVC), Health Probes (Startup, Readiness, Liveness), and CPU-driven Horizontal Pod Autoscaling in a dedicated `production-webapp` namespace.

---

## Task 1: Kubernetes Volumes

### Concepts Learned:
1. **`emptyDir`**: Temporary volume created when a Pod is assigned to a node. Exists only as long as that Pod is running. Used for temporary caching or scratch spaces.
2. **`hostPath`**: Mounts a file or directory from the host worker node's filesystem into the container. Used for node-level system monitoring agents.
3. **`PersistentVolume` (PV)**: A piece of storage in the cluster provisioned statically by an admin or dynamically by a StorageClass.
4. **`PersistentVolumeClaim` (PVC)**: A request for storage by a user/Pod specifying capacity and access modes (`ReadWriteOnce`, `ReadOnlyMany`, `ReadWriteMany`).
5. **`StorageClass` & Dynamic Provisioning**: Automatically provisions underlying cloud/local storage PVs on-demand whenever a PVC request is created.

Refer to the full volume guide: **[01-kubernetes-volumes/README.md](./01-kubernetes-volumes/README.md)**

![Task 1 Volume Execution](./screenshots/01-volumes.png)

---

## Task 2: HPA Hands-on Demo

### Step-by-Step Execution Walkthrough:
1. **Deploy Application**: Apply `deployment.yaml` with defined CPU requests (`200m`) and limits (`500m`).
2. **Configure Service & HPA**: Apply `service.yaml` and `hpa.yaml` targeting 50% average CPU utilization (`minReplicas: 1`, `maxReplicas: 10`).
3. **Execute Load Generator**: Launch load generator using `./load_generator.sh` (`while true; do wget -q -O- http://php-apache; done`).
4. **Observe Scaling**: Monitor real-time CPU spike and replica scaling from 1 pod to multiple pods.

### Useful Commands Executed:
```bash
# Verify HPA configuration & current status
kubectl get hpa

# View detailed metrics & scaling events
kubectl describe hpa php-apache

# Monitor pod replica creation in real-time
kubectl get pods -w

# Check CPU & Memory consumption per pod
kubectl top pods
```

![Task 2 HPA Scaling Output](./screenshots/02-hpa.png)

---

## Task 3: Mini Project Implementation

### Architecture Overview
Deployed a enterprise-ready web application in namespace `production-webapp`:
- **Namespace**: `production-webapp`
- **Storage**: PersistentVolumeClaim `webapp-pvc` (1Gi storage mounted at `/usr/share/nginx/html`)
- **Probes**:
  - `startupProbe`: Allows 50s initialization window before readiness checks.
  - `readinessProbe`: Ensures HTTP port 80 is ready before receiving traffic.
  - `livenessProbe`: Automatically restarts pod if container crashes or becomes unresponsive.
- **Autoscaling**: HPA `webapp-hpa` auto-scales pods between 2 and 5 replicas based on CPU target (50%).

![Task 3 Mini Project Implementation](./screenshots/03-mini-project.png)

---

## Cluster Verification Commands
```bash
# Verify all components in production-webapp namespace
kubectl get all,pvc,hpa -n production-webapp

# Check detailed probe events
kubectl describe deployment webapp-deployment -n production-webapp
```
