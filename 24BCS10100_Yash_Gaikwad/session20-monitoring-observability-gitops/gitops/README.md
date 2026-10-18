# GitOps

Prepared by: Yash Gaikwad (Roll no. 24BCS10100)
Session: 20 - Monitoring, Observability and GitOps

These are my theory notes on GitOps. The hands-on demo is done separately, so this file keeps the concepts, the tool comparison, and the commands and YAML I would reuse.

---

## What is GitOps

GitOps is a way of operating infrastructure and applications where the **desired state of the system is stored in Git**, and an automated agent makes the real environment match it. Instead of a person running `kubectl apply` from a laptop, I change a file, open a pull request, and the cluster updates itself after the merge.

The term was introduced by Weaveworks and is now standardised through the OpenGitOps project (CNCF).

### Git as the source of truth

- Every change to the environment is a Git commit, so I get history, author, review and an audit trail for free.
- The Git repo describes *what should be running*; the cluster is just one realisation of it.
- Anything done by hand in the cluster that is not in Git is considered **drift** and gets reverted.

### Declarative configuration

- Kubernetes manifests, Helm charts, Kustomize overlays (and Terraform for infra) describe the **end state**, not the steps.
- Declarative files are easy to diff, review and re-apply safely (idempotent).

### Continuous reconciliation

- A controller running in the cluster keeps comparing **desired state (Git)** with **actual state (cluster)** in a loop, and fixes the difference.
- This loop is what separates GitOps from "just storing YAML in Git".

---

## Pull-based vs push-based delivery

| | Push-based CI/CD | Pull-based GitOps |
|---|---|---|
| Who deploys | the CI pipeline runs `kubectl apply` / `helm upgrade` | an in-cluster agent pulls from Git and applies |
| Cluster credentials | CI system needs admin credentials to the cluster | credentials stay inside the cluster; only read access to Git is needed |
| Drift | not detected after the pipeline finishes | detected and corrected continuously |
| Security | larger attack surface (CI has cluster access) | smaller; cluster has an outbound connection only |
| Trigger | pipeline run | Git change or periodic sync |
| Examples | GitHub Actions deploy job, Jenkins | Argo CD, Flux |

In a typical setup both exist: **CI** (build, test, scan, push image) stays push-style, and **CD** becomes pull-style.

---

## The GitOps workflow step by step

1. A developer (or the CI pipeline) changes the desired state in the config repo, for example bumps the image tag in a manifest.
2. They open a **pull request**.
3. The PR is **reviewed** and automated checks run (YAML lint, `kubeconform`, `kustomize build`, policy checks).
4. The PR is **merged** into the main branch, which is now the new desired state.
5. The GitOps controller (Argo CD or Flux) detects the new commit, either through polling or a webhook.
6. The controller **syncs**: renders the manifests and applies them to the cluster.
7. It reports health and sync status; a failed sync or unhealthy resource is visible and can alert.
8. **Drift detection / self-heal**: if someone changes the live cluster manually (for example scales a deployment with `kubectl`), the controller notices it differs from Git and reverts it automatically.

```
 developer --> PR --> review --> merge to main
                                    |
                                    v
                               Git repository  <------- controller polls/webhook
                                    |                          |
                                    |  desired state           | applies + watches
                                    v                          v
                              +------------------------------------+
                              |   Kubernetes cluster (actual)      |
                              +------------------------------------+
```

---

## OpenGitOps principles

The four principles (OpenGitOps v1.0):

1. **Declarative**: the system is described declaratively, as the desired state.
2. **Versioned and immutable**: the desired state is stored in a way that enforces immutability and keeps a full version history (Git).
3. **Pulled automatically**: software agents automatically pull the desired state declarations from the source.
4. **Continuously reconciled**: agents continuously observe actual state and attempt to apply the desired state.

---

## Kubernetes and GitOps: Argo CD vs Flux

Both are CNCF graduated projects and both implement pull-based reconciliation for Kubernetes.

| Feature | Argo CD | Flux (v2) |
|---|---|---|
| Model | application-centric: an `Application` maps a Git path to a cluster namespace | toolkit of controllers: `GitRepository`, `Kustomization`, `HelmRelease` objects |
| UI | rich built-in web UI showing resource tree and diffs | no official built-in UI (CLI and community dashboards) |
| Install | one set of manifests or Helm chart | `flux bootstrap`, which also commits its own config to Git |
| Config sources | Git, Helm repos, OCI | Git, Helm repos, OCI, S3-style buckets |
| Tools supported | plain YAML, Kustomize, Helm, Jsonnet, plugins | Kustomize, Helm (native controllers) |
| Multi-cluster | one central Argo CD can manage many remote clusters | commonly one Flux per cluster, remote targets also possible |
| Multi-tenancy | `AppProject` with RBAC and SSO | Kubernetes RBAC and namespace-scoped objects |
| Image update automation | separate add-on (Argo CD Image Updater) | built in (image reflector and automation controllers) |
| Drift handling | `selfHeal` option | reconciles on its interval by default |
| Typical pick | teams wanting visibility, a UI and central control | teams preferring a lightweight, Kubernetes-native, CLI/Git-first approach |

---

## Example: installing Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl -n argocd get pods
kubectl -n argocd port-forward svc/argocd-server 8080:443
argocd admin initial-password -n argocd      # initial admin password
```

`--server-side` avoids the "annotation too long" error that large CRDs can cause with a normal client-side apply.

## Example: Argo CD Application with automated sync

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/<your-user>/<config-repo>.git
    targetRevision: main
    path: apps/demo/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: demo
  syncPolicy:
    automated:
      prune: true        # delete cluster resources that were removed from Git
      selfHeal: true     # revert manual changes made directly in the cluster
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 3
      backoff:
        duration: 10s
        factor: 2
        maxDuration: 3m
```

