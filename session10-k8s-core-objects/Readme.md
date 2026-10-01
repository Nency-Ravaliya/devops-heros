# Session 10: Kubernetes Pods, ReplicaSets & Deployments

This folder contains the assignment manifests, commands, observations, and real Minikube evidence for deployment strategies and Pod lifecycle states.

## Assignment map

| Requirement | Implementation | Evidence |
|---|---|---|
| Rolling Update | [`01-rolling-update/`](01-rolling-update/) | [`rolling-update.png`](screenshots/rolling-update.png) |
| Blue-Green | [`02-blue-green/`](02-blue-green/) | [`blue-green-routing.png`](screenshots/blue-green-routing.png) |
| Canary | [`03-canary/`](03-canary/) | 9 stable and 1 canary Pod produced a measured 36/4 traffic split ([evidence](screenshots/canary-deployment.png)) |
| Recreate | [`04-recreate/`](04-recreate/) | v1 was fully replaced by v2 with `strategy: Recreate` and the upgraded endpoint verified ([evidence](screenshots/recreate-deployment.png)) |
| Pod lifecycle | [`pod-lifecycle/`](pod-lifecycle/) | [`pod-lifecycle.png`](screenshots/pod-lifecycle.png) |
| Core objects | [`k8s-core-objects/`](k8s-core-objects/) | Pod, ReplicaSet, Deployment, DaemonSet, and StatefulSet manifests |

## Verified observations

- The rolling update replaced four replicas gradually and completed with all four replicas available on `nginx:1.25-alpine`.
- Blue and green Deployments were healthy simultaneously. Changing the Service selector to `slot: green` routed traffic to the green version.
- The lifecycle exercise produced Running, Pending, Completed, Error, ImagePullBackOff, init-container, and multi-container examples.
- The canary Service distributed 40 requests across the shared stable/canary selector: 36 reached stable v1 and 4 reached canary v2.
- The Recreate rollout reduced the old ReplicaSet to zero before the v2 ReplicaSet became ready, then returned `VERSION: v2 (UPGRADED)`.

## References

- [Instructor Kubernetes repository](https://github.com/Nency-Ravaliya/Kubernetes)
- [Kubernetes workload documentation](https://kubernetes.io/docs/concepts/workloads/)
