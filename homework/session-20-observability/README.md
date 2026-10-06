# Session 20 — Monitoring, observability, GitOps

Student: Viraj Bhanage, roll 24BCS10274

The course labs are in `session20-monitoring-observability-gitops/`. This file is the written half of the homework.

## Monitoring

Monitoring tells you when a known signal crosses a line you chose.

- **Metrics** are numbers over time: request rate, CPU, memory, error ratio.
- **Logs** are timestamped lines from the process.
- **Alerts** fire when a metric or log query stays outside a threshold. An alert needs an owner and a next step.
- **CPU and memory** come from Metrics Server (`kubectl top`) or from cAdvisor via Prometheus.
- **Application health** is the `/health` and `/ready` endpoints. Kubernetes probes use them. A 200 from `/health` means the process is alive. `/ready` means it can serve traffic.

The TaskBoard backend exposes `/metrics` for Prometheus. Grafana reads Prometheus and draws the dashboard. Course manifests are under `session20-monitoring-observability-gitops/03-prometheus` and `04-grafana`, and the capstone values are in `session21-python/monitoring/`.

## Observability

Observability is being able to explain a new failure from the telemetry you already collect, not only from alerts you predicted.

| Pillar | Question it answers | Typical tool |
|---|---|---|
| Metrics | How much, how often? | Prometheus |
| Logs | What did this process say? | Loki, CloudWatch, the journal |
| Traces | Which hop was slow? | Jaeger, Tempo |

You need all three because a CPU graph does not show the exception text, and a log line does not show which downstream call burned the latency. On Kubernetes, scrape Pods with annotations or a ServiceMonitor, ship container logs, and propagate a trace header at the Ingress.

## GitOps

GitOps means the Git commit is the source of truth for the cluster. The desired state is declarative YAML. A controller in the cluster continuously reconciles: if someone edits a live object, the controller changes it back to Git.

```text
Developer merges a manifest
  -> Git
  -> Argo CD notices the diff
  -> Argo CD applies the manifest
  -> cluster matches Git
```

Argo CD Application objects point at a repo path and a cluster. The course walkthrough is `session20-monitoring-observability-gitops/07-argocd`. A minimal Application:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: taskboard
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/bhanage-viraj/devops-heros.git
    path: session21-python/helm/taskboard
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: taskboard
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

`prune` deletes objects removed from Git. `selfHeal` reverts manual edits.

## Screenshots

- `kubectl top pods` or a Prometheus graph of CPU
- Grafana panel for the app
- Argo CD application status `Synced` / `Healthy` if you install Argo CD on the lab cluster
