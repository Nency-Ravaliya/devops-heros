# Session 10 — Kubernetes Pods, ReplicaSets & Deployments

**Submitted by:** Piyush Bansal
**Cluster used:** Kubernetes v1.36.1, single node (`desktop-control-plane`), arm64

All manifests were applied to a live cluster. Every command output below was captured from
that run.

## Contents

| Topic | Notes |
|---|---|
| Pod lifecycle | [pod-lifecycle/](pod-lifecycle/) — all 12 states, probes, init containers, debugging |
| Core objects | [core-objects/](core-objects/) — Pod → ReplicaSet → Deployment, self-healing proven |
| Rolling update | [01-rolling-update/](01-rolling-update/) — maxSurge in action, plus rollback |
| Blue-green | [02-blue-green/](02-blue-green/) — instant 100% traffic switch |
| Canary | [03-canary/](03-canary/) — measured 9/60 split across 60 requests |
| Recreate | [04-recreate/](04-recreate/) — caught the downtime window at t=2s |

## The four deployment strategies compared

| Strategy | Downtime | Extra pods | Versions coexist | Rollback |
|---|---|---|---|---|
| Rolling update | none | +maxSurge | yes, briefly | another rollout |
| Blue-green | none | 2N | no | instant |
| Canary | none | N + a few | yes, by design | scale canary to 0 |
| Recreate | **yes** | none | never | another outage |

## The four things that actually landed

**1. Self-healing is a reconciliation loop, not magic.** Deleting a pod by hand produced a
replacement in about a second — visible as a pod aged `1s` beside others aged `3m49s`. The
controller simply compares desired state to actual and acts on the difference.

**2. `maxSurge: 1` is observable.** During the rolling update there were briefly **5 pods**
for a 4-replica deployment. With `maxUnavailable: 0`, Kubernetes must add before it removes,
so capacity never dips.

**3. Blue-green and canary differ by one label in the Service selector.**
Blue-green's selector includes `slot`, so it matches exactly one deployment. Canary's matches
only `app`, so it spans both and splits traffic by pod count. Same mechanism, opposite
outcome — that is the insight I would not have got from reading alone.

**4. Recreate's downtime is only visible if you poll during the rollout.** Checking before
and after showed 3 pods both times. Polling once per second caught `running=0` at t=2s.

## Debugging skills practised

From the deliberately broken pods in [pod-lifecycle/](pod-lifecycle/):

| Symptom | Command that explains it | Root cause found |
|---|---|---|
| `Pending` | `kubectl describe pod` → Events | Insufficient memory to schedule |
| `ImagePullBackOff` | `kubectl describe pod` → Events | image does not exist |
| `CrashLoopBackOff` | `kubectl logs` + `lastState.terminated` | app exits with code 1 |
| restart count climbing | `kubectl describe` → Unhealthy events | liveness probe failing |

The general lesson: `kubectl get` tells you *that* something is wrong, `kubectl describe` and
`kubectl logs` tell you *why*.

## Liveness vs readiness vs startup

- **Liveness** fails → container **restarted**. For deadlocks.
- **Readiness** fails → pod removed from Service endpoints, left running. For "busy, don't
  send traffic".
- **Startup** → suspends the other two until the app has booted, so slow starters aren't
  killed prematurely.

## A cluster issue worth noting

The manifests specify `nginx:1.27`, which could not be pulled here — the local registry
mirror returned `500 Internal Server Error` for any uncached image:

```text
unexpected status from HEAD request to http://registry-mirror:1273/v2/library/nginx/manifests/1.27
```

An infrastructure problem, not a manifest problem. I ran the labs with `nginx:1.25-alpine`
(already cached locally) so the states and strategies could be demonstrated. The committed
YAML files are unchanged.
