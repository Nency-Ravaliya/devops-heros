# Session 15 Homework — Helm

**Submitted by:** Piyush Bansal
**Cluster:** Docker Desktop Kubernetes v1.36.1 (single node, arm64)
**Helm:** v4.3.0 (the course notes use v3; I list the differences I hit in task 1)

| Task | Folder | What is inside |
|---|---|---|
| 1. Helm commands | [01-helm-commands/](01-helm-commands/) | `helm create` chart (`web-chart/`) + create, install, list, status, get, upgrade, history, rollback, uninstall, repo, search with real output |
| 2. Helm rollback | [02-rollback/](02-rollback/) | `hello-chart/` + `values-v2.yaml`, `values-v3.yaml`. Install → Upgrade → Verify → Upgrade → Verify → Rollback → Verify, checked over HTTP |
| 3. Mini project | [03-mini-project/](03-mini-project/) | `notes-chart/` (Chart.yaml, values.yaml, values-prod.yaml, templates). Install, prod upgrade, bad upgrade, rollback, uninstall |

Deliverables:

- **Helm charts:** `01-helm-commands/web-chart`, `02-rollback/hello-chart`, `03-mini-project/notes-chart`
- **values.yaml / templates:** inside each chart
- **Installation, upgrade and rollback:** documented in each README
- **Screenshots:** I captured real terminal output as text blocks instead of screenshots

Namespaces used: `p15-cmds`, `p15-rollback`, `p15-notes` (all deleted at the end).
