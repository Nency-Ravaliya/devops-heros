# Session 15 — Helm

**Name:** Viraj Bhanage
**Roll number:** 24BCS10274

The Notes chart is `mini-project/notes-chart`.

```bash
helm install notes-viraj ./mini-project/notes-chart
helm upgrade notes-viraj ./mini-project/notes-chart -f mini-project/notes-chart/values-prod.yaml
helm history notes-viraj
helm rollback notes-viraj 1
```

The first revision is one replica on nginx 1.24. The prod values file moves it to three replicas on nginx 1.25. Rollback returns revision 1. Also practice `helm list`, `helm status`, `helm get values`, and `helm uninstall`. Screenshot `helm history` after the rollback.
