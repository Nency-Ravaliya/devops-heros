# Session 13 - Storage, HPA & Probes

| | |
|---|---|
| **Student** | Sourabh Srivastva |
| **Enrollment No.** | 24BCS10157 |
| **Session** | 13 - Storage, HPA & Probes |
| **Cluster** | kind `kind-devops-heros` (1 control-plane + 2 workers, Kubernetes v1.37.0), metrics-server, default StorageClass `standard` (rancher local-path) |

## Task checklist

- [x] **Task 1 - Kubernetes volumes**: emptyDir shared between two containers, hostPath checked from the node, static PV + PVC, StorageClass, dynamic provisioning through `standard`, data surviving Pod deletion, Retain vs Delete reclaim policy -> [01-kubernetes-volumes/README.md](01-kubernetes-volumes/README.md)
- [x] **Task 2 - HPA** with the course's `04-hpa` manifests: deploy the app, configure and verify the HPA, run a busybox `wget` load generator, observe CPU (`kubectl top pods`), scale-up (`kubectl get hpa -w` plus snapshots every 30s), stop the load, observe scale-down after the stabilization window. Two rounds: 1 generator (1 -> 2 -> 1) and 3 generators (1 -> 4 -> 5 -> 4 -> 2 -> 1) -> [02-hpa/README.md](02-hpa/README.md)
- [x] **Task 3 - Mini project** (course `mini-project/` spec): PVC + Deployment with startup/readiness/liveness probes + Service + HPA. All three verification tasks done (storage persistence, Service, HPA), plus bonus challenges 1 (30% target -> scaled 2 -> 3 -> 2), 2 (readiness gating -> empty endpoints) and 3 (liveness restart loop) -> [03-mini-project/README.md](03-mini-project/README.md)

## Folder layout

```text
Sourabh-24BCS10157/
├── README.md
├── 01-kubernetes-volumes/
│   ├── README.md
│   ├── emptydir-shared.yaml           # writer + nginx sharing an emptyDir
│   ├── hostpath-pod.yaml
│   ├── static-pv-pvc.yaml             # hand-made PV + PVC (class "manual")
│   ├── static-pv-pod.yaml
│   ├── dynamic-pvc.yaml               # PVC on StorageClass "standard"
│   ├── pvc-writer-pod.yaml
│   └── storageclass-retain.yaml       # custom StorageClass, reclaimPolicy Retain
├── 02-hpa/
│   └── README.md                      # uses ../../04-hpa/{deployment,service,hpa}.yaml unchanged
└── 03-mini-project/
    ├── README.md
    ├── namespace.yaml pvc.yaml deployment.yaml service.yaml hpa.yaml  # course files, namespace -> s13-mini
    └── hpa-challenge1-30pct.yaml      # bonus challenge 1
```

## Notes

- **Shared cluster:** I worked only in my own namespaces: `s13-storage` (Task 1), `s13` (Task 2) and `s13-mini` (Task 3, instead of the spec's `production-webapp`). All of them were deleted at the end.
- **All outputs are real.** Each one was copied from the terminal of the run. Long outputs are cut and marked with `...`. Periodic snapshots were taken by a small shell loop that ran `kubectl get hpa`, `kubectl top pods` and `kubectl get pods` every 30 seconds.
- **HPA spec vs reality:** in the mini project, a single busybox `wget` loop pushed nginx to only about 40% of its CPU request, below the 50% target, so the spec's "110% -> 5 replicas" did not happen as written. I recorded that honestly, then used the spec's own Bonus Challenge 1 (30% target) to show scaling with the same load. Task 2's three-generator round shows scaling up to `maxReplicas`.
