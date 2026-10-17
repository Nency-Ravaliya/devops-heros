# Session 20: Monitoring, observability, and GitOps

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

```bash
docker compose up --build -d
curl http://localhost:18200/health
curl http://localhost:18200/metrics
docker compose logs app
```

Prometheus runs at http://localhost:19090 and Grafana at http://localhost:13000.
Inspect Prometheus Targets and Alerts. Stop the app for over a minute to exercise
StudentAppDown. Notification delivery needs a separately configured Alertmanager.
Grafana provisions the Prometheus source; add panels with:

```promql
rate(study_requests_total[5m])
rate(container_cpu_usage_seconds_total{container_label_com_docker_compose_service="app"}[5m])
container_memory_working_set_bytes{container_label_com_docker_compose_service="app"}
up{job="student-app"}
```

cAdvisor needs privileged host visibility and is intended for a disposable Linux
lab; it has no published port. Run only on a lab host you control.
Metrics show numeric trends, logs record events, and traces connect spans for a
request across services. Prometheus/Grafana handle metrics, Loki can store logs,
and OpenTelemetry with Tempo/Jaeger handles traces. This demo implements metrics
and structured logs; traces are explained but not emitted. In Kubernetes also
inspect kubectl top, events, and container logs.

GitOps stores desired configuration in Git and continuously reconciles it.
Install Argo CD following https://argo-cd.readthedocs.io/en/stable/getting_started/,
then `kubectl apply -f gitops/application.yaml`. It watches this session branch
and manifest directory. Change replicas in Git and push to observe reconciliation.
Manually change replicas to see self-heal restore the Git value. Prune removes
managed resources removed from Git; use the dedicated student20 namespace only.

```bash
kubectl -n argocd get application student20
kubectl -n student20 get deploy,pods,svc
```

Capture real targets, dashboards, alert and sync output in evidence/.
Cleanup: remove the Argo Application, delete student20, then docker compose down.

## Verification

The app image built and served HTTP; Compose configuration parsed.

Prometheus/Grafana/cAdvisor containers and Argo CD demo need image downloads and a cluster.

Command output: [evidence/](evidence/).
