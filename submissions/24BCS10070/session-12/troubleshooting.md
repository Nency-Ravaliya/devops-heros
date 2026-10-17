# Secret base64 exercise and routing checks

The course troubleshooting note demonstrates confusing base64 with encryption.
`data` requires base64 strings; `stringData` accepts plain text and the API encodes it.
Our example uses stringData with a clearly dummy value. Never add real passwords to Git.

```bash
# Before: invalid base64 should be rejected by the API server.
kubectl -n student12 create secret generic invalid --from-literal=x=dummy --dry-run=client -o yaml
# To reproduce the error, use data: {x: "not valid base64!"} in a disposable manifest.
kubectl -n student12 apply -f secret.example.yaml
kubectl -n student12 describe pod -l app=config-web
kubectl -n student12 exec deployment/config-web -- sh -c 'test "$DEMO_VALUE" = "not-a-real-password" && echo "dummy value matches"'
```

If a Pod reports CreateContainerConfigError, describe it and check the referenced
Secret/ConfigMap name and key. Fix the reference, then restart the Deployment if
needed. Environment variables do not refresh automatically when a Secret changes.
For an Ingress 503, inspect `kubectl get endpointslices`, Pod readiness, selectors,
Service targetPort, and controller logs. For 404, verify Host and path matching.
Save before/after server output in `evidence/` when running these exercises.
