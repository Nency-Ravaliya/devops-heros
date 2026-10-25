# Session 15 – Helm

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123  
**Environment:** Helm v4.3.0 against my kind v0.33.0 cluster `kushal-lab` (Kubernetes v1.37.0, 1 control-plane + 2 workers) on Docker Desktop 29.0.1, macOS / Apple Silicon – the same cluster as sessions 9–12. Everything was installed into one namespace, `s15-helm` (`export HELM_NAMESPACE=s15-helm` in [`scripts/lib.sh`](scripts/lib.sh)), so my releases never mixed with anything else on the cluster.

Every command was really run; the raw output is in [`logs/`](logs), the exact commands in [`scripts/`](scripts). The course charts (`07-install-upgrade/app-chart`, `mini-project/README.md`) were used **unmodified**; the only chart I wrote is `03-mini-project/notes-chart`.

```text
kushal-24bcs10123/
├── README.md                          # this write-up
├── 01-helm-commands/README.md         # Task 1: every helm command, what it does, its output
├── 02-rollback-workflow/
│   ├── README.md                      # Task 2: install -> upgrade -> upgrade -> rollback, with history after each step
│   └── values-v1.yaml  values-v2.yaml  values-v3.yaml     # one values file per revision
├── 03-mini-project/
│   ├── README.md                      # Task 3: the Notes app chart, steps 1-15 of mini-project/README.md
│   └── notes-chart/                   # Chart.yaml, values.yaml, values-prod.yaml, templates/{deployment,service,configmap}.yaml
├── scripts/
│   ├── 01-helm-commands.sh  02-rollback-workflow.sh  03-mini-project.sh
│   ├── lib.sh                         # x()/hr() helpers, HELM_NAMESPACE, ready()/pods()
│   └── shot.mjs                       # headless-Chrome screenshot helper
├── logs/                              # one .txt per script, raw output
└── screenshots/                       # the Notes app before/after the production upgrade
```

| Task | Where | Result |
|---|---|---|
| 1. Helm commands | [01-helm-commands/README.md](01-helm-commands/README.md), [logs/01-helm-commands.txt](logs/01-helm-commands.txt) | 20 commands: `create lint template show package install list status get upgrade history rollback uninstall repo search version env` + `upgrade --install` and an install straight from a repo |
| 2. Rollback workflow | [02-rollback-workflow/README.md](02-rollback-workflow/README.md), [logs/02-rollback-workflow.txt](logs/02-rollback-workflow.txt) | revisions 1→2→3, `rollback 2` created revision 4 whose manifest is byte-identical to revision 2; `--atomic` rolled a broken upgrade back by itself (revisions 5 failed, 6 deployed) |
| 3. Mini project | [03-mini-project/README.md](03-mini-project/README.md), [logs/03-mini-project.txt](logs/03-mini-project.txt) | `notes-chart` lints clean, dev install → prod upgrade (3 × nginx 1.25, `ENVIRONMENT=production` inside the pods) → broken tag `ImagePullBackOff` → `rollback 2` → uninstall |

## 1. Helm commands – the short version

Full output and the explanation of every command is in [01-helm-commands/README.md](01-helm-commands/README.md). The lifecycle in one picture, as it actually happened in the log:

```text
$ helm create demo-chart                         -> 12 files (Chart.yaml, values.yaml, templates/...)
$ helm lint demo-chart                           -> 1 chart(s) linted, 0 chart(s) failed
$ helm package demo-chart                        -> demo-chart-0.1.0.tgz (5030 bytes)
$ helm install demo ./demo-chart-0.1.0.tgz --set image.tag=1.27-alpine
NAME: demo   NAMESPACE: s15-helm   STATUS: deployed   REVISION: 1
$ helm upgrade demo ./demo-chart-0.1.0.tgz --set image.tag=1.27-alpine --set replicaCount=2
STATUS: deployed   REVISION: 2
$ helm rollback demo 1
Rollback was a success! Happy Helming!
$ helm history demo
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         superseded  Upgrade complete
3         superseded  Upgrade complete          <- the `upgrade --install --reuse-values` no-op still made a revision
4         deployed    Rollback to 1
$ helm uninstall demo                            -> release "demo" uninstalled
```

Where Helm keeps all of that: one Secret per revision in the release namespace.

