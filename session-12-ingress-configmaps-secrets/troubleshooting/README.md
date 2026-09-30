# Troubleshooting: Secret Base64 Values

## Problem

A Secret can be accepted by Kubernetes but inject the wrong value when `data` contains malformed or incorrectly encoded Base64.

## Investigation

```bash
kubectl get secret yatri-db-secret
kubectl describe secret yatri-db-secret
kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
kubectl exec deployment/yatri-backend -- printenv POSTGRES_DB POSTGRES_USER
```

`kubectl describe` hides values, so decoding the selected key or verifying it inside the target container distinguishes an encoding issue from a missing environment reference.

## Root cause and fix

The unsafe approach is manually encoding values and accidentally including a newline. Prefer `stringData` so Kubernetes performs the encoding:

```yaml
stringData:
  POSTGRES_USER: yatri_user
  POSTGRES_PASSWORD: demonstration-only
```

After applying the corrected manifest, restart the Deployment because existing container environment variables do not update in place:

```bash
kubectl apply -f 04-full-demo/secret.yaml
kubectl rollout restart deployment/yatri-backend
kubectl rollout status deployment/yatri-backend
```

The successful ConfigMap and Secret verification is shown in [`../screenshots/configmap-secret.png`](../screenshots/configmap-secret.png). The before/after terminal screenshot for this isolated failure remains to be captured.
