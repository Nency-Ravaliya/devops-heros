# Session 20 - Monitoring, Observability & GitOps

This folder contains the lesson notes (`01`-`08`) and the hands-on assignment work (`09`-`12`).
Every demo in `09`-`12` was **actually run** on a MacBook (Apple Silicon, Docker Desktop + minikube).
Every screenshot is a capture of that real terminal output.

| Task | Deliverable | Folder |
|---|---|---|
| Task 1 - Monitoring | Monitoring demo (Prometheus, Alertmanager, Grafana) | [09-monitoring-stack](09-monitoring-stack/README.md) |
| Task 1 - Monitoring | Monitoring demo on Kubernetes (metrics-server, probes, events, HPA) | [11-k8s-monitoring](11-k8s-monitoring/README.md) |
| Task 2 - Observability | Observability documentation + traces demo (OpenTelemetry + Jaeger) | [10-observability](10-observability/README.md) |
| Task 3 - GitOps | GitOps demo with Argo CD | [12-gitops-argocd-demo](12-gitops-argocd-demo/README.md) |
| All | Screenshots | `screenshots/` inside each folder above |
| All | README.md | this file + one per folder |

---

## Folder map

```text
session20-monitoring-observability-gitops/
├── 01-monitoring-vs-observability/   lesson notes
├── 02-metrics-logs-traces/           lesson notes + busybox log demo
├── 03-prometheus/                    lesson notes + compose
├── 04-grafana/                       lesson notes + compose
├── 05-introduction-to-gitops/        lesson notes
├── 06-git-as-source-of-truth/        lesson notes
├── 07-argocd/                        lesson notes (Argo CD walkthrough)
├── 08-mini-project/                  lesson mini project brief
│
├── 09-monitoring-stack/              TASK 1  docker-compose: app + Prometheus + Alertmanager + Grafana
├── 10-observability/                 TASK 2  observability docs + tracing-demo/ (Jaeger)
├── 11-k8s-monitoring/                TASK 1  Kubernetes monitoring on minikube
└── 12-gitops-argocd-demo/            TASK 3  Argo CD GitOps demo on minikube
```

## Environment used

| Item | Version / value |
|---|---|
| Host | macOS, Apple Silicon (arm64) |
| Container runtime | Docker Desktop 29.x (about 3.9 GB of VM memory) |
| Kubernetes | minikube profile `session20`, 1 node, Kubernetes v1.37, docker driver |
| Monitoring | Prometheus v3, Alertmanager, node-exporter, Grafana 12 |
| Tracing | OpenTelemetry Python SDK, Jaeger all-in-one |
| GitOps | Argo CD (stable manifests), plus a local `git daemon` as the Git server |

Nothing else had to be installed. The `argocd` CLI was **not** used; everything goes through `kubectl`.

---

# Task 1 - Monitoring

> Monitoring = collecting known signals and alerting when they cross a threshold.
> It answers "**is** something wrong?".

Monitoring was demonstrated twice: once with a classic Prometheus stack, and once natively on Kubernetes.

### A) Prometheus stack - [09-monitoring-stack](09-monitoring-stack/README.md)

A small Python app exposes `/metrics`, `/health` and JSON logs.
Prometheus scrapes it, plus node-exporter for host CPU/memory.
Seven alert rules feed Alertmanager, which forwards to a webhook receiver.
Grafana gets a provisioned datasource and dashboard.

| Requirement | How it is shown | Screenshot |
|---|---|---|
| Metrics | raw `/metrics`, request rate, error ratio and p95 latency via PromQL | `09-04`, `09-05` |
| Logs | structured JSON logs, filtered by level and status | `09-08` |
| Alerts | HighErrorRate, HighCPUUsage, HighMemoryUsage, DemoAppDown go pending → firing → resolved, with the webhook notification | `09-10` … `09-14` |
| CPU utilization | process CPU and host CPU % by mode | `09-06`, `09-07` |
| Memory utilization | process RSS and host memory % | `09-06`, `09-12` |
| Application health | `/health`, Docker HEALTHCHECK, `up` metric, DemoAppDown alert | `09-02`, `09-13` |

