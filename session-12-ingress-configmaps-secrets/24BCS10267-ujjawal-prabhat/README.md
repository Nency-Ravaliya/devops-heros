# Session 12 - Ingress, ConfigMaps & Secrets

| | |
|---|---|
| **Student** | Ujjawal Prabhat |
| **Enrollment No.** | 24BCS10267 |
| **Session** | 12 - Ingress, ConfigMaps & Secrets |

## Task checklist

- [x] **Task 1 - ConfigMap** -> [`01-configmap/`](01-configmap/README.md): created from a literal and a file, injected as env (`configMapKeyRef` + `envFrom`) and as a volume, verified in the container, update behaviour shown
- [x] **Task 2 - Secret** -> [`02-secret/`](02-secret/README.md): created via `kubectl create secret`, injected as env + volume (tmpfs, mode 0400), base64 decoded and read in plain text from etcd, why not to commit secrets, Sealed Secrets / External Secrets / SOPS. Only `secret.example.yaml` with placeholders is in git
- [x] **Task 3 - Ingress** -> [`03-ingress/`](03-ingress/README.md): 2 apps + Services, host routing and path routing (`ingressClassName: nginx`), curl on `localhost:8081` with `Host` headers, each backend verified
- [x] **Task 4 - Ingress vs Ingress Controller** -> [`04-ingress-vs-controller/`](04-ingress-vs-controller/README.md), including the nginx.conf the controller generated from my Ingresses
- [x] **Task 5 - Troubleshooting** -> [`05-troubleshooting/`](05-troubleshooting/README.md): the course's `secret-base64-gotcha` reproduced against real PostgreSQL, plus 3 more broken manifests (Ingress class, Ingress port, ConfigMap key), each with symptom, commands, root cause, fixed YAML and before/after output

## Environment

kind cluster `kind-devops-heros` (Kubernetes v1.37.0, arm64), ingress-nginx controller v1.12.1 (kind flavour, host `8081 -> 80`),
namespace `s12`. All outputs are real captured terminal output. Long output is trimmed with `...`.

## Folder layout

```
24BCS10267-ujjawal-prabhat/
├── README.md
├── 01-configmap/            app.properties, pod-with-configmap.yaml, README.md
├── 02-secret/               secret.example.yaml (placeholders only), pod-with-secret.yaml, .gitignore, README.md
├── 03-ingress/              apps.yaml, ingress-host.yaml, ingress-path.yaml, README.md
├── 04-ingress-vs-controller/README.md
└── 05-troubleshooting/      postgres.yaml, broken/*.yaml, fixed/*.yaml, README.md
```

## Key takeaways

- **ConfigMap vs Secret:** same mechanics (env or volume). A Secret only adds base64 encoding, tmpfs mounts and separate RBAC. **Base64 is not
  encryption**: I decoded the password with one command and read it in plain text straight from etcd.
- **Env vars are fixed when the container starts.** Mounted ConfigMaps/Secrets update in place (about 65 s here).
- **An Ingress is only rules. The controller does the work.** No matching IngressClass/controller means the Ingress is silently ignored.
- Most errors were explained by `kubectl describe` events or controller/app logs: `couldn't find key`, `Ignoring ingress`, `FATAL: password authentication failed`.

## Cleanup

```bash
kubectl delete ns s12
```
