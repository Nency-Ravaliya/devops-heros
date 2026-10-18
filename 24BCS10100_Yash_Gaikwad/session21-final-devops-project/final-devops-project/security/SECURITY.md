# Security policy for StockPilot

This is the short policy that the pipeline in `devsecops.yml` enforces. It applies to the
`main` branch and to every image that is pushed to the registry.

## What is checked on every push and pull request

| Control | Tool | Config file | Blocks the pipeline when |
|---|---|---|---|
| Static analysis (SAST) of the code | Semgrep | `semgrep-rules.yml` + public packs | any finding (rules are ERROR level) |
| Dependency scan (SCA), Python | pip-audit | pinned `backend/requirements.txt` | any known vulnerability in a pinned package |
| Dependency scan (SCA), JavaScript | npm audit | `frontend/package-lock.json` | a HIGH or CRITICAL advisory in a production dependency |
| Secret scan | gitleaks | `.gitleaks.toml` | a secret anywhere in the git history |
| Container image scan | Trivy | `trivy.yaml`, `.trivyignore` | a HIGH or CRITICAL vulnerability that has a fix |
| **Security gate** | job `security-gate` | `devsecops.yml` | any of the four scan jobs did not succeed |

Nothing is pushed to the registry and nothing is deployed unless the gate passes.

## Rules for the team

1. **No secrets in Git.** Passwords, tokens and keys live in GitHub secrets or in a Kubernetes
   Secret, never in the repository, never in an image layer. If one is committed by mistake it must be
   treated as leaked: **rotate it first**, then remove it (deleting the file is not enough, the
   history keeps it).
2. **Findings are fixed, not hidden.** The preferred fix is to upgrade the dependency or the base image.
3. **Exceptions are rare and written down.** To accept a vulnerability add it to `.trivyignore` with a
   comment that explains why it is safe, who agreed, and an expiry date (`exp:YYYY-MM-DD`).
   The file is empty today. Allowlists in `.gitleaks.toml` must be narrow (one path or one pattern each).
4. **Least privilege.** Workflows start from `permissions: contents: read`; a job that needs more
   (pushing images needs `packages: write`) asks for it on its own. Containers run as a non-root user
   with all Linux capabilities dropped.
5. **Immutable, traceable images.** Images are tagged with the git commit SHA (never `latest`), and the
   image that was scanned is the same file that is pushed.

## Branch protection (repository setting, not a file)

On GitHub: *Settings > Branches > Branch protection rule for `main`* and tick
*Require status checks to pass before merging*. Add the checks **Unit tests** and **Security gate**.
Then a pull request cannot be merged while the gate is red. The gate job runs even when a scan was
skipped or failed (`if: always()`) and fails in that case, because GitHub treats a *skipped*
required check as passed.

## Reporting a vulnerability

Open a private security advisory on the repository (*Security > Report a vulnerability*) or email the
maintainer listed in the repository profile. Please do not open a public issue for a security problem.
Expected reaction: acknowledgement within 3 working days, a fix or a decision within 14 days.
