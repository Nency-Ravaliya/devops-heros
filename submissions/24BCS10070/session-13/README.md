# Session 13: Storage, HPA, and probes

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

The mini-project combines a PVC, two web replicas, a Service, startup/readiness/
liveness probes, CPU requests, and an HPA from 2 to 5 replicas at 50% requested CPU.
Read `01-kubernetes-volumes/README.md` for storage notes and the single-node RWO limitation.

```bash
minikube addons enable metrics-server
kubectl create namespace student13
kubectl -n student13 apply -f mini-project/
kubectl -n student13 rollout status deployment/storage-web
kubectl -n student13 get pvc,pods,hpa,svc
kubectl -n student13 exec deployment/storage-web -- sh -c 'echo "PENTA GUNA SAI KUMAR" > /data/student.txt'
kubectl -n student13 rollout restart deployment/storage-web
kubectl -n student13 rollout status deployment/storage-web
kubectl -n student13 exec deployment/storage-web -- cat /data/student.txt
kubectl -n student13 apply -f load-generator.yaml
kubectl -n student13 get hpa -w
kubectl -n student13 top pods
kubectl -n student13 describe hpa storage-web
kubectl -n student13 get pods
kubectl -n student13 delete -f load-generator.yaml
```

CPU needs time to populate. An unknown HPA target can mean missing metrics-server
or CPU requests. If one client does not generate enough CPU, run several load Pods;
do not claim scaling without seeing it. Scale-down normally waits through a stabilization window.
Startup protects slow initialization, readiness removes unhealthy Pods from traffic,
and liveness restarts a stuck container. Test a bad readiness path with a temporary
patch and inspect endpoints; restore the manifest afterwards.
Cleanup: `kubectl delete namespace student13` (also removes the claim).

## Verification

Manifest syntax checked; storage notes and mini-project files prepared.

PVC persistence, probe behavior and HPA scaling need a cluster with storage and metrics-server.
