# gitops/ - Argo CD

Argo CD deploys the **same Helm chart** (`helm/taskboard`) from Git, using automated sync with `prune` and `selfHeal`. Nobody runs `kubectl apply` or `helm upgrade` against the cluster any more. Every change is a commit.

```
gitops/
├── argocd-application.yaml          LOCAL demo Application (applied): git://host.minikube.internal/taskboard-gitops
├── argocd-application-github.yaml   real-world Application -> github.com/jenyyy4/devops-heros (applied -> ns taskboard-prod)
├── project.yaml                     AppProject "taskboard": allowed repos + only namespace taskboard
├── apps/taskboard/values-local.yaml environment values for the local cluster (THIS is what you edit + commit)
├── sync-local-repo.sh               copy chart + apps/ into the local git repo, commit, start git daemon
└── watch-sync.sh                    print Argo sync/health + workload state whenever it changes
```

## Which values file does Argo CD read?

| Application | Source | Value files | Image tag keys that CD bumps |
|-------------|--------|-------------|------------------------------|
| `taskboard` (local, applied) | `git://host.minikube.internal/taskboard-gitops`, path `helm/taskboard` | `values.yaml` and `../../gitops/apps/taskboard/values-local.yaml` | `.backend.image.tag` and `.frontend.image.tag` in `gitops/apps/taskboard/values-local.yaml` |
| `taskboard-prod` (GitHub, applied to ns `taskboard-prod`) | `https://github.com/jenyyy4/devops-heros.git`, path `session21-python/final-devops-project/helm/taskboard` | `values.yaml`, `values-prod.yaml`, `apps/taskboard/values-prod-minikube.yaml` | `.backend.image.tag` and `.frontend.image.tag` in `helm/taskboard/values-prod.yaml` |

The flow is the same in both cases. CI builds the images and pushes them to GHCR. CD commits the new tag into the values file. Argo CD notices the commit and rolls the cluster forward.

## Local Git source (no GitHub push)

This follows the Session 20 approach (`session20-.../12-gitops-argocd-demo`). A local repo is served read-only with `git daemon`. Inside minikube, `host.minikube.internal` resolves to the Mac.

```bash
GITOPS_SRC=~/gitops-src ./gitops/sync-local-repo.sh "initial"     # repo = $GITOPS_SRC/taskboard-gitops
kubectl -n argocd exec deploy/argocd-repo-server -- git ls-remote git://host.minikube.internal/taskboard-gitops
```

## Install (lean)

```bash
curl -sSLo /tmp/argocd-install.yaml https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f /tmp/argocd-install.yaml        # v3.5.4
kubectl -n argocd scale deploy argocd-dex-server argocd-notifications-controller argocd-applicationset-controller --replicas=0
kubectl -n argocd patch cm argocd-cm --type merge -p '{"data":{"timeout.reconciliation":"30s"}}'
kubectl -n argocd rollout restart deploy/argocd-repo-server statefulset/argocd-application-controller
```

`argocd-server` (the UI and API) was **scaled to 0 later**. The node was swapping, and everything in this demo uses `kubectl -n argocd get applications` or the Application status. To use the UI, scale it back up and port-forward it:

```bash
kubectl -n argocd scale deploy argocd-server --replicas=1
kubectl -n argocd port-forward svc/argocd-server 8443:443
```

Get the admin password with:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## Demo (screenshots 70-76)

1. **Hand over from Helm to Argo CD (72).** Run `helm uninstall taskboard`; the StatefulSet PVC is kept. Then `kubectl apply -f gitops/project.yaml -f gitops/argocd-application.yaml`. The result is `Synced / Healthy` at revision `e746164`, and the PVC (and its data) is reused.
2. **Git change (73).** Bump the backend tag to `1.1.0` and `frontend.replicaCount` to 2 in `values-local.yaml`, then commit with `sync-local-repo.sh`. About 60s later, Argo goes `OutOfSync`, then `Synced/Progressing`, then `Healthy`.
3. **Self-heal (74).** `kubectl scale deploy taskboard-frontend --replicas=0` is reverted to 2 within about 10s. `kubectl patch cm taskboard-config LOG_LEVEL=trace` is reverted to `info`.
4. **Prune (75).** Setting `autoscaling.enabled: false` in Git makes Argo delete the HPA (`status: Pruned`).
5. **Roll forward (76).** Re-enable the HPA with another commit. `git log` and the Application `status.history` line up one to one.

To make Argo poll immediately instead of waiting up to 30s:

```bash
kubectl -n argocd annotate app taskboard argocd.argoproj.io/refresh=normal --overwrite
```

## Gotchas

* **Ordering.** Argo CD can adopt resources, but leaving a Helm release *and* an Application on the same objects means two owners. Uninstall the Helm release first.
* **Load on the node.** The repo-server crash-looped and the API server restarted several times. While the controller couldn't reach the repo-server, the app showed `Unknown/Degraded` with `ComparisonError: lookup argocd-repo-server ... i/o timeout`. Once the load dropped, the app returned to `Synced/Healthy` without any manual sync.
* **HPA health.** Argo marks an HPA as `Degraded` while metrics-server is unavailable (`FailedGetResourceMetric`). In this demo, that was the main cause of the `Degraded` flaps.
