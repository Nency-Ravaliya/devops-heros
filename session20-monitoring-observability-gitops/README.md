# Session 20 - Monitoring, Observability and GitOps

I completed this session in three parts: a small monitoring stack, notes and examples for the three observability pillars, and an Argo CD GitOps project.

## Monitoring

The Prometheus example is in [`03-prometheus/`](03-prometheus/), and the Prometheus/Grafana stack is in [`04-grafana/`](04-grafana/). I configured a five-second scrape interval and a target-down alert rule.

```bash
cd session20-monitoring-observability-gitops/04-grafana
docker compose config
docker compose up -d
curl -fsS http://localhost:9090/-/ready
curl -fsS http://localhost:3000/api/health
docker compose down
```

CPU, memory, request rate, errors, and application health are the first signals I would place on a service dashboard. Metrics show trends, logs explain individual events, and traces follow one request across services. My notes and Kubernetes logging example are in [`02-metrics-logs-traces/`](02-metrics-logs-traces/).

## GitOps

The mini project in [`08-mini-project/`](08-mini-project/) defines a Namespace, two-replica Deployment, Service, and Argo CD Application. The Application watches this repository and enables automated pruning and self-healing.

```text
GitHub main branch
        |
        | desired YAML
        v
     Argo CD
        |
        | reconcile
        v
Kubernetes namespace session20
        ├── Deployment
        └── Service
```

I keep the Argo CD `Application` manifest outside the watched workload directory. Otherwise Argo CD would try to render its own control object as part of the application workload.

The validation steps are:

```bash
kubectl apply --dry-run=client -f 08-mini-project/app/
kubectl apply --dry-run=client -f 08-mini-project/argocd-application.yaml
```

On a cluster with Argo CD installed, I apply the Application, check that it becomes `Synced` and `Healthy`, change the replica count in Git, and verify that Argo CD reconciles the cluster. I also test self-healing by manually scaling the Deployment away from the Git value and watching it return to the declared count.
