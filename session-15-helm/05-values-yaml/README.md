# `values.yaml`

```yaml
replicaCount: 1
image:
  repository: nginx
  tag: latest
```

`values.yaml` holds the default configuration for a chart.

---

## 1. Why values.yaml?

Without values.yaml, every configuration is hardcoded inside templates:

```yaml
# templates/deployment.yaml
replicas: 1                   # hardcoded
image: nginx:latest           # hardcoded
```

With values.yaml, the template becomes flexible:

```yaml
# templates/deployment.yaml
replicas: {{ .Values.replicaCount }}
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

---

## 2. Create values.yaml

```yaml
replicaCount: 1

image:
  repository: nginx
  tag: latest

service:
  port: 80

app:
  name: demo-app
```

---

## 3. Use Values in Templates

```yaml
# templates/deployment.yaml
metadata:
  name: {{ .Values.app.name }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
        - name: app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

---

## 4. Override Values at Install Time

**Option A: Override with --set flag**

```bash
helm install my-app ./chart --set replicaCount=3
```

**Option B: Override with a separate values file**

Create `values-prod.yaml`:

```yaml
replicaCount: 5
image:
  tag: v2.0.0
```

Install using it:

```bash
helm install my-app ./chart -f values-prod.yaml
```

---

## 5. Check What Values Will Be Used

Render templates and check:

```bash
helm template my-app ./chart | grep "replicas:"
```

Expected output:

```text
  replicas: 1
```

Now with override:

```bash
helm template my-app ./chart --set replicaCount=3 | grep "replicas:"
```

Expected output:

```text
  replicas: 3
```

---

## 6. Priority of Values

```text
Lowest priority   -->   Highest priority

values.yaml  ->  -f file  ->  --set flag
```

`--set` always wins.

---

## Key Learning

```text
values.yaml = the default configuration
-f file     = environment-specific overrides (dev, prod)
--set       = quick one-off overrides (avoid in production)
```

---

## Reference

* **Values and templates:** https://helm.sh/docs/chart_template_guide/values_files/
