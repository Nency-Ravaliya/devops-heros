# Session 14 - Kubernetes Troubleshooting

I worked through each failure by checking the resource status first, then using `describe`, events, and logs to find the reason. I kept separate folders for the small command exercises and for each broken example.

## Commands I practiced

```bash
kubectl get pods
kubectl get pods -o wide
kubectl describe pod <pod>
kubectl logs <pod>
kubectl logs <pod> --previous
kubectl exec <pod> -- <command>
kubectl get events --sort-by=.lastTimestamp
kubectl explain pod.spec.containers
kubectl top pods
```

The examples are in [`01-kubectl-get/`](01-kubectl-get/), [`02-kubectl-describe/`](02-kubectl-describe/), [`03-kubectl-logs/`](03-kubectl-logs/), [`04-kubectl-exec/`](04-kubectl-exec/), and [`05-events/`](05-events/).

## CrashLoopBackOff

The container printed `Something went wrong!` and exited with code 1. `kubectl logs --previous` and the last terminated state confirmed that the application was crashing after it started. I replaced the command with the fixed version and verified `1/1 Running` with zero restarts.

- [Diagnosis screenshot](screenshots/crashloop-diagnosis.png)
- [Fixed Pod screenshot](screenshots/crashloop-fixed.png)
- [Commands and YAML](06-crashloopbackoff/)

## ErrImagePull and ImagePullBackOff

The Pod used `nginx:this-image-does-not-exist`. Events showed both `ErrImagePull` and the later back-off message. After changing the image to `nginx:1.27`, the same Pod became ready.

- [Before and after screenshot](screenshots/imagepullbackoff-before-after.png)
- [Commands and YAML](07-imagepullbackoff/)

## Pending Pod

The Pod requested a node named `node-that-does-not-exist`. It stayed Pending with `PodScheduled: False`, and the scheduler event said the node did not match the selector. Removing that selector allowed the replacement Pod to run on Minikube.

- [Before and after screenshot](screenshots/pending-before-after.png)
- [Commands and YAML](08-pending-pods/)

## ContainerCreating

I watched a new `httpd:2.4` Pod while Kubernetes downloaded the image. It remained in `ContainerCreating` for several seconds, then became Running. The events showed the order: Scheduled, Pulling, Pulled, Created, Started. In this case it was a normal startup phase rather than a fault.

- [Startup investigation screenshot](screenshots/containercreating-investigation.png)

## Service, DNS, networking and configuration

The Service initially selected `app: web-ahsgdf`, while the Pods had `app: web`. That left the EndpointSlice empty. DNS and the HTTP request failed even though the Pods themselves were running. After correcting the selector, the EndpointSlice received two Pod IPs, the full Service name resolved, and the request returned HTTP 200.

- [Recovery screenshot](screenshots/service-dns-recovery.png)
- [Commands and YAML](09-service-dns-troubleshooting/)

The main lesson from these exercises was to avoid guessing from the status name alone. Events explained the image and scheduling problems, logs explained the crash, and labels plus EndpointSlices explained the Service problem.

The combined practice project is in [`mini-project/`](mini-project/).
