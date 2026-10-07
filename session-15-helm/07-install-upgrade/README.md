# Install and Upgrade

```bash
helm install my-app ./my-chart
helm upgrade my-app ./my-chart
```

These two commands manage the full lifecycle of a release.

---

## 1. Create the Chart

```bash
mkdir -p app-chart/templates
```

`app-chart/Chart.yaml`:

```yaml
apiVersion: v2
name: app-chart
description: Install and upgrade demo
type: application
version: 0.1.0
appVersion: "1.0"
```

`app-chart/values.yaml`:

```yaml
replicaCount: 1
image:
  repository: nginx
  tag: "1.24"
```

`app-chart/templates/deployment.yaml`:

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
```

---

## 2. Install the Chart

```bash
helm install web-app ./app-chart
```

Expected output:

```text
NAME: web-app
LAST DEPLOYED: ...
NAMESPACE: default
STATUS: deployed
REVISION: 1
```

Check the deployment:

```bash
kubectl get pods
```

Expected output:

```text
NAME                        READY   STATUS    RESTARTS   AGE
web-app-app-xxxx            1/1     Running   0          10s
```

---

## 3. Check Release History

```bash
helm list
```

Expected output:

```text
NAME      NAMESPACE   REVISION   STATUS     CHART
web-app   default     1          deployed   app-chart-0.1.0
```

---

## 4. Upgrade with a New Value

Upgrade the release with 3 replicas:

```bash
helm upgrade web-app ./app-chart --set replicaCount=3
```

Expected output:

```text
Release "web-app" has been upgraded. Happy Helming!
NAME: web-app
LAST DEPLOYED: ...
STATUS: deployed
REVISION: 2
```

---

## 5. Check Pods After Upgrade

```bash
kubectl get pods
```

Expected output:

```text
NAME                        READY   STATUS    RESTARTS
web-app-app-aaaa            1/1     Running   0
web-app-app-bbbb            1/1     Running   0
web-app-app-cccc            1/1     Running   0
```

Three pods are now running.

---

## 6. install vs upgrade vs upgrade --install

```text
helm install    = fails if release already exists
helm upgrade    = fails if release does not exist
helm upgrade --install = installs if new, upgrades if exists
```

The safest command for CI/CD pipelines:

```bash
helm upgrade --install web-app ./app-chart
```

---

## 7. Uninstall

```bash
helm uninstall web-app
```

Expected output:

```text
release "web-app" uninstalled
```

---

## Key Learning

```text
REVISION: 1  = first install
REVISION: 2  = after first upgrade
REVISION: 3  = after second upgrade
```

Every install or upgrade creates a new revision. This enables rollback.

---

## Reference

* **Helm install:** https://helm.sh/docs/helm/helm_install/
* **Helm upgrade:** https://helm.sh/docs/helm/helm_upgrade/
