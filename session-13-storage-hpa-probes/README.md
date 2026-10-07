# Session 13: Kubernetes Storage, HPA & Health Probes

**Author:** Shivansh Singh  
**Course:** SST DevOps & Cloud [SWE]  
**Session:** 13  
**Status:** Completed  

---

## 1. Assignment Overview & Structure

This repository contains the complete implementation and documentation for **Session 13: Kubernetes Storage, HPA & Probes**.

```text
session-13-storage-hpa-probes/
├── 01-kubernetes-volumes/             # Task 1: Comprehensive Volumes Documentation & Manifests
│   ├── 01-emptydir.yaml               # Multi-container shared cache emptyDir pod
│   ├── 02-hostpath.yaml               # Host node filesystem logging mount
│   ├── 03-pv.yaml                     # Static PersistentVolume definition
│   ├── 04-pvc.yaml                    # PersistentVolumeClaim bound to static PV
│   ├── 05-storageclass.yaml           # StorageClass with WaitForFirstConsumer
│   ├── 06-dynamic-pvc.yaml            # Dynamically provisioned storage claim
│   └── README.md                      # Complete theoretical and practical guide
├── 02-hpa-hands-on/                   # Task 2: Elastic Scaling Hands-on
│   ├── deployment.yaml                # PHP-Apache application workload with resource requests
│   ├── service.yaml                   # ClusterIP service routing traffic to workload
│   ├── hpa.yml                        # Autoscaling policy (1-5 replicas, 50% CPU threshold)
│   ├── load-generator.yaml            # High-traffic generation deployment
│   ├── load-generator.sh              # Concurrent traffic firing script
│   └── README.md                      # Step-by-step logs, outputs, and verification
├── mini-project/                      # Task 3: Capstone Production Web App
│   ├── namespace.yaml                 # Dedicated production-webapp namespace
│   ├── pvc.yaml                       # 500Mi PersistentVolumeClaim (/data)
│   ├── deployment.yaml                # 2 replicas, probes (startup, readiness, liveness), PVC mount
│   ├── service.yaml                   # ClusterIP service on port 80
│   ├── hpa.yaml                       # HorizontalPodAutoscaler (min: 2, max: 5, target: 50%)
│   ├── load-generator.yaml            # Production load testing manifest
│   ├── verify.sh                      # Automated validation script
│   └── README.md                      # Architecture, triage guide, and verification steps
├── hpa/                               # Supporting HPA references
│   ├── backend-service.yaml
│   ├── hpa-backend.yaml
│   ├── hpa.yml
│   └── load_generator.sh
└── README.md                          # Master submission documentation (this file)
```

---

## 2. Deliverables Checklist

| Deliverable | Location | Description | Status |
| :--- | :--- | :--- | :---: |
| **Volume Documentation** | `01-kubernetes-volumes/README.md` | Deep dive into `emptyDir`, `hostPath`, `PV`, `PVC`, `StorageClass`, and dynamic provisioning with diagrams. | Completed |
| **Volume Manifests** | `01-kubernetes-volumes/*.yaml` | Working manifests for each volume concept. | Completed |
| **HPA YAML** | `02-hpa-hands-on/hpa.yml` | Autoscaling configuration targeting 50% CPU utilization. | Completed |
| **Load Generator** | `02-hpa-hands-on/load-generator.yaml` | High-concurrency traffic generator to simulate load spikes. | Completed |
| **HPA CLI Outputs** | `02-hpa-hands-on/README.md` | Recorded terminal outputs (`get hpa`, `top pods`, `describe hpa`, pod scaling events). | Completed |
| **Mini-Project Implementation**| `mini-project/` | Complete production web application integrating stateful storage, health diagnostics, and elastic autoscaling. | Completed |

---

## 3. Task 1 Summary: Kubernetes Volumes

Full documentation is available in [01-kubernetes-volumes/README.md](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-13-storage-hpa-probes/01-kubernetes-volumes/README.md).