![Prometheus targets](09-monitoring-stack/screenshots/09-03-prometheus-targets.png)
![CPU and memory via PromQL](09-monitoring-stack/screenshots/09-06-cpu-memory-promql.png)
![App down alert firing](09-monitoring-stack/screenshots/09-13-alert-app-down.png)

### B) Kubernetes - [11-k8s-monitoring](11-k8s-monitoring/README.md)

| Requirement | How it is shown | Screenshot |
|---|---|---|
| Metrics | metrics-server, `kubectl top nodes/pods`, requests/limits vs usage | `11-02`, `11-03` |
| Logs | `kubectl logs --tail / -l / --prefix / --previous` | `11-04`, `11-06` |
| Alerts | Warning events, plus `scripts/check-alerts.sh` firing on the CPU threshold, plus the HPA reacting to CPU | `11-09`, `11-10`, `11-11` |
| CPU / Memory utilization | `kubectl top` with a cpu-burner pod over its threshold | `11-02`, `11-10` |
| Application health | liveness probe broken → restart; readiness probe broken → endpoint removed → recovery | `11-05` … `11-08` |

![kubectl top](11-k8s-monitoring/screenshots/11-02-top-nodes-pods.png)
![Liveness probe failure](11-k8s-monitoring/screenshots/11-05-break-liveness.png)
![CPU alert script](11-k8s-monitoring/screenshots/11-10-check-alerts.png)

---

# Task 2 - Observability

> Observability = being able to understand *why* a system behaves the way it does from the data it emits,
> including for problems nobody predicted.

The full documentation is in **[10-observability/README.md](10-observability/README.md)**. It covers:

- **What each pillar means**: metrics (numbers over time), logs (discrete events), and traces (the path of one request across services).
  - Each pillar comes with real examples from the demo, the questions it answers, and its limits.
- **Why observability is required**: distributed systems, unknown-unknowns, MTTD/MTTR, SLIs/SLOs/error budgets, and the Golden Signals / RED / USE methods.
- **Common tools**: Prometheus, Grafana, Alertmanager, Loki, ELK/EFK, Fluent Bit, Jaeger, Tempo, Zipkin, OpenTelemetry, and SaaS APM tools.
- **Kubernetes observability**:
  - metrics-server, kube-state-metrics, cAdvisor, node-exporter, Prometheus Operator / ServiceMonitor
  - log agents as DaemonSets
  - events and probes
  - the OpenTelemetry Collector
  - an architecture diagram

| Pillar | Answers | Demonstrated in |
|---|---|---|
| Metrics | *How much / how often / how fast?* | 09 (Prometheus), 11 (`kubectl top`), 10 (`/metrics`) |
| Logs | *What exactly happened?* | 09 (JSON logs), 11 (`kubectl logs`), 10 (logs with `trace_id`) |
| Traces | *Where did the time go / where did it fail?* | 10 (OpenTelemetry → Jaeger, 2 services) |

The traces demo ([10-observability/tracing-demo](10-observability/tracing-demo/README.md)) sends real requests through
`frontend → orders → db.query` and reads the span trees back from Jaeger. It also shows log ↔ trace correlation through `trace_id`.

![Normal trace](10-observability/screenshots/10-04-trace-normal.png)
![Error trace](10-observability/screenshots/10-06-trace-error.png)
![Three pillars, one request](10-observability/screenshots/10-08-three-pillars-one-request.png)

---

# Task 3 - GitOps

Everything in this task was run for real in **[12-gitops-argocd-demo](12-gitops-argocd-demo/README.md)**.

