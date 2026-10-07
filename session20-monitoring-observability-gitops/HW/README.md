# Session 20 — Monitoring, Observability & GitOps

**Submitted by:** Piyush Bansal
**Cluster:** Docker Desktop Kubernetes v1.36.1 (single node `desktop-control-plane`, arm64, ~4 GB RAM, shared)

All output below was captured from a live run on this cluster. Nothing is invented. Where I did
not finish something, I say so.

| Task | Folder |
|---|---|
| 1. Monitoring demo | [01-monitoring/](01-monitoring/) |
| 2. Observability notes | this README, section "Task 2" |
| 3. GitOps (Argo CD) | [03-gitops/](03-gitops/) |

The cluster is small and shared, so I skipped the full kube-prometheus-stack (Grafana +
Alertmanager + node-exporter) and wrote a lean setup by hand:

- [01-monitoring/app.yaml](01-monitoring/app.yaml): `podinfo` (a small Go app that serves `/metrics`,
  `/healthz`, `/readyz` and JSON logs), 2 replicas, in namespace `p20-app`.
- [01-monitoring/prometheus.yaml](01-monitoring/prometheus.yaml): one Prometheus pod in `p20-monitoring`
  with RBAC, scraping itself, every podinfo pod (Kubernetes service discovery), and kubelet
  cAdvisor through the API server proxy (container CPU/memory). Two alert rules are in the same ConfigMap.

```bash
kubectl apply -f 01-monitoring/app.yaml -f 01-monitoring/prometheus.yaml
kubectl port-forward -n p20-monitoring svc/prometheus 18200:9090 &
kubectl port-forward -n p20-app svc/podinfo 18201:9898 &
```

---

## Task 1 — Monitoring

### Application health (probes)

podinfo has a startup, liveness and readiness probe.

```text
$ kubectl get pods -n p20-app -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP             NODE                    NOMINATED NODE   READINESS GATES
podinfo-7544f74f8b-8l4fm   1/1     Running   0          53s   10.244.0.119   desktop-control-plane   <none>           <none>
podinfo-7544f74f8b-tcn84   1/1     Running   0          39s   10.244.0.120   desktop-control-plane   <none>           <none>
$ kubectl describe pod -n p20-app -l app=podinfo | grep -E "^Name:|Liveness|Readiness|Startup|^    Ready:"
Name:             podinfo-7544f74f8b-8l4fm
    Ready:          True
    Liveness:     http-get http://:http/healthz delay=3s timeout=3s period=10s #success=1 #failure=6
    Readiness:    http-get http://:http/readyz delay=3s timeout=3s period=5s #success=1 #failure=3
    Startup:      http-get http://:http/healthz delay=0s timeout=3s period=5s #success=1 #failure=30
Name:             podinfo-7544f74f8b-tcn84
    Ready:          True
    Liveness:     http-get http://:http/healthz delay=3s timeout=3s period=10s #success=1 #failure=6
    Readiness:    http-get http://:http/readyz delay=3s timeout=3s period=5s #success=1 #failure=3
    Startup:      http-get http://:http/healthz delay=0s timeout=3s period=5s #success=1 #failure=30
$ curl -s localhost:18201/healthz; curl -s localhost:18201/readyz
{
  "status": "OK"
}
{
  "status": "OK"
}
```

**A real health problem I hit first.** My first version had a 1s probe timeout, a 200m CPU limit
and no startup probe. The shared node was very busy (the API server was slow and kube-scheduler
kept losing its lease), podinfo took ~30s to start, and the kubelet kept killing it:

```text
$ kubectl get events -n p20-app --field-selector reason=Unhealthy -o custom-columns=POD:.involvedObject.name,MSG:.message | tail -5
podinfo-cb567cb8c-tch2h    Readiness probe failed: Get "http://10.244.0.108:9898/readyz": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
podinfo-cb567cb8c-tch2h    Liveness probe failed: Get "http://10.244.0.108:9898/healthz": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
podinfo-cb567cb8c-xgjvr    Readiness probe failed: Get "http://10.244.0.109:9898/readyz": dial tcp 10.244.0.109:9898: connect: connection refused
podinfo-cb567cb8c-xgjvr    Readiness probe failed: Get "http://10.244.0.109:9898/readyz": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
podinfo-cb567cb8c-xgjvr    Liveness probe failed: Get "http://10.244.0.109:9898/healthz": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
$ kubectl get events -n p20-app --field-selector reason=Killing -o custom-columns=POD:.involvedObject.name,MSG:.message
POD                        MSG
podinfo-5f78f7cfb7-7g8vl   Container podinfo failed liveness probe, will be restarted
podinfo-5f78f7cfb7-7g8vl   Stopping container podinfo
podinfo-5f78f7cfb7-lf7vn   Container podinfo failed liveness probe, will be restarted
podinfo-5f78f7cfb7-lf7vn   Stopping container podinfo
podinfo-cb567cb8c-tch2h    Container podinfo failed liveness probe, will be restarted
podinfo-cb567cb8c-tch2h    Stopping container podinfo
podinfo-cb567cb8c-xgjvr    Container podinfo failed liveness probe, will be restarted
podinfo-cb567cb8c-xgjvr    Stopping container podinfo
```

