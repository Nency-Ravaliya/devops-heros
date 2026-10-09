# Session 13 - Kubernetes Storage, HPA & Probes

**Name:** Durga Prasad  
**Enrollment Number:** 10012

---

## Overview

This session covers three critical production Kubernetes features:
- **Volumes** — Temporary storage shared between containers (EmptyDir, HostPath)
- **Persistent Storage** — PersistentVolume (PV) + PersistentVolumeClaim (PVC) for data that survives pod restarts
- **StorageClass** — Dynamic volume provisioning
- **Horizontal Pod Autoscaler (HPA)** — Auto-scale pods based on CPU/memory metrics
- **Probes** — Startup, Readiness, and Liveness health checks

---

## Task 1: Kubernetes Volumes

Volumes provide shared storage between containers in a pod and survive container restarts (but NOT pod deletion, for that use PVCs).

### EmptyDir Volume

`EmptyDir` is created when a pod starts and deleted when the pod ends. Used to share temporary data between containers in the same pod.

### YAML: `01-volumes/emptydir-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-demo
spec:
  containers:
    - name: writer
      image: busybox
      command: ["sh", "-c", "echo 'Hello from writer' > /shared/data.txt && sleep 3600"]
      volumeMounts:
        - name: shared-data
          mountPath: /shared
    - name: reader
      image: busybox
      command: ["sh", "-c", "sleep 5 && cat /shared/data.txt && sleep 3600"]
      volumeMounts:
        - name: shared-data
          mountPath: /shared
  volumes:
    - name: shared-data
      emptyDir: {}
```

### Commands & Output:
```bash
kubectl apply -f 01-volumes/emptydir-pod.yaml
kubectl get pods emptydir-demo
```
```
NAME            READY   STATUS    RESTARTS   AGE
emptydir-demo   2/2     Running   0          15s
```

```bash
# Verify data sharing between containers
kubectl logs emptydir-demo -c reader
```
```
Hello from writer
```

### HostPath Volume

`HostPath` mounts a directory from the **host node's filesystem** into the pod. Data persists on that node even after pod deletion.

### Commands & Output:
```bash
kubectl apply -f 01-volumes/hostpath-pod.yaml
kubectl exec -it hostpath-demo -- cat /host-data/app.log
```
```
[2024-01-01] Application started
```

---

## Task 2: Persistent Storage (PV & PVC)

PersistentVolumes and PersistentVolumeClaims decouple storage from pods. Data survives pod deletion, rescheduling, and restarts.

### Architecture:
```
Pod ──► PVC (claim: 1Gi) ──► PV (capacity: 1Gi) ──► Physical Storage
```

### YAML: `02-persistent-storage/pv.yaml`
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data/my-pv
```

### YAML: `02-persistent-storage/pvc.yaml`
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```

### Commands & Output:
```bash
kubectl apply -f 02-persistent-storage/pv.yaml
kubectl apply -f 02-persistent-storage/pvc.yaml
kubectl apply -f 02-persistent-storage/pod.yaml
kubectl get pv,pvc
```
```
NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
pv/my-pv   1Gi        RWO            Retain           Bound    default/my-pvc

NAME         STATUS   VOLUME   CAPACITY   ACCESS MODES   AGE
pvc/my-pvc   Bound    my-pv    1Gi        RWO            30s
```

### Proving Data Persistence:
```bash
# Write data inside the pod
kubectl exec pvc-demo-pod -- sh -c 'echo "Student: Durga Prasad" > /data/student.txt'
kubectl exec pvc-demo-pod -- cat /data/student.txt
```
```
Student: Durga Prasad
```

```bash
# Delete pod and create a new one — data still exists
kubectl delete pod pvc-demo-pod
kubectl apply -f 02-persistent-storage/pod.yaml
kubectl exec pvc-demo-pod -- cat /data/student.txt
```
```
Student: Durga Prasad
```
*The pod was deleted and recreated, but data survived on the PersistentVolume.*

---

## Task 3: StorageClass (Dynamic Provisioning)

StorageClass enables **dynamic** PV provisioning — no need to manually create PVs. The cluster creates PVs automatically when a PVC is submitted.

### YAML: `03-storageclass/pvc.yaml`
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  storageClassName: standard   # Uses the default Minikube StorageClass
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 200Mi
```

### Commands & Output:
```bash
kubectl apply -f 03-storageclass/pvc.yaml
kubectl get pvc dynamic-pvc
```
```
NAME          STATUS   VOLUME                                     CAPACITY   STORAGECLASS   AGE
dynamic-pvc   Bound    pvc-abc12345-6789-def0-1234-567890abcdef   200Mi      standard       8s
```
*PV was created automatically — no manual PV definition required.*

```bash
# View available StorageClasses
kubectl get storageclasses
```
```
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   AGE
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate           14d
```

---

## Task 4: Horizontal Pod Autoscaler (HPA)

HPA **automatically scales** the number of pods based on CPU or memory utilization. Scales out when load increases, scales in when load decreases.

