# Session 10: Deployment strategies and Pod lifecycle

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

Create namespace `student10`; run commands from this directory. The lifecycle
manifests are the instructor's examples, retained with their original names.
Apply and inspect each lifecycle YAML separately, for example:

```bash
kubectl -n student10 apply -f pod-lifecycle/01-running.yaml
kubectl -n student10 get pods -o wide
kubectl -n student10 describe -f pod-lifecycle/01-running.yaml
```

Repeat for each file in pod-lifecycle/. Recheck status after scheduling and probes run.

```bash
kubectl create namespace student10
kubectl -n student10 apply -f strategies/
kubectl -n student10 rollout status deployment/rolling
kubectl -n student10 get pods -w
# In another terminal:
kubectl -n student10 set image deployment/rolling web=nginx:alpine
kubectl -n student10 rollout status deployment/rolling
kubectl -n student10 get rs,pods

# Switch the Service selector from blue to green:
kubectl -n student10 port-forward svc/colour 18100:80
# curl localhost:18100 before and after restarting port-forward for the new selector
kubectl -n student10 patch svc colour -p '{"spec":{"selector":{"app":"colour","version":"green"}}}'
kubectl -n student10 get endpointslices -l kubernetes.io/service-name=colour

# Nine stable replicas and one canary approximate 10% of new connections:
kubectl -n student10 get pods -l app=canary-web --show-labels
kubectl -n student10 run client --image=busybox:1.36 --restart=Never -- sh -c 'for i in $(seq 1 30); do wget -qO- http://canary-web; done'
kubectl -n student10 logs client

# Observe events while updating the Recreate deployment:
kubectl -n student10 get pods -l app=recreate -w
kubectl -n student10 set image deployment/recreate web=nginx:alpine
kubectl -n student10 rollout status deployment/recreate
kubectl -n student10 get events --sort-by=.metadata.creationTimestamp
```

RollingUpdate replaces Pods gradually. Blue-green keeps two versions and changes
the Service selector. Replica-based canary is approximate: connection reuse and
routing mean it is not a guaranteed 10% request split. Recreate removes old Pods
before starting replacements and can cause downtime.

| Lifecycle example | Expected lesson (not an execution result) |
|---|---|
| running | Healthy long-running process |
| pending | Scheduler cannot satisfy placement or resource requirements |
| succeeded | Process exits successfully with an appropriate restart policy |
| failed | Process exits unsuccessfully with Never restart policy |
| crashloopbackoff | Repeated exits cause increasing restart delay |
| imagepullbackoff | Image retrieval fails and retries are delayed |
| readiness | A running Pod may still be removed from Service traffic |
| liveness | Failed checks cause container restart |
| startup | Delays other probes until initialization succeeds |
| multi-container | Containers share a Pod network and can share volumes |
| termination | Grace period allows shutdown before forced termination |

Pod phases are Pending, Running, Succeeded, Failed, and Unknown. Waiting reasons
such as CrashLoopBackOff are not additional Pod phases. Capture actual `get`,
`describe`, events, and logs in `evidence/` when a cluster is available.
Cleanup: `kubectl delete namespace student10`.

## Verification

Manifest syntax checked.

All strategy and lifecycle runtime observations need a Kubernetes cluster.