Fix: `timeoutSeconds: 3`, a `startupProbe` (up to 150s to start), liveness `failureThreshold: 6`,
and no CPU limit (only a request). After that the pods stayed at 0 restarts (output above).

### Metrics

Raw metrics straight from the app:

```text
$ curl -s localhost:18201/metrics | grep -E "^http_requests_total|^process_resident_memory_bytes|^go_goroutines"
go_goroutines 22
http_requests_total{status="200"} 50
process_resident_memory_bytes 4.51584e+07
```

Prometheus targets (all `up`):

```text
$ curl -s localhost:18200/api/v1/targets | jq -r '.data.activeTargets[] | [.labels.job, .labels.pod // .labels.instance, .health, .lastError] | @tsv'
cadvisor	desktop-control-plane	up
podinfo	podinfo-88d5c948c-xq7tb	up
podinfo	podinfo-88d5c948c-2skzx	up
prometheus	localhost:9090	up
```

PromQL through the HTTP API (I sent light traffic to the app while running these; the
port-forward sticks to one pod, which is why `2skzx` gets most of it):

```text
$ curl -s localhost:18200/api/v1/query --data-urlencode 'query=up' | jq -r '.data.result[] | "\(.metric) \(.value[1])"'
{"__name__":"up","instance":"localhost:9090","job":"prometheus"} 1
{"__name__":"up","instance":"desktop-control-plane","job":"cadvisor"} 1
{"__name__":"up","instance":"10.244.0.121:9898","job":"podinfo","namespace":"p20-app","pod":"podinfo-88d5c948c-2skzx"} 1
{"__name__":"up","instance":"10.244.0.122:9898","job":"podinfo","namespace":"p20-app","pod":"podinfo-88d5c948c-xq7tb"} 1
$ curl -s localhost:18200/api/v1/query --data-urlencode 'query=sum by (pod, status) (rate(http_requests_total{job="podinfo"}[1m]))' | jq -r '.data.result[] | "\(.metric) \(.value[1])"'
{"pod":"podinfo-88d5c948c-2skzx","status":"200"} 2.1405137232935902
{"pod":"podinfo-88d5c948c-xq7tb","status":"200"} 0.3988990386533169
{"pod":"podinfo-88d5c948c-2skzx","status":"500"} 0
$ curl -s localhost:18200/api/v1/query --data-urlencode 'query=histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{job="podinfo"}[1m])))' | jq -r '.data.result[] | "\(.metric) \(.value[1])"'
{} 0.07944781602831044
```

So: ~2.5 req/s in total, and p95 latency ~79 ms.

### CPU and memory utilisation

From cAdvisor via PromQL:

```text
$ curl -s localhost:18200/api/v1/query --data-urlencode 'query=sum by (namespace, pod) (rate(container_cpu_usage_seconds_total{namespace=~"p20-.*", container!=""}[1m]))' | jq -r '.data.result[] | "\(.metric) \(.value[1])"'
{"namespace":"p20-app","pod":"podinfo-88d5c948c-2skzx"} 0.049314094268413634
{"namespace":"p20-app","pod":"podinfo-88d5c948c-xq7tb"} 0.016212344266852967
$ curl -s localhost:18200/api/v1/query --data-urlencode 'query=sum by (namespace, pod) (container_memory_working_set_bytes{namespace=~"p20-.*", container!=""}) / 1024 / 1024' | jq -r '.data.result[] | "\(.metric) \(.value[1])"'
{"namespace":"p20-app","pod":"podinfo-5f78f7cfb7-lf7vn"} 24.96875
{"namespace":"p20-app","pod":"podinfo-5f78f7cfb7-7g8vl"} 20.40234375
{"namespace":"p20-app","pod":"podinfo-7544f74f8b-8l4fm"} 23.9453125
{"namespace":"p20-app","pod":"podinfo-7544f74f8b-tcn84"} 24.6640625
{"namespace":"p20-app","pod":"podinfo-88d5c948c-2skzx"} 26.69140625
{"namespace":"p20-app","pod":"podinfo-88d5c948c-xq7tb"} 23.85546875
$ curl -s localhost:18200/api/v1/query --data-urlencode 'query=sum by (pod) (container_memory_working_set_bytes{namespace="p20-app", container="podinfo"}) / sum by (pod) (container_spec_memory_limit_bytes{namespace="p20-app", container="podinfo"}) * 100' | jq -r '.data.result[] | "\(.metric) \(.value[1])"'
{"pod":"podinfo-88d5c948c-2skzx"} 27.803548177083332
{"pod":"podinfo-88d5c948c-xq7tb"} 24.849446614583336
```

