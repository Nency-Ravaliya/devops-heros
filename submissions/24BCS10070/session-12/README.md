# Session 12: ConfigMaps, Secrets, and Ingress

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

```bash
minikube addons enable ingress
kubectl create namespace student12
kubectl -n student12 apply -f configmap.yaml -f secret.example.yaml
kubectl -n student12 apply -f deployment.yaml -f service.yaml -f ingress.yaml
kubectl -n student12 rollout status deployment/config-web
kubectl -n student12 exec deployment/config-web -- printenv COURSE ENVIRONMENT
kubectl -n student12 exec deployment/config-web -- sh -c 'test "$DEMO_VALUE" = "not-a-real-password" && echo "dummy value matches"'
kubectl -n student12 get ingress,svc,endpointslices
curl -H 'Host: student12.local' http://$(minikube ip)/
```

On platforms where the Minikube node IP is not reachable, use the controller's
documented tunnel or port-forward procedure. `secret.example.yaml` contains only
a public dummy value. Base64 is reversible encoding; use RBAC, encryption at rest,
and an external secret manager for real credentials.

Ingress is an API object describing HTTP routing rules. An Ingress Controller is
the running implementation that watches rules and configures a proxy or load balancer.
A rule alone does not forward traffic. Examples include ingress-nginx and Traefik;
the ingressClassName must match the installed controller. ConfigMaps hold ordinary
configuration and Secrets hold sensitive configuration, with different handling expectations.

See `troubleshooting.md` for investigation and correction steps.
Cleanup: `kubectl delete namespace student12`.

## Verification

Manifest syntax checked; public dummy Secret supplied.

Config injection, Ingress routing and before/after troubleshooting output need a cluster.
