# Security (DevSecOps)

| Control | Tool | Config | Gate (pipeline fails when…) |
|---|---|---|---|
| SAST | Bandit | [bandit.yaml](bandit.yaml) | any MEDIUM/HIGH finding in the backend code |
| SCA | pip-audit | `application/backend/requirements.txt` | any known vulnerability in a dependency |
| Secret scanning | Gitleaks | [.gitleaks.toml](.gitleaks.toml) | any secret in the git history |
| Container image scanning | Trivy | [.trivyignore](.trivyignore) | any fixable HIGH/CRITICAL CVE in either image |
| Security gate | GitHub Actions `needs:` | [../.github/workflows/ci-cd.yml](../.github/workflows/ci-cd.yml) | build/push/deploy only run after test + SAST + SCA + secret scan pass, and push only after the Trivy gate passes |

## Findings and fixes

| Finding | Tool | Fix | Result |
|---|---|---|---|
| Frontend image: 44 HIGH/CRITICAL (Alpine 3.21.3 packages in `nginx:1.27-alpine`) | Trivy | `nginx:stable-alpine` + `apk upgrade` | 0 |
| Backend image: 3 HIGH in starlette 0.41.3 | Trivy | `fastapi==0.142.2`, `prometheus-fastapi-instrumentator==8.1.0` (starlette 1.7.0) | 0 |
| `pytest==8.3.4` PYSEC-2026-1845 (blocked the first pipeline run) | pip-audit | `pytest==9.0.3` | 0 |
| Backend code | Bandit | none needed | no issues |
| Repository history | Gitleaks | none needed | no leaks |

## Runtime hardening
- Backend container runs as non-root user `10001`.
- Database credentials live in a Kubernetes **Secret**; non-secret settings in a **ConfigMap**.
- PostgreSQL is only reachable inside the cluster (ClusterIP Service).
- Images are tagged with the commit SHA, so every running container traces back to a commit.
