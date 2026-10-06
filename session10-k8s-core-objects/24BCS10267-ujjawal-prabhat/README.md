# Session 10 - Pods, ReplicaSets & Deployments

| | |
|---|---|
| **Student** | Ujjawal Prabhat |
| **Enrollment No.** | 24BCS10267 |
| **Session** | 10 - Pods, ReplicaSets & Deployments |

## Task checklist

- [x] **Task 1 - Deployment strategies** -> [`deployment-strategies/README.md`](deployment-strategies/README.md)
  - [x] Rolling update: `maxSurge: 1`, `maxUnavailable: 0`, image update, `get pods -w` / `get rs -w` timelines, old vs new RS, 0 failed requests
  - [x] Blue-green: two Deployments, Service selector switch, curl shows `v1 (BLUE)` -> `v2 (GREEN)`, instant rollback
  - [x] Canary: 9 stable + 1 canary sharing `app: canary-app`. 50-request samples gave 8/50 and 4/50, and 500 requests gave 45/500 (9%)
  - [x] Recreate: `get pods -w` shows all 3 old pods `Terminating` before any new pod is `Pending`, about 2 s of failed requests
- [x] **Task 2 - Pod lifecycle** -> [`pod-lifecycle/README.md`](pod-lifecycle/README.md)
  - [x] All 12 course manifests from `../pod-lifecycle/`: apply, get, phase, describe, logs, explanation
  - [x] Extra manifest for `postStart` / `preStop` hooks

## Environment

kind cluster `kind-devops-heros` (1 control-plane + 2 workers, Kubernetes v1.37.0, arm64), namespace `s10`.
All output in the sub-READMEs is real captured terminal output. Long outputs are trimmed and marked with `...`.

## Folder layout

```
24BCS10267-ujjawal-prabhat/
├── README.md
├── deployment-strategies/
│   ├── README.md
│   ├── client-pod.yaml                  # curlimages/curl client used for all traffic tests
│   ├── 01-rolling-update/  deployment-v1.yaml  deployment-v2.yaml  service.yaml
│   ├── 02-blue-green/      deployment-blue.yaml  deployment-green.yaml  service.yaml
│   ├── 03-canary/          deployment-stable.yaml  deployment-canary.yaml  service.yaml
│   └── 04-recreate/        deployment-v1.yaml  deployment-v2.yaml  service.yaml
└── pod-lifecycle/
    ├── README.md                        # uses the course YAMLs in ../../pod-lifecycle/
    └── 13-lifecycle-hooks.yaml          # extra: postStart/preStop demo
```

## Pod -> ReplicaSet -> Deployment (quick recap)

- **Pod**: one or more containers with a shared IP and volumes. Nothing restarts it if it is deleted.
- **ReplicaSet**: keeps N pods matching a label selector running (self-healing). It has no update logic of its own.
- **Deployment**: owns ReplicaSets. Each change to the pod template creates a **new** ReplicaSet (named with a new
  `pod-template-hash`). The `strategy` field decides how the old RS is scaled down and the new one scaled up, and the old RSs are kept for `rollout undo`.

## Things I found while doing this (real, not from the docs)

1. **`maxUnavailable: 0` alone did not give zero failed requests.** My first rolling update lost 1 of 60 requests because
   the old pod stopped before kube-proxy removed its endpoint. A `preStop` sleep fixed it (0 of 100 failed).
2. **Recreate downtime was only ~2 s, not the full termination time.** Pods that are terminating but still serving
   kept getting traffic, because kube-proxy falls back to them when no ready endpoints exist. The actual gap was from old exit to new readiness.
3. **A 50-request canary sample is noisy** (16% and 8% in two runs). 500 requests gave 9%, close to the expected 10%.
4. **PID 1 that ignores SIGTERM makes every deletion wait the full grace period** (16 s for my hooks pod vs 11 s for the trapped one).

## Cleanup

```bash
kubectl delete ns s10
```
