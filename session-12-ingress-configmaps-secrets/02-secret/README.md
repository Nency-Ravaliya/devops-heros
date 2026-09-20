# Secret — Protecting Sensitive Credentials in Kubernetes

## Why Do We Need Secrets?

### The Problem: Passwords Stored in Plain Text or Baked into Images
Teams with poor security practices often commit credentials directly into code or Docker images:
```python
# BAD: Password baked into code and leaked in git history
DB_PASSWORD = "superSecretPwd123"
```
Or worse, stored in a ConfigMap in plain text, visible to every developer with `kubectl get` access.

In a real enterprise breach in 2021, a team hardcoded an AWS key into a `Dockerfile` committed to a public GitHub repository. The key was found by a bot within 7 minutes, leading to thousands of dollars of cloud resource abuse.

### The Solution: Kubernetes Secret
A `Secret` is a dedicated Kubernetes object for sensitive data. Values are stored as **Base64-encoded strings**.

```text
Raw value:    secretpassword
Base64 value: c2VjcmV0cGFzc3dvcmQ=

echo -n "secretpassword" | base64
# -> c2VjcmV0cGFzc3dvcmQ=

echo -n "c2VjcmV0cGFzc3dvcmQ=" | base64 --decode
# -> secretpassword
```

---

## Important Points

* **Base64 is NOT encryption.** It is encoding. Anyone who can run `kubectl get secret` and has `RBAC` access can decode it. Secrets rely on Kubernetes RBAC for access control.
* For production-grade secret management, use **external secret managers** (AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager) integrated into Kubernetes via tools like `External Secrets Operator`.
* Always use `echo -n` when base64-encoding values. Without `-n`, a trailing newline character gets encoded, causing silent authentication failures.
* Secrets can be injected as environment variables (`secretRef`) or as **files mounted into a volume** (e.g., TLS private key files).
* Kubernetes stores Secrets in `etcd`. Enable **encryption at rest** for `etcd` in production clusters (a mandatory CIS Benchmark requirement).

---

## Real-World Use Cases
* Database credentials (`POSTGRES_USER`, `POSTGRES_PASSWORD`).
* API keys and OAuth client secrets for third-party integrations.
* TLS certificate (`tls.crt`) and private key (`tls.key`) for HTTPS termination.
* Docker Hub / ECR image pull credentials (`imagePullSecrets`).

---

## Code

### secret/db-secret.yaml
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: yatri-db-secret
  labels:
    app: yatri-backend
type: Opaque
data:
  # Base64 for 'yatri_admin' -> echo -n "yatri_admin" | base64
  POSTGRES_USER: eWF0cmlfYWRtaW4=
  # Base64 for 'secretpassword' -> echo -n "secretpassword" | base64
  POSTGRES_PASSWORD: c2VjcmV0cGFzc3dvcmQ=
  # Base64 for 'yatri_production_db' -> echo -n "yatri_production_db" | base64
  POSTGRES_DB: eWF0cmlfcHJvZHVjdGlvbl9kYg==
```

### Generating Base64 Values Yourself
```bash
echo -n "yatri_admin" | base64
# Output: eWF0cmlfYWRtaW4=

echo -n "secretpassword" | base64
# Output: c2VjcmV0cGFzc3dvcmQ=

echo -n "yatri_production_db" | base64
# Output: eWF0cmlfcHJvZHVjdGlvbl9kYg==
```

### Apply and Inspect
```bash
kubectl apply -f secret/db-secret.yaml
kubectl get secret yatri-db-secret
```

Expected Output:
```text
NAME               TYPE     DATA   AGE
yatri-db-secret    Opaque   3      5s
```

Notice: `kubectl describe secret` masks all values with `[3 bytes]` to prevent accidental exposure.

### Decode a Secret Value (for debugging)
```bash
kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
```

Output:
```text
secretpassword
```

### Cleanup
```bash
kubectl delete secret yatri-db-secret
```
