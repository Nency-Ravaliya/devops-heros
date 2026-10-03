# Chart Structure

```text
my-chart/
  Chart.yaml        <-- who is this chart?
  values.yaml       <-- what are the defaults?
  templates/        <-- what does it create?
    deployment.yaml
    service.yaml
    _helpers.tpl    <-- reusable template snippets
    NOTES.txt       <-- message shown after install
```

---

## 1. Create the Example Chart

```bash
mkdir -p simple-chart/templates
```

---

## 2. Chart.yaml

Create `simple-chart/Chart.yaml`:

```yaml
apiVersion: v2
name: simple-chart
description: A simple Helm chart example
type: application
version: 0.1.0
appVersion: "1.0"
```

* `version`: the version of this chart itself
* `appVersion`: the version of the application inside

---

## 3. values.yaml

Create `simple-chart/values.yaml`:

```yaml
replicaCount: 1
image:
  repository: nginx
  tag: latest
service:
  port: 80
```

These are the default values. You can override them at install time.

---

## 4. templates/deployment.yaml

Create `simple-chart/templates/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-app
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
        - name: app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: {{ .Values.service.port }}
```

* `{{ .Release.Name }}` = the name you give at `helm install`
* `{{ .Values.replicaCount }}` = value from `values.yaml`

---

## 5. templates/service.yaml

Create `simple-chart/templates/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-svc
spec:
  selector:
    app: {{ .Release.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
```

---

## 6. Render the Chart Locally

```bash
helm template my-release simple-chart
```

Expected output (partial):

```text
---
# Source: simple-chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-release-app
spec:
  replicas: 1
...
```

Notice `my-release-app` - Helm replaced `{{ .Release.Name }}` with `my-release`.

---

## 7. Install the Chart

```bash
helm install my-release simple-chart
```

Check:

```bash
kubectl get pods
kubectl get services
```

---

## Clean Up

```bash
helm uninstall my-release
```

---

## Key Learning

```text
Chart.yaml    = chart metadata (name, version)
values.yaml   = default values for templates
templates/    = Kubernetes YAML with {{ variables }}
```

---

## Reference

* **Chart file structure:** https://helm.sh/docs/topics/charts/#the-chart-file-structure
