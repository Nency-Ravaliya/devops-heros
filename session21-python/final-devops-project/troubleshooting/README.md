# Final Troubleshooting Challenge

There are nine intentionally broken variants of the TaskBoard backend. For each one I applied the broken manifest, investigated it with the usual `kubectl` toolkit, found the root cause, applied the fix and verified it. All of the output below comes from real runs on the `session21` minikube cluster. The screenshots are `screenshots/80-97`, two per scenario: broken plus investigation, then fix plus verification.

```
troubleshooting/scenarios/
├── 00-common.yaml                         namespace tb-debug, ConfigMap api-config, Secret api-db, toolbox pod
├── 01-imagepullbackoff/{broken,fixed}.yaml
├── 02-crashloop-wrong-db-password/...
├── 03-service-no-endpoints/...
├── 04-readiness-probe-wrong-path/...
├── 05-configmap-key-missing/...
├── 06-oomkilled/...
├── 07-ingress-wrong-service-port/...
├── 08-pvc-pending-storageclass/...
└── 09-hpa-missing-requests/...
```

**Why a separate namespace (`tb-debug`)?** Namespace `taskboard` is owned by Argo CD with `selfHeal: true`. Argo would put any breakage back to the Git state before it could be investigated, which is GitOps working as intended. The scenarios therefore run in `tb-debug` and reuse the Argo-managed Postgres through cluster DNS (`taskboard-postgres.taskboard.svc.cluster.local`).

```bash
cd troubleshooting
kubectl apply -f scenarios/00-common.yaml
kubectl apply -f scenarios/0N-.../broken.yaml     # investigate ...
kubectl apply -f scenarios/0N-.../fixed.yaml      # fix + verify
kubectl delete ns tb-debug                        # when finished
```

## The investigation toolkit

| Question | Command |
|----------|---------|
| What state is it in? | `kubectl get pods -o wide`, `kubectl get deploy,rs,svc,ingress,pvc,hpa` |
| Why? | `kubectl describe pod/svc/ingress/pvc/hpa <name>`, then read **State / Last State / Events** |
| What happened recently? | `kubectl events --for pod/<name>` or `kubectl get events --field-selector reason=Failed` |
| What did the app say? | `kubectl logs deploy/x`, and `--previous` for the crashed container |
| Is traffic wired correctly? | `kubectl get endpointslices -l kubernetes.io/service-name=x` and `kubectl get svc x -o jsonpath='{.spec.selector}'`; then compare with `kubectl get pods --show-labels` |
| Test from inside the cluster | `kubectl exec toolbox -- wget -qO- http://svc:port/path` or `kubectl exec deploy/x -- ...` |
| Node / kernel level | `minikube ssh "sudo dmesg"` |

---

### 01: ImagePullBackOff (wrong image tag)

**Symptom.** The pod is `0/1 ImagePullBackOff`.

**Investigation** (screenshot 80):

```
$ kubectl -n tb-debug describe pod -l app=api | grep -E "Image:|State:|Reason:"
    Image:          taskboard-backend:9.9.9
      Reason:       ImagePullBackOff
$ kubectl -n tb-debug get events --field-selector reason=Failed -o jsonpath='{range .items[*]}{.message}{"\n"}{end}' | sort -u
Failed to pull image "taskboard-backend:9.9.9": ... "docker.io/library/taskboard-backend:9.9.9": pull access denied, repository does not exist or may require authorization
$ minikube -p session21 image ls | grep taskboard-backend
docker.io/library/taskboard-backend:1.1.0
docker.io/library/taskboard-backend:1.0.0
```

**Root cause.** Tag `9.9.9` was never built. It is not in the node's image store, so the kubelet tried Docker Hub, which denied the pull.

**Fix.** Change the image to `taskboard-backend:1.0.0`, an existing tag. In real environments, pin tags that CI has actually pushed and use `imagePullSecrets` for private registries.

**Verification** (81). After `rollout status`, the pod is `1/1 Running`, the image is `taskboard-backend:1.0.0`, and `/ready` returns `{"status":"READY"}`.

### 02: CrashLoopBackOff (wrong DB password in the Secret)

**Symptom.** The pod is `0/1 CrashLoopBackOff`, and its restart count keeps climbing.

**Investigation** (82):

```
$ kubectl -n tb-debug describe pod -l app=api | grep -A4 "Last State"
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
$ kubectl -n tb-debug logs deploy/api --previous | tail -4
sqlalchemy.exc.OperationalError: (psycopg.OperationalError) connection failed: ... FATAL:  password authentication failed for user "taskboard"
$ kubectl -n taskboard logs taskboard-postgres-0 | grep "password authentication failed" | tail -2
... FATAL:  password authentication failed for user "taskboard"
$ kubectl -n tb-debug get secret api-db -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
wrong-password
```

**Root cause.** Secret `api-db` holds the wrong password. `alembic upgrade head` fails on start, the container exits with code 1, and the kubelet backs off.

**Fix.** Correct the Secret, then **`kubectl rollout restart deploy/api`**. Environment variables from a Secret are only read when the container starts, so updating the Secret alone does not fix pods that are already running.

