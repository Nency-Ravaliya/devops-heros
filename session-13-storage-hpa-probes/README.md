# Session 13: Kubernetes Storage, HPA & Probes

Submission index for the Session 13 assignment. Each task lives in its own folder with a detailed README,
the manifests that were applied, and a `screenshots/` folder. All command output in the READMEs was copied
from real runs, and the screenshots are terminal captures of that output.

## Environment

| Item | Value |
| --- | --- |
| Cluster | Single-node **Minikube v1.39.0**, profile `session13` |
| Kubernetes | **v1.37.0** |
| Container runtime | containerd |
| Driver | Docker Desktop **29.8.2** (docker driver) |
| Metrics | `metrics-server` addon **v0.9.0** |
| Host | macOS arm64 |
| Node size | 4 CPU / 3000 MB |

The `session13` cluster was recreated once mid-session after the Docker Desktop data was wiped. Task 1 and
Task 2 output comes from the first `session13` cluster; the mini-project output comes from the second, which
was started with the same configuration.

## Repository layout

```text
session-13-storage-hpa-probes/
├── README.md                    # this index                                  [submission]
├── 01-kubernetes-volumes/       # Task 1: volume documentation + labs         [submission]
│   ├── README.md
│   ├── 01-emptydir.yaml
│   ├── 02-hostpath.yaml
│   ├── 03-static-pv-pvc.yaml
│   ├── 04-storageclass-dynamic.yaml
│   └── screenshots/             # 13 screenshots
├── 02-hpa-hands-on/             # Task 2: HPA hands-on                        [submission]
│   ├── README.md
│   ├── deployment.yaml
│   ├── hpa.yml
│   ├── load-generator.yaml
│   └── screenshots/             # 17 screenshots
├── mini-project/                # Task 3: mini project                        [submission]
│   ├── README.md                # instructor guide + "Execution Results"
│   ├── namespace.yaml  pvc.yaml  deployment.yaml  service.yaml  hpa.yaml
│   ├── load-generator.yaml
│   └── screenshots/             # 19 screenshots
├── 01-volumes/                  # lecture material (provided, unmodified)
├── 02-persistent-storage/       # lecture material (provided, unmodified)
├── 03-storageclass/             # lecture material (provided, unmodified)
├── 04-hpa/                      # lecture material (provided, unmodified)
├── 05-probes/                   # lecture material (provided, unmodified)
└── hpa/                         # lecture material (provided, unmodified)
```

## Deliverables checklist