The busier pod uses ~49 millicores, the other ~16. Each pod uses ~24–27 MiB, which is ~25–28% of
its 96 MiB limit. The memory query still lists pods from my earlier rollouts (`5f78…`, `7544…`):
cAdvisor kept reporting those deleted pods for a few minutes, and the query has no filter for
"pod still exists" (that needs kube-state-metrics, which I did not install).

**Not done:** `kubectl top`. metrics-server on this shared cluster was in `CrashLoopBackOff`
(the node was overloaded) during my run, so `kubectl top pods -n p20-app` only returned
`error: Metrics API not available`. The PromQL queries above show the same CPU/memory data.

### Logs

I ran podinfo with `--level=debug` so it logs every request as JSON:

```text
$ curl -s -i localhost:18202/status/500 | head -1
HTTP/1.1 500 Internal Server Error
$ kubectl logs -n p20-app -l app=podinfo --prefix --tail=50 | grep -E "request started|Starting" | tail -5 | cut -c1-260
[pod/podinfo-88d5c948c-xq7tb/podinfo] {"level":"debug","ts":"2026-10-07T18:04:20.580Z","caller":"http/logging.go:21","msg":"request started","proto":"HTTP/1.1","uri":"/readyz","method":"GET","remote":"10.244.0.1:57020","user-agent":"kube-probe/1.36"}
[pod/podinfo-88d5c948c-xq7tb/podinfo] {"level":"debug","ts":"2026-10-07T18:04:23.874Z","caller":"http/logging.go:21","msg":"request started","proto":"HTTP/1.1","uri":"/healthz","method":"GET","remote":"10.244.0.1:57026","user-agent":"kube-probe/1.36"}
[pod/podinfo-88d5c948c-xq7tb/podinfo] {"level":"debug","ts":"2026-10-07T18:04:25.581Z","caller":"http/logging.go:21","msg":"request started","proto":"HTTP/1.1","uri":"/readyz","method":"GET","remote":"10.244.0.1:57042","user-agent":"kube-probe/1.36"}
[pod/podinfo-88d5c948c-xq7tb/podinfo] {"level":"debug","ts":"2026-10-07T18:04:25.772Z","caller":"http/logging.go:21","msg":"request started","proto":"HTTP/1.1","uri":"/metrics","method":"GET","remote":"10.244.0.110:42836","user-agent":"Prometheus/3.5.0"}
[pod/podinfo-88d5c948c-xq7tb/podinfo] {"level":"debug","ts":"2026-10-07T18:04:30.572Z","caller":"http/logging.go:21","msg":"request started","proto":"HTTP/1.1","uri":"/readyz","method":"GET","remote":"10.244.0.1:35748","user-agent":"kube-probe/1.36"}
$ kubectl logs -n p20-app -l app=podinfo --prefix --tail=200 | grep "/status/500" | cut -c1-260
[pod/podinfo-88d5c948c-2skzx/podinfo] {"level":"debug","ts":"2026-10-07T18:04:33.139Z","caller":"http/logging.go:21","msg":"request started","proto":"HTTP/1.1","uri":"/status/500","method":"GET","remote":"127.0.0.1:38932","user-agent":"curl/8.7.1"}
$ kubectl logs -n p20-monitoring deploy/prometheus | grep -E "Server is ready|Completed loading of configuration" | cut -c1-140
time=2026-10-07T17:41:19.406Z level=INFO source=main.go:1537 msg="Completed loading of configuration file" db_storage=89.166µs remote_storag
time=2026-10-07T17:41:19.540Z level=INFO source=main.go:1273 msg="Server is ready to receive web requests."
```

