# Session 15: Helm

Managing many Kubernetes YAML files across multiple environments leads to copy-paste errors and configuration drift.

Helm solves this. It is the package manager for Kubernetes.

---

## Why Helm?

Without Helm, deploying to three environments means three separate sets of YAML files. Change one value and you update three files manually.

With Helm, you write one chart. You pass different values for each environment.

---

## Topics Covered

| Folder | Topic |
|--------|-------|
| `01-what-is-helm/` | What is Helm, installing Helm, first commands |
| `02-helm-charts/` | What is a Chart, creating and installing charts |
| `03-chart-structure/` | Chart directory layout, Chart.yaml, values.yaml, templates |
| `04-chart-yaml/` | Chart.yaml fields, version vs appVersion |
| `05-values-yaml/` | Default values, overriding with -f and --set |
| `06-templates/` | Go template syntax, variables, conditionals |
| `07-install-upgrade/` | helm install, helm upgrade, revision history |
| `08-rollback/` | helm rollback, --atomic flag, auto rollback |
| `09-deploying-application/` | Full application deployment: lint, install, upgrade, rollback |
| `mini-project/` | Deploy the Notes App from scratch using Helm |

---

## Core Concepts

**Chart:** A packaged collection of Kubernetes YAML templates with variables. Think of it as a recipe.

**Release:** A running instance of a chart deployed to a cluster. Think of it as the cooked meal.

**Values:** The variables you pass to customize the chart. Think of them as the ingredients.

---

## Key Commands

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Create a new chart
helm create my-chart

# Render templates locally (no cluster needed)
helm template my-release ./my-chart

# Check chart for errors
helm lint ./my-chart

# Install a chart
helm install my-release ./my-chart

# Install with custom values
helm install my-release ./my-chart -f values-prod.yaml

# List all releases
helm list

# Upgrade a release
helm upgrade my-release ./my-chart --set replicaCount=3

# View release history
helm history my-release

# Rollback to a previous revision
helm rollback my-release 1

# Remove a release
helm uninstall my-release
```

---

## Helm 2 vs Helm 3

```text
Helm 2: required Tiller (a server pod in the cluster)
        ran with cluster-admin privileges
        security risk

Helm 3: no Tiller
        client-only
        uses your kubeconfig permissions
        release state stored as Kubernetes Secrets
```

---

## Interview Preparation

**Beginner:**

Q: What is Helm?
A: Helm is a package manager for Kubernetes. It packages Kubernetes YAML files into parameterized charts that can be installed, upgraded, and rolled back with single commands.

Q: What is the difference between a Chart and a Release?
A: A Chart is the packaged template (the recipe). A Release is a running instance of that chart installed in a cluster (the cooked meal).

**Intermediate:**

Q: What is the difference between values.yaml and --set?
A: values.yaml holds the default configuration in version control. --set overrides individual values at runtime. In production pipelines, use separate values files (-f values-prod.yaml) so all configuration is auditable in Git.

Q: What does --atomic do?
A: During helm upgrade, --atomic auto-rolls back to the previous healthy revision if any pod fails readiness within the timeout period.

**Scenario-Based:**

Q: You run helm upgrade and it gets stuck in pending-upgrade state. What do you do?
A: Inspect helm secrets with kubectl get secrets -l owner=helm. Find the stuck pending revision secret and delete it. Then run helm rollback to the last healthy revision.

---

## Reference

* **Helm Documentation:** https://helm.sh/docs/
* **Helm Chart Template Guide:** https://helm.sh/docs/chart_template_guide/
* **Helm CLI Reference:** https://helm.sh/docs/helm/