```text
$ kubectl -n s15-helm get secret -l owner=helm -o custom-columns='NAME:.metadata.name,TYPE:.type'
NAME                         TYPE
sh.helm.release.v1.demo.v1   helm.sh/release.v1
```

## 2. Rollback workflow – the short version

Log: [logs/02-rollback-workflow.txt](logs/02-rollback-workflow.txt). Chart: the professor's `07-install-upgrade/app-chart`, values from [02-rollback-workflow/](02-rollback-workflow/).

```text
install  -f values-v1.yaml   ->  REVISION 1   1 pod   nginx:1.24
upgrade  -f values-v2.yaml   ->  REVISION 2   2 pods  nginx:1.25
upgrade  -f values-v3.yaml   ->  REVISION 3   3 pods  nginx:1.26
rollback 2                   ->  REVISION 4   2 pods  nginx:1.25   (manifest of revision 4 == manifest of revision 2)
upgrade --atomic (bad tag)   ->  REVISION 5 failed, REVISION 6 "Rollback to 4" – done by Helm itself after the 45 s timeout
```

## 3. Mini project – the short version

Log: [logs/03-mini-project.txt](logs/03-mini-project.txt). Chart: [03-mini-project/notes-chart](03-mini-project/notes-chart), written file by file from the mini-project README.

```text
$ helm install notes-dev notes-chart                              -> REVISION 1, 1 x nginx:1.24, ENVIRONMENT=development
$ helm upgrade notes-dev notes-chart -f notes-chart/values-prod.yaml -> REVISION 2, 3 x nginx:1.25, ENVIRONMENT=production
$ helm upgrade notes-dev notes-chart --set image.tag=broken-tag-does-not-exist
notes-dev-deploy-79b4dbdffd-6pjcb   nginx:broken-tag-does-not-exist   Pending   ImagePullBackOff
$ helm rollback notes-dev 2                                        -> REVISION 4 "Rollback to 2", 3 x nginx:1.25 Running
$ helm uninstall notes-dev                                         -> everything Terminating, only kube-root-ca.crt left in the namespace
```

The chart's `nodePort: 30090` is not one of the ports my kind cluster maps to the Mac, so I verified the Service from inside the docker network (`curl http://<node-ip>:30090` from a `curlimages/curl` container) and through `kubectl port-forward`; details in the mini-project README.

## What I understood

* A **chart** is a folder of Kubernetes YAML with `{{ }}` holes plus `Chart.yaml`; **values** fill the holes; a **release** is one installed copy with a name. `helm template` renders without a cluster, `helm install` renders and applies.
* Helm does not keep state in a database: every revision is a Secret `sh.helm.release.v1.<release>.v<N>` in the namespace. That is why `helm history` survives my laptop and why uninstalling deletes those Secrets too.
* `helm upgrade` always makes a new revision, even if nothing changed (revision 3 above). `helm rollback N` does not go "back" – it creates a **new** revision with the content of N, so history is append-only.
* `helm rollback` only restores what Helm rendered. The Deployment's own `rollout history` is separate (it had revisions 1-3 of its own), and a rollback via Helm is just one more Deployment rollout.
* Helm reports `deployed` as soon as the API server accepted the objects – revision 3 of the Notes app was "deployed" while its pod sat in `ImagePullBackOff`. `--atomic` (or `--wait`) is what makes Helm actually wait for readiness and roll back on failure, which is why it is the flag to use in CI.
* `-f values-prod.yaml` and `--set key=value` are the two ways to override `values.yaml`; `--set` wins over `-f`, and `--reuse-values` carries the previous revision's overrides forward.
* `helm search repo` searches the index files I downloaded with `helm repo update`; `helm search hub` queries Artifact Hub over the network.

## Checklist

- [x] Task 1: `create install list status get upgrade history rollback uninstall repo search` (+ `lint template package show version env`, `upgrade --install`) executed, explained and captured
- [x] Task 2: install → upgrade → verify → upgrade again → verify → rollback → verify, `helm history` after every step
- [x] Task 3: `notes-chart` written from scratch, `values.yaml` + `values-prod.yaml`, templates, lint, template, install, upgrade, bad upgrade, rollback, uninstall
- [x] Screenshots, README files, raw logs