| Deliverable | Where |
| --- | --- |
| Volume documentation | [01-kubernetes-volumes/README.md](01-kubernetes-volumes/README.md) (emptyDir, hostPath, PV, PVC, StorageClass, dynamic provisioning, with labs) |
| HPA YAML | [02-hpa-hands-on/hpa.yml](02-hpa-hands-on/hpa.yml), [mini-project/hpa.yaml](mini-project/hpa.yaml) |
| Load generator | [02-hpa-hands-on/load-generator.yaml](02-hpa-hands-on/load-generator.yaml), [mini-project/load-generator.yaml](mini-project/load-generator.yaml) |
| HPA output (`get hpa`, `get pods`, `top pods`, `describe hpa`) | [02-hpa-hands-on/README.md](02-hpa-hands-on/README.md): Steps 3-4 (configure/verify), Steps 5-6 (load and scale-up), Step 7 (scale-down), Step 8 (full watch timeline) |
| Screenshots | [01-kubernetes-volumes/screenshots/](01-kubernetes-volumes/screenshots/) (13), [02-hpa-hands-on/screenshots/](02-hpa-hands-on/screenshots/) (17), [mini-project/screenshots/](mini-project/screenshots/) (19) |
| Mini-project implementation | [mini-project/](mini-project/) manifests |
| README documentation | This file, the per-task READMEs, and [mini-project/README.md#execution-results](mini-project/README.md#execution-results) |

## Task summaries

### Task 1: Kubernetes Volumes ([01-kubernetes-volumes/](01-kubernetes-volumes/))

- **emptyDir:** two containers in one Pod share the same directory; data survives a container restart but
  is wiped when the Pod is deleted.
- **hostPath:** a file written from the Pod is visible on the node and survives Pod deletion, but is tied
  to one node (documented as unsuitable for production).
- **Static PV/PVC:** a 500Mi claim bound to a whole 1Gi PV; data persisted across Pod deletion; with
  `Retain`, deleting the PVC left the PV `Released` and the file still on the node.
- **StorageClass / dynamic provisioning:** a custom StorageClass on `k8s.io/minikube-hostpath` created a
  PV `pvc-<uid>` sized exactly to the 200Mi request; with `Delete`, removing the PVC removed the PV too.
- Ends with comparison tables (volume types, access modes, reclaim policies, PV lifecycle, static vs dynamic).

### Task 2: HPA hands-on ([02-hpa-hands-on/](02-hpa-hands-on/))

- App: `hpa-demo` (nginx, CPU request 100m). HPA from `hpa.yml`: min 1, max 5, target 50% CPU,
  scale-down stabilization window 60s.
- 1 load generator: CPU reached **75%**, HPA scaled **1 -> 2** (`ceil(1 x 75/50) = 2`).
- 4 load generators: CPU reached **101%**, HPA scaled **2 -> 5** in one step (`ceil(2 x 101/50) = 5`),
  then held at `maxReplicas` while utilization stayed around 87%.
- Load removed: CPU dropped to 0%, and after the **60s** stabilization window the HPA went **5 -> 1**.
- All `kubectl get hpa / get pods / top pods / describe hpa` output and the full `-w` timeline are in the README.

### Task 3: Mini project ([mini-project/](mini-project/))

- Namespace `production-webapp`; PVC `web-data` (500Mi, RWO, default `standard` class) mounted at `/data`.
- Deployment `web-app` (nginx, 2 replicas, CPU request 100m / limit 200m, `Recreate` strategy) with
  startup, readiness and liveness HTTP probes; ClusterIP Service `web-service`.
- HPA `web-app-hpa`: min 2, max 5, target 50% CPU; load generated by an ApacheBench (`ab`) Deployment
  (`httpd:2.4-alpine`, `ab -k -c 20` against the Service ClusterIP, 500m CPU limit).
- Observed results:
  - PVC `web-data` bound dynamically (500Mi, `standard` class).
  - Both pods share the volume: a file written from one pod was readable from the other, and from a
    replacement pod after a pod was deleted.
  - `web-service` returned HTTP 200 via `kubectl port-forward`.
  - 1 `ab` generator: CPU **44%/50%**, no scale-up.
  - 3 generators: CPU **191%/50%**, HPA scaled **2 -> 4 -> 5** (nginx pods pinned at their 200m CPU limit).
  - Load stopped: CPU fell to ~1%, but replicas held at 5 for the default **300s** scale-down stabilization
    window (`ScaleDownStabilized`), then went **5 -> 2**.
  - The optional bonus probe challenges were not performed.
- Full output and screenshots: [mini-project/README.md#execution-results](mini-project/README.md#execution-results).

## Issues encountered and fixes

1. **DNS flood from the load generator.** The busybox `wget` loop against `http://hpa-demo-service` did a
   DNS lookup per request; with 4 generators CoreDNS was flooded (`wget: bad address`), load collapsed to
   15% and the HPA scaled back down. Fix: target the ClusterIP through the injected env var
   `$<SVC>_SERVICE_HOST` (e.g. `$HPA_DEMO_SERVICE_SERVICE_HOST`), which skips DNS entirely.
2. **Process-per-request generator saturated the node.** The busybox `wget` loop forks a new process per
   request and, during the mini-project, consumed enough CPU to saturate the small node. Fix: the
   mini-project generator uses ApacheBench (`httpd:2.4-alpine`, `ab -k -c 20`), a single process with
   keep-alive connections, capped with a **500m** CPU limit.
3. **HPA shows `<unknown>`.** Brand-new pods have no metrics-server sample yet, so the HPA reports
   `cpu: <unknown>/50%` with `FailedGetResourceMetric` events. It resolves after one or two scrape cycles;
   a CPU request on the container is required for it to resolve at all.
4. **Two Minikube clusters at once starved the host.** Running a second Minikube cluster concurrently on an
   8 GB Mac caused API server TLS handshake timeouts and metrics-server restarts. Fix: run one cluster at
   a time.
5. **hostpath provisioner is node-local.** Minikube's `k8s.io/minikube-hostpath` provisioner stores data
   on the node where the pod runs, so a pod rescheduled to another node would not see it. A single-node
   cluster was used so the persistence tests are meaningful.

## How to reproduce

```bash
minikube start -p session13 --driver=docker --cpus=4 --memory=3000 --addons=metrics-server
kubectl top nodes        # wait until metrics are available

# Task 1: apply one manifest at a time and follow the labs in the README
cd 01-kubernetes-volumes
kubectl apply -f 01-emptydir.yaml
kubectl apply -f 02-hostpath.yaml
kubectl apply -f 03-static-pv-pvc.yaml
kubectl apply -f 04-storageclass-dynamic.yaml

# Task 2
cd ../02-hpa-hands-on
kubectl apply -f deployment.yaml
kubectl apply -f hpa.yml
kubectl apply -f load-generator.yaml
kubectl scale deployment load-generator --replicas=4
kubectl get hpa -w        # in a second terminal; also: kubectl get pods, kubectl top pods, kubectl describe hpa hpa-demo
kubectl delete deployment load-generator

# Task 3
cd ../mini-project
kubectl apply -f namespace.yaml
kubectl apply -f pvc.yaml -f deployment.yaml -f service.yaml -f hpa.yaml
kubectl apply -f load-generator.yaml
kubectl get hpa -n production-webapp -w
```

Each folder README has its own cleanup section for removing individual resources.

## Cleanup

```bash
minikube delete -p session13
```
