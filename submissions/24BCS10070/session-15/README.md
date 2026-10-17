# Session 15: Helm mini-project and rollback

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

This chart packages the course Notes example with configurable replicas, image,
Service, ConfigMap, and production overrides. Run from this directory:

```bash
helm create /tmp/student-helm-starter
helm lint notes-chart
helm template notes notes-chart
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo bitnami --max-col-width 60
helm install notes notes-chart -n student15 --create-namespace --wait
helm list -n student15
helm status notes -n student15
helm get values notes -n student15
helm get manifest notes -n student15
helm upgrade notes notes-chart -n student15 -f notes-chart/values-prod.yaml --wait
kubectl -n student15 get pods
helm upgrade notes notes-chart -n student15 --reuse-values --set image.tag=this-tag-does-not-exist
kubectl -n student15 describe pods
helm history notes -n student15
helm rollback notes 2 -n student15 --wait
kubectl -n student15 rollout status deployment/notes
helm history notes -n student15
helm uninstall notes -n student15
kubectl delete namespace student15
```

Revision 1 installs development values; revision 2 sets three production replicas;
revision 3 intentionally sets a nonexistent image. Without `--wait`, Helm can
record an upgrade before Pods become healthy. A rollback to revision 2 creates
a new revision with the earlier configuration. Check Pods as well as Helm status.
Local lint/render results and any actual runtime results are in `evidence/`.

## Verification

helm lint passed and chart templates rendered locally.

Install/upgrade/rollback/uninstall history needs a cluster; repository search needs network access.

Command output: [evidence/](evidence/).