The logs show all three kinds of callers: the kubelet's probes (`kube-probe/1.36`), Prometheus
scraping `/metrics`, and my own curl.

### Alerts (one rule really firing)

Rule from [prometheus.yaml](01-monitoring/prometheus.yaml):

```yaml
- alert: PodinfoDown
  expr: (count(up{job="podinfo"} == 1) or vector(0)) < 1
  for: 30s
```

`or vector(0)` matters: when the Deployment has 0 pods there are no targets at all, so
`up == 0` would return nothing and never fire. I scaled the app to 0 and polled `/api/v1/alerts`:

```text
$ curl -s localhost:18200/api/v1/rules | jq -r '.data.groups[].rules[] | [.name, .state, .health, .query] | @tsv'
PodinfoDown	inactive	ok	(count(up{job="podinfo"} == 1) or vector(0)) < 1
PodinfoHighCPU	inactive	ok	sum by (pod) (rate(container_cpu_usage_seconds_total{container="podinfo",namespace="p20-app"}[1m])) > 0.1
$ date -u +%H:%M:%S; kubectl scale deploy/podinfo -n p20-app --replicas=0
18:06:49
deployment.apps/podinfo scaled
$ date -u +%H:%M:%S; curl -s localhost:18200/api/v1/alerts | jq -r '.data.alerts[] | [.labels.alertname, .state, .activeAt, .annotations.summary] | @tsv'
18:07:00
$ date -u +%H:%M:%S; curl -s localhost:18200/api/v1/alerts | jq -r '.data.alerts[] | [.labels.alertname, .state, .activeAt, .annotations.summary] | @tsv'
18:07:10
PodinfoDown	pending	2026-10-07T18:07:09.603638981Z	No healthy podinfo targets are being scraped
$ date -u +%H:%M:%S; curl -s localhost:18200/api/v1/alerts | jq -r '.data.alerts[] | [.labels.alertname, .state, .activeAt, .annotations.summary] | @tsv'
18:07:22
PodinfoDown	pending	2026-10-07T18:07:09.603638981Z	No healthy podinfo targets are being scraped
$ date -u +%H:%M:%S; curl -s localhost:18200/api/v1/alerts | jq -r '.data.alerts[] | [.labels.alertname, .state, .activeAt, .annotations.summary] | @tsv'
18:07:32
PodinfoDown	pending	2026-10-07T18:07:09.603638981Z	No healthy podinfo targets are being scraped
$ date -u +%H:%M:%S; curl -s localhost:18200/api/v1/alerts | jq -r '.data.alerts[] | [.labels.alertname, .state, .activeAt, .annotations.summary] | @tsv'
18:07:43
PodinfoDown	firing	2026-10-07T18:07:09.603638981Z	No healthy podinfo targets are being scraped
$ curl -s localhost:18200/api/v1/rules | jq -r '.data.groups[].rules[] | [.name, .state, .health, .query] | @tsv'
PodinfoDown	firing	ok	(count(up{job="podinfo"} == 1) or vector(0)) < 1
PodinfoHighCPU	inactive	ok	sum by (pod) (rate(container_cpu_usage_seconds_total{container="podinfo",namespace="p20-app"}[1m])) > 0.1
```

inactive → **pending** at 18:07:09 (first evaluation with no targets) → **firing** at 18:07:43,
after the 30s `for:` window. Then I scaled back and the alert cleared:

```text
$ date -u +%H:%M:%S; kubectl scale deploy/podinfo -n p20-app --replicas=2 && kubectl rollout status deploy/podinfo -n p20-app --timeout=240s
18:07:43
deployment.apps/podinfo scaled
Waiting for deployment "podinfo" rollout to finish: 0 out of 2 new replicas have been updated...
Waiting for deployment "podinfo" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "podinfo" rollout to finish: 1 of 2 updated replicas are available...
deployment "podinfo" successfully rolled out
$ date -u +%H:%M:%S; curl -s localhost:18200/api/v1/alerts | jq -r '.data.alerts[] | [.labels.alertname, .state, .activeAt, .annotations.summary] | @tsv'; echo '(alerts list end)'
18:08:12
(alerts list end)
$ curl -s localhost:18200/api/v1/query --data-urlencode 'query=up{job="podinfo"}' | jq -r '.data.result[] | "\(.metric.pod) up=\(.value[1])"'
podinfo-88d5c948c-c87tz up=1
podinfo-88d5c948c-4j5cz up=1
```

