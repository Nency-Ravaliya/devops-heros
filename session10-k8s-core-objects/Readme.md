# Session 10 — Kubernetes Core Objects & Deployment Strategies (Homework)

**Name:** Chhavi Ahlawat
**Enrollment Number:** 24BCS10201
**Email:** chhavi.24bcs10201@sst.scaler.com

---

## Homework Tasks

| Task | Description | Status |
|---|---|---|
| 1 | Core objects — Pod, ReplicaSet, Deployment, DaemonSet | ✅ |
| 2 | Pod lifecycle — Running/Pending/Succeeded/Failed/CrashLoopBackOff/probes/init/multi-container/termination | ✅ |
| 3 | Deployment strategies — Rolling Update, Blue-Green, Canary, Recreate | ✅ |
| 4 | Troubleshooting — broken image, selector mismatch | ✅ |

---

## Folder Guide

| Folder | Covers |
|---|---|
| [`pod/`](pod), [`replicaset/`](replicaset), [`deployment/`](deployment), [`daemonset/`](daemonset) | The 4 core objects |
| [`pod-lifecycle/`](pod-lifecycle/README.md) | All 12 pod lifecycle states |
| [`01-rolling-update/`](01-rolling-update/README.md) | Zero-downtime rolling update |
| [`02-blue-green/`](02-blue-green/README.md) | Instant traffic switch via Service selector |
| [`03-canary/`](03-canary/README.md) | Gradual traffic shift across two Deployments |
| [`04-recreate/`](04-recreate/README.md) | All-at-once redeploy (brief downtime) |
| [`troubleshooting/`](troubleshooting) | Broken image & selector mismatch |

---

## 1. Core Objects
```bash
kubectl apply -f pod/nginx-pod.yaml
kubectl apply -f replicaset/backend-rs.yaml
kubectl apply -f deployment/deployment-v1.yaml
kubectl apply -f daemonset/node-agent-ds.yaml

kubectl get pods,rs,deployment,daemonset
```
![Core objects — pod, replicaset, deployment, daemonset running](screenshots/core-objects.png)

## 2. Pod Lifecycle
```bash
cd pod-lifecycle
kubectl apply -f 01-running.yaml -f 02-pending.yaml -f 04-failed.yaml -f 05-crashloopbackoff.yaml -f 06-imagepullbackoff.yaml
kubectl get pods -w
```
![Pod lifecycle — Running / Pending / CrashLoopBackOff / ImagePullBackOff side by side](screenshots/pod-lifecycle.png)

Details: [`pod-lifecycle/README.md`](pod-lifecycle/README.md)

## 3. Rolling Update
```bash
kubectl apply -f 01-rolling-update/deployment-v1.yaml
kubectl apply -f 01-rolling-update/service.yaml
kubectl rollout status deployment/app-rolling
kubectl apply -f 01-rolling-update/deployment-v2.yaml
kubectl get pods -l app=app-rolling -w
```
![Rolling update — pods rolling from v1 to v2 with zero downtime](screenshots/rolling-update.png)

## 4. Blue-Green Deployment
```bash
kubectl apply -f 02-blue-green/deployment-blue.yaml
kubectl apply -f 02-blue-green/deployment-green.yaml
kubectl apply -f 02-blue-green/service-blue.yaml
kubectl describe svc myapp-service | grep Selector      # -> points to blue
kubectl apply -f 02-blue-green/service-green.yaml
kubectl describe svc myapp-service | grep Selector      # -> now points to green
```
![Blue-green — service selector switching from blue to green](screenshots/blue-green.png)

## 5. Canary Deployment
```bash
kubectl apply -f 03-canary/deployment-stable.yaml
kubectl apply -f 03-canary/service.yaml
kubectl apply -f 03-canary/deployment-canary.yaml
kubectl scale deployment app-canary --replicas=3
kubectl scale deployment app-stable --replicas=7
kubectl get pods -l app=myapp-canary --show-labels
```
![Canary — stable and canary pods running together in a 7:3 split](screenshots/canary.png)

## 6. Recreate Deployment
```bash
kubectl apply -f 04-recreate/deployment-v1.yaml
kubectl apply -f 04-recreate/service.yaml
kubectl get pods -l app=app-recreate -w
kubectl apply -f 04-recreate/deployment-v2.yaml     # watch old pods die BEFORE new ones start
```
![Recreate — all v1 pods Terminating before any v2 pod appears](screenshots/recreate.png)

## 7. Troubleshooting
```bash
kubectl apply -f troubleshooting/broken-image.yaml
kubectl get pods                                     # ImagePullBackOff
kubectl describe pod <pod-name> | grep -A5 Events

kubectl apply -f troubleshooting/selector-mismatch.yaml
kubectl get endpoints selector-error-demo             # empty — selector matches no pod
```
![Troubleshooting — ImagePullBackOff and empty endpoints from a selector mismatch](screenshots/troubleshooting.png)

---

## Cleanup
```bash
kubectl delete -f pod/nginx-pod.yaml -f replicaset/backend-rs.yaml -f deployment/deployment-v1.yaml -f daemonset/node-agent-ds.yaml
kubectl delete -f 01-rolling-update/service.yaml -f 01-rolling-update/deployment-v1.yaml
kubectl delete -f 02-blue-green/service-green.yaml -f 02-blue-green/deployment-blue.yaml -f 02-blue-green/deployment-green.yaml
kubectl delete -f 03-canary/service.yaml -f 03-canary/deployment-canary.yaml -f 03-canary/deployment-stable.yaml
kubectl delete -f 04-recreate/service.yaml -f 04-recreate/deployment-v2.yaml
kubectl delete -f troubleshooting/broken-image.yaml -f troubleshooting/selector-mismatch.yaml
```

---

## Resources
- https://github.com/Nency-Ravaliya/Kubernetes
- k8s core objects: https://github.com/Nency-Ravaliya/Kubernetes/blob/main/core-objects.md
