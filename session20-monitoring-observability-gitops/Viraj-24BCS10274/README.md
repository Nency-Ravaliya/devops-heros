# Session 20 — Monitoring and GitOps

**Name:** Viraj Bhanage
**Roll number:** 24BCS10274

Monitoring is a line you set in advance: CPU, memory, errors, and `/health`. Observability is explaining a failure you did not predict, using metrics, logs, and traces. Prometheus holds the metrics. Logs are what the process printed. A trace shows which hop was slow.

GitOps means Git is the cluster's desired state. Argo CD watches the repo and puts drift back. For this fork the application path is `session21-python/helm/taskboard` and the repo is `https://github.com/bhanage-viraj/devops-heros.git`. `selfHeal` reverts a manual edit. `prune` deletes an object that was removed from Git.

More detail is in `homework/session-20-observability/README.md`.
