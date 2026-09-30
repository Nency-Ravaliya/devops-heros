# Session 13: Kubernetes Storage, HPA & Probes

## Assignment map

| Requirement | Implementation | Evidence |
|---|---|---|
| Volume documentation | [`01-kubernetes-volumes/README.md`](01-kubernetes-volumes/README.md) | Includes manifests from the storage exercises |
| HPA YAML and load generator | [`04-hpa/`](04-hpa/) and [`hpa/load_generator.sh`](hpa/load_generator.sh) | CPU crossed the target and replicas increased from 2 to 3 ([screenshot](screenshots/hpa-scaling.png)) |
| Persistent data | [`mini-project/pvc.yaml`](mini-project/pvc.yaml) | File survived Pod replacement ([screenshot](screenshots/pvc-persistence.png)) |
| Health probes | [`05-probes/`](05-probes/) and mini-project Deployment | Startup, readiness, and liveness paths verified ([screenshot](screenshots/probes-service.png)) |
| Mini project | [`mini-project/`](mini-project/) | PVC, Deployment, Service, HPA, probes, and full README |

The screenshots are real output from the `production-webapp` namespace in Minikube.