**Verification** (83). The pod is `1/1 Running` with 0 restarts. The logs show `Application startup complete`, and `/api/tasks/stats` returns `{"total":3,...}`.

### 03: Service has no endpoints (selector mismatch)

**Symptom.** The pod is Running and Ready, but `wget http://api:8000/ready` gives `Connection refused`.

**Investigation** (84):

```
$ kubectl -n tb-debug get pods -l app=api --show-labels
api-7d674fb77c-l4fph   1/1   Running   ...   app=api,pod-template-hash=7d674fb77c
$ kubectl -n tb-debug get endpointslices -l kubernetes.io/service-name=api
api-htmrx   IPv4   <unset>   <unset>
$ kubectl -n tb-debug get svc api -o jsonpath='selector: {.spec.selector}'
selector: {"app":"backend"}
$ kubectl -n tb-debug get pods -l app=backend
No resources found in tb-debug namespace.
```

**Root cause.** The Service selector is `app=backend`, but the pods are labelled `app=api`. The selector matches nothing, so the Service has 0 endpoints.

**Fix.** Change the selector to `app: api`.

**Verification** (85). The EndpointSlice now lists `10.244.0.74` on port 8000. Both `wget http://api:8000/ready` and the FQDN `api.tb-debug.svc.cluster.local` return a response.

### 04: Pod never Ready (readiness probe on the wrong path)

**Symptom.** The pod is `0/1 Running` with no restarts, and `rollout status` times out.

**Investigation** (86):

```
$ kubectl -n tb-debug describe pod -l app=api | grep -E "Readiness:|^  Ready "
    Readiness:  http-get http://:http/readyz delay=0s timeout=5s period=5s ...
  Ready                       False
$ kubectl -n tb-debug events --for pod/<pod> | grep Unhealthy
... Readiness probe failed: HTTP probe failed with statuscode: 404
$ kubectl -n tb-debug logs deploy/api | grep readyz | tail -2
INFO:     10.244.0.1:50940 - "GET /readyz HTTP/1.1" 404 Not Found
$ kubectl -n tb-debug get endpointslice ... ready=...
10.244.0.75 ready=false
```

**Root cause.** The probe calls `/readyz`, but the app serves `/ready`, so every check returns 404. The pod is never marked Ready and never receives Service traffic. The liveness probe on `/health` passes, which is why there are no restarts.

**Fix.** Set `readinessProbe.httpGet.path: /ready`.

**Verification** (87). The pod is `1/1`, the endpoint shows `ready=true`, and `wget http://api:8000/ready` returns `{"status":"READY"}`.

### 05: CreateContainerConfigError (ConfigMap key missing)

**Symptom.** The pod is `0/1 CreateContainerConfigError` and the container never starts.

**Investigation** (88):

```
$ kubectl -n tb-debug describe pod -l app=api | grep -E "Reason:|DB_HOST"
      Reason:       CreateContainerConfigError
      DB_HOST:       <set to the key 'DB_HOSTNAME' of config map 'api-config'>  Optional: false
  Warning  Failed ... Error: couldn't find key DB_HOSTNAME in ConfigMap tb-debug/api-config
$ kubectl -n tb-debug get configmap api-config -o jsonpath="{.data}"
{"DB_HOST":"taskboard-postgres.taskboard.svc.cluster.local","DB_NAME":"taskboard","DB_PORT":"5432"}
```

**Root cause.** The env var refers to key `DB_HOSTNAME`, but the ConfigMap only has `DB_HOST`. The reference is not optional, so the kubelet refuses to create the container.

**Fix.** Use `configMapKeyRef.key: DB_HOST`. Alternatively, add the key, or mark the reference `optional: true` if the value really is optional.

**Verification** (89). The pod is `1/1 Running`, `printenv DB_HOST` prints the Postgres FQDN, and `/ready` returns `READY`.

### 06: OOMKilled (memory limit too small)

**Symptom.** The pod status is `OOMKilled` and it keeps restarting.

**Investigation** (90):

```
$ kubectl -n tb-debug describe pod -l app=api | grep -A3 "Last State|Limits:"
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
    Limits:   memory:  40Mi
$ minikube -p session21 ssh "sudo dmesg | grep -i 'memory cgroup out of memory' | tail -2"
Memory cgroup out of memory: Killed process 1024 (alembic) total-vm:62460kB, anon-rss:37900kB ...
$ kubectl -n taskboard exec deploy/taskboard-backend -- cat /sys/fs/cgroup/memory.current   # healthy pod
71 MiB
```

**Root cause.** The 40Mi limit is lower than what Python, Alembic, FastAPI and SQLAlchemy need at start-up. A healthy pod uses about 71 MiB, so the kernel's cgroup OOM killer ends the process (exit 137 = SIGKILL).

**Fix.** Set requests to `96Mi` and the limit to `256Mi`, sized from observed usage plus headroom.

**Verification** (91). The pod is `1/1 Running` with `restarts=0`. `memory.current` shows 72 MiB against a `memory.max` of 256 MiB.

### 07: Ingress returns 503 (wrong service port)

