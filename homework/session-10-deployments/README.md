# Session 10 — Deployment strategies and Pod lifecycle

Student: Viraj Bhanage, roll 24BCS10274

Apply on a running cluster:

```bash
kubectl apply -f rolling-update.yaml
kubectl apply -f blue-green.yaml
kubectl apply -f canary.yaml
kubectl apply -f recreate.yaml
kubectl apply -f pod-lifecycle.yaml
kubectl get pods -o wide
kubectl describe pod lifecycle-pending
```

## Rolling update

`rolling-web` uses `maxUnavailable: 0` and `maxSurge: 1`. An update starts one extra Pod on the new template before any old Pod is removed, so capacity never drops. Change the image tag and watch `kubectl get pods -w`. Old and new Pods overlap until the rollout finishes.

```bash
kubectl set image deployment/rolling-web web=nginx:1.25-alpine
kubectl rollout status deployment/rolling-web
```

## Blue-green

`web-blue` (nginx) and `web-green` (Apache) run at the same time. The Service `color-web` selects `version: blue`. Switching traffic is a selector change, not a Pod restart:

```bash
kubectl patch svc color-web -p '{"spec":{"selector":{"app":"color-web","version":"green"}}}'
```

Point it back to `blue` the same way. Only the selected color receives traffic.

## Canary

`canary-stable` has 4 replicas and `canary-new` has 1. Both share the label `app: canary-web`, and the Service selects that label. About 1 of 5 requests reaches the canary image `nginx:1.25-alpine`. Raise or lower the canary replica count to change the percentage.

## Recreate

`recreate-web` uses `strategy.type: Recreate`. On update, Kubernetes terminates the old Pods first and only then creates the new ones. There is a window with zero ready Pods. Use it when two versions cannot run together.

## Pod lifecycle

| Pod | What you should see | Why |
|---|---|---|
| `lifecycle-running` | `Running` | Nginx process stays up |
| `lifecycle-succeeded` | `Succeeded` | `restartPolicy: Never` and exit code 0 |
| `lifecycle-failed` | `Failed` | exit code 1 and `restartPolicy: Never` |
| `lifecycle-pending` | `Pending` | `nodeSelector` matches no node, so the scheduler waits |

`CrashLoopBackOff` is not a phase. The phase stays `Running` or `Waiting` while the kubelet restarts a container that keeps exiting and `restartPolicy` is `Always`.

Paste `kubectl get pods` and `kubectl describe pod lifecycle-pending` under this heading after you apply the files. That describe output should mention a failed scheduling predicate for the node selector.
