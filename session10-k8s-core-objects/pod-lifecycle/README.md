# Kubernetes Pod Lifecycle Lab

This lab demonstrates major Pod lifecycle phases, container states, health probes, init container sequences, sidecars, and graceful termination routines.

## Recommended Labs

1. **Running** (`01-running.yaml`): Standard active Pod state.
2. **Pending** (`02-pending.yaml`): Insufficient CPU/Memory resource scheduling constraints.
3. **Succeeded** (`03-succeeded.yaml`): One-shot job exiting with 0.
4. **Failed** (`04-failed.yaml`): Container terminating with non-zero exit status.
5. **CrashLoopBackOff** (`05-crashloopbackoff.yaml`): Exponential backoff restart loop.
6. **ImagePullBackOff** (`06-imagepullbackoff.yaml`): Invalid container image tag or repository.
7. **Readiness Probe** (`07-readiness.yaml`): Controls traffic routing readiness (`Running != Ready`).
8. **Liveness Probe** (`08-liveness.yaml`): Automatic container restart upon health check failure.
9. **Startup Probe** (`09-startup.yaml`): Postpones liveness/readiness checks for slow-booting applications.
10. **Init Container** (`10-init-container.yaml`): Sequential initialization containers running before main application containers.
11. **Multi-container Pod** (`11-multi-container.yaml`): Co-located sidecar logging/monitoring container pattern.
12. **Graceful Termination** (`12-termination.yaml`): `SIGTERM` trap handler with `terminationGracePeriodSeconds`.

## Operational Commands

- **Deploy All Lifecycle Labs**:
  ```bash
  kubectl apply -f .
  ```

- **Observe Real-time Pod Transitions**:
  ```bash
  kubectl get pods -w
  ```

- **Detailed Container Inspection**:
  ```bash
  kubectl describe pod <pod-name>
  kubectl logs <pod-name>
  ```

- **Cleanup**:
  ```bash
  kubectl delete -f .
  ```