There is no Alertmanager here (to save memory), so the alert is not sent anywhere. In a real
setup Prometheus would push the firing alert to Alertmanager, which routes it to Slack/email/PagerDuty.

---

## Task 2 — Observability

**Monitoring** answers questions you already knew to ask ("is the app up? is CPU above 80%?").
**Observability** is being able to answer new questions about a system from the data it emits,
without shipping new code. Monitoring is one thing you do with an observable system.

### The three pillars

| Pillar | What it is | What I used above |
|---|---|---|
| **Metrics** | Numbers over time, cheap to store, good for dashboards and alerts | `http_requests_total`, `http_request_duration_seconds`, `container_cpu_usage_seconds_total`, `container_memory_working_set_bytes`, `up` |
| **Logs** | Timestamped events with detail about one thing that happened | podinfo JSON request logs, Prometheus start-up logs, probe failure events |
| **Traces** | The journey of one request across services, as a tree of timed spans | not run here (single service, no tracing backend) |

- **Metrics** told me *that* something was wrong (`up` went missing → alert firing) and *how much*
  (2.5 req/s, p95 79 ms, 25 MiB).
- **Logs** told me *what exactly* happened (which caller hit `/status/500`, and when).
- **Traces** would tell me *where* time is spent when one request goes through several services
  (frontend → API → DB). podinfo can export OpenTelemetry traces, but I did not install a trace
  backend (Jaeger/Tempo) on this small shared cluster, so I have no real trace output to show.

### Why observability is needed

- Microservices and Kubernetes are dynamic: pods move, restart and get new IPs (my pods changed
  names four times during this homework). You cannot SSH in and look around.
- Failures are often partial or slow, not "down". Latency percentiles and error rates catch them.
- Faster incident response (lower MTTD/MTTR): an alert says something is wrong, metrics narrow it
  down, logs/traces explain it. My probe failures are an example: events showed
  `context deadline exceeded`, which pointed at a slow, busy node, not a broken app.
- Capacity planning and right-sizing: the memory data showed ~25 MiB use against a 96 MiB limit.

### Common tools

| Area | Tools |
|---|---|
| Metrics | Prometheus (used here), Thanos / Mimir / VictoriaMetrics for long-term, Datadog, CloudWatch |
| Dashboards | Grafana |
| Alerting | Prometheus rules + Alertmanager (rules used here), PagerDuty, Opsgenie |
| Logs | Loki + Promtail/Alloy, EFK (Elasticsearch, Fluentd/Fluent Bit, Kibana), CloudWatch Logs |
| Traces | OpenTelemetry (instrumentation + collector), Jaeger, Grafana Tempo, Zipkin |
| All-in-one | Datadog, New Relic, Dynatrace, Elastic Observability |

### Kubernetes observability

Where the data comes from in Kubernetes, and what I used:

- **kubelet / cAdvisor**: per-container CPU and memory. I scraped it through
  `/api/v1/nodes/<node>/proxy/metrics/cadvisor`.
- **metrics-server**: short-term CPU/memory for `kubectl top` and HPA. It was crash-looping on this
  shared node during my run.
- **kube-state-metrics**: object state (desired vs ready replicas, pod phase). Not installed; it
  would have let me filter out deleted pods in the memory query.
- **Service discovery**: Prometheus asks the Kubernetes API for endpoints, so new podinfo pods were
  scraped automatically after every rollout and scale.
- **Probes**: liveness/readiness/startup are the cluster's built-in health checks; failures show
  up as `Unhealthy` / `Killing` events.
- **Logs**: containers write to stdout/stderr, the kubelet stores them, `kubectl logs` reads them.
  In production an agent (Fluent Bit/Promtail) ships them to Loki or Elasticsearch, because logs are
  gone when the pod is deleted.
- **Events**: `kubectl get events` is a short-lived log of what the control plane did.

---

## Task 3 — GitOps

### Concepts

- **GitOps**: the desired state of the cluster lives in Git, and an agent in the cluster keeps the
  real state equal to it. People change Git (pull request, review, merge), not the cluster.
- **Git as the source of truth**: Git has history, review, blame and revert. If it is not in Git it
  should not exist in the cluster.
- **Declarative configuration**: YAML says *what* I want (`replicas: 2`), not *how* to get there.
- **Continuous reconciliation**: the agent keeps comparing desired (Git) and actual (cluster)
  state and fixes drift. It is a loop, not a one-time `kubectl apply`.
