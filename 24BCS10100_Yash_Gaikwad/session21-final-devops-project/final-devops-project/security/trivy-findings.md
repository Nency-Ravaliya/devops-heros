# Security notes

## What Trivy scans and what the result means

Trivy runs twice in the pipeline (`build-scan-push` job, once for `stockpilot-backend` and once for
`stockpilot-frontend`). For each freshly built image it unpacks every layer, reads the installed OS packages
(Debian/Alpine) and the Python/Node dependencies, and compares them with databases of published CVEs. The step is
configured with `severity: HIGH,CRITICAL`, `ignore-unfixed: true` and `exit-code: 1`, so any HIGH or CRITICAL
vulnerability that already has a fix fails the job **before** the image is pushed to the registry. A clean result
means "no known, fixable HIGH/CRITICAL vulnerability in the image at scan time"; it is not a guarantee of security,
only one automated control (new CVEs are published every day, which is why the scan runs on every build).

`ignore-unfixed` is deliberate: failing a build on a vulnerability nobody has patched yet blocks the team without
giving them anything to do. Those findings still show up in a normal `trivy image` run.

## A real finding from this project

The first scan of the images failed, which is exactly what the gate is for:

| Image | Package | Finding | Fixed in |
|-------|---------|---------|----------|
| backend | `starlette` 0.52.1 | **CVE-2026-48818** (HIGH): SSRF and NTLM credential theft through UNC paths in `StaticFiles` | 1.1.0 |
| backend | `starlette` 0.52.1 | CVE-2026-54283 (HIGH): form-size limits ignored for `application/x-www-form-urlencoded`, enabling denial of service | 1.3.1 |
| frontend | `nginx` 1.28.2 and several Alpine libraries (`libcrypto3`, `libssl3`, `pcre2`, `zlib`, `curl`, ...) | multiple HIGH CVEs, e.g. CVE-2026-42533 (code execution through crafted HTTP requests) | newer rebuilds |

How they were fixed:

- **starlette:** the project had pinned an old FastAPI/instrumentator combination. Upgrading to FastAPI 0.143,
  Starlette 1.7.0 and `prometheus-fastapi-instrumentator` 8.1 removed both findings and all tests still passed.
  (The application does not serve `StaticFiles` or parse forms, so it was not exploitable here, but the gate
  correctly treats a vulnerable dependency as a failure.)
- **nginx:** the `nginx-unprivileged:1.28-alpine` tag had not been rebuilt since February. Switching to the current
  stable line `1.30-alpine` (rebuilt this week) plus `apk upgrade --no-cache` in the Dockerfile cleared every
  finding.

Run it yourself:

```bash
docker build -t stockpilot-backend:local ./backend
docker build -t stockpilot-frontend:local ./frontend
trivy image --severity HIGH,CRITICAL --ignore-unfixed stockpilot-backend:local
trivy image --severity HIGH,CRITICAL --ignore-unfixed stockpilot-frontend:local
# without installing Trivy:
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --ignore-unfixed stockpilot-backend:local
```

## Security layers in this project

| Layer | What is in place |
|-------|------------------|
| Source / secrets | `.gitignore` excludes `.env`, `terraform.tfvars` and state. No passwords or credentialed connection strings are stored in the repository: the backend requires `DATABASE_URL` from the environment, Docker Compose uses a private-network database without a password, and the Helm chart generates a random database password. CI uses `GITHUB_TOKEN` and encrypted repository secrets, and a gitleaks job scans the whole history on every push |
| Dependencies | all backend dependencies pinned to exact versions; `npm ci` with a lockfile |
| Container scanning | Trivy gate in CI (above) |
| Container hardening | non-root users (uid 10001 / 101), `HEALTHCHECK`, multi-stage frontend image with no build tools at runtime |
| Kubernetes | `runAsNonRoot`, `allowPrivilegeEscalation: false`, all capabilities dropped, `seccompProfile: RuntimeDefault`, read-only root filesystem for the backend, resource limits, Pod Security Admission labels on the namespace, `ClusterIP` Services (nothing but the Ingress is exposed) |
| Runtime | readiness/liveness probes, Prometheus metrics |

Not covered (out of scope for the capstone): SAST of the source code, network policies, image signing, and a managed
secret store such as AWS Secrets Manager (the generated database password lives in a Kubernetes Secret).

## Secret scanning

An early version of this repository contained a local-development database login (user and password both
`stockpilot`) in the compose file, the backend config and the Helm values. Secret scanners such as GitGuardian flag
that pattern (a password inside a connection URI). They were placeholders, not real credentials, but they were removed
anyway: the current tree has no password literals or credentialed URIs, and the `secret-scan` job (gitleaks) fails the
pipeline if a real secret is ever committed. Run it locally with:

```bash
docker run --rm -v "$PWD:/repo" zricethezav/gitleaks:v8.30.1 git /repo --no-banner --redact
```
