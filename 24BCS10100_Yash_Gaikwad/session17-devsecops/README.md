# Session 17: Complete CI/CD and DevSecOps Pipeline

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

Homework: build a complete CI/CD + DevSecOps pipeline. I reused my own project **StockPilot** (FastAPI + React + PostgreSQL, public at <https://github.com/Yash-1706/devops-assgn>). Its real pipeline on GitHub already covers build, unit tests, secret scanning, a Trivy image gate and a push to GHCR. This session adds what was missing, **SAST, SCA and an explicit security gate**, writes the tool configuration, the Kubernetes manifests and a complete `devsecops.yml` workflow, and then *runs every security tool for real* against the project.

| Deliverable | Where it is |
|---|---|
| Application | StockPilot: [`application/`](../session21-final-devops-project/final-devops-project/application/) (the source lives in Session 21; this folder holds the DevSecOps parts) |
| Dockerfile | [`dockerfiles/backend.Dockerfile`](dockerfiles/backend.Dockerfile), [`dockerfiles/frontend.Dockerfile`](dockerfiles/frontend.Dockerfile) |
| GitHub Actions workflow | [`workflows/devsecops.yml`](workflows/devsecops.yml) (**not yet run on GitHub**, see the status table) |
| Security tools configuration | [`security/`](security/): `.gitleaks.toml`, `trivy.yaml`, `.trivyignore`, `semgrep-rules.yml`, `run-security-scans.sh`, `SECURITY.md` |
| Kubernetes manifests | [`k8s/`](k8s/): namespace, configmap, postgres, backend, frontend |
| Successful pipeline output | [Real GitHub run](#3-what-really-ran-on-github-run-4) and [local tool output](#4-results-every-tool-run-for-real) |
| Screenshots | [Screenshots](#6-screenshots) |
| Complete README.md | this file |

### The expected flow and how it is implemented

```text
 Code -> Build -> Unit Test -> SAST -> SCA -> Secret Scan -> Docker Build -> Image Scan -> SECURITY GATE -> Push -> Deploy

   git push / pull request
          |
          v
      +--------+   +-----------+
      | build  |-->| unit-test |
      +--------+   +-----+-----+
                         |
      +------------------+------------------+------------------+
      |                  |                  |                  |
      v                  v                  v                  v
 +----------+      +-----------+     +---------------+   +--------------+
 |   sast   |      |    sca    |     | secret-scan   |   | docker-build |
 | Semgrep  |      | pip-audit |     | gitleaks over |   | image tar    |
 |(our code)|      | npm audit |     | full history  |   | per service  |
 +----+-----+      | (our deps)|     +-------+-------+   +------+-------+
      |            +-----+-----+             |                  |
      |                  |                   |                  v
      |                  |                   |           +-------------+
      |                  |                   |           | image-scan  |
      |                  |                   |           | Trivy: exit |
      |                  |                   |           | 1 on HIGH / |
      |                  |                   |           | CRITICAL    |
      |                  |                   |           +------+------+
      +------------------+---------+---------+------------------+
                                    v
                          +------------------+
                          |  SECURITY GATE   |   fails unless all four scans succeeded
                          +--------+---------+
                                   |  success only, and only on main
                                   v
                          +------------------+
                          |   push-image     |   GHCR, tag = commit SHA, GITHUB_TOKEN
                          +--------+---------+
                                   |  only if repository variable DEPLOY_ENABLED = true
                                   v
                          +------------------+
                          | deploy (kubectl) |
                          +------------------+
```

The stages happen in the required order: every box starts only when what it depends on has finished (`needs`), and nothing is pushed before the gate. The four scans do not depend on each other, so they run **in parallel**: a developer sees *all* findings in one run instead of fixing them one at a time, and the pipeline is faster.

### Required stage, tool, job and evidence

| Stage | Tool | Job in `devsecops.yml` | Evidence |
|---|---|---|---|
| Code | Git, GitHub, branch protection | triggers `push`, `pull_request`, `workflow_dispatch` | **GitHub**: 4 real runs, all triggered by push |
| Build | pip, npm + Vite | `build` | **GitHub** (the `test` job of the real run does the same) and **Local** |
| Unit test | pytest (48 tests) | `unit-test` | **GitHub**: 48 passed in run #4. **Local** re-run below |
| SAST | Semgrep | `sast` | **Local only** (the real pipeline has no SAST yet) |
| SCA | pip-audit, npm audit | `sca` | **Local only** (the real pipeline has no SCA yet) |
| Secret scan | gitleaks | `secret-scan` | **GitHub**: real job, no leaks in 61 commits. **Local** with the new config |
| Docker build | Docker Buildx | `docker-build` | **GitHub**: real builds. **Local** builds below |
| Container image scan | Trivy | `image-scan` | **GitHub**: real scans, 0 HIGH/CRITICAL. **Local** scans below |
| Security gate | bash job with `needs` | `security-gate` | **Local only**: the job's script is extracted from the YAML and run for open and closed cases. (The real pipeline gates through `needs` and Trivy's exit code 1.) |
| Push image | docker push to GHCR | `push-image` | **GitHub**: real, both images pushed with the commit SHA as tag |
| Deploy to Kubernetes | kubectl | `deploy` | **Not run**: skipped by design in the real pipeline; the manifests are validated offline only |

### What really ran where (please read)

| | GitHub (real runs) | Local (my laptop) | Not run |
|---|---|---|---|
| `devsecops.yml` as written | | linted with actionlint; its scan commands run locally with the same flags | **never executed on GitHub** (never pushed to the project repository) |
| Real workflow `ci-cd.yml` of StockPilot | 4 successful runs (test, secret scan, Trivy gate, GHCR push) | | `deploy` job: skipped by design |
| SAST, SCA | | Semgrep, pip-audit, npm audit | not part of the real GitHub pipeline yet |
| Kubernetes manifests | | `kubeconform`, Trivy config scan, read-only filesystem smoke test | never applied to a cluster |

Every output block is real, copied from the terminal by a script. Colour codes were removed and long outputs are cut where I say so. The line `# exit code: N` after a command is added by my script, it is not printed by the tool. Local runs used a clean copy of the project (no `.git`, `node_modules`, `.venv`, `dist`); the original folder was only read.

---

## 1. Tool configuration

All files are in [`security/`](security/). They are really used: the commands in this README pass them to the tools.

### Secret scanning: `.gitleaks.toml`

Gitleaks scans every commit (not only the latest) against rules for AWS keys, tokens, private keys and so on. `useDefault = true` keeps all built-in rules, and the allowlists are narrow exceptions: the pytest fixtures folder, lock-file hashes and obvious placeholders.

_security/.gitleaks.toml_

```toml
  1  # Gitleaks configuration: secret scanning of the whole git history.
  2  # Used by the secret-scan job of devsecops.yml and by run-security-scans.sh:
  3  #   gitleaks git <repo> --config security/.gitleaks.toml --redact
  4  
  5  title = "StockPilot gitleaks configuration"
  6  
  7  # Keep every built-in rule (AWS keys, GitHub / Slack / Stripe tokens, private keys, JWTs,
  8  # generic high-entropy API keys, ...) and only add exceptions on top.
  9  [extend]
 10  useDefault = true
 11  
 12  # ---------------------------------------------------------------------------
 13  # Allowlist. Each entry must be narrow and explained; a broad allowlist hides real leaks.
 14  # ---------------------------------------------------------------------------
 15  [[allowlists]]
 16  description = "Test fixtures: pytest uses dummy values only (in-memory SQLite, no real credentials)"
 17  paths = [
 18    '''^backend/tests/''',
 19  ]
 20  
 21  [[allowlists]]
 22  description = "Lock files contain integrity hashes (sha512-...) that look like high-entropy secrets"
 23  paths = [
 24    '''(^|/)package-lock\.json$''',
 25    '''(^|/)\.terraform\.lock\.hcl$''',
 26  ]
 27  
 28  [[allowlists]]
 29  description = "Obvious placeholders such as 'changeme' that appear in documentation and examples"
 30  regexes = [
 31    '''(?i)(changeme|your[-_]?password[-_]?here|<[a-z-]*password>)''',
 32  ]
```

### Image scanning and the gate policy: `trivy.yaml` and `.trivyignore`

The whole gate policy is only a few lines: severities `HIGH` and `CRITICAL`, only vulnerabilities that already have a fix (`ignore-unfixed`), and `exit-code: 1` so that the CI job fails. `.trivyignore` is empty on purpose and explains the rule for adding an exception (reason, owner, expiry date).

_security/trivy.yaml_

```yaml
  1  # Trivy configuration: the container image scan and the "security gate" policy.
  2  # Used by the image-scan job of devsecops.yml and by run-security-scans.sh:
  3  #   trivy image --config security/trivy.yaml <image>
  4  # (command line flags and TRIVY_* environment variables override this file)
  5  
  6  # --- the gate -------------------------------------------------------------
  7  # Exit with status 1 when at least one finding of the severities below is reported.
  8  # A non-zero exit code fails the CI job, which is what closes the gate.
  9  exit-code: 1
 10  severity:
 11    - HIGH
 12    - CRITICAL
 13  
 14  vulnerability:
 15    # Only fail on vulnerabilities that already have a fixed version: the team can act
 16    # on those. Unfixed ones still show up in a normal `trivy image` run without this flag.
 17    ignore-unfixed: true
 18  
 19  # --- what is scanned ------------------------------------------------------
 20  scan:
 21    scanners:
 22      - vuln      # OS packages and language packages (pip, npm) inside the image
 23      - secret    # passwords / keys baked into image layers
 24  
 25  # --- reporting ------------------------------------------------------------
 26  format: table
 27  timeout: 10m
 28  
 29  # --- exceptions (see .trivyignore, which is empty on purpose) ---------------
 30  # relative to the folder Trivy is started in (the repository root)
 31  ignorefile: security/.trivyignore
 32  
 33  # --- vulnerability database ------------------------------------------------
 34  # Two mirrors: the AWS one is tried first and the GHCR one is the fallback, because
 35  # a single mirror can answer "TOOMANYREQUESTS" (this happened in a real run of the
 36  # StockPilot pipeline on GitHub).
 37  db:
 38    repository:
 39      - public.ecr.aws/aquasecurity/trivy-db:2
 40      - ghcr.io/aquasecurity/trivy-db:2
```

_security/.trivyignore (only comments: no vulnerability is accepted)_

```text
  1  # Trivy ignore file: vulnerabilities that the team has decided to accept.
  2  #
  3  # THIS FILE IS EMPTY ON PURPOSE. The StockPilot images have no accepted findings, so
  4  # nothing is ignored and every HIGH/CRITICAL vulnerability with a fix stops the pipeline.
  5  #
  6  # Rule for adding a line (the security gate must never be silenced without a reason):
  7  #   1. one vulnerability ID per line, e.g. CVE-2099-12345
  8  #   2. a comment on the line above that says WHY it is safe to ignore
  9  #      (for example "the vulnerable function is never called by this app") and who agreed
 10  #   3. an expiry date so the exception is reviewed again, using Trivy's syntax:
 11  #        CVE-2099-12345 exp:2027-01-31
 12  #
 13  # Example of a correct entry (this is a made-up ID, so it is commented out):
 14  #   # StaticFiles is not used by this app; accepted by the team on 2026-10-18
 15  #   # CVE-2099-12345 exp:2027-01-31
```

### SAST: `semgrep-rules.yml`

Seven small rules of my own (hard-coded database password, `shell=True`, `eval`, SQL built from strings, open CORS, unsafe deserialisation, React `dangerouslySetInnerHTML`) are used together with the public packs `p/python`, `p/javascript` and `p/dockerfile`. One example rule:

_security/semgrep-rules.yml, the first rule (a regular expression, with an exception for placeholders)_

```yaml
  9    - id: stockpilot-database-url-with-inline-password
 10      languages: [generic]
 11      severity: ERROR
 12      message: >-
 13        A database URL contains a password (scheme://user:password@host). Read the whole URL
 14        from an environment variable (DATABASE_URL) or a Kubernetes Secret instead.
 15      patterns:
 16        - pattern-regex: 'postgres(ql)?(\+[a-z0-9]+)?://[^:/\s@"'']+:[^@\s"'']+@'
 17        # placeholders and variable references are fine: PASSWORD, <password>, ${PASSWORD}, $(POSTGRES_PASSWORD), %s, {password}
 18        - pattern-not-regex: '://[^:/\s@"'']+:(PASSWORD|password|<[^>]*>|\$\{?[A-Za-z_]+\}?|\$\([A-Za-z_]+\)|%s|\{[a-z_]*\})@'
 19      paths:
 20        exclude:
 21          - "tests/"
 22          - "security/"
 23      metadata:
 24        cwe: "CWE-798: Use of Hard-coded Credentials"
 25        owasp: "A07:2021 - Identification and Authentication Failures"
```

CodeQL is GitHub's own SAST alternative (`github/codeql-action/init` and `analyze`, results appear in the Security tab). I chose Semgrep because one tool covers both Python and JavaScript, and its rules are plain YAML that I can read, write and test in a few lines.

### SCA: pip-audit and npm audit

They need no config file; the settings are the command-line flags in [`run-security-scans.sh`](security/run-security-scans.sh) and in the `sca` job:

| Tool | Command | Meaning |
|---|---|---|
| pip-audit | `pip-audit -r backend/requirements.txt` | checks every **pinned** package against the Python Packaging Advisory Database / OSV; exit 1 if any is vulnerable |
| npm audit | `npm audit --omit=dev --audit-level=high` | checks the **production** dependencies of `package-lock.json`; exit 1 on a HIGH or CRITICAL advisory (build tools in `devDependencies` never reach the image) |

### Security policy and the local runner

[`security/SECURITY.md`](security/SECURITY.md) is the short policy (what is checked, rules for the team, branch protection, how to report a vulnerability). [`security/run-security-scans.sh`](security/run-security-scans.sh) runs all the tools above in containers, prints a summary table and exits 1 if any gate is closed; it is run for real at the end of section 4.

---

## 2. The workflow: `devsecops.yml`

> **Status: NOT YET RUN ON GITHUB.** This workflow was written for this homework and never pushed to the project repository, and in this homework repository it sits inside a session folder (GitHub only runs workflows from the root `.github/workflows`), so it has never executed on a GitHub runner. It was linted with `actionlint`, and the scan commands in it were run locally with the same flags (section 4).

_workflows/devsecops.yml, lines 16-41: triggers, concurrency, least-privilege permissions and the tool versions_

```yaml
 16  on:
 17    push:
 18      branches: [main]
 19    pull_request:
 20      branches: [main]
 21    workflow_dispatch:
 22  
 23  concurrency:
 24    group: devsecops-${{ github.ref }}
 25    cancel-in-progress: true
 26  
 27  # least privilege: read-only by default, a job that needs more asks for it itself
 28  permissions:
 29    contents: read
 30  
 31  env:
 32    PYTHON_VERSION: "3.12"
 33    NODE_VERSION: "22"
 34    BACKEND_DIR: backend
 35    FRONTEND_DIR: frontend
 36    SECURITY_DIR: security
 37    K8S_DIR: k8s
 38    SEMGREP_VERSION: "1.181.0"
 39    PIP_AUDIT_VERSION: "2.10.1"
 40    GITLEAKS_IMAGE: zricethezav/gitleaks:v8.30.1
 41    TRIVY_IMAGE: aquasec/trivy:0.75.0
```

_**Local**: actionlint result for the workflow (syntax, expressions, `needs` graph, shell scripts)._

```console
$ docker run --rm -v ./workflows:/repo:ro -w /repo rhysd/actionlint:latest -no-color -verbose devsecops.yml
verbose: Linting devsecops.yml
verbose: Found 0 parse errors in 2 ms for devsecops.yml
verbose: Found total 0 errors in 246 ms for devsecops.yml
# exit code: 0
```

### Jobs and the `needs` graph

| Job (name in the UI) | `needs` | What it does | Fails when |
|---|---|---|---|
| `build` (Build) | none | install backend dependencies, byte-compile, `npm ci && npm run build`, keep `dist/` as artifact | install or compile error |
| `unit-test` (Unit tests) | `build` | `pytest -v --junitxml=...`, keep the report | a test fails |
| `sast` (SAST (Semgrep)) | `unit-test` | Semgrep with `semgrep-rules.yml` + public packs, `--error` | any finding |
| `sca` (SCA (pip-audit and npm audit)) | `unit-test` | pip-audit on `requirements.txt`, npm audit on production deps | a known vulnerability |
| `secret-scan` (Secret scan (gitleaks)) | `unit-test` | gitleaks over the full history with `.gitleaks.toml` | a secret in any commit |
| `docker-build` (Docker build (service)) | `unit-test` | build backend and frontend once, keep each image as a tar artifact | build error |
| `image-scan` (Image scan (service)) | `docker-build` | Trivy on the tar with `trivy.yaml` | HIGH/CRITICAL with a fix |
| `security-gate` (Security gate) | `sast`, `sca`, `secret-scan`, `image-scan` | **runs always**, opens only if all four succeeded | any of them did not succeed |
| `push-image` (Push image (service)) | `security-gate` | `docker load` the scanned tar, log in with `GITHUB_TOKEN`, push `:<commit sha>` | only runs on `main` after the gate |
| `deploy` (Deploy to Kubernetes) | `push-image` | `kubectl apply`, `set image`, `rollout status` | only runs if `DEPLOY_ENABLED` is `true` |

Design choices worth knowing:

- **Build once, scan that exact image, push that exact image.** `docker-build` saves the image as a tar artifact; `image-scan` scans the tar; `push-image` loads the same tar. A rebuild between scan and push could produce different bytes, so I avoid it.
- **Image tag = commit SHA**, never `latest`, so an image can always be traced to the code that built it.
- **Permissions:** the workflow starts at `contents: read`; only `push-image` raises itself to `packages: write`.
- **Secrets:** only `GITHUB_TOKEN` (automatic) is used to push; `KUBE_CONFIG` is read only in the `deploy` job, and that job is off unless a repository variable says so.

### The security gate

`security-gate` is the single choke point in front of the registry:

_workflows/devsecops.yml, lines 276-314: the security-gate job_

```yaml
276    # ------------------------------------------------------------------
277    # 8. SECURITY GATE: one job that every scan must satisfy.
278    #    if: always() makes it run (and fail) even when an upstream job failed or was skipped.
279    #    Make it a REQUIRED status check in the branch protection rule of main, and nothing
280    #    can be merged while it is red. (GitHub counts a skipped required job as passed,
281    #    which is exactly why this job has to run and decide for itself.)
282    # ------------------------------------------------------------------
283    security-gate:
284      name: Security gate
285      needs: [sast, sca, secret-scan, image-scan]
286      if: ${{ always() }}
287      runs-on: ubuntu-latest
288      steps:
289        - name: Open only if every scan succeeded
290          env:
291            SAST_RESULT: ${{ needs.sast.result }}
292            SCA_RESULT: ${{ needs.sca.result }}
293            SECRET_RESULT: ${{ needs.secret-scan.result }}
294            IMAGE_RESULT: ${{ needs.image-scan.result }}
295          run: |
296            {
297              echo "### Security gate"
298              echo "| Scan | Result |"
299              echo "|---|---|"
300              echo "| SAST (Semgrep) | $SAST_RESULT |"
301              echo "| SCA (pip-audit, npm audit) | $SCA_RESULT |"
302              echo "| Secret scan (gitleaks) | $SECRET_RESULT |"
303              echo "| Image scan (Trivy) | $IMAGE_RESULT |"
304            } >> "$GITHUB_STEP_SUMMARY"
305  
306            closed=0
307            for result in "$SAST_RESULT" "$SCA_RESULT" "$SECRET_RESULT" "$IMAGE_RESULT"; do
308              if [ "$result" != "success" ]; then closed=1; fi
309            done
310            if [ "$closed" -eq 1 ]; then
311              echo "::error title=Security gate closed::at least one scan did not succeed, see the table above"
312              exit 1
313            fi
314            echo "Security gate open: all scans succeeded"
```

How the gate works:

1. `needs: [sast, sca, secret-scan, image-scan]` makes it wait for all four scans.
2. `if: ${{ always() }}` makes it run **even if a scan failed**. Without it, a failed scan would make the gate job *skipped*, and GitHub treats a skipped required check as *passed*, which would be a hole in the gate.
3. The script passes only if every result is exactly `success`; `failure`, `cancelled` and `skipped` all close the gate (exit 1).
4. `push-image` has `needs: security-gate`, so a closed gate means nothing is published, and `deploy` comes after `push-image`.

**Branch protection** makes the gate binding for pull requests: *Settings > Branches > Add rule for `main` > Require status checks to pass before merging*, then select **Unit tests** and **Security gate** (and tick *Require branches to be up to date*). From then on GitHub refuses to merge a pull request while the gate is red. That is a repository setting, not a file, so it is not part of the YAML (and I did not change any repository setting).

To prove the logic, I extracted the real script from the YAML and ran it with different results (**Local**). `GITHUB_STEP_SUMMARY` is pointed at a temporary file because the real variable only exists on a runner.

_**Local**: cut the `run:` script of the gate step out of the workflow file._

```console
$ awk '/IMAGE_RESULT: \$\{\{/{f=1;next} f&&/^        run: \|/{g=1;next} g&&/^  # -/{exit} g' workflows/devsecops.yml | sed 's/^          //' > gate.sh; wc -l gate.sh; head -n 3 gate.sh
20 gate.sh
{
  echo "### Security gate"
  echo "| Scan | Result |"
# exit code: 0
```

_**Local**: all four scans succeeded: the gate opens._

```console
$ export GITHUB_STEP_SUMMARY=gate-summary.md; rm -f gate-summary.md; SAST_RESULT=success SCA_RESULT=success SECRET_RESULT=success IMAGE_RESULT=success bash gate.sh
Security gate open: all scans succeeded
# exit code: 0
```

_**Local**: the Trivy image scan failed: the gate closes (the `::error` line is what the GitHub UI shows as a red annotation)._

```console
$ export GITHUB_STEP_SUMMARY=gate-summary.md; rm -f gate-summary.md; SAST_RESULT=success SCA_RESULT=success SECRET_RESULT=success IMAGE_RESULT=failure bash gate.sh
::error title=Security gate closed::at least one scan did not succeed, see the table above
# exit code: 1
```

_**Local**: a scan that was skipped also closes the gate, and the table that would appear on the run summary page._

```console
$ export GITHUB_STEP_SUMMARY=gate-summary.md; rm -f gate-summary.md; SAST_RESULT=skipped SCA_RESULT=success SECRET_RESULT=success IMAGE_RESULT=success bash gate.sh; echo; cat gate-summary.md
::error title=Security gate closed::at least one scan did not succeed, see the table above

### Security gate
| Scan | Result |
|---|---|
| SAST (Semgrep) | skipped |
| SCA (pip-audit, npm audit) | success |
| Secret scan (gitleaks) | success |
| Image scan (Trivy) | success |
# exit code: 0
```

---

## 3. What really ran on GitHub (run #4)

The real StockPilot workflow (`ci-cd.yml`, explained in Session 16) ran four times on GitHub, all green. Its jobs cover four stages of this session's flow: build and unit test (`test`), **secret scan** (`secret-scan`), **Docker build + Trivy gate** and **push to GHCR** (`build-scan-push`). All data below was read with read-only `gh` commands.

_**GitHub**: download the log of run #4 once._

```console
$ gh run view 38807406432 --repo Yash-1706/devops-assgn --log > run.log; wc -l run.log
3961 run.log
# exit code: 0
```

_**GitHub**: summary of the run (first lines). The `-` before the deploy job means skipped._

```console
$ gh run view 38807406432 --repo Yash-1706/devops-assgn | head -n 12

✓ main CI/CD · 38807406432
Triggered via push about 2 days ago

JOBS
✓ Validate Helm chart and Terraform in 21s (ID 116671709525)
✓ Scan for committed secrets (gitleaks) in 11s (ID 116671709913)
✓ Test (pytest + frontend build) in 34s (ID 116671709956)
✓ Build, scan and push (backend) in 1m14s (ID 116671994010)
✓ Build, scan and push (frontend) in 55s (ID 116671994086)
- Deploy to EKS with Helm in 0s (ID 116672568911)
# exit code: 0
```

_**GitHub**: the security-relevant steps of the real run: gitleaks, build, Trivy scan, login and push, with their results and durations._

```console
$ gh api repos/Yash-1706/devops-assgn/actions/runs/38807406432/jobs --jq '.jobs[] | select(.name|test("gitleaks|Build, scan")) | "\(.name)\n" + ([.steps[] | select(.number<=8) | "   \(.number) \(.name): \(.conclusion) (\(((.completed_at|fromdate) - (.started_at|fromdate)))s)"] | join("\n"))'
Scan for committed secrets (gitleaks)
   1 Set up job: success (1s)
   2 Run actions/checkout@v7: success (1s)
   3 Run gitleaks over the full git history: success (7s)
   6 Post Run actions/checkout@v7: success (1s)
   7 Complete job: success (0s)
Build, scan and push (backend)
   1 Set up job: success (6s)
   2 Run actions/checkout@v7: success (0s)
   3 Work out the image name (GHCR needs lower case): success (1s)
   4 Run docker/setup-buildx-action@v4: success (7s)
   5 Build image: success (22s)
   6 Scan image with Trivy (fail on HIGH / CRITICAL): success (20s)
   7 Log in to GitHub Container Registry: success (0s)
   8 Push image to GHCR: success (11s)
Build, scan and push (frontend)
   1 Set up job: success (3s)
   2 Run actions/checkout@v7: success (1s)
   3 Work out the image name (GHCR needs lower case): success (0s)
   4 Run docker/setup-buildx-action@v4: success (9s)
   5 Build image: success (12s)
   6 Scan image with Trivy (fail on HIGH / CRITICAL): success (14s)
   7 Log in to GitHub Container Registry: success (1s)
   8 Push image to GHCR: success (6s)
# exit code: 0
```

_**GitHub**: secret scan result of the real run: 61 commits scanned, no leaks._

```console
$ grep -P '^Scan for committed secrets' run.log | cut -f3- | sed -E 's/\^\[\[[0-9;]*m//g; s/^[0-9T:.Z-]+ //' | grep -E 'commits scanned|scanned ~|no leaks found'
9:07PM INF 61 commits scanned.
9:07PM INF scanned ~254938 bytes (254.94 KB) in 58ms
9:07PM INF no leaks found
# exit code: 0
```

_**GitHub**: the Trivy image scan of the real run (severity HIGH,CRITICAL, ignore-unfixed, exit-code 1): both images have 0 vulnerabilities, so the gate stayed open._

```console
$ grep -P '^Build, scan and push \((backend|frontend)\)' run.log | cut -f3- | sed -E 's/^[0-9T:.Z-]+ //' | grep -E '^│ ghcr.io/' | cut -c1-140
│ ghcr.io/yash-1706/stockpilot-backend:8999ad3d61ab1a182cadaa0c78c906ba61ab7697    │   debian   │        0        │    -    │
│ ghcr.io/yash-1706/stockpilot-frontend:8999ad3d61ab1a182cadaa0c78c906ba61ab7697 │ alpine │        0        │    -    │
# exit code: 0
```

_**GitHub**: the push to GHCR happened only after the scan passed (the push step is later in the same job)._

```console
$ grep -P '^Build, scan and push \((backend|frontend)\)' run.log | cut -f3- | sed -E 's/^[0-9T:.Z-]+ //' | grep -E 'Login Succeeded|The push refers to repository|: digest: sha256'
Login Succeeded!
The push refers to repository [ghcr.io/yash-1706/stockpilot-backend]
8999ad3d61ab1a182cadaa0c78c906ba61ab7697: digest: sha256:5c6cb14864956601f212260c4f059d9cfd9afe4dfe374c660987db7c7b308dd5 size: 2616
Login Succeeded!
The push refers to repository [ghcr.io/yash-1706/stockpilot-frontend]
8999ad3d61ab1a182cadaa0c78c906ba61ab7697: digest: sha256:21e250763cd3e1a8bf2c32d81ebb2ac45f15272712ebf6f62193d35f7e6cd4de size: 2823
# exit code: 0
```

On GitHub the real pipeline closes the gate in two ways: the Trivy step exits 1 (the job fails, so the push steps after it never run), and `build-scan-push` has `needs: [test, validate-infra, secret-scan]`, so it does not even start if the tests or the secret scan failed. `devsecops.yml` keeps that behaviour and adds SAST, SCA and an explicit gate job.

---

## 4. Results: every tool run for real

All commands below ran on my laptop (Windows 11, Docker Desktop, Git Bash) in clean copies of the project. Tools run in containers (`python:3.12-slim`, `node:22-alpine`, `zricethezav/gitleaks`, `aquasec/trivy`), so nothing was installed on the machine.

### Step 0: clean copies of the project

_**Local**: a copy without `.git`, dependencies and build output (for the SAST, SCA, build and test runs)._

```console
$ tar -C "$STOCKPILOT" --exclude=.git --exclude=node_modules --exclude=.venv --exclude=dist --exclude=.pytest_cache --exclude=__pycache__ -cf - . | tar -C "$SRC" -xf - && echo "files in the clean copy: $(find "$SRC" -type f | wc -l)"
files in the clean copy: 427
# exit code: 0
```

_**Local**: a separate clone with the full git history for the secret scan (the original repository stays untouched)._

```console
$ git clone -q --no-hardlinks "$STOCKPILOT" "$CLONE" && git -C "$CLONE" log --oneline | wc -l | xargs echo "commits in the clone:" && git -C "$CLONE" log -1 --format="HEAD: %h %s"
commits in the clone: 64
HEAD: 8999ad3 update test suite evidence and dependencies for 48 passing tests
# exit code: 0
```

### Unit tests

The same 48 tests as on GitHub, run again here for completeness.

_**Local**: pytest, quiet mode._

```console
$ docker run --rm -v "$SRC/backend:/src:ro" python:3.12-slim bash -c "cp -r /src /work && cd /work && pip install -q -r requirements-dev.txt 2>&1 | grep -v -E \"WARNING|notice\"; pytest -q 2>&1 | tail -n 4"

................................................                         [100%]
48 passed in 2.17s
# exit code: 0
```

### SAST: Semgrep

First install Semgrep in a container, check that my rule file is valid, then scan the backend and the frontend source with exactly the flags of the `sast` job.

_**Local**: a container named `s17-sast` with Semgrep 1.181.0._

```console
$ docker run -d --name s17-sast -v ./security:/work/security:ro -v "$SRC:/src:ro" python:3.12-slim sleep infinity >/dev/null && docker exec s17-sast bash -c "pip install -q semgrep==1.181.0 2>&1 | grep -v -E \"WARNING|notice\"; semgrep --version"

1.181.0
# exit code: 0
```

_**Local**: the custom rule file is valid (7 rules)._

```console
$ docker exec -w /work s17-sast semgrep --validate --config security/semgrep-rules.yml --metrics=off
Configuration is valid - found 0 configuration error(s), and 7 rule(s).
If Semgrep missed a finding, please send us feedback to let us know!
See https://semgrep.dev/docs/reporting-false-negatives/
# exit code: 0
```

_**Local**: SAST on StockPilot. Semgrep reports 0 findings (my 7 rules plus the public rule packs), so the gate is open. `--error` would make the exit code 1 on any finding._

```console
$ docker exec s17-sast bash -c "cp -r /src /work/project && cd /work/project && semgrep scan --config /work/security/semgrep-rules.yml --config p/python --config p/javascript --config p/dockerfile --metrics=off --error --sarif-output=/tmp/semgrep.sarif backend frontend/src frontend/Dockerfile"
[output cut: showing the last 22 of 32 lines] ...
  js               69      14          Custom          7                                                                
  python          156      13                                                                                           
  dockerfile        7       2                                                                                           
                                                                                                                        
                
                
┌──────────────┐
│ Scan Summary │
└──────────────┘
✅ Scan completed successfully.
 • Findings: 0 (0 blocking)
 • Rules run: 233
 • Targets scanned: 36
 • Parsed lines: ~100.0%
 • Scan skipped: 
   ◦ Files matching .semgrepignore patterns: 6
 • For a detailed list of skipped files and lines, run semgrep with the --verbose flag
Ran 233 rules on 36 files: 0 findings.
(need more rules? `semgrep login` for additional free Semgrep Registry rules)

If Semgrep missed a finding, please send us feedback to let us know!
See https://semgrep.dev/docs/reporting-false-negatives/
# exit code: 0
```

_**Local**: the SARIF report that the job keeps as an artifact._

```console
$ docker exec s17-sast bash -c "ls -l /tmp/semgrep.sarif"
-rw-r--r-- 1 root root 487433 Oct 18 14:29 /tmp/semgrep.sarif
# exit code: 0
```

**Does the SAST gate really close?** A clean result only means something if the tool also fails on bad code. I wrote a throw-away file with three classic mistakes (command injection, `eval` on user input, a database password in a URL) outside the project and scanned it with the same config:

_**Local**: Semgrep finds all three (blank lines removed from its output; exit code 1 means: gate closed)._

```console
$ docker exec s17-sast bash -c "mkdir -p /work/bad && cd /work/bad && printf \"import subprocess\nsubprocess.run(cmd, shell=True)\nx = eval(user_input)\nDB = \\\"postgresql://app:changeme@db/app\\\"\n\" > bad.py && cat bad.py && semgrep scan --config /work/security/semgrep-rules.yml --metrics=off --error bad.py" 2>&1 | grep -v -E "^ *$"
import subprocess
subprocess.run(cmd, shell=True)
x = eval(user_input)
DB = "postgresql://app:changeme@db/app"
┌─────────────┐
│ Scan Status │
└─────────────┘
  Scanning 1 file tracked by git with 7 Code rules:
  Language      Rules   Files          Origin   Rules                                                                   
 ─────────────────────────────        ────────────────                                                                  
  python            5       1          Custom       7                                                                   
  <multilang>       1       1                                                                                           
┌──────────────┐
│ Scan Summary │
└──────────────┘
✅ Scan completed successfully.
 • Findings: 3 (3 blocking)
 • Rules run: 6
 • Targets scanned: 1
 • Parsed lines: ~100.0%
 • No ignore information available
Ran 6 rules on 1 file: 3 findings.
┌─────────────────┐
│ 3 Code Findings │
└─────────────────┘
    bad.py
   ❯❯❱ work.security.stockpilot-subprocess-shell-true
          ❰❰ Blocking ❱❱
          subprocess called with shell=True. If any part of the command comes from a request, this is command
          injection. Pass the command as a list and leave shell=False.                                       
            2┆ subprocess.run(cmd, shell=True)
   ❯❯❱ work.security.stockpilot-eval-or-exec-on-dynamic-value
          ❰❰ Blocking ❱❱
          eval()/exec() on a non-literal value executes arbitrary code. Parse the data instead (json,
          ast.literal_eval).                                                                         
            3┆ x = eval(user_input)
   ❯❯❱ work.security.stockpilot-database-url-with-inline-password
          ❰❰ Blocking ❱❱
          A database URL contains a password (scheme://user:password@host). Read the whole URL from an
          environment variable (DATABASE_URL) or a Kubernetes Secret instead.                         
            4┆ DB = "postgresql://app:changeme@db/app"
# exit code: 1
```

### SCA: pip-audit and npm audit

SCA checks the *dependencies* against databases of known vulnerabilities. The Python packages are pinned in `requirements.txt`, which makes the result exact.

_**Local**: pip-audit on the pinned backend requirements (it resolves them in a temporary virtual environment)._

```console
$ docker run --rm -v "$SRC/backend:/src:ro" python:3.12-slim bash -c "pip install -q pip-audit==2.10.1 2>&1 | grep -v -E \"WARNING|notice\"; pip-audit -r /src/requirements.txt --progress-spinner off"

No known vulnerabilities found
# exit code: 0
```

_**Local**: npm audit on the production dependencies (the gate command of the `sca` job)._

```console
$ docker run --rm -v "$SRC/frontend:/src:ro" node:22-alpine sh -c "cp -r /src /app && cd /app && npm audit --omit=dev --audit-level=high"
found 0 vulnerabilities
npm notice
npm notice New major version of npm available! 10.9.9 -> 12.2.0
npm notice Changelog: https://github.com/npm/cli/releases/tag/v12.2.0
npm notice To update run: npm install -g npm@12.2.0
npm notice
# exit code: 0
```

_**Local**: for completeness, npm audit including the development dependencies (Vite and its plugin): also clean._

```console
$ docker run --rm -v "$SRC/frontend:/src:ro" node:22-alpine sh -c "cp -r /src /app && cd /app && npm audit"
found 0 vulnerabilities
npm notice
npm notice New major version of npm available! 10.9.9 -> 12.2.0
npm notice Changelog: https://github.com/npm/cli/releases/tag/v12.2.0
npm notice To update run: npm install -g npm@12.2.0
npm notice
# exit code: 0
```

**Does the SCA gate really close?** The same pip-audit on a deliberately outdated requirements file (a throw-away file I will also use for the vulnerable image below):

_The outdated pins (throw-away file, not part of the project)._

```console
$ cat vuln/requirements.txt
Django==3.0.0
Flask==0.12.2
Jinja2==2.10
requests==2.19.0
urllib3==1.23
# exit code: 0
```

_**Local**: pip-audit exits 1 and lists the vulnerable packages._

```console
$ docker run --rm -v ./vuln:/src:ro python:3.12-slim bash -c "pip install -q pip-audit==2.10.1 2>&1 | grep -v -E \"WARNING|notice\"; pip-audit -r /src/requirements.txt --progress-spinner off"

Found 97 known vulnerabilities in 6 packages
Name     Version ID              Fix Versions
-------- ------- --------------- --------------------
django   3.0     PYSEC-2021-9    2.2.18,3.0.12,3.1.6
django   3.0     PYSEC-2020-33   2.2.16,3.0.10,3.1.1
django   3.0     PYSEC-2020-31   2.2.13,3.0.7
django   3.0     PYSEC-2020-36   1.11.29,2.2.11,3.0.4
django   3.0     PYSEC-2021-98   2.2.24,3.1.12,3.2.4
django   3.0     PYSEC-2021-6    2.2.20,3.0.14,3.1.8
django   3.0     PYSEC-2021-99   2.2.24,3.1.12,3.2.4
django   3.0     PYSEC-2020-35   1.11.28,2.2.10,3.0.3
django   3.0     PYSEC-2020-34   2.2.16,3.0.10,3.1.1
django   3.0     PYSEC-2020-32   2.2.13,3.0.7
django   3.0     PYSEC-2020-31   2.2.13,3.0.7
django   3.0     PYSEC-2021-98   2.2.24,3.1.12,3.2.4
django   3.0     PYSEC-2021-6    2.2.20,3.0.14,3.1.8
django   3.0     PYSEC-2019-16   1.11.27,2.2.9,3.0.1
django   3.0     PYSEC-2020-34   2.2.16,3.0.10,3.1.1
django   3.0     PYSEC-2020-36   1.11.29,2.2.11,3.0.4
django   3.0     PYSEC-2021-439  2.2.25,3.1.14,3.2.10
django   3.0     PYSEC-2021-7    2.2.21,3.1.9,3.2.1
... [output cut here: showing the first 22 of 101 lines]
# exit code: 1
```

### Secret scan: gitleaks over the git history

Gitleaks reads the *history* of the clone with my `.gitleaks.toml`. (The clone has 64 commits, see Step 0; gitleaks prints its own count of scanned commits, 61, the same figure as in the real GitHub run on this same HEAD.)

_**Local**: secret scan of the whole history. No leaks._

```console
$ docker run --rm -v "$CLONE:/repo:ro" -v ./security:/cfg:ro zricethezav/gitleaks:v8.30.1 git /repo --config /cfg/.gitleaks.toml --no-banner --redact --verbose
2:31PM INF Unknown SCM platform. Use --platform to include links in findings. host=
2:31PM INF 61 commits scanned.
2:31PM INF scanned ~254938 bytes (254.94 KB) in 5.72s
2:31PM INF no leaks found
# exit code: 0
```

### Docker build and container image scan: Trivy

Build the two images exactly like the `docker-build` job does (`s17-` names are mine and are deleted at the end of the session).

_**Local**: build both images (`-q` prints only the image ids)._

```console
$ docker build -q -t s17-backend:local "$SRC/backend" && docker build -q -t s17-frontend:local "$SRC/frontend"
sha256:bba12594e8fcaa3756e3ef4e4451b198e97a21674b45c576b141208efef03a57
sha256:e7da8577acbebec5dca72fd81aeb96c4cec7a29c6e0f585cc55e297134404591
# exit code: 0
```

_**Local**: the two images._

```console
$ docker images --filter "reference=s17-*" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
REPOSITORY:TAG       SIZE
s17-frontend:local   95.3MB
s17-backend:local    302MB
# exit code: 0
```

Trivy runs in a container with the Docker socket mounted (so it can read the local images), the `security/` folder mounted read-only, and a named volume `s17-trivy-cache` that keeps the vulnerability database between runs. `--config security/trivy.yaml` carries the whole policy (HIGH/CRITICAL, ignore-unfixed, exit-code 1, `.trivyignore`).

_**Local**: Trivy on the backend image. 0 vulnerabilities of severity HIGH/CRITICAL that have a fix: exit code 0, gate open._

```console
$ docker run --rm -v //var/run/docker.sock:/var/run/docker.sock -v ./security:/work/security:ro -v s17-trivy-cache:/root/.cache -w /work aquasec/trivy:0.75.0 image --skip-version-check --config security/trivy.yaml s17-backend:local
2026-10-18T14:39:07Z	INFO	Loaded	file_path="security/trivy.yaml"
2026-10-18T14:39:07Z	INFO	[vulndb] Need to update DB
2026-10-18T14:39:07Z	INFO	[vulndb] Downloading vulnerability DB...
2026-10-18T14:39:07Z	INFO	[vulndb] Downloading artifact...	repo="public.ecr.aws/aquasecurity/trivy-db:2"
794.46 KiB / 128.46 MiB [>___________________________________________________________] 0.60% ? p/s ?2.36 MiB / 128.46 MiB [->____________________________________________________________] 1.84% ? p/s ?3.56 MiB / 128.46 MiB [->____________________________________________________________] 2.77% ? p/s ?4.65 MiB / 128.46 MiB [->_______________________________________________] 3.62% 6.46 MiB p/s ETA 19s6.45 MiB / 128.46 MiB [-->______________________________________________] 5.02% 6.46 MiB p/s ETA 18s7.43 MiB / 128.46 MiB [-->______________________________________________] 5.78% 6.46 MiB p/s ETA 18s8.74 MiB / 128.46 MiB [--->_____________________________________________] 6.80% 6.48 MiB p/s ETA 18s9.89 MiB / 128.46 MiB [--->_____________________________________________] 7.70% 6.48 MiB p/s ETA 18s10.75 MiB / 128.46 MiB [---->___________________________________________] 8.37% 6.48 MiB p/s ETA 18s12.15 MiB / 128.46 MiB [---->___________________________________________] 9.46% 6.43 MiB p/s ETA 18s13.78 MiB / 128.46 MiB [----->_________________________________________] 10.72% 6.43 MiB p/s ETA 17s15.55 MiB / 128.46 MiB [----->_________________________________________] 12.10% 6.43 MiB p/s ETA 17s16.35 MiB / 128.46 MiB [----->_________________________________________] 12.73% 6.47 MiB p/s ETA 17s18.04 MiB / 128.46 MiB [------>________________________________________] 14.04% 6.47 MiB p/s ETA 17s19.55 MiB / 128.46 MiB [------->_______________________________________] 15.22% 6.47 MiB p/s ETA 16s20.16 MiB / 128.46 MiB [------->_______________________________________] 15.70% 6.46 MiB p/s ETA 16s21.44 MiB / 128.46 MiB [------->_______________________________________] 16.69% 6.46 MiB p/s ETA 16s23.08 MiB / 128.46 MiB [-------->______________________________________] 17.97% 6.46 MiB p/s ETA 16s24.25 MiB / 128.46 MiB [-------->______________________________________] 18.88% 6.48 MiB p/s ETA 16s25.51 MiB / 128.46 MiB [--------->_____________________________________] 19.85% 6.48 MiB p/s ETA 15s26.35 MiB / 128.46 MiB [--------->_____________________________________] 20.51% 6.48 MiB p/s ETA 15s27.85 MiB / 128.46 MiB [---------->____________________________________] 21.68% 6.45 MiB p/s ETA 15s28.59 MiB / 128.46 MiB [---------->____________________________________] 22.26% 6.45 MiB p/s ETA 15s29.21 MiB / 128.46 MiB [---------->____________________________________] 22.74% 6.45 MiB p/s ETA 15s29.65 MiB / 128.46 MiB [---------->____________________________________] 23.08% 6.23 MiB p/s ETA 15s30.38 MiB / 128.46 MiB [----------->___________________________________] 23.65% 6.23 MiB p/s ETA 15s31.50 MiB / 128.46 MiB [----------->___________________________________] 24.52% 6.23 MiB p/s ETA 15s33.51 MiB / 128.46 MiB [------------>__________________________________] 26.08% 6.24 MiB p/s ETA 15s35.21 MiB / 128.46 MiB [------------>__________________________________] 27.41% 6.24 MiB p/s ETA 14s36.51 MiB / 128.46 MiB [------------->_________________________________] 28.42% 6.24 MiB p/s ETA 14s38.18 MiB / 128.46 MiB [------------->_________________________________] 29.72% 6.34 MiB p/s ETA 14s40.48 MiB / 128.46 MiB [-------------->________________________________] 31.52% 6.34 MiB p/s ETA 13s42.25 MiB / 128.46 MiB [--------------->_______________________________] 32.89% 6.34 MiB p/s ETA 13s43.79 MiB / 128.46 MiB [---------------->______________________________] 34.09% 6.54 MiB p/s ETA 12s44.96 MiB / 128.46 MiB [---------------->______________________________] 35.00% 6.54 MiB p/s ETA 12s46.18 MiB / 128.46 MiB [---------------->______________________________] 35.95% 6.54 MiB p/s ETA 12s47.41 MiB / 128.46 MiB [----------------->_____________________________] 36.91% 6.50 MiB p/s ETA 12s48.55 MiB / 128.46 MiB [----------------->_____________________________] 37.79% 6.50 MiB p/s ETA 12s50.08 MiB / 128.46 MiB [------------------>____________________________] 38.99% 6.50 MiB p/s ETA 12s51.14 MiB / 128.46 MiB [------------------>____________________________] 39.81% 6.48 MiB p/s ETA 11s52.60 MiB / 128.46 MiB [------------------->___________________________] 40.95% 6.48 MiB p/s ETA 11s54.08 MiB / 128.46 MiB [------------------->___________________________] 42.10% 6.48 MiB p/s ETA 11s55.07 MiB / 128.46 MiB [-------------------->__________________________] 42.87% 6.49 MiB p/s ETA 11s55.96 MiB / 128.46 MiB [-------------------->__________________________] 43.56% 6.49 MiB p/s ETA 11s57.32 MiB / 128.46 MiB [-------------------->__________________________] 44.62% 6.49 MiB p/s ETA 10s59.07 MiB / 128.46 MiB [--------------------->_________________________] 45.98% 6.50 MiB p/s ETA 10s60.33 MiB / 128.46 MiB [---------------------->________________________] 46.97% 6.50 MiB p/s ETA 10s61.75 MiB / 128.46 MiB [---------------------->________________________] 48.07% 6.50 MiB p/s ETA 10s62.87 MiB / 128.46 MiB [----------------------->_______________________] 48.95% 6.49 MiB p/s ETA 10s64.33 MiB / 128.46 MiB [------------------------>_______________________] 50.07% 6.49 MiB p/s ETA 9s65.25 MiB / 128.46 MiB [------------------------>_______________________] 50.79% 6.49 MiB p/s ETA 9s66.54 MiB / 128.46 MiB [------------------------>_______________________] 51.80% 6.47 MiB p/s ETA 9s68.20 MiB / 128.46 MiB [------------------------->______________________] 53.09% 6.47 MiB p/s ETA 9s69.59 MiB / 128.46 MiB [-------------------------->_____________________] 54.18% 6.47 MiB p/s ETA 9s70.97 MiB / 128.46 MiB [-------------------------->_____________________] 55.25% 6.53 MiB p/s ETA 8s72.45 MiB / 128.46 MiB [--------------------------->____________________] 56.40% 6.53 MiB p/s ETA 8s73.54 MiB / 128.46 MiB [--------------------------->____________________] 57.25% 6.53 MiB p/s ETA 8s74.60 MiB / 128.46 MiB [--------------------------->____________________] 58.07% 6.49 MiB p/s ETA 8s76.38 MiB / 128.46 MiB [---------------------------->___________________] 59.46% 6.49 MiB p/s ETA 8s77.44 MiB / 128.46 MiB [---------------------------->___________________] 60.28% 6.49 MiB p/s ETA 7s78.85 MiB / 128.46 MiB [----------------------------->__________________] 61.38% 6.53 MiB p/s ETA 7s80.23 MiB / 128.46 MiB [----------------------------->__________________] 62.46% 6.53 MiB p/s ETA 7s81.83 MiB / 128.46 MiB [------------------------------>_________________] 63.70% 6.53 MiB p/s ETA 7s82.45 MiB / 128.46 MiB [------------------------------>_________________] 64.18% 6.50 MiB p/s ETA 7s83.85 MiB / 128.46 MiB [------------------------------->________________] 65.27% 6.50 MiB p/s ETA 6s84.91 MiB / 128.46 MiB [------------------------------->________________] 66.10% 6.50 MiB p/s ETA 6s86.10 MiB / 128.46 MiB [-------------------------------->_______________] 67.03% 6.47 MiB p/s ETA 6s87.31 MiB / 128.46 MiB [-------------------------------->_______________] 67.97% 6.47 MiB p/s ETA 6s88.09 MiB / 128.46 MiB [-------------------------------->_______________] 68.57% 6.47 MiB p/s ETA 6s88.87 MiB / 128.46 MiB [--------------------------------->______________] 69.18% 6.35 MiB p/s ETA 6s89.73 MiB / 128.46 MiB [--------------------------------->______________] 69.85% 6.35 MiB p/s ETA 6s90.51 MiB / 128.46 MiB [--------------------------------->______________] 70.46% 6.35 MiB p/s ETA 5s91.04 MiB / 128.46 MiB [---------------------------------->_____________] 70.87% 6.18 MiB p/s ETA 6s91.62 MiB / 128.46 MiB [---------------------------------->_____________] 71.32% 6.18 MiB p/s ETA 5s92.45 MiB / 128.46 MiB [---------------------------------->_____________] 71.96% 6.18 MiB p/s ETA 5s92.77 MiB / 128.46 MiB [---------------------------------->_____________] 72.22% 5.96 MiB p/s ETA 5s93.47 MiB / 128.46 MiB [---------------------------------->_____________] 72.76% 5.96 MiB p/s ETA 5s94.30 MiB / 128.46 MiB [----------------------------------->____________] 73.41% 5.96 MiB p/s ETA 5s95.24 MiB / 128.46 MiB [----------------------------------->____________] 74.14% 5.84 MiB p/s ETA 5s96.26 MiB / 128.46 MiB [----------------------------------->____________] 74.93% 5.84 MiB p/s ETA 5s98.10 MiB / 128.46 MiB [------------------------------------>___________] 76.37% 5.84 MiB p/s ETA 5s99.82 MiB / 128.46 MiB [------------------------------------->__________] 77.71% 5.96 MiB p/s ETA 4s101.99 MiB / 128.46 MiB [------------------------------------->_________] 79.40% 5.96 MiB p/s ETA 4s102.98 MiB / 128.46 MiB [------------------------------------->_________] 80.17% 5.96 MiB p/s ETA 4s104.49 MiB / 128.46 MiB [-------------------------------------->________] 81.34% 6.08 MiB p/s ETA 3s105.91 MiB / 128.46 MiB [-------------------------------------->________] 82.44% 6.08 MiB p/s ETA 3s107.19 MiB / 128.46 MiB [--------------------------------------->_______] 83.44% 6.08 MiB p/s ETA 3s107.79 MiB / 128.46 MiB [--------------------------------------->_______] 83.91% 6.04 MiB p/s ETA 3s108.55 MiB / 128.46 MiB [--------------------------------------->_______] 84.50% 6.04 MiB p/s ETA 3s109.02 MiB / 128.46 MiB [--------------------------------------->_______] 84.87% 6.04 MiB p/s ETA 3s110.01 MiB / 128.46 MiB [---------------------------------------->______] 85.64% 5.89 MiB p/s ETA 3s110.60 MiB / 128.46 MiB [---------------------------------------->______] 86.10% 5.89 MiB p/s ETA 3s111.78 MiB / 128.46 MiB [---------------------------------------->______] 87.02% 5.89 MiB p/s ETA 2s112.66 MiB / 128.46 MiB [----------------------------------------->_____] 87.70% 5.79 MiB p/s ETA 2s113.74 MiB / 128.46 MiB [----------------------------------------->_____] 88.54% 5.79 MiB p/s ETA 2s114.33 MiB / 128.46 MiB [----------------------------------------->_____] 89.00% 5.79 MiB p/s ETA 2s115.34 MiB / 128.46 MiB [------------------------------------------>____] 89.78% 5.71 MiB p/s ETA 2s116.74 MiB / 128.46 MiB [------------------------------------------>____] 90.88% 5.71 MiB p/s ETA 2s118.01 MiB / 128.46 MiB [------------------------------------------->___] 91.86% 5.71 MiB p/s ETA 1s118.84 MiB / 128.46 MiB [------------------------------------------->___] 92.51% 5.72 MiB p/s ETA 1s119.84 MiB / 128.46 MiB [------------------------------------------->___] 93.29% 5.72 MiB p/s ETA 1s120.75 MiB / 128.46 MiB [-------------------------------------------->__] 94.00% 5.72 MiB p/s ETA 1s121.41 MiB / 128.46 MiB [-------------------------------------------->__] 94.51% 5.62 MiB p/s ETA 1s122.49 MiB / 128.46 MiB [-------------------------------------------->__] 95.35% 5.62 MiB p/s ETA 1s123.32 MiB / 128.46 MiB [--------------------------------------------->_] 96.00% 5.62 MiB p/s ETA 0s124.08 MiB / 128.46 MiB [--------------------------------------------->_] 96.59% 5.55 MiB p/s ETA 0s124.87 MiB / 128.46 MiB [--------------------------------------------->_] 97.20% 5.55 MiB p/s ETA 0s125.63 MiB / 128.46 MiB [--------------------------------------------->_] 97.80% 5.55 MiB p/s ETA 0s126.41 MiB / 128.46 MiB [---------------------------------------------->] 98.41% 5.44 MiB p/s ETA 0s127.66 MiB / 128.46 MiB [---------------------------------------------->] 99.37% 5.44 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 5.44 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 5.31 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 5.31 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 5.31 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 4.97 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 4.97 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 4.97 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 4.65 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 4.65 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 4.65 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 4.35 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 4.35 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 4.35 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 4.07 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 4.07 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 4.07 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 3.80 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 3.80 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 3.80 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 3.56 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 3.56 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 3.56 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 3.33 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 3.33 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 3.33 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 3.11 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 3.11 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 3.11 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.91 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.91 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.91 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.73 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.73 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.73 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.55 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.55 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.55 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.39 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.39 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.39 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.23 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.23 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.23 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.09 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.09 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 2.09 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 1.95 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 1.95 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 1.95 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 1.83 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 1.83 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 1.83 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 1.71 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 1.71 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [--------------------------------------------->] 100.00% 1.71 MiB p/s ETA 0s128.46 MiB / 128.46 MiB [-------------------------------------------------] 100.00% 3.89 MiB p/s 33s2026-10-18T14:39:42Z	INFO	[vulndb] Artifact successfully downloaded	repo="public.ecr.aws/aquasecurity/trivy-db:2"
2026-10-18T14:39:42Z	INFO	[vuln] Vulnerability scanning is enabled
2026-10-18T14:39:42Z	INFO	[secret] Secret scanning is enabled
2026-10-18T14:39:42Z	INFO	[secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2026-10-18T14:39:42Z	INFO	[secret] Please see https://trivy.dev/docs/v0.75/guide/scanner/secret#recommendation for faster secret detection
2026-10-18T14:39:49Z	INFO	[python] Licenses acquired from one or more METADATA files may be subject to additional terms. Use `--debug` flag to see all affected packages.
2026-10-18T14:39:50Z	INFO	Detected OS	family="debian" version="13.7"
2026-10-18T14:39:50Z	INFO	[debian] Detecting vulnerabilities...	os_version="13" pkg_num=87
2026-10-18T14:39:50Z	INFO	Number of language-specific files	num=1
2026-10-18T14:39:50Z	INFO	[python-pkg] Detecting vulnerabilities...
2026-10-18T14:39:50Z	WARN	Using severities from other vendors for some vulnerabilities. Read https://trivy.dev/docs/v0.75/guide/scanner/vulnerability#severity-selection for details.

Report Summary

┌──────────────────────────────────────────────────────────────────────────────────┬────────────┬─────────────────┬─────────┐
│                                      Target                                      │    Type    │ Vulnerabilities │ Secrets │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ s17-backend:local (debian 13.7)                                                  │   debian   │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.12/site-packages/alembic-1.20.0.dist-info/METADATA         │ python-pkg │        0        │    -    │
... [output cut here: showing the first 24 of 91 lines]
# exit code: 0
```

_**Local**: Trivy on the frontend image: exit code 0, gate open._

```console
$ docker run --rm -v //var/run/docker.sock:/var/run/docker.sock -v ./security:/work/security:ro -v s17-trivy-cache:/root/.cache -w /work aquasec/trivy:0.75.0 image --skip-version-check --config security/trivy.yaml s17-frontend:local
[output cut: showing the last 14 of 19 lines] ...
2026-10-18T14:31:49Z	INFO	Detected OS	family="alpine" version="3.24.2"
2026-10-18T14:31:49Z	INFO	[alpine] Detecting vulnerabilities...	os_version="3.24" repository="3.24" pkg_num=70
2026-10-18T14:31:49Z	INFO	Number of language-specific files	num=0

Report Summary

┌────────────────────────────────────┬────────┬─────────────────┬─────────┐
│               Target               │  Type  │ Vulnerabilities │ Secrets │
├────────────────────────────────────┼────────┼─────────────────┼─────────┤
│ s17-frontend:local (alpine 3.24.2) │ alpine │        0        │    -    │
└────────────────────────────────────┴────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
# exit code: 0
```

### Demonstration: the security gate closes

**Container image gate.** I build a deliberately vulnerable throw-away image, an end-of-life Python 3.8 base with the outdated packages from above, and scan it with the *same* config:

_The throw-away Dockerfile._

```console
$ cat vuln/Dockerfile
# DELIBERATELY VULNERABLE throw-away image used only to prove that the security gate closes
FROM python:3.8-slim
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# exit code: 0
```

_**Local**: build it._

```console
$ docker build -q -t s17-vulnerable:demo vuln
sha256:21285e51b5ef82147520be638c13ebc0718c03fbebe896e85530fd25a53a218a
# exit code: 0
```

_**Local**: Trivy with the same policy on the vulnerable image: HIGH and CRITICAL findings with a fix exist, exit code 1, **gate closed** (first 45 lines of a long table)._

```console
$ docker run --rm -v //var/run/docker.sock:/var/run/docker.sock -v ./security:/work/security:ro -v s17-trivy-cache:/root/.cache -w /work aquasec/trivy:0.75.0 image --skip-version-check --config security/trivy.yaml s17-vulnerable:demo
2026-10-18T14:32:12Z	INFO	Loaded	file_path="security/trivy.yaml"
2026-10-18T14:32:12Z	INFO	[vuln] Vulnerability scanning is enabled
2026-10-18T14:32:12Z	INFO	[secret] Secret scanning is enabled
2026-10-18T14:32:12Z	INFO	[secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2026-10-18T14:32:12Z	INFO	[secret] Please see https://trivy.dev/docs/v0.75/guide/scanner/secret#recommendation for faster secret detection
2026-10-18T14:32:21Z	INFO	[python] Licenses acquired from one or more METADATA files may be subject to additional terms. Use `--debug` flag to see all affected packages.
2026-10-18T14:32:22Z	INFO	Detected OS	family="debian" version="12.7"
2026-10-18T14:32:22Z	INFO	[debian] Detecting vulnerabilities...	os_version="12" pkg_num=106
2026-10-18T14:32:22Z	INFO	Number of language-specific files	num=1
2026-10-18T14:32:22Z	INFO	[python-pkg] Detecting vulnerabilities...
2026-10-18T14:32:22Z	WARN	Using severities from other vendors for some vulnerabilities. Read https://trivy.dev/docs/v0.75/guide/scanner/vulnerability#severity-selection for details.
2026-10-18T14:32:22Z	INFO	Table result includes only package filenames. Use '--format json' option to get the full path to the package file.

Report Summary

┌──────────────────────────────────────────────────────────────────────────────────┬────────────┬─────────────────┬─────────┐
│                                      Target                                      │    Type    │ Vulnerabilities │ Secrets │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ s17-vulnerable:demo (debian 12.7)                                                │   debian   │       61        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/Django-3.0.dist-info/METADATA              │ python-pkg │       13        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/Flask-0.12.2.dist-info/METADATA            │ python-pkg │        3        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/Jinja2-2.10.dist-info/METADATA             │ python-pkg │        1        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/MarkupSafe-2.1.5.dist-info/METADATA        │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/asgiref-3.8.1.dist-info/METADATA           │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/certifi-2026.7.22.dist-info/METADATA       │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/chardet-3.0.4.dist-info/METADATA           │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/click-8.1.8.dist-info/METADATA             │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/idna-2.7.dist-info/METADATA                │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/itsdangerous-2.2.0.dist-info/METADATA      │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/pip-23.0.1.dist-info/METADATA              │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/pytz-2026.5.dist-info/METADATA             │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/requests-2.19.0.dist-info/METADATA         │ python-pkg │        1        │    -    │
... [output cut here: showing the first 45 of 423 lines]
# exit code: 1
```

_**Local**: the same scan as a summary: the number of findings per component._

```console
$ docker run --rm -v //var/run/docker.sock:/var/run/docker.sock -v ./security:/work/security:ro -v s17-trivy-cache:/root/.cache -w /work aquasec/trivy:0.75.0 image --skip-version-check --config security/trivy.yaml --report summary s17-vulnerable:demo
2026-10-18T14:32:24Z	INFO	Loaded	file_path="security/trivy.yaml"
2026-10-18T14:32:24Z	INFO	[vuln] Vulnerability scanning is enabled
2026-10-18T14:32:24Z	INFO	[secret] Secret scanning is enabled
2026-10-18T14:32:24Z	INFO	[secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2026-10-18T14:32:24Z	INFO	[secret] Please see https://trivy.dev/docs/v0.75/guide/scanner/secret#recommendation for faster secret detection
2026-10-18T14:32:25Z	INFO	Detected OS	family="debian" version="12.7"
2026-10-18T14:32:25Z	INFO	[debian] Detecting vulnerabilities...	os_version="12" pkg_num=106
2026-10-18T14:32:25Z	INFO	Number of language-specific files	num=1
2026-10-18T14:32:25Z	INFO	[python-pkg] Detecting vulnerabilities...
2026-10-18T14:32:25Z	WARN	Using severities from other vendors for some vulnerabilities. Read https://trivy.dev/docs/v0.75/guide/scanner/vulnerability#severity-selection for details.
2026-10-18T14:32:25Z	INFO	Table result includes only package filenames. Use '--format json' option to get the full path to the package file.

Report Summary

┌──────────────────────────────────────────────────────────────────────────────────┬────────────┬─────────────────┬─────────┐
│                                      Target                                      │    Type    │ Vulnerabilities │ Secrets │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ s17-vulnerable:demo (debian 12.7)                                                │   debian   │       61        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/Django-3.0.dist-info/METADATA              │ python-pkg │       13        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/Flask-0.12.2.dist-info/METADATA            │ python-pkg │        3        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/Jinja2-2.10.dist-info/METADATA             │ python-pkg │        1        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/MarkupSafe-2.1.5.dist-info/METADATA        │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/asgiref-3.8.1.dist-info/METADATA           │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.8/site-packages/certifi-2026.7.22.dist-info/METADATA       │ python-pkg │        0        │    -    │
... [output cut here: showing the first 30 of 422 lines]
# exit code: 1
```

| Image | Trivy exit code | Gate |
|---|---|---|
| `s17-backend:local` (StockPilot backend) | 0 | open: image may be pushed |
| `s17-frontend:local` (StockPilot frontend) | 0 | open: image may be pushed |
| `s17-vulnerable:demo` (throw-away) | 1 | **closed: pipeline fails, nothing is pushed** |

The table above is built from the exit codes of the three scans, not typed by hand.

**Secret scan gate.** A throw-away git repository (outside the project) with fake keys. The key strings are assembled with `printf` at run time and the scan uses `--redact`, so no key text appears in this README. `AKIA` followed by 16 letters is the format of an AWS access key id. I use two fake keys: the one printed in the AWS documentation (assembled from `AKIA` + `IOSFODNN7EXAMPLE`) and an invented one made of a keyboard row.

_**Local**: create the throw-away repository._

```console
$ rm -rf secret-demo && mkdir -p secret-demo/backend/app secret-demo/backend/tests && cd secret-demo && git init -q -b main && git config core.autocrlf false && git config user.name "Demo User" && git config user.email "demo@example.com" && echo "# secret scan demo" > README.md && git add . && git commit -q -m "first commit" && git log --oneline
ad0c69e first commit
# exit code: 0
```

_**Local**: commit 2 contains the AWS *documentation* example key._

```console
$ cd secret-demo && printf "AWS_ACCESS_KEY_ID = \"%s%s\"\n" AKIA IOSFODNN7EXAMPLE > backend/app/docs_example.py && git add . && git commit -q -m "add the AWS documentation example key" && git log --oneline -n 1
4cf11ca add the AWS documentation example key
# exit code: 0
```

_**Local**: gitleaks does **not** report it, although it does report the invented key in the next steps: its built-in rules ignore AWS's published example key, which is public and not a real credential. So this is not a useful test key._

```console
$ docker run --rm -v ./secret-demo:/repo:ro -v ./security:/cfg:ro zricethezav/gitleaks:v8.30.1 git /repo --no-banner --redact --verbose
2:32PM INF 2 commits scanned.
2:32PM INF scanned ~62 bytes (62 bytes) in 352ms
2:32PM INF no leaks found
# exit code: 0
```

_**Local**: commit 3 puts an invented fake key into a *test fixture* file._

```console
$ cd secret-demo && printf "AWS_ACCESS_KEY_ID = \"%s%s\"\n" AKIA QWERTYUIOPASDFGH > backend/tests/fixture.py && git add . && git commit -q -m "add a test fixture with a fake key" && git log --oneline -n 1
27e87b2 add a test fixture with a fake key
# exit code: 0
```

_**Local**: with the default rules (no project config) the fake key is found: exit code 1, gate closed. Secret and finding are redacted._

```console
$ docker run --rm -v ./secret-demo:/repo:ro -v ./security:/cfg:ro zricethezav/gitleaks:v8.30.1 git /repo --no-banner --redact --verbose
Finding:     ...WS_ACCESS_KEY_ID = "REDACTED
Secret:      REDACTED
RuleID:      aws-access-token
Entropy:     3.984184
File:        backend/tests/fixture.py
Line:        1
Commit:      27e87b2d914eefe45d0a591653cde69cadd431b2
Author:      Demo User
Email:       demo@example.com
Date:        2026-10-18T14:32:31Z
Fingerprint: 27e87b2d914eefe45d0a591653cde69cadd431b2:backend/tests/fixture.py:aws-access-token:1

2:32PM INF 3 commits scanned.
2:32PM INF scanned ~105 bytes (105 bytes) in 392ms
2:32PM WRN leaks found: 1
# exit code: 1
```

_**Local**: with the project config the same commit passes, because `backend/tests/` is allowlisted as a fixtures folder. This is the allowlist working._

```console
$ docker run --rm -v ./secret-demo:/repo:ro -v ./security:/cfg:ro zricethezav/gitleaks:v8.30.1 git /repo --no-banner --redact --verbose --config /cfg/.gitleaks.toml
2:32PM INF 3 commits scanned.
2:32PM INF scanned ~105 bytes (105 bytes) in 509ms
2:32PM INF no leaks found
# exit code: 0
```

_**Local**: commit 4 is the real mistake: the same fake key in application code._

```console
$ cd secret-demo && printf "AWS_ACCESS_KEY_ID = \"%s%s\"\n" AKIA QWERTYUIOPASDFGH > backend/app/settings.py && git add . && git commit -q -m "oops: a key in application code" && git log --oneline -n 1
6e19935 oops: a key in application code
# exit code: 0
```

_**Local**: the project config does not cover application code, so gitleaks fails the build: exit code 1, gate closed. Note the file, the rule id and the commit hash it reports._

```console
$ docker run --rm -v ./secret-demo:/repo:ro -v ./security:/cfg:ro zricethezav/gitleaks:v8.30.1 git /repo --no-banner --redact --verbose --config /cfg/.gitleaks.toml
Finding:     ...WS_ACCESS_KEY_ID = "REDACTED
Secret:      REDACTED
RuleID:      aws-access-token
Entropy:     3.984184
File:        backend/app/settings.py
Line:        1
Commit:      6e19935c9af8684bceffb3158410b95f70b44f2c
Author:      Demo User
Email:       demo@example.com
Date:        2026-10-18T14:32:36Z
Fingerprint: 6e19935c9af8684bceffb3158410b95f70b44f2c:backend/app/settings.py:aws-access-token:1

2:32PM INF 4 commits scanned.
2:32PM INF scanned ~148 bytes (148 bytes) in 627ms
2:32PM WRN leaks found: 1
# exit code: 1
```

_**Local**: now the "obvious fix": delete the file in a new commit._

```console
$ cd secret-demo && git rm -q backend/app/settings.py && git commit -q -m "remove the key again" && git log --oneline -n 5
cbc7923 remove the key again
6e19935 oops: a key in application code
27e87b2 add a test fixture with a fake key
4cf11ca add the AWS documentation example key
ad0c69e first commit
# exit code: 0
```

_**Local**: the scan **still fails**, because the key is still in the git history. Deleting a leaked secret is not enough: it must be rotated, and the history cleaned if the repository is shared._

```console
$ docker run --rm -v ./secret-demo:/repo:ro -v ./security:/cfg:ro zricethezav/gitleaks:v8.30.1 git /repo --no-banner --redact --verbose --config /cfg/.gitleaks.toml
[output cut: showing the last 6 of 15 lines] ...
Date:        2026-10-18T14:32:36Z
Fingerprint: 6e19935c9af8684bceffb3158410b95f70b44f2c:backend/app/settings.py:aws-access-token:1

2:32PM INF 4 commits scanned.
2:32PM INF scanned ~148 bytes (148 bytes) in 553ms
2:32PM WRN leaks found: 1
# exit code: 1
```

_**Local**: since this throw-away repository was never pushed, I can drop the two commits (a real shared repository needs a history rewrite and a force-push *after* the key has been rotated)._

```console
$ cd secret-demo && git reset -q --hard HEAD~2 && git log --oneline
27e87b2 add a test fixture with a fake key
4cf11ca add the AWS documentation example key
ad0c69e first commit
# exit code: 0
```

_**Local**: history clean again: exit code 0, gate open._

```console
$ docker run --rm -v ./secret-demo:/repo:ro -v ./security:/cfg:ro zricethezav/gitleaks:v8.30.1 git /repo --no-banner --redact --verbose --config /cfg/.gitleaks.toml
2:32PM INF 3 commits scanned.
2:32PM INF scanned ~105 bytes (105 bytes) in 435ms
2:32PM INF no leaks found
# exit code: 0
```

### The whole local gate in one command

`run-security-scans.sh` runs every tool above in order and prints a summary (the tools' own output is long, so only the end of the output is shown). It uses the clone with history, and a name prefix so that its images do not clash with the ones above.

_**Local**: the local security gate. Exit code 0 means every gate is open._

```console
$ IMAGE_PREFIX=s17 bash security/run-security-scans.sh "$CLONE"
[output cut: showing the last 16 of 176 lines] ...
└────────────────────────────────────┴────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

----- Image scan trivy (frontend): exit code 0

================ SECURITY GATE (local) ================
SAST  semgrep                    PASS (exit 0)
SCA   pip-audit (backend)        PASS (exit 0)
SCA   npm audit (frontend)       PASS (exit 0)
Secrets gitleaks (history)       PASS (exit 0)
Docker build (2 images)          PASS (exit 0)
Image scan trivy (backend)       PASS (exit 0)
Image scan trivy (frontend)      PASS (exit 0)
GATE OPEN: nothing blocks the push of the images.
# exit code: 0
```

---

## 5. Kubernetes manifests

[`k8s/`](k8s/) deploys the two images that the pipeline produces, plus a small PostgreSQL:

| File | Resources |
|---|---|
| `00-namespace.yaml` | Namespace `stockpilot` with the Pod Security Admission label `enforce: restricted` |
| `01-configmap.yaml` | ConfigMap `stockpilot-config`: non-secret settings (user, database, host, backend URL) |
| `02-postgres.yaml` | Service + StatefulSet (1 replica, 1Gi volume) |
| `03-backend.yaml` | Deployment (2 replicas) + Service `backend` (ClusterIP :8000) |
| `04-frontend.yaml` | Deployment (2 replicas) + Service `frontend` (ClusterIP :80 -> 8080) |

Hardening built in (the pods are written to satisfy the `restricted` Pod Security profile; I could not test that on a live cluster):

| Control | Where |
|---|---|
| Runs as non-root with a fixed numeric uid (backend 10001, frontend 101, postgres 70) | `securityContext.runAsNonRoot` / `runAsUser` |
| No privilege escalation, **all** Linux capabilities dropped, seccomp `RuntimeDefault` | container and pod `securityContext` |
| Read-only root file system (writable `emptyDir` only where needed: `/tmp`, `/etc/nginx/conf.d`, `/var/run/postgresql`) | `readOnlyRootFilesystem: true` |
| CPU and memory requests **and limits** | `resources` |
| Health: `startupProbe` (backend: migrations run first), `livenessProbe`, `readinessProbe` | each container |
| The database password is **not in the manifests**: it comes from the Secret `stockpilot-db` | `secretKeyRef` |
| Nothing is exposed outside the cluster: all Services are `ClusterIP` | Services |
| No service-account token mounted in the pods | `automountServiceAccountToken: false` |

### Create the secret (once per cluster, never committed)

```bash
kubectl apply -f k8s/00-namespace.yaml
kubectl create secret generic stockpilot-db -n stockpilot \
  --from-literal=POSTGRES_PASSWORD="$(openssl rand -hex 16)"
kubectl apply -f k8s/
```

### Validation (offline, no cluster)

I did not apply anything to a cluster. The manifests are validated offline:

_**Local**: kubeconform checks every resource against the official Kubernetes JSON schemas (`-strict` also rejects unknown fields)._

```console
$ docker run --rm -v ./k8s:/work:ro ghcr.io/yannh/kubeconform -summary -strict -verbose /work
/work/02-postgres.yaml - Service postgres is valid
/work/01-configmap.yaml - ConfigMap stockpilot-config is valid
/work/00-namespace.yaml - Namespace stockpilot is valid
/work/03-backend.yaml - Service backend is valid
/work/04-frontend.yaml - Service frontend is valid
/work/02-postgres.yaml - StatefulSet postgres is valid
/work/03-backend.yaml - Deployment backend is valid
/work/04-frontend.yaml - Deployment frontend is valid
Summary: 8 resources found in 5 files - Valid: 8, Invalid: 0, Errors: 0, Skipped: 0
# exit code: 0
```

_**Local**: I also tried `kubectl apply --dry-run=client`, but kubectl still needs an API server to look up resource types, so it **cannot run offline** (an empty kubeconfig was used on purpose, so nothing could reach a real cluster). kubeconform is the offline check._

```console
$ KUBECONFIG=empty-kubeconfig kubectl apply --dry-run=client --validate=false -f k8s/ 2>&1 | tail -n 3 | cut -c1-200
unable to recognize "k8s\\03-backend.yaml": Get "http://localhost:8080/api?timeout=32s": dial tcp [::1]:8080: connectex: No connection could be made because the target machine actively refused it.
unable to recognize "k8s\\04-frontend.yaml": Get "http://localhost:8080/api?timeout=32s": dial tcp [::1]:8080: connectex: No connection could be made because the target machine actively refused it.
unable to recognize "k8s\\04-frontend.yaml": Get "http://localhost:8080/api?timeout=32s": dial tcp [::1]:8080: connectex: No connection could be made because the target machine actively refused it.
# exit code: 1
```

_**Local**: Trivy misconfiguration scan of the manifests with the same gate (HIGH/CRITICAL, exit code 1): clean._

```console
$ docker run --rm -v ./k8s:/work/k8s:ro -v s17-trivy-cache:/root/.cache -w /work aquasec/trivy:0.75.0 config --skip-version-check --severity HIGH,CRITICAL --exit-code 1 --report summary k8s
[output cut: showing the last 14 of 23 lines] ...
├───────────────────┼────────────┼───────────────────┤
│ 00-namespace.yaml │ kubernetes │         0         │
├───────────────────┼────────────┼───────────────────┤
│ 01-configmap.yaml │ kubernetes │         0         │
├───────────────────┼────────────┼───────────────────┤
│ 02-postgres.yaml  │ kubernetes │         0         │
├───────────────────┼────────────┼───────────────────┤
│ 03-backend.yaml   │ kubernetes │         0         │
├───────────────────┼────────────┼───────────────────┤
│ 04-frontend.yaml  │ kubernetes │         0         │
└───────────────────┴────────────┴───────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
# exit code: 0
```

_**Local**: everything Trivy still reports at lower severities (count, severity, rule). I accept these: the postgres and nginx images define their own users (uid 70 and 101, flagged as LOW because they are below 10000), and `ghcr.io`, where my own two images live, is not on Trivy's default list of trusted registries (flagged as MEDIUM for the backend and frontend containers)._

```console
$ docker run --rm -v ./k8s:/work/k8s:ro -v s17-trivy-cache:/root/.cache -w /work aquasec/trivy:0.75.0 config --skip-version-check -f json k8s 2>/dev/null | python -c "import sys,json,collections; d=json.load(sys.stdin); c=collections.Counter((m[\"Severity\"],m[\"ID\"],m[\"Title\"]) for r in d[\"Results\"] for m in r.get(\"Misconfigurations\",[])); [print(n,k) for k,n in sorted(c.items())]"
2 ('LOW', 'KSV-0020', 'Runs with UID <= 10000')
2 ('LOW', 'KSV-0021', 'Runs with GID <= 10000')
2 ('MEDIUM', 'KSV-0125', 'Restrict container images to trusted registries')
# exit code: 0
```

**Does the manifest gate close?** While writing the manifests, Trivy flagged the frontend and postgres containers for a writable root file system (HIGH, rule KSV-0014). I fixed them (read-only root plus the `emptyDir` mounts above). To show the rule again, I removed the `readOnlyRootFilesystem` line from a *copy* of the frontend manifest and scanned that copy:

_**Local**: HIGH finding, exit code 1: the gate would close._

```console
$ docker run --rm -v ./k8s-before:/work/k8s:ro -v s17-trivy-cache:/root/.cache -w /work aquasec/trivy:0.75.0 config --skip-version-check --severity HIGH,CRITICAL --exit-code 1 --report summary k8s
2026-10-18T14:39:53Z	INFO	[misconfig] Misconfiguration scanning is enabled
2026-10-18T14:39:53Z	INFO	[checks-client] Need to update the checks bundle
2026-10-18T14:39:53Z	INFO	[checks-client] Downloading the checks bundle...
159.25 KiB / 234.57 KiB [---------------------------------------->__________________] 67.89% ? p/s ?234.57 KiB / 234.57 KiB [--------------------------------------------------------->] 100.00% ? p/s ?234.57 KiB / 234.57 KiB [---------------------------------------------] 100.00% 758.76 KiB p/s 500ms2026-10-18T14:39:57Z	INFO	Detected config files	num=1

Report Summary

┌──────────────────┬────────────┬───────────────────┐
│      Target      │    Type    │ Misconfigurations │
├──────────────────┼────────────┼───────────────────┤
│ 04-frontend.yaml │ kubernetes │         1         │
└──────────────────┴────────────┴───────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


04-frontend.yaml (kubernetes)
=============================
Tests: 24 (SUCCESSES: 23, FAILURES: 1)
Failures: 1 (HIGH: 1, CRITICAL: 0)

KSV-0014 (HIGH): Container 'frontend' of Deployment 'frontend' should set 'securityContext.readOnlyRootFilesystem' to true
════════════════════════════════════════
An immutable root file system prevents applications from writing to their local disk. This can limit intrusions, as attackers will not be able to tamper with the file system or write foreign executables to disk.

See https://avd.aquasec.com/misconfig/ksv-0014
────────────────────────────────────────
 04-frontend.yaml:32-72
────────────────────────────────────────
  32 ┌         - name: frontend
  33 │           image: ghcr.io/yash-1706/stockpilot-frontend:8999ad3d61ab1a182cadaa0c78c906ba61ab7697
  34 │           ports:
  35 │             - name: http
  36 │               containerPort: 8080
  37 │           env:
  38 │             # nginx proxies /api to the backend Service (a fully qualified name, because nginx
  39 │             # does not use the pod's DNS search domains)
  40 └             - name: BACKEND_URL
  ..   
────────────────────────────────────────
# exit code: 1
```

A read-only root file system must not break the applications, so I started the real images that way (read-only root, only the `emptyDir` equivalents writable, non-root user, no capabilities) with plain Docker:

_**Local**: the frontend image runs with a read-only root file system._

```console
$ docker run -d --name s17-vuln --read-only --user 101:101 --cap-drop ALL --security-opt no-new-privileges --tmpfs /tmp --tmpfs /etc/nginx/conf.d:uid=101,gid=101,mode=0777 -p 18082:8080 s17-frontend:local >/dev/null; sleep 4; curl -s -i http://localhost:18082/healthz | head -n 1; docker rm -f s17-vuln >/dev/null
HTTP/1.1 200 OK
# exit code: 0
```

_**Local**: the postgres image runs with a read-only root file system (a throw-away password generated on the fly, container removed right after)._

```console
$ docker run -d --name s17-vuln --read-only --user 70:70 --cap-drop ALL --security-opt no-new-privileges --tmpfs /tmp --tmpfs /var/run/postgresql:uid=70,gid=70 --tmpfs /var/lib/postgresql/data:uid=70,gid=70 -e POSTGRES_USER=stockpilot -e POSTGRES_DB=stockpilot -e POSTGRES_PASSWORD="$(date +%s%N | sha256sum | cut -c1-16)" -e PGDATA=/var/lib/postgresql/data/pgdata postgres:16-alpine >/dev/null; sleep 12; docker exec s17-vuln pg_isready -U stockpilot -d stockpilot; docker rm -f s17-vuln >/dev/null
/var/run/postgresql:5432 - accepting connections
# exit code: 0
```

---

## 6. Screenshots

**Real GitHub run** (public pages, rendered by headless Microsoft Edge). The run page of run #4 shows the job graph: tests, secret scan and infra validation in parallel, then the matrix build-scan-push (2 jobs), and the deploy job skipped.

![GitHub Actions run #4 of StockPilot](screenshots/actions-run-38807406432.png)

_Run #4: the real pipeline with the secret scan, the Trivy gate and the image push._

![GHCR package: backend](screenshots/ghcr-package-backend.png)

_The backend image that the pipeline pushed after the scan, tagged with the commit SHA of run #4._

![GHCR package: frontend](screenshots/ghcr-package-frontend.png)

_The frontend image from the same run._

**Local scan reports** (Trivy's own HTML report, opened in headless Edge). The first is the StockPilot backend (gate open), the second the deliberately vulnerable throw-away image (gate closed).

![Trivy report: StockPilot backend](screenshots/trivy-report-backend.png)

_StockPilot backend image: no HIGH/CRITICAL vulnerability with a fix, so the gate is open._

![Trivy report: vulnerable demo image](screenshots/trivy-report-vulnerable.png)

_The throw-away vulnerable image: the same policy reports vulnerabilities, so the gate is closed._

---

## 7. Clean up

Remove everything I created for this session: containers, images, the cache volume, the temporary repositories and copies.

_**Local**: remove the s17- images, the Trivy cache volume and the throw-away folders._

```console
$ docker rmi s17-backend:local s17-frontend:local s17-vulnerable:demo | grep -E "Untagged" ; docker volume rm s17-trivy-cache; rm -rf secret-demo vuln k8s-before
Untagged: s17-backend:local
Untagged: s17-frontend:local
Untagged: s17-vulnerable:demo
s17-trivy-cache
# exit code: 0
```

_**Local**: nothing is left._

```console
$ docker ps -a --filter 'name=s17-' --format '{{.Names}}' | wc -l | xargs echo 'remaining s17- containers:'; docker images --filter 'reference=s17-*' -q | wc -l | xargs echo 'remaining s17- images:'; docker volume ls -q --filter 'name=s17-' | wc -l | xargs echo 'remaining s17- volumes:'
remaining s17- containers: 0
remaining s17- images: 0
remaining s17- volumes: 0
# exit code: 0
```

## What I learned

- **DevSecOps means the security checks are pipeline jobs**, not a review at the end. SAST (my code), SCA (my dependencies), secret scanning (my history) and image scanning (my container) each look at a different thing, and none of them replaces another.
- A **clean result is only evidence if the tool can fail**. So for every scan I also showed it failing on purpose: Semgrep on a bad file, pip-audit on old pins, Trivy on an old base image, gitleaks on a fake key, Trivy-config on a manifest without a read-only root.
- The **security gate** is just a job that `needs` all the scans, runs with `if: always()`, and exits 1 unless every result is `success`. It must run even when an upstream job failed, because GitHub counts a *skipped* required check as passed. Branch protection then makes it binding.
- **Scan the artifact you ship.** Building the image once, saving it as a tar, scanning that tar and pushing that same tar avoids the gap in which a rebuild could differ from what was scanned.
- **Deleting a secret from the code does not remove it from git history.** The scan keeps failing until the history is rewritten, and a real key must be *rotated* first. Gitleaks also ignores the documented AWS example key on purpose, so it is not a good test value.
- Allowlists and ignore files are part of the policy: narrow, explained, and expiring (`.trivyignore` is empty on purpose).
- Scanning my own Kubernetes manifests with Trivy found a real HIGH issue (writable root file system) that I then fixed and verified by actually starting the images with a read-only root.
- Being honest about what ran where matters: the real GitHub pipeline covers the secret scan, the Trivy gate and the push; SAST, SCA and the explicit gate job exist as a linted workflow and as locally executed commands, but have not run on GitHub.
