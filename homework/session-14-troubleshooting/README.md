# Session 14 — Troubleshooting

Student: Viraj Bhanage, roll 24BCS10274

## Commands

| Command | What it answers |
|---|---|
| `kubectl get pods -o wide` | Phase, node, IP, restarts |
| `kubectl describe pod` | Events, probes, why it is Pending or waiting |
| `kubectl logs` | Process stdout and stderr. `--previous` is the crashed container |
| `kubectl exec` | Shell inside a running container |
| `kubectl get events --sort-by=.lastTimestamp` | Cluster timeline |
| `kubectl explain pod.spec.containers` | Field documentation |
| `kubectl top pods` | CPU and memory, needs Metrics Server |

## Scenarios in the course repo

| Scenario | Symptom | Root cause | Fix |
|---|---|---|---|
| `scenario-1-crashloop` | `CrashLoopBackOff`, restarts climbing | Python exits 1 because `DATABASE_URL` is unset | Set the env var. Fixed file: `fixed/scenario-1-crashloop.yaml` |
| `scenario-2-imagepull` | `ImagePullBackOff` / `ErrImagePull` | Image `yatri-api-service:v999-invalid-tag-does-not-exist` does not exist | Use `nginx:1.27-alpine`. Fixed file: `fixed/scenario-2-imagepull.yaml` |
| `scenario-3-pending` | `Pending`, never `ContainerCreating` | Requests `cpu: "500"` and `memory: "1000Gi"` | Request `100m` / `128Mi`. Fixed file: `fixed/scenario-3-pending.yaml` |
| `scenario-4-dns-failure` | `curl` to the database fails, Pod stays up | Hostname `postgres-db-wrong-name.production.svc.cluster.local` does not exist | Use the real Service FQDN. `kubectl get svc -n production` |
| `scenario-5-oomkilled` | Restart reason `OOMKilled` | The process allocates about 200MB and the limit is `20Mi` | Stop the leak, or raise the limit above the working set. Fixed file: `fixed/scenario-5-oomkilled.yaml` |

`ContainerCreating` usually means the image is still pulling or a volume is not mounted. `describe` shows `FailedMount` or `Pulling`.

Service connectivity: compare Service `selector` with Pod labels, then `kubectl get endpoints`. Empty endpoints mean the selector matches nothing. DNS issues: `nslookup` the Service name from a debug Pod and check CoreDNS logs.

## Mini project

`session-14-kubernetes-troubleshooting/mini-project/deployment.yaml` and `service.yaml` are a healthy nginx Deployment plus ClusterIP. `broken-pod.yaml` uses `nginx:this-tag-does-not-exist`.

```bash
kubectl apply -f session-14-kubernetes-troubleshooting/mini-project/deployment.yaml
kubectl apply -f session-14-kubernetes-troubleshooting/mini-project/service.yaml
kubectl apply -f session-14-kubernetes-troubleshooting/mini-project/broken-pod.yaml
kubectl describe pod project-broken-pod
kubectl delete pod project-broken-pod
kubectl get pods,svc
```

Before: `project-broken-pod` is `ErrImagePull`. The Deployment Pods are `Running` and `troubleshooting-service` has endpoints. After deleting the broken Pod, only the healthy Deployment remains.

Screenshot `kubectl describe pod project-broken-pod` (the `Failed` image pull event) and `kubectl get pods` after the fix.