- **Workflow**: edit YAML → commit → PR → merge → Argo CD detects the new commit → syncs → cluster
  matches Git. A manual `kubectl` change is drift, and with `selfHeal: true` it is reverted.
- **Kubernetes + GitOps**: Kubernetes is already a reconciliation system (a Deployment controller
  keeps N pods running). GitOps adds one more loop on top: Git → cluster objects.

### What I set up

- [03-gitops/app/](03-gitops/app/): `namespace.yaml`, `deployment.yaml` (`replicas: 2`, nginx),
  `service.yaml`, based on the session's `08-mini-project`. Pushed to my fork on branch
  `submission/piyush-session-20`.
- [03-gitops/argocd-application.yaml](03-gitops/argocd-application.yaml): the Application pointing at
  `https://github.com/PiyushhBansal/devops-heros.git`, that branch, path
  `session20-monitoring-observability-gitops/HW/03-gitops/app`, with `automated: {prune, selfHeal}`.
  It is outside `app/` so Argo CD does not manage its own Application.

Argo CD **core** install (no UI/API server/Dex, to save memory), v3.5.4. The manifest has
`namespace: argocd` hard-coded in one place only (the controller's ClusterRoleBinding subject), so I
changed that one line and installed into my own namespace `p20-argocd`:

```text
$ kubectl create namespace p20-argocd
namespace/p20-argocd created
$ kubectl apply -n p20-argocd --server-side -f argocd-core-p20.yaml | tail -8
deployment.apps/argocd-applicationset-controller serverside-applied
deployment.apps/argocd-redis serverside-applied
deployment.apps/argocd-repo-server serverside-applied
statefulset.apps/argocd-application-controller serverside-applied
networkpolicy.networking.k8s.io/argocd-application-controller-network-policy serverside-applied
networkpolicy.networking.k8s.io/argocd-applicationset-controller-network-policy serverside-applied
networkpolicy.networking.k8s.io/argocd-redis-network-policy serverside-applied
networkpolicy.networking.k8s.io/argocd-repo-server-network-policy serverside-applied
$ kubectl get pods -n p20-argocd
NAME                                 READY   STATUS    RESTARTS   AGE
argocd-application-controller-0      1/1     Running   0          5m55s
argocd-redis-55d565584d-dtrlz        1/1     Running   0          6m6s
argocd-repo-server-6995847c8-qfwmv   1/1     Running   0          6m1s
```

(`argocd-core-p20.yaml` is `core-install.yaml` from the v3.5.4 tag with that one-line change. I
scaled the ApplicationSet controller to 0 since I do not use ApplicationSets.)

### Not completed

I ran out of time before applying the Application, so I have **no real output** for:

- the initial sync (`Synced` / `Healthy`, 2 pods in `p20-gitops`),
- pushing `replicas: 2 → 3` and watching Argo CD reconcile it,
- self-heal (`kubectl scale --replicas=1` being reverted to the Git value).

A lot of time went into the shared cluster being overloaded (scheduler and controller-manager
restarting, metrics-server crash-looping), which delayed every rollout. The manifests are ready;
the next steps would be:

```bash
kubectl apply -f 03-gitops/argocd-application.yaml
kubectl get application session20-mini -n p20-argocd
# edit app/deployment.yaml replicas: 3, commit, push, then
kubectl get deploy session20-mini -n p20-gitops -w
kubectl scale deploy session20-mini -n p20-gitops --replicas=1   # selfHeal should put it back to 3
```

---

## Cleanup

```bash
kubectl delete ns p20-app p20-monitoring p20-argocd
kubectl delete clusterrole p20-prometheus argocd-application-controller
kubectl delete clusterrolebinding p20-prometheus argocd-application-controller
kubectl delete crd applications.argoproj.io applicationsets.argoproj.io appprojects.argoproj.io
```

## What I learned

- An alert on `up == 0` does not fire when there are zero pods, because there is no series at all.
  `or vector(0)` fixes that.
- Probes are part of the app's health, but tight timeouts plus a CPU limit on a busy node turn a
  healthy app into a crash loop. A `startupProbe` is the right tool for slow starts.
- Metrics tell you something is wrong, logs tell you what happened; the two together found my
  probe problem in a minute.
- Argo CD core needs only three pods; the `argocd` namespace is hard-coded in one ClusterRoleBinding.
