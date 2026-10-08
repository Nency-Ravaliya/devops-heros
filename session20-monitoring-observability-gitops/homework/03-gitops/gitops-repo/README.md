# gitops-demo

Desired state for the Session 20 GitOps demo. Argo CD watches `apps/web` on `main` and keeps the cluster in sync with it.
Change anything here, open a PR / commit to `main`, and Argo CD applies it. Manual `kubectl` changes are reverted (self-heal).
