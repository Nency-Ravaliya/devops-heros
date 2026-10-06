# Session 15 — Helm

Student: Viraj Bhanage, roll 24BCS10274

Install Helm, then practice against the chart that is already in the course repo:

```bash
brew install helm
helm create demo
helm install notes ./session-15-helm/mini-project/notes-chart
helm list
helm status notes
helm get values notes
helm get manifest notes
helm upgrade notes ./session-15-helm/mini-project/notes-chart -f session-15-helm/mini-project/notes-chart/values-prod.yaml
helm history notes
helm rollback notes 1
helm uninstall notes
helm repo add bitnami https://charts.bitnami.com/bitnami
helm search repo nginx
```

| Command | What it does |
|---|---|
| `helm create` | Scaffolds Chart.yaml, values.yaml, and templates |
| `helm install` | Renders templates and applies them as a release |
| `helm list` | Releases in the namespace |
| `helm status` | Last status of one release |
| `helm get` | Values, manifest, or notes stored for that revision |
| `helm upgrade` | New revision with new values or templates |
| `helm history` | Revision list |
| `helm rollback` | Reapplies an older revision |
| `helm uninstall` | Deletes the release objects |
| `helm repo` / `helm search` | Find charts published by someone else |

## Rollback workflow

1. Install revision 1 from `values.yaml` (1 replica, nginx `1.24`, environment `development`).
2. Upgrade with `values-prod.yaml` (3 replicas, nginx `1.25`). `helm history` shows revision 2. `kubectl get deploy` shows 3 replicas.
3. Upgrade again if you change a value, and confirm revision 3.
4. `helm rollback notes 1` returns the development values. `helm history` marks revision 1 as deployed again via a new revision record.
5. `kubectl get pods` shows the replica count from revision 1.

## Mini project

`session-15-helm/mini-project/notes-chart/` already has `Chart.yaml`, `values.yaml`, `values-prod.yaml`, and templates for the Deployment, Service, and ConfigMap. That is the Notes app chart. Screenshot `helm list`, `helm history notes`, and `kubectl get pods` after install, after upgrade, and after rollback.
