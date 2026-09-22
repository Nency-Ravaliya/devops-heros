# What is Helm?

```text
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f configmap.yaml
...
```

That is what you do without Helm. For every environment.

> "Helm is the package manager for Kubernetes."

---

## 1. The Problem Helm Solves

Imagine you need to deploy the same application to three environments:

```text
Dev        Staging      Production
1 replica  2 replicas   10 replicas
small CPU  medium CPU   large CPU
```

Without Helm, you write three separate sets of YAML files. If you change one setting, you update three files manually.

With Helm, you write **one chart** and pass different values.

---

## 2. What is a Helm Chart?

A Helm Chart is a packaged collection of Kubernetes YAML files with variables.

```text
my-chart/
  Chart.yaml       <-- metadata about the chart
  values.yaml      <-- default variables
  templates/       <-- YAML files with {{ variables }}
```

Think of a chart like a **recipe**. The recipe stays the same. You decide the ingredients (values).

---

## 3. Install Helm

Run:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Verify:

```bash
helm version
```

Expected output:

```text
version.BuildInfo{Version:"v3.15.0", ...}
```

---

## 4. Your First Helm Command

List installed releases:

```bash
helm list
```

Expected output (empty cluster):

```text
NAME    NAMESPACE    REVISION    UPDATED    STATUS    CHART    APP VERSION
```

---

## 5. Install a Public Chart

Add the bitnami repository:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

Install nginx:

```bash
helm install my-nginx bitnami/nginx
```

Expected output:

```text
NAME: my-nginx
LAST DEPLOYED: ...
NAMESPACE: default
STATUS: deployed
REVISION: 1
```

Check what was created:

```bash
kubectl get pods
kubectl get services
```

---

## 6. Remove the Release

```bash
helm uninstall my-nginx
```

Expected output:

```text
release "my-nginx" uninstalled
```

All Kubernetes resources created by that release are now deleted.

---

## Key Concepts

```text
Chart    = the packaged template (recipe)
Release  = a running instance of a chart (cooked meal)
Values   = the variables you pass in (ingredients)
```

---

## Helm 2 vs Helm 3

```text
Helm 2: required a server pod called Tiller running in the cluster
        (security risk, required cluster-admin privileges)

Helm 3: no Tiller, client-only
        uses your kubeconfig permissions directly
        release state stored as Kubernetes Secrets
```

---

## Useful Commands

```bash
helm version
helm repo add <name> <url>
helm repo update
helm search repo <keyword>
helm install <release-name> <chart>
helm list
helm uninstall <release-name>
```

---

## Reference

* **Helm Documentation:** https://helm.sh/docs/
* **Helm GitHub:** https://github.com/helm/helm
* **Helm Charts:** https://helm.sh/docs/topics/charts/
