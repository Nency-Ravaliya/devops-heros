# `Chart.yaml`

```yaml
apiVersion: v2
name: my-app
version: 0.1.0
```

This file tells Helm what the chart is and who made it.

---

## 1. Required Fields

Create `Chart.yaml`:

```yaml
apiVersion: v2
name: my-app
description: A learning chart
type: application
version: 0.1.0
appVersion: "1.0"
```

* `apiVersion: v2` - required for Helm 3
* `name` - the chart name
* `version` - the chart's own version (use Semantic Versioning)
* `appVersion` - the version of the app this chart deploys

---

## 2. version vs appVersion

```text
version    = version of the Helm chart itself
             Changes when you change the chart files

appVersion = version of the application being deployed
             Example: "2.3.1" (your Docker image tag)
```

Example:

```yaml
version: 0.2.0       # chart changed (new template)
appVersion: "1.5.0"  # app version (Docker image tag)
```

---

## 3. Add More Metadata

```yaml
apiVersion: v2
name: my-app
description: A learning chart
type: application
version: 0.1.0
appVersion: "1.0"
keywords:
  - nginx
  - web
home: https://example.com
maintainers:
  - name: Nency
    email: nency@example.com
```

---

## 4. Chart Type

```text
type: application   = deploys something to the cluster (default)
type: library       = shared templates, not deployed directly
```

For almost all cases, use `application`.

---

## 5. Verify Your Chart.yaml

Run:

```bash
helm lint my-app/
```

Expected output:

```text
==> Linting my-app/
1 chart(s) linted, 0 chart(s) failed
```

If `Chart.yaml` has errors:

```text
[ERROR] Chart.yaml: apiVersion is required
```

---

## 6. Use Chart Metadata in Templates

Inside a template file, you can reference Chart.yaml values:

```yaml
# templates/deployment.yaml
metadata:
  labels:
    chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
    app-version: "{{ .Chart.AppVersion }}"
```

* `{{ .Chart.Name }}` = `my-app`
* `{{ .Chart.Version }}` = `0.1.0`
* `{{ .Chart.AppVersion }}` = `1.0`

---

## Key Learning

```text
Chart.yaml fields:
  apiVersion  = must be v2 for Helm 3
  name        = chart name
  version     = chart version (changes when templates change)
  appVersion  = application version (matches Docker image tag)
```

---

## Reference

* **Chart.yaml fields:** https://helm.sh/docs/topics/charts/#the-chartyaml-file
