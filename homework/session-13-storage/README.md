# Session 13 — Storage, HPA, probes

Student: Viraj Bhanage, roll 24BCS10274

Volume notes: [01-kubernetes-volumes/README.md](01-kubernetes-volumes/README.md)

## HPA

`hpa.yaml` deploys `registry.k8s.io/hpa-example`, a Service, an autoscaler (1–5 replicas, 50% CPU), and a busybox load generator.

```bash
kubectl apply -f hpa.yaml
kubectl get hpa
kubectl get pods
kubectl top pods
kubectl describe hpa hpa-web
```

The load generator loops `wget` against the Service. CPU climbs above 50% and the HPA adds Pods up to 5. Delete the load generator and the replica count falls back toward 1 after the scale-down delay.

Metrics Server must be installed (`minikube addons enable metrics-server`). Without it, `kubectl top` fails and the HPA target stays `<unknown>`.

## Mini project

The production web app is already in `session-13-storage-hpa-probes/mini-project/`:

- namespace `production-webapp`
- PVC `web-data` 500Mi
- Deployment with startup, readiness, and liveness probes
- ClusterIP Service
- HPA min 2, max 5, target 50% CPU

```bash
kubectl apply -f session-13-storage-hpa-probes/mini-project/namespace.yaml
kubectl apply -f session-13-storage-hpa-probes/mini-project/pvc.yaml
kubectl apply -f session-13-storage-hpa-probes/mini-project/deployment.yaml
kubectl apply -f session-13-storage-hpa-probes/mini-project/service.yaml
kubectl apply -f session-13-storage-hpa-probes/mini-project/hpa.yaml
```

Write your name into `/data/student.txt` on one Pod, delete that Pod, and read the file from the replacement Pod. The PVC keeps the file. Screenshot `kubectl get pvc,pods,hpa -n production-webapp`.
