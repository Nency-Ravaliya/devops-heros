# Session 14 - Kubernetes Troubleshooting

| | |
|---|---|
| **Student** | Antara Utane |
| **Enrollment No.** | 24BCS10106 |
| **Session** | 14 - Kubernetes Troubleshooting |
| **Cluster** | kind `kind-devops-heros` (1 control-plane + 2 workers, Kubernetes v1.37.0, CNI kindnet, metrics-server) |

## Task checklist

- [x] **Task 1 - kubectl hands-on**: `get` (`-o wide`, `-o yaml`, jsonpath, `-l`, `--show-labels`), `describe`, `logs` (`-f`, `--previous`, `-c`, `--all-containers`, `--tail`, `--timestamps`), `exec`, `kubectl events` (`--for`, `--types`) and `get events --sort-by`, `explain`, `top` -> [01-kubectl-commands/README.md](01-kubectl-commands/README.md)
- [x] **Task 2 - Reproduce and troubleshoot**, each with problem, investigation, root cause, fix and verification -> [02-troubleshooting-scenarios/README.md](02-troubleshooting-scenarios/README.md)
  - [x] CrashLoopBackOff (course `scenario-1-crashloop` + `06-crashloopbackoff`)
  - [x] ImagePullBackOff / ErrImagePull (course `scenario-2-imagepull`)
  - [x] Pending: impossible resource requests (course `scenario-3-pending`) and a nodeSelector that matches nothing (course `08-pending-pods`)
  - [x] ContainerCreating: missing ConfigMap and Secret volume
  - [x] Service connectivity: selector mismatch and targetPort mismatch, giving empty endpoints
  - [x] DNS: wrong service name and namespace (course `scenario-4-dns-failure`), with CoreDNS checks
  - [x] Pod networking: default-deny NetworkPolicy. I verified that kindnet `v20260820` **does** enforce NetworkPolicy
  - [x] Configuration: wrong ConfigMap key (CreateContainerConfigError), then an invalid env value
  - [x] Bonus: OOMKilled (course `scenario-5-oomkilled`)
- [x] **Task 3 - Mini project** (course `mini-project/` spec): deploy, check, broken image pod, the 5 questions, Service selector challenge, troubleshooting table and the 10 README questions -> [03-mini-project/README.md](03-mini-project/README.md)

## Folder layout

```text
Antara-24BCS10106/
├── README.md
├── 01-kubectl-commands/
│   ├── README.md
│   └── debug-demo.yaml                 # web Deployment, multi-container pod, restarting pod
├── 02-troubleshooting-scenarios/
│   ├── README.md
│   ├── 01-crashloopbackoff/fixed.yaml
│   ├── 03-pending/fixed-resources.yaml, fixed-nodeselector.yaml
│   ├── 04-containercreating/broken.yaml, fix-configmap-secret.yaml
│   ├── 05-service-connectivity/app.yaml, broken-service.yaml, fixed-service.yaml
│   ├── 06-dns/postgres-db.yaml, dns-test-pod.yaml, fixed.yaml
│   ├── 07-network-policy/deny-all.yaml, allow-client.yaml
│   ├── 08-config-issue/configmap.yaml, broken.yaml, fixed.yaml
│   └── 09-oomkilled/fixed.yaml
└── 03-mini-project/
    ├── README.md
    ├── service-wrong-selector.yaml
    └── fixed-pod.yaml
```

When a scenario's broken manifest comes from the course, it is applied straight from the course folder and is not copied here.

## Notes

- **Shared cluster:** everything ran in my namespaces `s14` (Tasks 1 and 2) and `s14-mini` (Task 3). The course YAMLs have no namespace, so I applied them with `-n`. Both namespaces were deleted at the end.
- **All outputs are real**, copied from the terminal. Long outputs are cut and marked with `...`. In a few places I re-broke a scenario to get a cleaner capture, and the README says so where that happened.
- **Findings beyond the course material:**
  1. On this v1.37 cluster, a crash-looping pod's STATUS alternates between `Error` and `CrashLoopBackOff`. During the back-off, `kubectl logs --previous` can fail, because the "current" container is already the dead one.
  2. The course's `09-service-dns-troubleshooting/dns-test-pod.yaml` image (`registry.k8s.io/e2e-test-images/dnsutils:1.3`) no longer exists and ends in ImagePullBackOff. I used busybox instead.
