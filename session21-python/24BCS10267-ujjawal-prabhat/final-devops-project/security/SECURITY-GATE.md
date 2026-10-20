# StockPilot security gate policy

Enforced by `.github/workflows/24bcs10267-final-project.yml` (repository root).

## Principle

No image is built, pushed or deployed unless the tests and every scanner pass.
Each scanner job fails on its own findings. The `security-gate` job needs all of
them and fails if any did not succeed. The `build` jobs need the gate, and each
build job runs Trivy on the image it just built before it pushes anything.

## Controls

| Layer | Tool | Scope | Blocks when |
|---|---|---|---|
| Unit tests | pytest | `backend/` | any test fails |
| SAST | Semgrep 1.179.0 (`p/python`, `p/javascript`, `p/dockerfile`, `p/secrets`, `security/semgrep.yml`) | `backend/`, `frontend/` | any finding (`--error`) |
| SCA | Trivy fs (`security/trivy.yaml`) | `backend/requirements.txt`, `frontend/package-lock.json` (incl. build-time deps) | a HIGH/CRITICAL with a fix available |
| Secrets | Gitleaks 8.30.1 (`security/gitleaks.toml`) | the project folder | any leak |
| Container | Trivy image (`security/trivy.yaml`) | backend and frontend image, amd64 and arm64 | a HIGH/CRITICAL with a fix available |

### Custom Semgrep rules (`security/semgrep.yml`)
- `stockpilot-no-raw-sql-fstring`: SQL built with f-strings, `%` or `.format()`.
- `stockpilot-no-hardcoded-db-password`: a `postgresql://user:pass@` URL in source code.
- `stockpilot-no-debug-uvicorn`: `uvicorn.run(..., reload=True)` or `debug=True`.
- `stockpilot-no-wildcard-cors-with-credentials`: CORS `*` combined with credentials.

All four were run against a deliberately bad file:
`docs/outputs/semgrep-custom-rules-negative-test.txt`.

## Severity policy

- HIGH/CRITICAL with a fixed version: block. Fix by upgrading the dependency or
  the base image packages (`apt-get upgrade` / `apk upgrade` in the Dockerfiles).
- HIGH/CRITICAL without a fix (`--ignore-unfixed`): not blocking, because a
  rebuild cannot remove them. They are visible with
  `trivy image --severity HIGH,CRITICAL <image>`.
- MEDIUM/LOW: not reported in CI.

## Exceptions

An accepted risk goes in `security/.trivyignore` with the CVE id, reason, owner
and expiry date, reviewed in a pull request. The file is empty.

Gitleaks runs with its default rules and no allowlist.

## Secrets handling

- No real credentials in Git. `helm/stockpilot/values.yaml` has the placeholder
  password; the GitOps environment uses `database.existingSecret`, created with
  `kubectl create secret ... $(openssl rand -hex 16)` (`scripts/gitops-bootstrap.sh`).
- `docker-compose.yml` uses a fixed password for a throwaway local database only.
- CI uses the short-lived `GITHUB_TOKEN`: `packages: write` only in the build and
  publish jobs, `contents: write` only in `gitops-promote`.
