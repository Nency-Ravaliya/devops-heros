# Session 20 - Monitoring, Observability & GitOps

**Student:** Ujjawal Prabhat (24BCS10267)

| Task | Where |
|---|---|
| T1 Monitoring demo: metrics, logs, alerts, CPU, memory, application health | [Task 1](#task-1---monitoring-demo), `monitoring/` |
| T2 Observability documentation | [Task 2](#task-2---observability) |
| T3 GitOps demo (08-mini-project with Argo CD) | [Task 3](#task-3---gitops), `gitops/` |

```text
monitoring/
  01-app.yaml                 Namespace session20-monitoring + podinfo Deployment (probes, limits) + Service
  02-servicemonitor.yaml      tells Prometheus to scrape podinfo /metrics
  03-prometheusrule.yaml      PodinfoDown, PodinfoPodNotReady, PodinfoHighCPU
  04-grafana-dashboard.yaml   dashboard as a ConfigMap (CPU %, memory %, requests, ready pods)
gitops/
  argocd-application.yaml     Argo CD Application session20-mini (applied once, outside app/)
  app/                        the path Argo CD watches
    namespace.yaml            session20
    deployment.yaml           session20-mini, replicas: 2
    service.yaml              session20-mini
```

## Environment

Local kind cluster (`kind-devops-heros`, 3 nodes). kube-prometheus-stack (Prometheus, Alertmanager, Grafana, kube-state-metrics, node-exporter) and Argo CD were installed once with:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install kps prometheus-community/kube-prometheus-stack -n monitoring --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false

kubectl create namespace argocd
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

The `*NilUsesHelmValues=false` flags make Prometheus pick up ServiceMonitors, PodMonitors and PrometheusRules from every namespace, not only ones labelled `release: kps`. The Grafana admin password is not written here; it is read from the `kps-grafana` secret (see 1.6).

```text
$ helm list -n monitoring
NAME	NAMESPACE 	REVISION	UPDATED                              	STATUS  	CHART                       	APP VERSION
kps 	monitoring	1       	2026-10-06 18:55:34.240507 +0800 WITA	deployed	kube-prometheus-stack-91.9.0	v0.94.1    

$ kubectl -n monitoring get pods
NAME                                                    READY   STATUS    RESTARTS       AGE
alertmanager-kps-kube-prometheus-stack-alertmanager-0   2/2     Running   4 (163m ago)   13d
kps-grafana-5d65bffb7f-9vvcg                            3/3     Running   6 (163m ago)   13d
kps-kube-prometheus-stack-operator-57cbd8fcdd-qhwph     1/1     Running   5 (163m ago)   13d
kps-kube-state-metrics-747b7b996-g92xn                  1/1     Running   4 (163m ago)   13d
kps-prometheus-node-exporter-8sqwk                      1/1     Running   2 (163m ago)   13d
kps-prometheus-node-exporter-bq45s                      1/1     Running   2 (163m ago)   13d
kps-prometheus-node-exporter-qlkcq                      1/1     Running   2 (163m ago)   13d
prometheus-kps-kube-prometheus-stack-prometheus-0       2/2     Running   4 (163m ago)   13d

$ kubectl -n argocd get pods
NAME                                                READY   STATUS    RESTARTS       AGE
argocd-application-controller-0                     1/1     Running   2 (163m ago)   13d
argocd-applicationset-controller-7fb7c76f76-p978b   1/1     Running   2 (163m ago)   13d
argocd-dex-server-7d54f7f9d6-cpjd4                  1/1     Running   2 (163m ago)   13d
argocd-notifications-controller-7fcfd67447-h798k    1/1     Running   2 (163m ago)   13d
argocd-redis-6bf744486c-lwzb8                       1/1     Running   2 (163m ago)   13d
argocd-repo-server-57b98df6c6-kww8s                 1/1     Running   2 (163m ago)   13d
argocd-server-665b8b6947-t7jx5                      1/1     Running   3 (163m ago)   13d
```

---

# Task 1 - Monitoring demo

The app is [podinfo](https://github.com/stefanprodan/podinfo): it exposes Prometheus metrics on `/metrics`, health on `/healthz` (liveness) and `/readyz` (readiness), and with `--level=debug` logs every request as JSON.

## 1.1 Deploy

```text
$ kubectl apply -f monitoring/
namespace/session20-monitoring created
deployment.apps/podinfo created
service/podinfo created
servicemonitor.monitoring.coreos.com/podinfo created
prometheusrule.monitoring.coreos.com/podinfo-alerts created
configmap/podinfo-dashboard created

$ kubectl -n session20-monitoring rollout status deploy/podinfo --timeout=180s
Waiting for deployment "podinfo" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "podinfo" rollout to finish: 1 of 2 updated replicas are available...
deployment "podinfo" successfully rolled out

$ kubectl -n session20-monitoring get deploy,pods,svc,servicemonitor,prometheusrule,configmap
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/podinfo   2/2     2            2           1s

NAME                           READY   STATUS    RESTARTS   AGE
pod/podinfo-5b6fcb4755-sbp6s   1/1     Running   0          1s
pod/podinfo-5b6fcb4755-wbrrl   1/1     Running   0          1s

NAME              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/podinfo   ClusterIP   10.96.221.91   <none>        9898/TCP   1s

NAME                                           AGE
servicemonitor.monitoring.coreos.com/podinfo   1s

NAME                                                  AGE
prometheusrule.monitoring.coreos.com/podinfo-alerts   1s

NAME                          DATA   AGE
configmap/kube-root-ca.crt    1      1s
configmap/podinfo-dashboard   1      1s
```

Port-forwards used below (each in its own terminal):

```bash
kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 19090:9090
kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-alertmanager 19093:9093
kubectl -n monitoring port-forward svc/kps-grafana 13000:80
kubectl -n session20-monitoring port-forward svc/podinfo 19898:9898
```

## 1.2 Metrics exposed by the app

Some traffic, including errors (`/status/500` returns HTTP 500 on purpose):

```text
$ curl -s localhost:19090/-/ready
Prometheus Server is Ready.

$ for i in $(seq 60); do curl -s -o /dev/null localhost:19898/; done; for i in $(seq 20); do curl -s -o /dev/null localhost:19898/status/500; done

$ curl -s localhost:19898/metrics | grep -E '^http_requests_total'
http_requests_total{status="200"} 105
http_requests_total{status="500"} 20
```

(The port-forward sends all traffic to one pod; the 200 count also includes the kubelet probes.)

## 1.3 Logs

Containers log to stdout; `kubectl logs` reads them from the node.

```text
$ kubectl -n session20-monitoring logs deploy/podinfo --tail=4
Found 2 pods, using pod/podinfo-5b6fcb4755-sbp6s
{"level":"debug","ts":"2026-10-20T07:45:09.881Z","caller":"http/logging.go:21","msg":"request started","proto":"HTTP/1.1","uri":"/readyz","method":"GET","remote":"10.244.2.1:42876","user-agent":"kube-probe/1.37"}
{"level":"debug","ts":"2026-10-20T07:45:13.620Z","caller":"http/logging.go:21","msg":"request started","proto":"HTTP/1.1","uri":"/healthz","method":"GET","remote":"10.244.2.1:42884","user-agent":"kube-probe/1.37"}
{"level":"debug","ts":"2026-10-20T07:45:14.647Z","caller":"http/logging.go:21","msg":"request started","proto":"HTTP/1.1","uri":"/metrics","method":"GET","remote":"10.244.2.13:33944","user-agent":"Prometheus/3.15.0"}
{"level":"debug","ts":"2026-10-20T07:45:14.721Z","caller":"http/logging.go:21","msg":"request started","proto":"HTTP/1.1","uri":"/readyz","method":"GET","remote":"10.244.2.1:42892","user-agent":"kube-probe/1.37"}

$ kubectl -n session20-monitoring logs -l app=podinfo --prefix --tail=-1 | grep -E 'Starting HTTP|/status/500' | head -4
[pod/podinfo-5b6fcb4755-sbp6s/podinfo] {"level":"info","ts":"2026-10-20T07:43:03.831Z","caller":"http/server.go:224","msg":"Starting HTTP Server.","addr":":9898"}
[pod/podinfo-5b6fcb4755-sbp6s/podinfo] {"level":"debug","ts":"2026-10-20T07:45:08.563Z","caller":"http/logging.go:21","msg":"request started","proto":"HTTP/1.1","uri":"/status/500","method":"GET","remote":"127.0.0.1:52734","user-agent":"curl/8.7.1"}
[pod/podinfo-5b6fcb4755-sbp6s/podinfo] {"level":"debug","ts":"2026-10-20T07:45:08.576Z","caller":"http/logging.go:21","msg":"request started","proto":"HTTP/1.1","uri":"/status/500","method":"GET","remote":"127.0.0.1:52738","user-agent":"curl/8.7.1"}
[pod/podinfo-5b6fcb4755-sbp6s/podinfo] {"level":"debug","ts":"2026-10-20T07:45:08.582Z","caller":"http/logging.go:21","msg":"request started","proto":"HTTP/1.1","uri":"/status/500","method":"GET","remote":"127.0.0.1:52748","user-agent":"curl/8.7.1"}

$ kubectl -n session20-monitoring logs -l app=podinfo --tail=-1 | grep -c '/status/500'
20
```

The log lines show the kubelet probes (`kube-probe`), Prometheus scraping `/metrics`, and the 20 error requests sent above. Logs say *what happened* to each request; metrics only count them.

## 1.4 Metrics in Prometheus: CPU, memory, requests, health

A second batch of traffic (spread over 30 s so the 500 counter rises between scrapes), then the queries. `q` is a small shell helper that runs a PromQL query through the HTTP API and keeps only the `pod`/`status` labels and the value:

```bash
q() { curl -s localhost:19090/api/v1/query --data-urlencode "query=$1" | jq -c '.data.result[] | {pod: .metric.pod, status: .metric.status, value: .value[1]} | del(.[] | nulls)'; }
```

```text
$ for i in $(seq 30); do curl -s -o /dev/null localhost:19898/; curl -s -o /dev/null localhost:19898/status/500; sleep 1; done

$ curl -s 'localhost:19090/api/v1/targets?state=active' | jq -r '.data.activeTargets[] | select(.labels.namespace=="session20-monitoring") | [.labels.pod, .scrapeUrl, .health] | @tsv'
podinfo-5b6fcb4755-wbrrl	http://10.244.1.51:9898/metrics	up
podinfo-5b6fcb4755-sbp6s	http://10.244.2.32:9898/metrics	up

$ q 'up{namespace="session20-monitoring"}'
{"pod":"podinfo-5b6fcb4755-sbp6s","value":"1"}
{"pod":"podinfo-5b6fcb4755-wbrrl","value":"1"}

$ q 'sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="session20-monitoring", container="podinfo"}[5m]))'
{"pod":"podinfo-5b6fcb4755-sbp6s","value":"0.010446608409420433"}
{"pod":"podinfo-5b6fcb4755-wbrrl","value":"0.007334703509130047"}

$ q 'sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="session20-monitoring", container="podinfo"}[5m])) / sum by (pod) (kube_pod_container_resource_limits{namespace="session20-monitoring", container="podinfo", resource="cpu"})'
{"pod":"podinfo-5b6fcb4755-sbp6s","value":"0.05223304204710216"}
{"pod":"podinfo-5b6fcb4755-wbrrl","value":"0.036671233753340256"}

$ q 'sum by (pod) (container_memory_working_set_bytes{namespace="session20-monitoring", container="podinfo"})'
{"pod":"podinfo-5b6fcb4755-sbp6s","value":"25649152"}
{"pod":"podinfo-5b6fcb4755-wbrrl","value":"21667840"}

$ q 'sum by (pod) (container_memory_working_set_bytes{namespace="session20-monitoring", container="podinfo"}) / sum by (pod) (kube_pod_container_resource_limits{namespace="session20-monitoring", container="podinfo", resource="memory"})'
{"pod":"podinfo-5b6fcb4755-sbp6s","value":"0.19110107421875"}
{"pod":"podinfo-5b6fcb4755-wbrrl","value":"0.16143798828125"}

$ q 'sum by (status) (rate(http_request_duration_seconds_count{namespace="session20-monitoring"}[5m]))'
{"status":"200","value":"0.8350860695656531"}
{"status":"500","value":"0.10526278855161912"}

$ q 'kube_pod_status_ready{namespace="session20-monitoring", condition="true"}'
{"pod":"podinfo-5b6fcb4755-wbrrl","value":"1"}
{"pod":"podinfo-5b6fcb4755-sbp6s","value":"1"}
```

| Signal | Query | Reading |
|---|---|---|
| Scrape health | `up` | both targets found by the ServiceMonitor, `1` = up |
| CPU usage | `rate(container_cpu_usage_seconds_total[5m])` | cores, e.g. 0.0104 = 10.4 millicores |
| CPU utilization | usage / `kube_pod_container_resource_limits{resource="cpu"}` | about 5% and 4% of the 200m limit |
| Memory usage | `container_memory_working_set_bytes` | about 24 MiB and 21 MiB |
| Memory utilization | working set / memory limit | about 19% and 16% of 128Mi |
| Requests | `rate(http_request_duration_seconds_count[5m])` by status | 200s and 500s per second |
| Application health | `kube_pod_status_ready` (kube-state-metrics, from the readiness probe) | `1` = ready |

## 1.5 Alerts

[`monitoring/03-prometheusrule.yaml`](monitoring/03-prometheusrule.yaml) defines three rules. Prometheus loaded them; then **Demo A - application health: readiness fails, `PodinfoPodNotReady` fires.** `POST /readyz/disable` (through the port-forward, so it reached pod `sbp6s`) makes podinfo's readiness endpoint return 503:

```text
$ curl -s localhost:19090/api/v1/rules | jq -c '.data.groups[] | select(.name=="podinfo.rules") | .rules[] | {alert: .name, health, state}'
{"alert":"PodinfoDown","health":"ok","state":"inactive"}
{"alert":"PodinfoPodNotReady","health":"ok","state":"inactive"}
{"alert":"PodinfoHighCPU","health":"ok","state":"inactive"}

$ date -u +%T; curl -s -X POST localhost:19898/readyz/disable -w "%{http_code}\n"; sleep 20; kubectl -n session20-monitoring get pods
07:52:57
202
NAME                       READY   STATUS    RESTARTS   AGE
podinfo-5b6fcb4755-sbp6s   0/1     Running   0          10m
podinfo-5b6fcb4755-wbrrl   1/1     Running   0          10m

$ kubectl -n session20-monitoring get events --field-selector reason=Unhealthy
LAST SEEN   TYPE      REASON      OBJECT                         MESSAGE
10m         Warning   Unhealthy   pod/podinfo-5b6fcb4755-sbp6s   Readiness probe failed: Get "http://10.244.2.32:9898/readyz": dial tcp 10.244.2.32:9898: connect: connection refused
5m2s        Warning   Unhealthy   pod/podinfo-5b6fcb4755-sbp6s   Liveness probe failed: Get "http://10.244.2.32:9898/healthz": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
4m56s       Warning   Unhealthy   pod/podinfo-5b6fcb4755-sbp6s   Readiness probe failed: Get "http://10.244.2.32:9898/readyz": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
3s          Warning   Unhealthy   pod/podinfo-5b6fcb4755-sbp6s   Readiness probe failed: HTTP probe failed with statuscode: 503
10m         Warning   Unhealthy   pod/podinfo-5b6fcb4755-wbrrl   Readiness probe failed: Get "http://10.244.1.51:9898/readyz": dial tcp 10.244.1.51:9898: connect: connection refused
3m41s       Warning   Unhealthy   pod/podinfo-5b6fcb4755-wbrrl   Readiness probe failed: Get "http://10.244.1.51:9898/readyz": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
5m1s        Warning   Unhealthy   pod/podinfo-5b6fcb4755-wbrrl   Liveness probe failed: Get "http://10.244.1.51:9898/healthz": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
```

The pod stays `Running` (liveness still passes) but is `0/1` and removed from the Service. The older events in that list are real too: right after start-up the probes got `connection refused` (no `initialDelaySeconds`), and around 07:48 a few probes timed out (1 s default timeout) while the cluster was busy. They were single failures and never lasted the 30 s the alert needs.

The alert became active (pending) at 07:53:54, fired after its `for: 30s`, and reached Alertmanager:

```text
$ q 'kube_pod_status_ready{namespace="session20-monitoring", condition="false"}'
{"pod":"podinfo-5b6fcb4755-wbrrl","value":"0"}
{"pod":"podinfo-5b6fcb4755-sbp6s","value":"1"}

$ curl -s localhost:19090/api/v1/alerts | jq -c '.data.alerts[] | select(.labels.alertname | startswith("Podinfo")) | {alertname: .labels.alertname, pod: .labels.pod, severity: .labels.severity, state, activeAt}'
{"alertname":"PodinfoPodNotReady","pod":"podinfo-5b6fcb4755-sbp6s","severity":"warning","state":"firing","activeAt":"2026-10-20T07:53:54.084771994Z"}

$ curl -s 'localhost:19093/api/v2/alerts?filter=alertname=~"Podinfo.*"' | jq -c '.[] | {alertname: .labels.alertname, state: .status.state, startsAt, summary: .annotations.summary}'
{"alertname":"PodinfoPodNotReady","state":"active","startsAt":"2026-10-20T07:54:24.084Z","summary":"Pod podinfo-5b6fcb4755-sbp6s is not ready (readiness probe failing)"}
```

Recovery, then **Demo B - app down: scaled to 0, `PodinfoDown` fires:**

```text
$ curl -s -X POST localhost:19898/readyz/enable -w "%{http_code}\n"; kubectl -n session20-monitoring wait --for=condition=Ready pod -l app=podinfo --timeout=90s
202
pod/podinfo-5b6fcb4755-sbp6s condition met
pod/podinfo-5b6fcb4755-wbrrl condition met

$ date -u +%T; kubectl -n session20-monitoring scale deploy/podinfo --replicas=0
07:57:07
deployment.apps/podinfo scaled

$ date -u +%T; kubectl -n session20-monitoring get deploy podinfo
07:59:04
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
podinfo   0/0     0            0           16m

$ curl -s localhost:19090/api/v1/alerts | jq -c '.data.alerts[] | select(.labels.alertname | startswith("Podinfo")) | {alertname: .labels.alertname, severity: .labels.severity, state, activeAt, value}'
{"alertname":"PodinfoDown","severity":"critical","state":"firing","activeAt":"2026-10-20T07:57:54.084771994Z","value":"0e+00"}

$ curl -s 'localhost:19093/api/v2/alerts?filter=alertname=~"Podinfo.*"' | jq -c '.[] | {alertname: .labels.alertname, state: .status.state, startsAt, summary: .annotations.summary, receivers: [.receivers[].name]}'
{"alertname":"PodinfoDown","state":"active","startsAt":"2026-10-20T07:58:24.084Z","summary":"podinfo has no healthy scrape target","receivers":["null"]}
```

The receiver is `null` because the chart's default Alertmanager config does not send notifications anywhere; a real setup would add a Slack or email receiver. Recovery:

```text
$ kubectl -n session20-monitoring scale deploy/podinfo --replicas=2; kubectl -n session20-monitoring rollout status deploy/podinfo --timeout=120s
deployment.apps/podinfo scaled
Waiting for deployment "podinfo" rollout to finish: 0 out of 2 new replicas have been updated...
Waiting for deployment "podinfo" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "podinfo" rollout to finish: 1 of 2 updated replicas are available...
deployment "podinfo" successfully rolled out

$ date -u +%T; curl -s localhost:19090/api/v1/alerts | jq -c '[.data.alerts[] | select(.labels.alertname | startswith("Podinfo"))] | length'
08:09:26
0
```

`PodinfoHighCPU` (usage above 80% of the CPU limit for 1 minute) was loaded but **not** made to fire: the app uses about 5% of its limit and no CPU stress test was run.

## 1.6 Grafana

The dashboard in `monitoring/04-grafana-dashboard.yaml` is loaded by the Grafana sidecar (it watches ConfigMaps labelled `grafana_dashboard: "1"`). The admin password is read from the chart's secret into a variable and never printed:

```bash
GF_PASS=$(kubectl -n monitoring get secret kps-grafana -o jsonpath='{.data.admin-password}' | base64 -d)
```

```text
$ curl -s localhost:13000/api/health | jq -c .
{"database":"ok","version":"13.2.3","commit":"90ffed056f0884267356c12a0eeb72a022af53f1"}

$ curl -s -u admin:$GF_PASS 'localhost:13000/api/search?query=Session%2020' | jq -c '.[] | {uid, title, url}'
{"uid":"session20-podinfo","title":"Session 20 - podinfo","url":"/d/session20-podinfo/session-20-podinfo"}

$ curl -s -u admin:$GF_PASS localhost:13000/api/dashboards/uid/session20-podinfo | jq -c '{panels: [.dashboard.panels[].title], provisioned: .meta.provisioned}'
{"panels":["CPU utilization (% of limit)","Memory utilization (% of limit)","HTTP requests/s by status","Ready pods"],"provisioned":true}
```

UI: `http://localhost:13000/d/session20-podinfo` (user `admin`, password from the command above).

---

# Task 2 - Observability

**Monitoring** answers "is something wrong?" using signals chosen in advance (dashboards, threshold alerts like `PodinfoDown`). **Observability** answers "why is it wrong?": the system emits enough data that you can investigate failures nobody predicted. Monitoring is the automated part of observability; production systems use both.

## The three pillars

| Pillar | What it is | Answers | In this lab |
|---|---|---|---|
| **Metrics** | Numbers sampled over time, with labels (counters, gauges, histograms). Cheap to store and aggregate, good for alerts and trends | How much? How often? How fast? | `container_cpu_usage_seconds_total`, `container_memory_working_set_bytes`, `http_requests_total`, `kube_pod_status_ready` |
| **Logs** | Timestamped records of individual events, ideally structured (JSON) | What exactly happened? | podinfo's JSON request log (`"uri":"/status/500"`) |
| **Traces** | The path of one request through several services, as a tree of timed spans sharing a trace ID | Where did the time go? Which service failed? | Not demonstrated (single service, no tracing backend) |

They are most useful together: an alert from a metric points to a pod and a time, the logs of that pod show the failing requests, and a trace ID in a log line shows which downstream call was slow.

## Why observability is required

- Modern systems are distributed: one user request crosses many services, so "the API returned 500" is not enough to find the cause.
- Detect problems before users report them, and shorten the time to find and fix them (MTTD / MTTR).
- Measure SLOs ("99.9% of requests under 300 ms") and plan capacity from real CPU/memory usage.
- Containers are short-lived: if logs and metrics are not collected centrally they disappear with the pod.
- Safe releases: you can only tell whether a deploy made things worse if you measure before and after.

## Common tools

| Area | Tools |
|---|---|
| Metrics | Prometheus (+ Alertmanager), Thanos / Mimir for long-term storage |
| Dashboards | Grafana |
| Logs | Loki, ELK/EFK (Elasticsearch + Logstash/Fluentd/Fluent Bit + Kibana) |
| Traces | Jaeger, Grafana Tempo, Zipkin |
| Instrumentation standard | OpenTelemetry (SDKs + Collector for metrics, logs and traces) |
| Managed / SaaS | Datadog, New Relic, AWS CloudWatch + X-Ray, Google Cloud Operations, Azure Monitor |

## Kubernetes observability

- **Service discovery instead of static targets.** Pod IPs change, so the Prometheus Operator uses ServiceMonitors. In Demo B the new pods were scraped automatically after scaling back up.
- **Signals at every layer:** node-exporter (node CPU, disk, network), cAdvisor in the kubelet (container CPU/memory), kube-state-metrics (object state: pod ready, deployment replicas), control-plane metrics (API server, scheduler, etcd), and the application's own `/metrics`.
- **Built-in health:** liveness and readiness probes; their result becomes `kube_pod_status_ready` and `Unhealthy` events (`kubectl get events`).
- **Logs** go to stdout/stderr and are read with `kubectl logs`; a DaemonSet agent (Fluent Bit, Promtail/Alloy) ships them to Loki or Elasticsearch so they survive pod deletion.
- **Everything as code:** ServiceMonitor, PrometheusRule and dashboard ConfigMaps are Kubernetes objects, so they can live in Git and be deployed with GitOps like the app.
- **Labels connect the signals:** `namespace`, `pod` and `container` are the same in metrics and logs, which is what lets you jump from an alert to the right logs.

---

# Task 3 - GitOps

## Concepts

- **What is GitOps:** running applications and infrastructure by declaring the desired state in Git and letting an agent in the cluster (Argo CD, Flux) pull that state and apply it continuously. People change Git, not the cluster.
- **Git as the source of truth:** what is committed is the only accepted definition of what should run. Every change is a commit with an author, a diff and history, can be reviewed in a pull request, and can be undone with `git revert`. Anything in the cluster that differs from Git is drift.
- **Declarative configuration:** you describe the end result (`replicas: 3`, `image: nginx:1.27-alpine`), not the steps (`kubectl scale ...`). Applying the same file twice changes nothing, and the controller works out how to get there.
- **Continuous reconciliation:** the agent repeatedly compares desired state (Git) with actual state (cluster) and fixes the difference. Argo CD polls Git (default about every 3 minutes, or on a webhook) and watches the live objects; with `selfHeal: true` it also reverts manual changes made in the cluster.
- **Kubernetes + GitOps:** Kubernetes is already declarative and controller-based (a Deployment controller keeps the pod count equal to `spec.replicas`). GitOps adds one more loop on top, whose input is a Git commit. Argo CD itself is configured with a Kubernetes object (`Application`).

## Workflow

```text
Developer --edit YAML, commit, push--> Git (GitHub fork, branch 24BCS10267/session-20)
                                           |
                                    poll / webhook
                                           v
                                        Argo CD  <-- watches live objects
                                  compare desired vs actual
                                           |
                                     sync (apply, prune)
                                           v
                              Kubernetes namespace session20
                                           ^
                kubectl scale (drift) -----+  --> self-heal reverts it to Git
```

## Mini-project setup

[`gitops/app/`](gitops/app/) holds the Namespace, Deployment (`replicas: 2`) and Service from `08-mini-project`, with the same names (`session20`, `session20-mini`). [`gitops/argocd-application.yaml`](gitops/argocd-application.yaml) is kept outside that path and points Argo CD at this fork and branch:

```yaml
  source:
    repoURL: https://github.com/UjjawalPrabhat/devops-heros.git
    targetRevision: 24BCS10267/session-20
    path: session20-monitoring-observability-gitops/24BCS10267-ujjawal-prabhat/gitops/app
  destination:
    namespace: session20
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions: [ CreateNamespace=true ]
```

## Demo

> **(pending: push - Argo syncs from GitHub)** Argo CD reads these manifests from GitHub, so the demo can only run after this branch is pushed. The commands are below; their outputs will be added after the run.

Step 5 - create the Application and check the first sync (expected: `Synced`, `Healthy`, 2 pods):

```bash
kubectl apply -f gitops/argocd-application.yaml
kubectl get applications -n argocd
kubectl get all -n session20
```

Step 7 - change the desired state in Git only (`replicas: 2` to `replicas: 3` in `gitops/app/deployment.yaml`):

```bash
git add gitops/app/deployment.yaml
git commit -m "Scale application to three replicas"
git push origin 24BCS10267/session-20
kubectl get deployment session20-mini -n session20 -w
kubectl -n argocd get application session20-mini -o jsonpath='{.status.sync.revision}{"\n"}'
```

Step 8 - self-heal: change the cluster by hand and watch Argo CD revert it:

```bash
kubectl scale deployment session20-mini -n session20 --replicas=1
kubectl get deployment session20-mini -n session20
kubectl -n argocd get events --field-selector involvedObject.name=session20-mini --sort-by=.lastTimestamp | tail -6
```

Step 9 - observe:

```bash
kubectl logs deployment/session20-mini -n session20 --tail=5
kubectl get pods -n session20
kubectl get application session20-mini -n argocd
```

---

# Viva answers (08-mini-project)

1. **Monitoring vs observability:** monitoring watches known signals and alerts ("is it broken?"); observability lets you explain unexpected behaviour from the data the system emits ("why is it broken?").
2. **Metrics vs logs vs traces:** numbers over time / individual events / the journey of one request across services.
3. **Prometheus:** a metrics database that scrapes `/metrics` endpoints, stores labelled time series, is queried with PromQL and evaluates alert rules.
4. **Grafana:** a dashboard tool that visualises data from sources such as Prometheus; it stores no metrics itself.
5. **GitOps:** managing deployments by declaring the desired state in Git and letting an agent reconcile the cluster to it.
6. **Git as source of truth:** Git holds the only accepted desired state, with history, review, diffs and rollback.
7. **Argo CD:** a Kubernetes controller that watches a Git repo, compares it with the cluster, shows Synced/OutOfSync and Healthy/Degraded, and syncs.
8. **Desired state:** what Git says should run (e.g. `replicas: 3`).
9. **Actual state:** what is running in the cluster right now.
10. **Reconciliation:** the compare-and-fix loop that moves the actual state to the desired state.
11. **Self-healing:** with `selfHeal: true`, Argo CD reverts manual cluster changes that differ from Git.
12. **Replicas 2 to 3 in Git:** after the push Argo CD sees a new revision, marks the app OutOfSync, applies the Deployment, a third pod starts, and the app is Synced/Healthy again.

---

## Cleanup

kube-prometheus-stack and Argo CD stay installed (they are shared with the Session 21 project). This session only:

```bash
kubectl delete -f monitoring/
kubectl delete -f gitops/argocd-application.yaml
kubectl delete namespace session20
```