### Key Takeaways:
1. **`emptyDir`**: Temporary scratchpad directory created when a Pod is scheduled. Shared across containers inside the same Pod, destroyed when the Pod is deleted.
2. **`hostPath`**: Mounts a file/directory directly from the host Node into the Pod. Persists across Pod restarts on the same Node, but introduces security risks and couples workloads to specific nodes.
3. **`PersistentVolume` (PV)**: Cluster-scoped storage resource configured with storage capacity, access modes (`RWO`, `ROX`, `RWX`), and reclaim policies (`Retain`, `Delete`).
4. **`PersistentVolumeClaim` (PVC)**: Namespaced user request for storage. Automatically binds 1-to-1 with a compatible PV based on access mode and requested capacity.
5. **`StorageClass` & Dynamic Provisioning**: Eliminates the manual burden of creating PVs ahead of time. When a PVC requests a `StorageClass`, the volume provisioner plugin automatically allocates the underlying cloud/node storage on demand.

```text
[ Developer creates PVC ] ──> [ StorageClass ] ──> [ Cloud Provisioner ]
                                                          │
                                                          ▼
[ Pod mounts Volume ] <─────── [ PVC Bound ] <──── [ PV Auto-created ]
```

---

## 4. Task 2 Summary: HPA Hands-on & Scaling Verification

Full output logs and steps are available in [02-hpa-hands-on/README.md](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-13-storage-hpa-probes/02-hpa-hands-on/README.md).

### Verification Workflow:
1. **Deploy Workload**: Deployed `hpa-demo` (PHP Apache) with CPU resource requests (`cpu: 100m`) and limits (`cpu: 250m`).
2. **Deploy Service**: Exposed on ClusterIP port 80.
3. **Configure HPA**: Created `hpa.yml` targeting 50% CPU utilization with `minReplicas: 1` and `maxReplicas: 5`.
4. **Initial Verification**: Verified initial metric baseline (`0%/50%` CPU utilization, 1 replica).
5. **Load Generation**: Launched `load-generator` deployment issuing non-stop HTTP requests.
6. **Observed CPU Spike**: Utilization surged from `0%` to `142%`.
7. **Observed Autoscaling**: HPA automatically calculated target replica count and scaled up from 1 Pod to 4, then 5 Pods.
8. **Scale-Down Stabilization**: Deleted the load generator; CPU usage dropped to `0%` and the controller smoothly scaled the deployment back down to 1 replica.

```bash
$ kubectl get hpa hpa-demo
NAME       REFERENCE             TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   142%/50%   1         5         5          3m15s
```

---

## 5. Task 3 Summary: Mini-Project (Production-Ready Web App)

Full architecture and testing steps are available in [mini-project/README.md](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-13-storage-hpa-probes/mini-project/README.md).

### Components Implemented:
- **Namespace**: `production-webapp` ensuring clean workload isolation.
- **Persistent Storage**: `web-data` PVC (500Mi, `ReadWriteOnce`) mounted at `/data`. Verified that writing to `/data/persistence-test.txt` persists across Pod deletion and rescheduling.
- **Elastic Autoscaling**: HPA policy maintaining 2 to 5 replicas based on a 50% CPU threshold.
- **Three-Tier Health Probes**:
  - `startupProbe`: Guards slow-initializing applications (failure threshold: 30, period: 2s).
  - `readinessProbe`: Controls whether the Pod IP is added to the Service endpoints (initial delay: 5s, timeout: 2s).
  - `livenessProbe`: Detects deadlocks and restarts the container when unresponsive (initial delay: 5s, period: 5s).

---

## 6. How to Run the Assignment

### 1. Test Task 1 Volumes
```bash
cd 01-kubernetes-volumes
kubectl apply -f 01-emptydir.yaml
kubectl logs emptydir-demo -c reader
kubectl delete -f 01-emptydir.yaml
```

### 2. Run Task 2 HPA
```bash
cd ../02-hpa-hands-on
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yml
kubectl get hpa hpa-demo
kubectl apply -f load-generator.yaml
kubectl get hpa hpa-demo -w
```

### 3. Deploy Task 3 Mini-Project
```bash
cd ../mini-project
chmod +x verify.sh
./verify.sh
```
