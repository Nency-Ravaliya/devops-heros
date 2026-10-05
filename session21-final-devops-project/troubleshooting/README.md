# Troubleshooting exercise

I kept two deliberate failures in this folder.

## Broken image

`broken-image.yaml` uses an image tag that does not exist. I diagnose it with:

```bash
kubectl get pods
kubectl describe pod <pod>
kubectl get events --sort-by=.lastTimestamp
```

The important event is the registry pull failure, which leads to `ErrImagePull` and then `ImagePullBackOff`. The fix is to use a published tag and reapply the workload.

## Broken Service

`broken-service.yaml` intentionally uses a selector that does not match the application Pods. The Service exists but its EndpointSlice is empty.

```bash
kubectl get service,endpointslice
kubectl get pods --show-labels
kubectl describe service <service>
```

I fix the selector so it matches the Pod label, wait for endpoints to appear, and then repeat the HTTP request. This separates a Service-routing problem from an application crash.
