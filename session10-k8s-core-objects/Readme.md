# Session 10: Kubernetes Pods, ReplicaSets & Deployments

This folder contains the assignment manifests, commands, observations, and real Minikube evidence for deployment strategies and Pod lifecycle states.

## Assignment map

| Requirement | Implementation | Evidence |
|---|---|---|
| Rolling Update | [`01-rolling-update/`](01-rolling-update/) | [`rolling-update.png`](screenshots/rolling-update.png) |
| Blue-Green | [`02-blue-green/`](02-blue-green/) | [`blue-green-routing.png`](screenshots/blue-green-routing.png) |
| Canary | [`03-canary/`](03-canary/) | Commands and expected observations are documented in its README |
| Recreate | [`04-recreate/`](04-recreate/) | Commands and expected observations are documented in its README |
| Pod lifecycle | [`pod-lifecycle/`](pod-lifecycle/) | [`pod-lifecycle.png`](screenshots/pod-lifecycle.png) |
| Core objects | [`k8s-core-objects/`](k8s-core-objects/) | Pod, ReplicaSet, Deployment, DaemonSet, and StatefulSet manifests |

## Verified observations

- The rolling update replaced four replicas gradually and completed with all four replicas available on `nginx:1.25-alpine`.
- Blue and green Deployments were healthy simultaneously. Changing the Service selector to `slot: green` routed traffic to the green version.
- The lifecycle exercise produced Running, Pending, Completed, Error, ImagePullBackOff, init-container, and multi-container examples.

Canary and Recreate are implemented and documented, but their final terminal screenshots are still pending. The repository does not claim screenshots that were not captured.

## References

- [Instructor Kubernetes repository](https://github.com/Nency-Ravaliya/Kubernetes)
- [Kubernetes workload documentation](https://kubernetes.io/docs/concepts/workloads/)
