# Session 13 Homework: Kubernetes Storage, HPA & Probes

**Submitted by:** Piyush Bansal

All demos were run on Docker Desktop Kubernetes (single arm64 node). The output in each README is real.

| Task | README | What's in it |
|---|---|---|
| 1. Kubernetes Volumes | [01-kubernetes-volumes/README.md](01-kubernetes-volumes/README.md) | emptyDir, hostPath, static PV/PVC, StorageClass, dynamic provisioning |
| 2. HPA Hands-on | [02-hpa/README.md](02-hpa/README.md) | HPA YAML, load generators, `get hpa -w` / `top pods` / `describe hpa` output |
| 3. Mini Project | [03-mini-project/README.md](03-mini-project/README.md) | PVC + probes + HPA web app, persistence and service checks |
| Probes | [04-probes/README.md](04-probes/README.md) | Liveness, readiness and startup probes, plus failing readiness and liveness demos |

Not completed: a separate HPA scale-out capture for the mini project's `web-app-hpa`, and mini-project
bonus challenge 1. Details are in the READMEs.