**Symptom.** `curl http://debug.taskboard.local/api/tasks` returns **HTTP 503**, although the pod and Service are healthy.

**Investigation** (92):

```
$ kubectl -n tb-debug describe ingress api | grep /api
                         /api   api:8080 ()          <- "()" = no endpoints behind this backend
$ kubectl -n tb-debug get svc api
api    ClusterIP   10.97.176.198   <none>   8000/TCP
$ kubectl -n ingress-nginx logs deploy/ingress-nginx-controller | grep tb-debug-api | tail -1
"GET /api/tasks HTTP/1.1" 503 ... [tb-debug-api-8080] [] - - - -
```

**Root cause.** The Ingress backend uses `port: 8080`, but Service `api` only exposes `8000`. The controller builds an upstream `tb-debug-api-8080` with no servers in it and answers with 503.

**Fix.** Set the Ingress backend `port.number: 8000`.

**Verification** (93). The request returns **HTTP 200** and `/api/tasks/stats` returns JSON. The Ingress now shows `api:8000 (10.244.0.81:8000)`, and the controller log shows upstream `[tb-debug-api-8000] 10.244.0.81:8000 ... 200`.

### 08: PVC Pending (StorageClass does not exist)

**Symptom.** The PVC is `Pending` and the pod is `Pending`.

**Investigation** (94):

```
$ kubectl -n tb-debug describe pvc scratch-data | grep -E "StorageClass|Status"
StorageClass:  fast-ssd
Status:        Pending
  Warning  ProvisioningFailed  ...  storageclass.storage.k8s.io "fast-ssd" not found
$ kubectl -n tb-debug events --for pod/writer | tail -1
  Warning  FailedScheduling  ...  0/1 nodes are available: pod has unbound immediate PersistentVolumeClaims.
$ kubectl get storageclass
standard (default)   k8s.io/minikube-hostpath   Delete   Immediate
```

**Root cause.** `storageClassName: fast-ssd` does not exist, so no provisioner creates a PV. The pod cannot be scheduled while its claim is unbound.

**Fix.** Use `storageClassName: standard`, or omit it to get the cluster default. `kubectl apply` of the fixed file is rejected with `spec is immutable after creation`. Delete the Pending PVC and the pod, then recreate them.

**Verification** (95). The PVC is `Bound` to `pvc-b00e8c09-...` (256Mi, standard), the pod is `1/1 Running`, and `kubectl logs writer` prints the date it wrote to `/data/hello.txt`.

### 09: HPA shows `<unknown>` (no CPU request)

**Symptom.** `kubectl get hpa` shows `cpu: <unknown>/50%` and the HPA never scales.

**Investigation** (96):

```
$ kubectl -n tb-debug describe hpa api | grep "missing request"
  Warning  FailedGetResourceMetric  ...  failed to get cpu utilization: missing request for cpu in container api of Pod api-64bd976869-ztwfk
$ kubectl top pod -n tb-debug -l app=api
api-64bd976869-ztwfk   12m   64Mi           <- metrics-server works fine
$ kubectl -n tb-debug get deploy api -o jsonpath='resources={...resources}'
resources={}
```

**Root cause.** Utilization is calculated as usage divided by the request. The container has no CPU request, so there is nothing to divide by.

The first attempt at breaking this scenario only removed `requests` and kept `limits`. The HPA still worked (`cpu: 3%/50%`), because the API server sets requests equal to limits when only limits are given. To reproduce the failure, the whole `resources` block has to go.

**Fix.** Add `resources.requests: {cpu: 50m, memory: 96Mi}` and the limits back.

**Verification** (97). The HPA shows `cpu: 22%/50%`, with `ScalingActive True ValidMetricFound`.

---

## Real incidents seen while building the capstone

These were not staged. They are recorded here as part of the challenge:

| Symptom | Root cause | Fix |
|---------|-----------|-----|
| `apply -k` failed: `failed calling webhook "validate.nginx.ingress.kubernetes.io"` | The ingress controller pod wasn't ready yet, straight after `addons enable ingress` | Wait for the controller, then apply again |
| Backend `Init:0/1` forever, init log said `postgres:5432 - no attempt` | `pg_isready` running as uid 10001 has no user name | `pg_isready -U probe ...` |
| `nginx: host not found in upstream "backend"` risk | The frontend nginx proxies to `http://backend:8000` | Keep the backend Service named `backend` in the manifests and the chart |
| `TLS handshake timeout`, pods restarting, metrics-server `CrashLoopBackOff`, Argo app `Unknown/Degraded` | The 2-vCPU, 2.9 GB node was saturated: CPU PSI around 95%, IO PSI around 85%, swapping. Starting kube-prometheus-stack triggered it | Replaced kube-prometheus-stack with server-only Prometheus plus Grafana, scaled unused Argo components to 0, and raised the kicbase container quota (`docker update --cpus=4 --memory=3300m session21`) |
| `helm upgrade --reuse-values` did not pick up new probe timeouts | `--reuse-values` ignores new chart defaults | `--reset-then-reuse-values` |
| Error-rate panel showed "No data" instead of 0 | No `status="5xx"` series exists until the first 5xx | `(... ) or vector(0)` |
