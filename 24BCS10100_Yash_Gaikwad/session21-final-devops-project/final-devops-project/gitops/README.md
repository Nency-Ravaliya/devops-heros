# gitops/

GitOps means **Git is the source of truth** and a controller inside the cluster keeps the cluster equal to it. Here the controller is **Argo CD**.

| File | Purpose |
|---|---|
| [`argocd-application.yaml`](argocd-application.yaml) | the Argo CD `Application`: "render the Helm chart at `helm/stockpilot` from this repository (with `values-dev.yaml`) and keep the `stockpilot` namespace identical to it" |

Automated sync is on with **prune** (objects removed from Git are removed from the cluster) and **self-heal** (manual changes made directly in the cluster are reverted).

```bash
# once: install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# once: tell Argo CD what to watch
kubectl apply -f gitops/argocd-application.yaml

# from now on: change the chart or the values in Git, commit, push. Argo CD does the rest.
kubectl get applications -n argocd
```

The full workflow, a live demonstration (sync, self-heal after a manual change, and a change made through a Git commit) and the explanation of the concepts are in [Session 20](../../../session20-monitoring-observability-gitops) and in the README of this project.
