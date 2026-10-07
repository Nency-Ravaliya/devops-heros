# StockPilot security gate policy

Owner: Antara Utane (24BCS10106). Enforced by job **7. Security gate** in
`.github/workflows/24BCS10106-final-project.yml`.

## Principle

Nothing reaches the registry (GHCR) or a cluster unless every automated
security check in the pipeline passes. The gate runs only after all scanners
finish. It reads their finding counts from job outputs and fails the workflow
if any count is non-zero. `push-image` and `deploy` depend on the gate, so a
failed gate means no image is pushed and nothing is deployed.

Individual scan jobs never fail on their own findings (`exit-code: 0`). They
always upload their full reports as artifacts, so one place makes the
pass/fail decision and every report stays available for triage.

## Controls

| # | Layer | Tool | Scope | Blocks the pipeline when |
|---|---|---|---|---|
| 1 | Unit tests | pytest + coverage | `application/` | any test fails |
| 2 | SAST | Semgrep (`p/python`, `p/secrets`, `p/dockerfile`, `security/semgrep.yml`) | `application/`, `docker/` | at least one finding |
| 3a | SCA | pip-audit | `application/requirements.txt` | any known-vulnerable pinned dependency |
| 3b | SCA | Trivy fs (`security/trivy.yaml`) | `application/` | any HIGH/CRITICAL with a fix available |
| 4 | Secrets | Gitleaks (`security/gitleaks.toml`) | the project folder only | any leak |
| 5 | Container | Trivy image, per platform (amd64 + arm64) | the exact OCI archive that will be pushed | any HIGH/CRITICAL with a fix available |

### Custom Semgrep rules (`security/semgrep.yml`)
- `stockpilot-no-raw-sql-fstring`: SQL built with f-strings, `%` or `.format()`.
- `stockpilot-no-hardcoded-db-password`: a `postgresql://user:pass@` URL in source code.
- `stockpilot-no-debug-uvicorn`: `uvicorn.run(..., reload=True)` or `debug=True`.
- `stockpilot-no-wildcard-cors-with-credentials`: CORS `*` combined with credentials.

All four were checked against a deliberately bad file. Real output is in
`docs/outputs/semgrep-custom-rules-negative-test.txt`.

## Severity policy

- **CRITICAL / HIGH with a fixed version available:** block. Fix by upgrading
  the dependency or base image, then rebuild.
- **CRITICAL / HIGH with no fix yet (unfixed OS CVEs):** don't block, but
  report. The pipeline summary prints both counts for every platform. On
  2026-10-06 `python:3.12-slim` (Debian 13.7) had **44 unfixed HIGH** findings
  locally and **0 fixable**.
- **MEDIUM / LOW:** reported only.

## Exceptions

An accepted risk goes in `security/.trivyignore` with the CVE id, the reason,
an owner and an expiry date, and it's reviewed in a pull request. At the time
of writing the file is empty: there are no exceptions.

Gitleaks allowlists in `security/gitleaks.toml` are as narrow as possible:
- the literal placeholder `change-me-placeholder`;
- `stockpilot-api:<40-hex git SHA>`. The gate blocked CI run
  [37460645786](https://github.com/Antara Utane/devops-heros/actions/runs/37460645786)
  because `generic-api-key` matched the commit-SHA image tag in captured
  outputs. A commit SHA is public, so only that exact shape is allowed
  (`regexTarget = "match"`). The same config still reports a real
  `api_key = "..."` string and a non-hex tag. That was verified locally, and the
  evidence is in `docs/outputs/ci-run-37460645786-gate-blocked.txt`.

## Image hardening (`docker/Dockerfile`)
- Multi-stage build. The runtime image has no compiler, no pip and no setuptools, because the
  system pip vendors `urllib3`/`msgpack`, which Trivy flagged HIGH. That was
  found locally and fixed (see `docs/outputs/trivy-image-local.txt`).
- `apt-get upgrade` in the runtime stage picks up Debian security fixes.
- Runs as fixed UID/GID 10001. Kubernetes enforces `runAsNonRoot`, a
  `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`, drops ALL
  capabilities, uses `seccompProfile: RuntimeDefault` and sets
  `automountServiceAccountToken: false`.

## Secrets handling
- The repo has no real credentials. `kubernetes/02-secret.example.yaml` and
  `values.yaml` contain only the placeholder `change-me-placeholder`, which is
  explicitly allow-listed in Gitleaks.
- The prod and GitOps environments use `database.existingSecret`. The Secret is
  created out-of-band (`kubectl create secret ... $(openssl rand -hex 16)`).
  On AWS this would be Secrets Manager plus the External Secrets Operator.
- CI pushes with the short-lived `GITHUB_TOKEN` (`packages: write` only in the
  push job). It doesn't use a personal access token.