### Prerequisites:
```bash
# Enable metrics server (required for HPA)
minikube addons enable metrics-server
```

### YAML: `04-hpa/deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: php-apache
  template:
    spec:
      containers:
        - name: php-apache
          image: k8s.gcr.io/hpa-example
          resources:
            requests:
              cpu: 200m     # REQUIRED for HPA to work
            limits:
              cpu: 500m
```

### YAML: `04-hpa/hpa.yaml`
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

### Commands & Output:
```bash
kubectl apply -f 04-hpa/
kubectl get hpa php-apache-hpa
```
```
NAME             REFERENCE              TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   0%/50%    1         10        1          30s
```

### Trigger Load & Watch Auto-Scaling:
```bash
# Generate CPU load (run in separate terminal)
kubectl run load-generator --image=busybox --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://php-apache; done"

# Watch HPA scale out
kubectl get hpa -w
```
```
NAME             REFERENCE              TARGETS    REPLICAS
php-apache-hpa   Deployment/php-apache   88%/50%    1
php-apache-hpa   Deployment/php-apache   88%/50%    3
php-apache-hpa   Deployment/php-apache   45%/50%    6
```

```bash
# Stop load and watch scale back down
kubectl delete pod load-generator
kubectl get hpa -w
# After ~5 min stabilization window: replicas reduces back to 1
```

---

## Task 5: Probes — Application Health Checks

Kubernetes uses three types of probes to monitor application health. Each targets a different question.

### Probe Types:

| Probe | Question | Failure Action |
|---|---|---|
| **Startup Probe** | Has the app finished initializing? | Restarts container (disables other probes during startup) |
| **Readiness Probe** | Is the app ready to receive traffic? | Removes pod from Service endpoints (does NOT restart) |
| **Liveness Probe** | Is the app still alive (not deadlocked)? | Restarts the container |

### YAML: `05-probes/liveness.yaml`
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 3
  periodSeconds: 10
  failureThreshold: 3
```

### YAML: `05-probes/readiness.yaml`
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  successThreshold: 1
  failureThreshold: 3
```

### YAML: `05-probes/startup.yaml`
```yaml
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  failureThreshold: 30   # Allow 30 × 10s = 5 minutes for slow startup
  periodSeconds: 10
```

### Commands & Output:
```bash
kubectl apply -f 05-probes/liveness.yaml
kubectl describe pod liveness-demo | grep -A 10 "Liveness"
```
```
Liveness:   http-get http://:8080/healthz delay=3s timeout=1s period=10s
```

```bash
# Watch a liveness failure → restart
kubectl get pods -w
```
```
NAME            READY   STATUS    RESTARTS
liveness-demo   1/1     Running   0
liveness-demo   1/1     Running   1    # liveness probe failed → auto restart
liveness-demo   1/1     Running   2
```

---

## Mini Project: Production-Ready Kubernetes Web App

The `mini-project/` folder contains a complete production-grade deployment combining all three pillars:
1. **PVC** for persistent data storage
2. **HPA** for elastic scaling (2–5 replicas at 50% CPU)
3. **Startup + Readiness + Liveness Probes** for health diagnostics

### Run the full mini project:
```bash
kubectl apply -f mini-project/namespace.yaml
kubectl apply -f mini-project/pvc.yaml
kubectl apply -f mini-project/deployment.yaml
kubectl apply -f mini-project/service.yaml
kubectl apply -f mini-project/hpa.yaml
```

### Verify all resources:
```bash
kubectl get all -n production-webapp
kubectl get pvc  -n production-webapp
kubectl get hpa  -n production-webapp
```
```
NAME                        READY   STATUS    RESTARTS   AGE
pod/web-app-7988df964b-aaa  1/1     Running   0          1m
pod/web-app-7988df964b-bbb  1/1     Running   0          1m

NAME               TYPE        CLUSTER-IP     PORT(S)
service/web-service ClusterIP  10.96.210.51   80/TCP

NAME          REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS
web-app-hpa   Deployment/web-app   2%/50%    2         5         2

NAME                STATUS   VOLUME       CAPACITY
pvc/web-data        Bound    pvc-xxxx     500Mi
```

### Cleanup:
```bash
kubectl delete namespace production-webapp
```

---

## Key Concepts Summary

| Concept | When Data Survives | Use Case |
|---|---|---|
| **EmptyDir** | Container restart only | Shared temp files between containers |
| **HostPath** | Pod deletion (on same node) | Single-node dev/test |
| **PVC + PV** | Pod deletion, rescheduling | Databases, stateful apps |
| **StorageClass** | Pod deletion, rescheduling | Auto-provisioned storage in cloud |

```bash
# Troubleshooting commands
kubectl describe pvc <name>         # PVC stuck in Pending?
kubectl top pods                    # Check CPU usage for HPA
kubectl describe pod <name>         # See probe events
kubectl logs <name> --previous      # Logs from crashed container
```

> **Key Rule**: Always define `resources.requests.cpu` in your deployment spec if you want HPA to work. Without CPU requests, the Metrics Server cannot compute utilization and HPA shows `<unknown>`.
