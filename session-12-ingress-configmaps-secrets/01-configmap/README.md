# ConfigMap — Decoupling Plain-Text Configuration from Container Images

## Why Do We Need ConfigMap?

### The Problem: Configuration Baked Into Docker Images
Imagine you write a Python app and hardcode inside it:
```python
LOG_LEVEL = "DEBUG"
PORT = 5000
DATABASE_HOST = "localhost"
```
You build a Docker image and push it to your registry. Now you want to deploy the same app to Production. In Production:
* `LOG_LEVEL` should be `INFO` (not `DEBUG`)
* `DATABASE_HOST` should be `prod-db.internal` (not `localhost`)

If configuration is baked into the image, you must **rebuild the Docker image every time a config value changes**. That violates the 12-Factor App principle:
> **Your code must be identical across all environments. Only the configuration changes.**

### The Solution: ConfigMap
A `ConfigMap` stores plain-text key-value pairs outside your container image. Your application reads them as environment variables or volume-mounted config files at runtime.

```text
WITHOUT ConfigMap:                    WITH ConfigMap:
--------------------                  --------------------
Image: v1 (LOG=DEBUG)                 Image: v1 (no hardcoded config)
Image: v2 (LOG=INFO)                       |
Image: v3 (PORT=8080)            ConfigMap: LOG=INFO, PORT=5000
                                       |
                                   Same image deployed everywhere!
```

---

## Important Points

* ConfigMaps are for **non-sensitive** data only (log levels, port numbers, feature flags, API base URLs).
* Never store passwords, tokens, or certificates in a ConfigMap.
* ConfigMaps can be consumed as **environment variables** (`envFrom`) or **mounted as files** inside a container.
* Updating a ConfigMap does NOT automatically restart your pods. Pods must be restarted to pick up new values (unless using a volume mount with live reload).
* ConfigMaps have a size limit of **1 MiB**.

---

## Real-World Use Cases
* Storing `LOG_LEVEL`, `ENVIRONMENT` (dev/staging/prod), `CACHE_TTL`, `MAX_CONNECTIONS` for a microservice.
* Mounting an entire Nginx `nginx.conf` file into a pod via a ConfigMap volume.
* Passing feature-flag toggles (`FEATURE_DARK_MODE: "true"`) without rebuilding images.

---

## Code

### configmap/app-config.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: yatri-app-config
  labels:
    app: yatri-backend
data:
  ENVIRONMENT: "production"
  LOG_LEVEL: "INFO"
  PORT: "5000"
  DEFAULT_CURRENCY: "INR"
  MAX_BOOKING_DAYS: "30"
```

### Apply and Inspect
```bash
kubectl apply -f configmap/app-config.yaml
kubectl get configmap yatri-app-config
kubectl describe configmap yatri-app-config
```

Expected Output:
```text
NAME               DATA   AGE
yatri-app-config   5      8s

Name:         yatri-app-config
Data
====
DEFAULT_CURRENCY:  INR
ENVIRONMENT:       production
LOG_LEVEL:         INFO
MAX_BOOKING_DAYS:  30
PORT:              5000
```

### Reading a ConfigMap Value Live
```bash
kubectl get configmap yatri-app-config -o jsonpath='{.data.LOG_LEVEL}'
```
Output:
```text
INFO
```

### Cleanup
```bash
kubectl delete configmap yatri-app-config
```
