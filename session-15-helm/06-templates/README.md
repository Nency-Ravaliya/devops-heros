# Templates

```yaml
# templates/deployment.yaml
spec:
  replicas: {{ .Values.replicaCount }}
```

Templates are Kubernetes YAML files with Go template variables inside `{{ }}`.

---

## 1. What is a Template?

A template is a regular Kubernetes YAML file with variables injected using `{{ }}`.

```text
Without template:   replicas: 1       (hardcoded)
With template:      replicas: {{ .Values.replicaCount }}  (flexible)
```

---

## 2. Create the Chart Directory

```bash
mkdir -p template-demo/templates
```

---

## 3. Create values.yaml

`template-demo/values.yaml`:

```yaml
replicaCount: 2
image:
  repository: nginx
  tag: latest
service:
  port: 80
```

---

## 4. Create the Deployment Template

`template-demo/templates/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-app
  labels:
    app: {{ .Release.Name }}
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

---

## 5. Go Template Variables

```text
{{ .Release.Name }}         = the release name you type at install
{{ .Values.replicaCount }}  = value from values.yaml
{{ .Chart.Name }}           = name from Chart.yaml
{{ .Chart.Version }}        = version from Chart.yaml
```

---

## 6. Conditional Templates

```yaml
{{- if .Values.service.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-svc
spec:
  ports:
    - port: {{ .Values.service.port }}
{{- end }}
```

If `service.enabled` is `false` in values.yaml, this entire block is not generated.

---

## 7. Render Templates Locally

```bash
helm template my-release template-demo
```

Expected output (partial):

```text
---
# Source: template-demo/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-release-app
spec:
  replicas: 2
```

Notice `{{ .Release.Name }}` became `my-release`.  
Notice `{{ .Values.replicaCount }}` became `2`.

---

## 8. Render With Different Values

```bash
helm template my-release template-demo --set replicaCount=5 | grep "replicas:"
```

Expected output:

```text
  replicas: 5
```

---

## Key Learning

```text
{{ .Values.key }}    = read from values.yaml
{{ .Release.Name }}  = the release name
{{ .Chart.Name }}    = the chart name
{{- if ... }}        = conditional (omits block if false)
{{- end }}           = closes the if block
```

---

## Reference

* **Go templating in Helm:** https://helm.sh/docs/chart_template_guide/