| Concept | Meaning |
|---|---|
| **GitOps** | Operating infrastructure and apps by declaring the desired state in Git; an agent makes the cluster match it. |
| **Git as the source of truth** | The cluster state is whatever is in Git. Changes go through commits / PRs, so you get history, review, audit and rollback for free. |
| **Declarative configuration** | You describe *what* (for example `replicas: 3`), not *how* (`kubectl scale ...`). |
| **Continuous reconciliation** | A controller loops: observe the cluster → diff it against Git → act to remove the drift (self-heal, prune). |
| **GitOps workflow** | Developer commits → Git → Argo CD (in the cluster) **pulls** and syncs → cluster. Nobody runs `kubectl apply` by hand. |
| **Kubernetes + GitOps** | K8s is declarative and API-driven, so it fits naturally. Argo CD / Flux run as controllers and track an `Application` CRD. |

```text
 developer ──git commit/push──▶  Git repo (desired state)
                                      ▲
                                      │ pull (every 30s / on refresh)
                                      │
                          ┌───────────┴───────────┐
                          │   Argo CD controller  │  observe → diff → sync
                          └───────────┬───────────┘
                                      │ apply / prune / self-heal
                                      ▼
                             Kubernetes cluster (actual state)
```

What the demo shows:

| Step | Screenshot |
|---|---|
| Argo CD installed, the Git source repo, the `Application` applied | `12-01` … `12-03` |
| App **Synced / Healthy**, sync revision = Git HEAD | `12-04` |
| GitOps change: `replicas` 2 → 3 by a **git commit** → cluster follows | `12-05`, `12-06` |
| **Self-heal**: manual `kubectl scale` / deleting the Deployment is reverted | `12-07`, `12-08` |
| **Prune**: a resource removed from Git is removed from the cluster | `12-09`, `12-10` |
| **Rollback** with `git revert` | `12-11`, `12-12` |
| App reachable, sync history | `12-13`, `12-14` |

> The Git server is a local `git daemon` instead of GitHub, so nothing is pushed anywhere.
> [12-gitops-argocd-demo/README.md](12-gitops-argocd-demo/README.md) explains how to point the same Application at a real GitHub repository.

![Synced and healthy](12-gitops-argocd-demo/screenshots/12-04-app-synced-healthy.png)
![Git commit scales the app](12-gitops-argocd-demo/screenshots/12-06-argo-synced-3-replicas.png)
![Self-heal](12-gitops-argocd-demo/screenshots/12-07-self-heal-scale.png)

---

## How to reproduce (quick)

```bash
# Task 1 - Prometheus stack
cd 09-monitoring-stack && docker compose up -d --build && ./scripts/load.sh
#   Prometheus http://localhost:9090  Alertmanager :9093  Grafana :3000 (admin/admin)

# Task 2 - tracing demo
cd 10-observability/tracing-demo && docker compose up -d --build
curl "http://localhost:8081/order?item=book"     # Jaeger UI http://localhost:16686

# Task 1 + 3 - Kubernetes
minikube start -p session20 --driver=docker --cpus=2 --memory=1800
minikube -p session20 addons enable metrics-server
kubectl --context session20 apply -f 11-k8s-monitoring/manifests/
# Argo CD: follow 12-gitops-argocd-demo/README.md
```

Cleanup instructions are at the end of each folder's README.

## Issues hit while doing the assignment

- **Memory and CPU pressure.** Docker Desktop had about 3.9 GB of RAM and was shared with other minikube clusters.
  - Probes timed out with the default 1s, so `timeoutSeconds: 3` was set.
  - The memory alert flapped because the container was swapping, so `memswap_limit` was set.
  - These issues are left visible in the screenshots and explained in each README.
- **Image pulls failed inside minikube.** DNS for `auth.docker.io` failed on the node, so images were pre-pulled with `minikube -p session20 ssh -- sudo crictl pull <image>`.
- **Argo CD on a small cluster.** dex, notifications and applicationset controllers were scaled to 0 because they aren't needed for this demo.
- **OpenTelemetry on `python:3.12-slim`.** Instrumentation 0.48b0 needs `pkg_resources`, so the demo pins SDK 1.29.0 / instrumentation 0.50b0.
