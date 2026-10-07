# Session 15 - Helm

| | |
|---|---|
| **Student** | Dhruv Yadav |
| **Enrollment No.** | 24BCS10204 |
| **Session** | 15 - Helm (package manager for Kubernetes) |
| **Cluster** | kind `kind-devops-heros` (1 control-plane + 2 workers, Kubernetes v1.37.0) |
| **Helm** | v4.3.0 |

## Task checklist

- [x] **Task 1 - Helm commands**: `create`, `lint`, `install`, `list`, `status`, `get values / manifest / notes / all / metadata`, `upgrade`, `history`, `rollback`, `uninstall` (with and without `--keep-history`), `repo add / list / update`, `search repo`, `search hub`, `show chart` - run and explained -> [01-helm-commands/README.md](01-helm-commands/README.md)
- [x] **Task 2 - Rollback workflow**: Install -> Verify -> Upgrade -> Verify -> Upgrade again -> Verify -> Rollback -> Verify. Each revision changes replicas, image tag and the ConfigMap message, and every step is checked with `helm history`, `kubectl` and `curl` -> [02-rollback-workflow/README.md](02-rollback-workflow/README.md)
- [x] **Task 3 - Mini project (notes-chart)**: my own chart (Chart.yaml, values.yaml, values-prod.yaml, templates with `_helpers.tpl`, NOTES.txt), `helm lint`, `helm template`, then install -> upgrade to prod -> history -> bad upgrade -> rollback -> uninstall, following the course spec -> [03-mini-project/README.md](03-mini-project/README.md)

## Folder layout

```text
24BCS10204-Dhruv-prabhat/
├── README.md                      # this file
├── 01-helm-commands/README.md     # every Helm command, run and explained
├── 02-rollback-workflow/
│   ├── README.md
│   ├── values-v1.yaml             # revision 1: 1 replica, nginx 1.24, "v1" message
│   ├── values-v2.yaml             # revision 2: 2 replicas, "v2" message
│   └── values-v3.yaml             # revision 3: 3 replicas, nginx 1.25, "v3" message
└── 03-mini-project/
    ├── README.md
    └── notes-chart/               # my chart (used by Task 2 and Task 3)
        ├── Chart.yaml
        ├── values.yaml
        ├── values-prod.yaml
        └── templates/
            ├── _helpers.tpl
            ├── configmap.yaml
            ├── deployment.yaml
            ├── service.yaml
            └── NOTES.txt
```

## Notes about the environment

- The cluster is shared, so everything ran in my own namespaces: `s15` (Tasks 1 and 2) and `s15-mini` (Task 3). The course spec uses the `default` namespace, so I added `-n <namespace>` to each command.
- Everything below was really run. All outputs were copied from the terminal. Very long outputs are cut and marked with `...`.
- Helm v4 differs from the Helm 3 output in the course notes in a few places: `helm list` shows releases in **all** states by default (the old `--all` flag no longer exists, so `--uninstalled` and similar filters are used instead), and `helm get metadata` shows `APPLY_METHOD: server-side apply`.
