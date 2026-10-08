# Security tools configuration

| Layer | Tool | Config file | Gate rule (pipeline fails when…) |
|---|---|---|---|
| SAST | **Bandit 1.9.4** | [`../pyproject.toml`](../pyproject.toml) `[tool.bandit]` | any **MEDIUM or HIGH** severity issue (`--severity-level medium`) |
| SAST | **CodeQL** (`security-extended` queries) | inline in the workflow | CodeQL alerts go to the GitHub Security tab (Code scanning) |
| SCA | **pip-audit** | `requirements.txt` | **any** known vulnerability in a pinned dependency |
| SCA | **Trivy fs** | [`../.trivyignore`](../.trivyignore) | any **HIGH/CRITICAL** CVE in dependency manifests |
| Secrets | **Gitleaks v8.30.1** (whole git history, `fetch-depth: 0`) | [`../.gitleaks.toml`](../.gitleaks.toml) | **any** secret found (built-in ruleset: AWS, GitHub, Slack, private keys, generic high-entropy API keys …) |
| Secrets | **GitHub push protection** | repository setting (on by default for public repos) | known-provider secrets are rejected at `git push` time, before they reach the repo |
| Container | **Trivy image** | [`../.trivyignore`](../.trivyignore) | any **fixable HIGH/CRITICAL** CVE (`ignore-unfixed: true`). A full report of all severities is uploaded as SARIF to the Security tab |
| Gate | `security-gate` job | workflow | any of the jobs above did not succeed → push and deploy are skipped |

## Decisions and accepted risks

- **Bandit B311 (`random` module) is skipped.** In this app `random` only picks a greeting text and simulates pipeline durations. It is never used for tokens, passwords or anything cryptographic. Everything else Bandit finds at MEDIUM or above breaks the build.
- **Trivy `ignore-unfixed: true` on the gate.** A vulnerability with no released fix can't be fixed by us, so blocking on it would only make the gate useless. Those findings are still visible in the SARIF report.
- **`.trivyignore` is empty.** If a CVE ever has to be accepted, it goes in here with a reason and a review date, so the exception is visible in code review.

## Hardening that came out of the scans

1. **SAST:** `app.run(host="0.0.0.0", debug=True)` was replaced with environment-driven host and debug values (defaults: `127.0.0.1`, debug off). In containers the app is served by gunicorn.
2. **Container image:** the single-stage image shipped `pip` and `setuptools`, whose vendored `msgpack`, `urllib3` and `setuptools` had 4 HIGH CVEs. The multi-stage Dockerfile builds a virtualenv in a builder stage and removes `pip`, `setuptools`, `wheel` and `ensurepip` from the runtime image, which brought it to **0 HIGH/CRITICAL**.
3. **Kubernetes runtime:** `runAsNonRoot` (uid 10001), `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`, all capabilities dropped, `seccompProfile: RuntimeDefault`, CPU and memory limits, and readiness and liveness probes.

## Run the scanners locally

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt "bandit[toml]" pip-audit
bandit -c pyproject.toml -r app --severity-level medium      # SAST
pip-audit -r requirements.txt                                # SCA
trivy fs --scanners vuln --severity HIGH,CRITICAL .          # SCA (manifests)
gitleaks git . --config .gitleaks.toml --redact -v           # secrets (full history)
docker build -t devsecops-dashboard:local .
trivy image --severity HIGH,CRITICAL --ignore-unfixed devsecops-dashboard:local   # image
```