- `prune: true` removes resources that disappear from Git; without it deleted manifests would leave orphans in the cluster.
- `selfHeal: true` is the drift-correction part.
- Day-to-day commands:

```bash
kubectl apply -f application.yaml
argocd app list
argocd app get demo-app
argocd app diff demo-app
argocd app sync demo-app        # manual sync if automation is off
```

## Example: Flux bootstrap

```bash
flux bootstrap github \
  --owner=<your-user> \
  --repository=<fleet-repo> \
  --branch=main \
  --path=clusters/dev \
  --personal

flux get sources git
flux get kustomizations
flux reconcile kustomization flux-system --with-source
```

---

## Repo layout suggestion

**App repo vs config repo**

- **App repo**: source code, Dockerfile, tests. CI builds, scans and pushes an image.
- **Config repo** (GitOps repo): only Kubernetes manifests / Helm values. The controller watches this one.
- Separating them keeps noisy code commits from triggering deployments, allows different access control, and keeps a clean deployment history. CI finishes by committing the new image tag to the config repo (for example with `kustomize edit set image`) or by opening a PR to it.

**Kustomize base and overlays**

```
config-repo/
|-- apps/
|   `-- demo/
|       |-- base/
|       |   |-- deployment.yaml
|       |   |-- service.yaml
|       |   `-- kustomization.yaml
|       `-- overlays/
|           |-- dev/
|           |   `-- kustomization.yaml
|           `-- prod/
|               |-- kustomization.yaml
|               `-- replicas-patch.yaml
`-- clusters/
    |-- dev/          # Argo CD Application / Flux Kustomization objects
    `-- prod/
```

`base/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
```

`overlays/prod/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
images:
  - name: myorg/demo
    newTag: "1.4.2"
patches:
  - path: replicas-patch.yaml
```

Preview locally before pushing:

```bash
kubectl kustomize apps/demo/overlays/prod
kubectl diff -k apps/demo/overlays/prod
```

---

## Benefits

- **Audit and traceability**: who changed what and when is just `git log`.
- **Easy rollback**: revert a commit.
- **Consistency**: the same declarative process for every environment; rebuilding a cluster is re-pointing the controller at the repo.
- **Better security**: no cluster admin credentials in CI; change control through PR review and branch protection.
- **Drift correction** and faster, more repeatable deployments.
- **Developer friendly**: uses tools engineers already know (Git, PRs).

## Challenges

- **Secrets management**: secrets must not be stored as plain text in Git. Common solutions:
  - **Sealed Secrets**: encrypt the secret with the cluster's public key (`kubeseal`); only the in-cluster controller can decrypt, so the sealed file is safe to commit.
  - **SOPS** (with age, or cloud KMS): encrypts values inside YAML files; Flux supports it natively, Argo CD through plugins such as KSOPS.
  - **External Secrets Operator**: Git holds only a reference; the operator fetches the real value from AWS Secrets Manager, HashiCorp Vault and similar.
- **Repo structure and tooling decisions** (mono-repo vs many repos, environment promotion).
- **Learning curve** and keeping controller permissions scoped in multi-tenant clusters.
- **Stateful or order-dependent changes** (database migrations, CRD ordering) need sync waves/hooks or dependencies.
- **Feedback delay**: reconciliation is asynchronous, so a merge is not an instant deploy; failures show up in the controller, not in the CI run.
- Image tag updates need an automated step, otherwise someone must edit the config repo manually.

```bash
# Sealed Secrets example: the plain secret never gets committed
kubectl create secret generic db-creds \
  --from-literal=password='<DB_PASSWORD>' \
  --dry-run=client -o yaml \
  | kubeseal --format yaml > sealed-db-creds.yaml
```

---

## Rollback with git revert

Because Git is the source of truth, rolling back is a Git operation, not a cluster operation.

```bash
git log --oneline -5                 # find the bad commit
git revert <bad-commit-sha>          # creates a new commit that undoes it
git push origin main                 # controller sees the commit and syncs
```

- `git revert` is preferred over `git reset --hard` + force push, because history stays intact and the rollback itself is reviewable.
- The controller then re-applies the previous manifests; with `prune` the resources introduced by the bad change are removed.
- With Argo CD automated sync enabled, `argocd app rollback` is not allowed (it would be undone by the next sync), so reverting in Git is the correct path. For an emergency, disable auto-sync on the app first, then re-enable after Git is fixed.
- Flux behaves the same way: revert in Git, then optionally `flux reconcile kustomization <name> --with-source` to speed it up.

---

## Interview quick points

- GitOps = Git as the single source of truth + declarative config + an automated agent that continuously reconciles the cluster to match.
- Pull-based: an agent in the cluster fetches from Git, so CI never needs cluster credentials. Push-based: the pipeline pushes changes in and does not watch for drift.
- OpenGitOps principles: declarative, versioned and immutable, pulled automatically, continuously reconciled.
- Argo CD: Application CRD, strong UI, central multi-cluster. Flux: set of controllers (source, kustomize, helm, notification, image automation), very Kubernetes-native.
- `prune` deletes resources removed from Git; `selfHeal` reverts manual live changes.
- Keep app code and deployment config in separate repos; CI updates the image tag in the config repo.
- Use Kustomize overlays (or Helm values) for per-environment differences instead of copying whole manifests.
- Never commit plain Kubernetes Secrets; use Sealed Secrets, SOPS or External Secrets Operator.
- Rollback = `git revert` and push; the controller does the rest.
- GitOps is not only for Kubernetes, but Kubernetes' declarative API is what makes it work so well.
