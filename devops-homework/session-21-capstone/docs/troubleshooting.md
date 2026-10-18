# Troubleshooting runbook

Start with observed symptoms and preserve the relevant events/logs before changing anything.

```bash
kubectl get pods,svc,ingress,hpa,pvc -n queuedesk
kubectl get events -n queuedesk --sort-by=.lastTimestamp
kubectl logs -n queuedesk deployment/queuedesk-backend --tail=100
helm status queuedesk -n queuedesk
helm history queuedesk -n queuedesk
```

| Symptom | Inspect | Likely fix |
|---|---|---|
| ImagePullBackOff | `kubectl describe pod <pod> -n queuedesk` | Use the published full SHA, correct lower-case GHCR name and public package visibility or a valid pull Secret |
| Backend Running but not Ready | `/ready`, backend logs, migration Job | Confirm the Secret, PostgreSQL Service and completed Alembic Job; do not restart healthy Pods repeatedly |
| Migration Job fails | `kubectl logs job/queuedesk-migrate-<revision> -n queuedesk` | Fix database connection/schema migration; the Job retries transient startup failures |
| PVC Pending | `kubectl describe pvc <name> -n queuedesk` and EBS CSI controller logs | Check `gp3`, the CSI IAM role, add-on state and node availability; WaitForFirstConsumer waits until a Pod is scheduled |
| CrashLoopBackOff | Pod description; `kubectl logs <pod> -n queuedesk --previous` | Fix the logged application/configuration issue; check memory limits for OOMKilled |
| Empty Service endpoints | `kubectl get endpointslices -n queuedesk -l kubernetes.io/service-name=queuedesk-backend` | Match Service selectors to Pod labels and resolve failing readiness probes |
| ALB address missing | Ingress events; controller logs in kube-system | Check controller IAM trust/policy, subnet tags, region/VPC and controller readiness |
| ALB returns 503 | Target-group health, Services and readiness | Confirm backend `/health` and frontend `/nginx-health` target checks; frontend Service overrides the Ingress health path |
| Prometheus target absent | ServiceMonitor and Prometheus selectors | Check `release: monitoring`, namespace discovery and Service labels; install CRDs before the app |
| HPA shows unknown | `kubectl top pods`, Metrics Server logs | Fix the Metrics API and verify CPU resource requests |
| CI deploy times out | EKS API CIDRs, AWS role, EKS access entry | Ensure the runner's egress is permitted and OIDC subject uses the `production` environment |
| Terraform destroy blocked | ALBs, ENIs, EBS resources | Delete Kubernetes-created resources while controllers and EKS are still running, wait, retry |

## Isolated failure lab: image

This lab uses `queuedesk-lab` and does not overwrite the application release.

```bash
kubectl apply -f troubleshooting/broken-image.yaml
kubectl get pods -n queuedesk-lab
kubectl describe deployment image-lab -n queuedesk-lab
kubectl describe pods -n queuedesk-lab -l app=image-lab
kubectl get events -n queuedesk-lab --sort-by=.lastTimestamp
```

Find the nonexistent image tag and `ErrImagePull`/`ImagePullBackOff`. Repair and verify:

```bash
kubectl set image deployment/image-lab web=nginxinc/nginx-unprivileged:stable-alpine -n queuedesk-lab
kubectl rollout status deployment/image-lab -n queuedesk-lab
kubectl delete -f troubleshooting/broken-image.yaml
```

Deleting this manifest also removes its lab namespace; run the next lab independently after cleanup.

## Isolated failure lab: Service

```bash
kubectl apply -f troubleshooting/broken-service.yaml
kubectl rollout status deployment/service-lab -n queuedesk-lab
kubectl get pods --show-labels -n queuedesk-lab
kubectl describe svc service-lab -n queuedesk-lab
kubectl get endpointslices -n queuedesk-lab -l kubernetes.io/service-name=service-lab
```

The Service selects `app=wrong-label`, but the Pod has `app=service-lab`, so there are no endpoints. Repair the selector:

```bash
kubectl patch svc service-lab -n queuedesk-lab -p '{"spec":{"selector":{"app":"service-lab"}}}'
kubectl get endpointslices -n queuedesk-lab -l kubernetes.io/service-name=service-lab
kubectl port-forward svc/service-lab 8088:80 -n queuedesk-lab
curl http://localhost:8088
# Stop port-forward, then clean up:
kubectl delete -f troubleshooting/broken-service.yaml
```

## Trivy blocks a release

Read the package name, installed version, fixed version and CVE advisory in the report. Update the affected dependency/base image, regenerate locks where appropriate, rebuild, and rerun the scans. A CVE with no fix still fails this pipeline. Do not silently lower severity, add `continue-on-error`, or enable `ignore-unfixed` to make the release green. Capture the actual report and explain whether the finding concerns an OS package or an application dependency.

The original backend image produced 44 HIGH findings in Debian OS packages, including ncurses (CVE-2025-69720); the Python dependency section had no HIGH/CRITICAL findings. Switching to the Python 3.12 Alpine base removed those affected OS packages, and the replacement image passed the same local Trivy gate with zero HIGH/CRITICAL findings on October 17, 2026. The workflow still blocks publication if either image fails its scan.
