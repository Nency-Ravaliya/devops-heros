# helm/taskboard - the TaskBoard Helm chart

This one chart deploys the full stack: ConfigMap, Secret, Postgres StatefulSet and PVC, backend and frontend Deployments and Services, Ingress, and the HPA. The ServiceMonitor and PrometheusRule are optional and switched off by default. The chart also includes NOTES.txt and a `helm test` hook.

```
helm/taskboard/
├── Chart.yaml            chart 1.1.0, appVersion 1.0.0
├── values.yaml           defaults = local minikube (local images, taskboard.local, HPA 1-3)
├── values-dev.yaml       1 replica each, no HPA, smaller requests, debug logging
├── values-prod.yaml      GHCR images, frontend x2, HPA 2-6, TLS ingress, existingSecret, 10Gi, monitoring on
└── templates/
    ├── _helpers.tpl      names, labels, image refs, db host, secret name
    ├── configmap.yaml    APP_NAME / LOG_LEVEL / DB_HOST / DB_PORT / DB_NAME
    ├── secret.yaml       DB_USER / DB_PASSWORD (skipped when postgres.auth.existingSecret is set; `required` guard)
    ├── postgres.yaml     headless Service + StatefulSet + volumeClaimTemplate (postgres.enabled toggle)
    ├── backend.yaml      Deployment (+wait-for-db init, startup/liveness/readiness probes, checksum annotations) + Service "backend"
    ├── frontend.yaml     Deployment (nginx-unprivileged :8080) + Service
    ├── ingress.yaml      /api -> backend, / -> frontend, optional TLS/annotations
    ├── hpa.yaml          autoscaling/v2 on CPU (Deployment omits `replicas` when enabled)
    ├── servicemonitor.yaml / prometheusrule.yaml   only when the prometheus-operator CRDs exist
    ├── tests/test-connection.yaml                  `helm test`: wget backend /ready + frontend /healthz
    └── NOTES.txt
```

What changed from the chart that was copied in:

* **Ingress fixed.** It pointed at the nonexistent Service `taskboard-backend` on port 8080. It now uses the real Service and port.
* **Postgres moved to a StatefulSet.** It used to be a Deployment with a separate PVC. It is now a StatefulSet with a `volumeClaimTemplate`, and it has a liveness probe.
* **Credentials come from the Secret.** `DATABASE_URL` used to contain the password in plain text. The backend now reads the user and password from the Secret through `secretKeyRef`.
* **New fields:** a ConfigMap, a startup probe, a securityContext (non-root, read-only root filesystem, all capabilities dropped), `checksum/config` and `checksum/secret` annotations, standard `app.kubernetes.io/*` labels, the `imagePullSecrets`, `existingSecret` and `postgres.enabled` toggles, and the frontend on port 8080.
* **Toggles default to off.** `serviceMonitor` and `prometheusRule` used to be on by default, which broke clusters without the CRDs. Both are now switched off by default.

## Commands used (see screenshots 50-55)

```bash
helm lint helm/taskboard -f helm/taskboard/values-dev.yaml
helm lint helm/taskboard -f helm/taskboard/values-prod.yaml
helm template taskboard helm/taskboard -n taskboard | grep '^kind:' | sort | uniq -c

helm install taskboard helm/taskboard -n taskboard --create-namespace --wait
helm test taskboard -n taskboard

helm upgrade taskboard helm/taskboard -n taskboard --reuse-values \
  --set backend.image.tag=1.1.0 --set frontend.replicaCount=2 --wait          # rev 2
helm upgrade taskboard helm/taskboard -n taskboard --reuse-values \
  --set config.logLevel=debug --wait                                          # rev 3: checksum rolls pods
helm history taskboard -n taskboard
helm rollback taskboard 1 -n taskboard --wait                                  # rev 4 = rev 1 again
helm list -A
```

Environments:

```bash
helm upgrade --install taskboard helm/taskboard -n taskboard -f helm/taskboard/values-dev.yaml
helm upgrade --install taskboard helm/taskboard -n taskboard -f helm/taskboard/values-prod.yaml   # needs Secret taskboard-db-prod
```

## Gotcha: `--reuse-values` ignores new chart defaults

When I changed default probe timeouts in `values.yaml`, `helm upgrade --reuse-values` did not apply them. It reuses the values of the previous release and does not merge in the new chart's defaults. Use `--reset-then-reuse-values` (Helm 3.14 or later) when the chart's defaults have changed.

In the final state, the Helm release was uninstalled and Argo CD deploys this same chart from Git. See `../gitops/`.
