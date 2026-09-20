# Kubernetes Pods, ReplicaSets & Deployments

**Name:** Shreyas S
**Enrollment number:** 10401
**GitHub:** [NeuralSynth](https://github.com/NeuralSynth)

> **Execution status:** Manifests and exercises prepared. Cluster execution and actual output are pending because Docker Desktop / Minikube is stopped. This page does not claim a successful cluster run.

## Object comparison

| Object | Responsibility | What happens when a Pod is deleted? |
| --- | --- | --- |
| Standalone Pod | Runs one group of containers | No controller recreates it |
| ReplicaSet | Maintains a matching number of Pods | Creates a replacement with a new name/UID |
| Deployment | Manages ReplicaSets, updates and revision history | Its ReplicaSet replaces the Pod |

[objects.yaml](objects.yaml) defines all three with different selectors. This prevents a ReplicaSet from adopting the standalone Pod or a Deployment's Pods. Each selector matches its own Pod template labels.

## Exercise

The runner applies the objects, waits for readiness, deletes one ReplicaSet Pod and verifies replacement, scales the Deployment from two to three replicas, updates Nginx from `1.27-alpine` to `1.28-alpine`, waits for rollout, reads the revision history, rolls back and verifies the original image.

```bash
kubectl --context devops-homework -n rudray-devops-hw get pods,rs,deployments
kubectl --context devops-homework -n rudray-devops-hw scale deployment/deployment-web --replicas=3
kubectl --context devops-homework -n rudray-devops-hw set image deployment/deployment-web nginx=nginx:1.28-alpine
kubectl --context devops-homework -n rudray-devops-hw rollout status deployment/deployment-web
kubectl --context devops-homework -n rudray-devops-hw rollout history deployment/deployment-web
kubectl --context devops-homework -n rudray-devops-hw rollout undo deployment/deployment-web
```

`maxUnavailable: 0` keeps the desired number available during a healthy rolling update, and `maxSurge: 1` permits one extra Pod. Spare capacity is needed for that extra Pod. A failed readiness probe prevents the new Pod receiving traffic. `rollout undo` restores an earlier Pod template; it does not roll back external data or the replica count.

## Pod lifecycle and troubleshooting

Pod phases are `Pending`, `Running`, `Succeeded`, `Failed` and `Unknown`. `CrashLoopBackOff` and `ImagePullBackOff` are displayed container waiting reasons, not Pod phases. For a failing workload, inspect events with `describe`, inspect the image and command, check current and previous container logs (`logs --previous`), then check readiness/liveness probes and resource limits.

RollingUpdate gradually replaces Pods. Recreate stops the old Pods first. Blue/green uses separate Deployments and switches a Service selector. Canary runs a small new version beside the stable version; plain Service routing does not guarantee an exact traffic percentage.

## Run and capture actual output

From the repository root, after Docker Desktop is running:

```bash
minikube start -p devops-homework --driver=docker --cpus=2 --memory=3072
minikube addons enable ingress -p devops-homework
python3 scripts/run-kubernetes-labs.py --context devops-homework --topic 10
```

The runner saves commands, actual stdout/stderr and exit codes to `OUTPUT.md` in this folder. It marks success only after the checks finish. All resources are limited to the `rudray-devops-hw` namespace; the ingress addon is cluster-wide in this dedicated Minikube profile.

After finishing all four topics, remove the assignment resources:

```bash
kubectl --context devops-homework delete namespace rudray-devops-hw
```

## References

- [Instructor course repository](https://github.com/Nency-Ravaliya/devops-heros)
- [Kubernetes concepts](https://kubernetes.io/docs/concepts/)
- [Submission index](../../README.md)
