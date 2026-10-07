# Session 17 — Complete CI/CD & DevSecOps Pipeline

**Submitted by:** Piyush Bansal
**Workflow:** [`.github/workflows/piyush-session17-devsecops.yml`](../../.github/workflows/piyush-session17-devsecops.yml)
**Runs on:** my fork `PiyushhBansal/devops-heros`, GitHub-hosted `ubuntu-latest` runners

| Run | Commit | Result |
|---|---|---|
| [#37659259529](https://github.com/PiyushhBansal/devops-heros/actions/runs/37659259529) | `060ef76` removed the vulnerable pin | ✅ all 10 stages green, image pushed and deployed |
| [#37658196030](https://github.com/PiyushhBansal/devops-heros/actions/runs/37658196030) | `146fd23` with `urllib3==1.26.4` on purpose | ❌ **security gate blocked it**, push + deploy skipped |
| [#37657597395](https://github.com/PiyushhBansal/devops-heros/actions/runs/37657597395) | `3f92fdf` first push | ❌ my own bug in the docker-build check (container name `t` rejected by Docker), fixed in `146fd23` |

All output below is real: from my laptop or pulled from the GitHub Actions logs with `gh`
(`GH_REPO=PiyushhBansal/devops-heros` set; `cut -c30-` only strips the timestamp column).

## Flow

```text
Code (push to submission/piyush-session-17, paths: HW/ + workflow)
 ↓
1. Build ............ pip install + pip check, compileall, source tarball artifact
 ↓
2. Unit Test ........ pytest, 13 tests, coverage must be >= 90%, JUnit artifact
 ↓
3. SAST ............. Bandit + Semgrep (my rules + p/python + p/flask)
 ↓
4. SCA .............. pip-audit + Trivy fs on requirements.txt
 ↓
5. Secret Scan ...... Gitleaks: current files + commit history of the HW folder
 ↓
6. Docker Build ..... multi-stage image, saved as a tarball artifact, quick run as non-root/read-only
 ↓
7. Image Scan ....... Trivy on that exact tarball
 ↓
8. Security Gate .... security/gate.py reads all 7 reports, fails on HIGH/CRITICAL
 ↓
9. Push Image ....... docker load the scanned tarball, push to ghcr.io with GITHUB_TOKEN
 ↓
10. Deploy .......... kind cluster, kubectl apply (image pinned by digest), rollout status, smoke test
```

Every job `needs:` the one before it, so a failure anywhere stops everything after it.

### How the gate works

The scanners never fail their own job on findings. Each one writes a JSON report and
uploads it as an artifact (`report-sast`, `report-sca`, `report-secrets`, `report-image`).
The gate job downloads all of them and applies one policy in one place
([`security/gate.py`](security/gate.py)):

| Check | Blocks on |
|---|---|
| Bandit | any HIGH severity issue |
| Semgrep | any ERROR severity finding |
| Trivy fs (SCA) | any HIGH/CRITICAL vulnerability with a fix available |
| pip-audit (SCA) | any known vulnerability that has a fixed version |
| Gitleaks files + history | any finding |
| Trivy image | any HIGH/CRITICAL vulnerability with a fix available |
| *missing/broken report* | always blocks, so a crashed scanner never looks like a clean scan |

The image that is pushed is the image that was scanned: job 6 saves the image with
`docker save`, job 7 scans that tarball, and job 9 `docker load`s the same tarball and
pushes it. Nothing is rebuilt after the scan. Job 10 then deploys it by **digest**, not by tag.

## Security tool configuration

| File | Tool | What it sets |
|---|---|---|
| `security/bandit.yaml` | Bandit (SAST) | scan `app/`, exclude `tests/`, no checks skipped |
| `security/semgrep.yml` | Semgrep (SAST) | my 3 rules: Flask `debug=True`, hard-coded `SECRET_KEY`, `subprocess(..., shell=True)` (run together with `p/python` and `p/flask`) |
| `security/trivy.yaml` | Trivy (SCA + image) | vuln scanner, all severities reported, `ignore-unfixed`, JSON output, exit-code 0 (the gate decides) |
| `security/.trivyignore` | Trivy | place for accepted CVEs (empty: nothing accepted) |
| `security/gitleaks.toml` | Gitleaks | default rules + a GitHub token rule, `reports/` allow-listed |
| `security/gate.py` | Security gate | the policy table above |

## Application, container and Kubernetes hardening

- `app/main.py`: small Flask task API (`/health`, `GET/POST /api/tasks`, `GET/DELETE /api/tasks/<id>`,
  `POST /api/tasks/<id>/done`), input validation, security headers on every response.
- `Dockerfile`: multi-stage; the runtime image has no pip/setuptools, runs as uid 10001,
  gunicorn with `--no-control-socket` so it works on a read-only root filesystem.
- `k8s/namespace.yaml`: namespace `p17-devsecops` with Pod Security Admission **`restricted`** enforced.
- `k8s/deployment.yaml`: 2 replicas, `runAsNonRoot`, `readOnlyRootFilesystem`, drop ALL capabilities,
  no privilege escalation, seccomp `RuntimeDefault`, no service-account token, probes, requests/limits,
  `imagePullSecrets: ghcr-pull` (the secret is created in the pipeline from `GITHUB_TOKEN`, never stored in the repo).
- `k8s/service.yaml`: ClusterIP on port 80 → 8080.

## Local checks (before pushing)

```text
$ python -m pytest -q --cov=app --cov-report=term-missing
.............                                                            [100%]
================================ tests coverage ================================
_______________ coverage: platform darwin, python 3.13.5-final-0 _______________

Name              Stmts   Miss  Cover   Missing
-----------------------------------------------
app/__init__.py       0      0   100%
app/main.py          64      1    98%   93
-----------------------------------------------
TOTAL                64      1    98%
13 passed in 2.36s
```

All scanners + the gate on my laptop (`bandit -q` prints nothing when there are no issues; the gate reads its JSON report.
The history scan needs the CI checkout, so locally I only ran the folder scan):

```text
$ bandit -c security/bandit.yaml -r app -f json -o reports/bandit.json --exit-zero -q; bandit -c security/bandit.yaml -r app --exit-zero -q | grep -E "(Low|Medium|High):" | head -3
$ semgrep scan --metrics=off --config security/semgrep.yml --config p/python --config p/flask --json -o reports/semgrep.json app 2>&1 | grep -E "^Ran "
Ran 154 rules on 2 files: 0 findings.
$ pip-audit -r requirements.txt -f json -o reports/pip-audit.json
No known vulnerabilities found
$ docker run --rm -v "$PWD:/src" -v s17-trivy-cache:/root/.cache aquasec/trivy:0.75.0 fs --quiet --config /src/security/trivy.yaml --ignorefile /src/security/.trivyignore -o /src/reports/trivy-fs.json /src/requirements.txt && python -c "import json;r=json.load(open('reports/trivy-fs.json'));print('trivy fs vulnerabilities:', sum(len(x.get('Vulnerabilities') or []) for x in r.get('Results') or []))"
trivy fs vulnerabilities: 0
$ docker run --rm -v "$PWD:/src" ghcr.io/gitleaks/gitleaks:v8.30.1 dir /src --config /src/security/gitleaks.toml --report-format json --report-path /src/reports/gitleaks.json --exit-code 0 --no-banner 2>&1 | sed "s/\x1b\[[0-9;]*m//g"
6:09PM INF scanned ~34695 bytes (34.69 KB) in 848ms
6:09PM INF no leaks found
$ docker build -q -t s17-tasks:local . && docker save s17-tasks:local -o reports/image.tar
sha256:fa62ce19da9d08d84697b702874687b19e86d0bb3b4f7fe1658e608840283301
$ docker run --rm -v "$PWD:/src" -v s17-trivy-cache:/root/.cache aquasec/trivy:0.75.0 image --quiet --config /src/security/trivy.yaml --ignorefile /src/security/.trivyignore --input /src/reports/image.tar -o /src/reports/trivy-image.json
$ python security/gate.py reports
CHECK                                  RESULT   FINDINGS
------------------------------------------------------------
SAST    bandit (HIGH)                  PASS     0
SAST    semgrep (ERROR)                PASS     0
SCA     trivy fs (HIGH/CRITICAL)       PASS     0
SCA     pip-audit (fixable)            PASS     0
SECRETS gitleaks (files)               PASS     0
SECRETS gitleaks (git history)         PASS     0
IMAGE   trivy image (HIGH/CRITICAL)    PASS     0
------------------------------------------------------------
SECURITY GATE: PASSED - image can be pushed and deployed
```

Running the image the way Kubernetes will (read-only, no capabilities):

```text
$ docker run -d --name s17-t --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges -p 18170:8080 s17-tasks:local
89f192fe80f81bd8bdbd1c8c2fc1bcee8a9786c4df4b297d13b0e1fb4baf4f34
$ docker exec s17-t id
uid=10001(appuser) gid=10001(appuser) groups=10001(appuser)
$ curl -s -X POST -H 'Content-Type: application/json' -d '{"title":"scan image"}' localhost:18170/api/tasks
{"done":false,"id":1,"title":"scan image"}
$ curl -s -X POST -H 'Content-Type: application/json' -d '{"title":""}' localhost:18170/api/tasks
{"error":"'title' is required"}
$ curl -s localhost:18170/api/tasks
{"tasks":[{"done":false,"id":1,"title":"scan image"}]}
$ curl -sI localhost:18170/health | grep -iE "^(x-|content-security)"
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'none'
```

Manifests checked against the real API server (Docker Desktop cluster, my own namespace only).
No Pod Security warning on the dry run means the Deployment passes the `restricted` profile:

```text
$ kubectl apply -f k8s/namespace.yaml
namespace/p17-devsecops created
$ sed 's|IMAGE_PLACEHOLDER|ghcr.io/piyushhbansal/session17-tasks-api:test|' k8s/deployment.yaml | kubectl apply --dry-run=server -f -
deployment.apps/tasks-api created (server dry run)
$ kubectl apply --dry-run=server -f k8s/service.yaml
service/tasks-api created (server dry run)
$ kubectl delete namespace p17-devsecops
namespace "p17-devsecops" deleted
```

### The gate caught my first Dockerfile

My first Dockerfile left `pip` inside the virtualenv. pip vendors its own copies of
`urllib3`, `msgpack` and `pkg_resources` (setuptools), and Trivy found HIGH CVEs in them.
I kept that version as `Dockerfile.before` and re-ran the image scan + gate on it
(the other reports were empty placeholders for this check):

```text
$ docker build -q -f reports/Dockerfile.before -t s17-tasks:before . && docker save s17-tasks:before -o reports/image.tar
sha256:88304700e5599708f571df22a4f7a5b351423e6b88bc295cc5d0d5cb073c1977
$ docker run --rm -v "$PWD:/src" -v s17-trivy-cache:/root/.cache aquasec/trivy:0.75.0 image --quiet --config /src/security/trivy.yaml --ignorefile /src/security/.trivyignore --input /src/reports/image.tar -o /src/reports/trivy-image.json
$ python security/gate.py reports | grep -E "^(IMAGE|  \[IMAGE\]|SECURITY)"
IMAGE   trivy image (HIGH/CRITICAL)    FAIL     4
  [IMAGE] msgpack 1.1.2 GHSA-6v7p-g79w-8964 HIGH (fixed in 1.2.1)
  [IMAGE] setuptools 70.3.0 CVE-2025-47273 HIGH (fixed in 78.1.1)
  [IMAGE] urllib3 2.7.0 CVE-2026-97687 HIGH (fixed in 2.8.0)
  [IMAGE] urllib3 2.7.0 CVE-2026-97689 HIGH (fixed in 2.8.0)
SECURITY GATE: FAILED - image will NOT be pushed or deployed
```

Fix: `pip uninstall -y pip` in the build stage after installing the requirements (the app
never needs pip at runtime). After that the image scan was clean.

## Run 1 of the demo: the gate blocks a vulnerable dependency (#37658196030)

I pinned `urllib3==1.26.4` (an old version with known HIGH CVEs) in `requirements.txt` on purpose.

```text
$ gh run view --job 112923953245 --log | cut -f3- | cut -c30- | grep -E '^(\{|x-content|X-Content|x-frame|X-Frame|Smoke test passed)'
{"status":"ok"}
{"app":"session17-tasks","version":"060ef76"}
{"done":false,"id":1,"title":"smoke test"}
{"tasks":[{"done":false,"id":1,"title":"smoke test"}]}
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Smoke test passed
```

```text
$ gh run view 37658196030 --json jobs --jq '.jobs[] | "\(.conclusion)\t\(.name)"'
success	1. Build
success	2. Unit Test
success	3. SAST (Bandit + Semgrep)
success	4. SCA (pip-audit + Trivy fs)
success	5. Secret Scan (Gitleaks)
success	6. Docker Build
success	7. Container Image Scan (Trivy)
failure	8. Security Gate (block HIGH/CRITICAL)
skipped	9. Push Image (GHCR)
skipped	10. Deploy to Kubernetes (kind)
```

```text
$ gh api repos/PiyushhBansal/devops-heros/actions/jobs/112919868071/logs | cut -c30- | sed -n '/^CHECK/,/^SECURITY GATE/p' | head -24
CHECK                                  RESULT   FINDINGS
------------------------------------------------------------
SAST    bandit (HIGH)                  PASS     0
SAST    semgrep (ERROR)                PASS     0
SCA     trivy fs (HIGH/CRITICAL)       FAIL     8
SCA     pip-audit (fixable)            FAIL     20
SECRETS gitleaks (files)               PASS     0
SECRETS gitleaks (git history)         PASS     0
IMAGE   trivy image (HIGH/CRITICAL)    FAIL     8
------------------------------------------------------------
Blocking findings:
  [SCA] urllib3 1.26.4 CVE-2021-33503 HIGH (fixed in 1.26.5)
  [SCA] urllib3 1.26.4 CVE-2023-43804 HIGH (fixed in 2.0.6, 1.26.17)
  [SCA] urllib3 1.26.4 CVE-2025-66418 HIGH (fixed in 2.6.0)
  [SCA] urllib3 1.26.4 CVE-2025-66471 HIGH (fixed in 2.6.0)
  [SCA] urllib3 1.26.4 CVE-2026-21441 HIGH (fixed in 2.6.3)
  [SCA] urllib3 1.26.4 CVE-2026-44431 HIGH (fixed in 2.7.0)
  [SCA] urllib3 1.26.4 CVE-2026-97687 HIGH (fixed in 2.8.0)
  [SCA] urllib3 1.26.4 CVE-2026-97689 HIGH (fixed in 2.8.0)
  [SCA] urllib3 1.26.4 PYSEC-2021-108 (fixed in 1.26.5)
  [SCA] urllib3 1.26.4 PYSEC-2021-108 (fixed in 1.26.5)
  [SCA] urllib3 1.26.4 PYSEC-2026-1995 (fixed in 1.26.19, 2.2.2)
  [SCA] urllib3 1.26.4 PYSEC-2023-192 (fixed in 1.26.17, 2.0.6)
  [SCA] urllib3 1.26.4 PYSEC-2023-192 (fixed in 1.26.17, 2.0.6)
```

(The gate listed 36 blocking findings; `head -24` cuts the list.) All scan jobs were green
because they only report. The gate turned the reports into a decision, and because
`push-image` `needs: security-gate`, the vulnerable image never reached GHCR or the cluster.

## Run 2: fixed, full green pipeline (#37659259529)

I removed the pin (commit `060ef76`) and pushed.

```text
$ gh run view 37659259529 --json jobs --jq '.jobs[] | "\(.conclusion)\t\(.name)"'
success	1. Build
success	2. Unit Test
success	3. SAST (Bandit + Semgrep)
success	4. SCA (pip-audit + Trivy fs)
success	5. Secret Scan (Gitleaks)
success	6. Docker Build
success	7. Container Image Scan (Trivy)
success	8. Security Gate (block HIGH/CRITICAL)
success	9. Push Image (GHCR)
success	10. Deploy to Kubernetes (kind)
```

```text
$ gh api repos/PiyushhBansal/devops-heros/actions/runs/37659259529/artifacts --jq '.artifacts[] | "\(.name)\t\(.size_in_bytes) bytes"'
report-secrets	284 bytes
app-source	4142 bytes
test-report	459 bytes
image-tar	46111750 bytes
report-image	39545 bytes
report-sca	848 bytes
report-sast	992 bytes
```

### 1. Build

```text
$ gh run view --job 112922266500 --log | cut -f3- | cut -c30- | grep -E '^(compiled OK|-rw|No broken)'
No broken requirements found.
compiled OK
-rw-r--r-- 1 runner runner 3975 Oct  7 17:28 tasks-api-060ef76.tar.gz
```

### 2. Unit Test

```text
$ gh run view --job 112922394997 --log | cut -f3- | cut -c30- | grep -E '(PASSED|FAILED|^TOTAL|passed in|Required test coverage)'
tests/test_app.py::test_health PASSED                                    [  7%]
tests/test_app.py::test_security_headers_present PASSED                  [ 15%]
tests/test_app.py::test_create_and_get_task PASSED                       [ 23%]
tests/test_app.py::test_list_tasks PASSED                                [ 30%]
tests/test_app.py::test_complete_task PASSED                             [ 38%]
tests/test_app.py::test_delete_task PASSED                               [ 46%]
tests/test_app.py::test_create_rejects_bad_title[None] PASSED            [ 53%]
tests/test_app.py::test_create_rejects_bad_title[body1] PASSED           [ 61%]
tests/test_app.py::test_create_rejects_bad_title[body2] PASSED           [ 69%]
tests/test_app.py::test_create_rejects_bad_title[body3] PASSED           [ 76%]
tests/test_app.py::test_create_rejects_bad_title[body4] PASSED           [ 84%]
tests/test_app.py::test_create_rejects_long_title PASSED                 [ 92%]
tests/test_app.py::test_missing_task_is_404 PASSED                       [100%]
TOTAL                64      1    98%
Required test coverage of 90% reached. Total coverage: 98.44%
============================== 13 passed in 0.28s =========================
```

### 3. SAST

```text

```

### 4. SCA

```text
$ gh run view --job 112922494994 --log | cut -f3- | cut -c30- | grep -E '^(\s+(Low|Medium|High): |Ran [0-9]+ rules|semgrep findings)'
		Low: 0
		Medium: 0
		High: 0
		Low: 0
		Medium: 0
		High: 0
Ran 154 rules on 2 files: 0 findings.
semgrep findings: 0
```

### 5. Secret scan

```text
$ gh run view --job 112922728745 --log | cut -f3- | cut -c30- | grep -E '(No known vulnerabilities|Detecting vulnerabilities|Number of language)'
No known vulnerabilities found
No known vulnerabilities found
2026-10-07T17:29:44Z	INFO	Number of language-specific files	num=1
2026-10-07T17:29:44Z	INFO	[pip] Detecting vulnerabilities...
```

The first scan is the HW folder; the second is the commit history of that folder (2 commits touched it).

### 6. Docker build

```text
$ gh run view --job 112923127055 --log | cut -f3- | cut -c30- | grep -E '(commits scanned|scanned ~|no leaks found|leaks found)' | sed 's/\x1b\[[0-9;]*m//g'
5:29PM INF scanned ~12837 bytes (12.84 KB) in 9.07ms
5:29PM INF no leaks found
5:29PM INF 2 commits scanned.
5:29PM INF scanned ~13306 bytes (13.31 KB) in 163ms
5:29PM INF no leaks found
```

### 7. Image scan

```text
$ gh run view --job 112923189218 --log | cut -f3- | cut -c30- | grep -E '^(REPOSITORY|ghcr.io/piyushhbansal|\{"status|container user)'
REPOSITORY                                  TAG       IMAGE ID       CREATED        SIZE
ghcr.io/piyushhbansal/session17-tasks-api   060ef76   71f317b88d88   1 second ago   125MB
{"status":"ok"}
container user: uid=10001(appuser) gid=10001(appuser) groups=10001(appuser)
```

(No HIGH/CRITICAL vulnerability with a fix was found, so the table step printed nothing; the counts are in the gate output.)

### 8. Security gate

```text
$ gh api repos/PiyushhBansal/devops-heros/actions/jobs/112923405488/logs | cut -c30- | grep -E '(Detected OS|Detecting vulnerabilities)'
2026-10-07T17:30:47Z	INFO	Detected OS	family="debian" version="13.7"
2026-10-07T17:30:47Z	INFO	[debian] Detecting vulnerabilities...	os_version="13" pkg_num=87
2026-10-07T17:30:47Z	INFO	[python-pkg] Detecting vulnerabilities...
```

### 9. Push image to GHCR

```text
$ gh api repos/PiyushhBansal/devops-heros/actions/jobs/112923585175/logs | cut -c30- | sed -n '/^CHECK/,/^SECURITY GATE/p'
CHECK                                  RESULT   FINDINGS
------------------------------------------------------------
SAST    bandit (HIGH)                  PASS     0
SAST    semgrep (ERROR)                PASS     0
SCA     trivy fs (HIGH/CRITICAL)       PASS     0
SCA     pip-audit (fixable)            PASS     0
SECRETS gitleaks (files)               PASS     0
SECRETS gitleaks (git history)         PASS     0
IMAGE   trivy image (HIGH/CRITICAL)    PASS     0
------------------------------------------------------------
SECURITY GATE: PASSED - image can be pushed and deployed
```

### 10. Deploy to Kubernetes (kind on the runner)

```text
$ gh run view --job 112923646225 --log | cut -f3- | cut -c30- | grep -E '^(Login Succeeded|Loaded image|pushed:|[0-9a-f]{7}: digest|latest: digest)'
Login Succeeded
Loaded image: ghcr.io/piyushhbansal/session17-tasks-api:060ef76
060ef76: digest: sha256:6fae953e1cdfbd49714b49749948377c6e5dd94af926b1d18e298064e6b715f9 size: 1992
latest: digest: sha256:6fae953e1cdfbd49714b49749948377c6e5dd94af926b1d18e298064e6b715f9 size: 1992
pushed: ghcr.io/piyushhbansal/session17-tasks-api@sha256:6fae953e1cdfbd49714b49749948377c6e5dd94af926b1d18e298064e6b715f9
```

Smoke test through the Service (`kubectl port-forward`), including the security headers:

```text
$ gh run view --job 112923953245 --log | cut -f3- | cut -c30- | grep -E '^(namespace/|secret/|Deploying|deployment|service/|Waiting for dep|NAME|pod/|replicaset)'
namespace/p17-devsecops created
secret/ghcr-pull created
Deploying ghcr.io/piyushhbansal/session17-tasks-api@sha256:6fae953e1cdfbd49714b49749948377c6e5dd94af926b1d18e298064e6b715f9
deployment.apps/tasks-api created
service/tasks-api created
Waiting for deployment "tasks-api" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "tasks-api" rollout to finish: 1 of 2 updated replicas are available...
deployment "tasks-api" successfully rolled out
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                                                                                                              SELECTOR
deployment.apps/tasks-api   2/2     2            2           7s    tasks-api    ghcr.io/piyushhbansal/session17-tasks-api@sha256:6fae953e1cdfbd49714b49749948377c6e5dd94af926b1d18e298064e6b715f9   app=tasks-api
NAME                                  DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                                                                                                              SELECTOR
replicaset.apps/tasks-api-68775f6c4   2         2         2       7s    tasks-api    ghcr.io/piyushhbansal/session17-tasks-api@sha256:6fae953e1cdfbd49714b49749948377c6e5dd94af926b1d18e298064e6b715f9   app=tasks-api,pod-template-hash=68775f6c4
NAME                            READY   STATUS    RESTARTS   AGE   IP           NODE                NOMINATED NODE   READINESS GATES
pod/tasks-api-68775f6c4-fzj6f   1/1     Running   0          7s    10.244.0.5   s17-control-plane   <none>           <none>
pod/tasks-api-68775f6c4-q7rf7   1/1     Running   0          7s    10.244.0.6   s17-control-plane   <none>           <none>
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE   SELECTOR
service/tasks-api   ClusterIP   10.96.176.192   <none>        80/TCP    7s    app=tasks-api
```

## Notes

- Every job logs `The process '/usr/bin/git' failed with exit code 128` during checkout clean-up.
  It comes from a broken gitlink in the course repo (`session-16-github-actions/mini-project ...`
  has no `.gitmodules` entry). It does not affect the run.
- The Kubernetes deploy goes to a kind cluster created inside the GitHub runner (I have no cloud
  cluster for this course). It still pulls the real image from GHCR, with a secret made from `GITHUB_TOKEN`.
- I did not change any repo or package settings.
- Scanner versions are pinned (Trivy 0.75.0 image, Gitleaks 8.30.1, Bandit 1.9.4, Semgrep 1.179.0,
  pip-audit 2.10.1) so the pipeline does not change under me.

## What I learned

- Scanners find problems; the gate is what stops a release. Keeping the policy in one place
  (`gate.py`) made it easy to read and change.
- A crashed scanner must not count as "no findings", so the gate fails on a missing report.
- Scan the exact artifact you ship: save → scan → load → push, then deploy by digest.
- Tooling brings CVEs too. The only HIGH findings in my own image came from pip's vendored
  libraries, not from my code or my dependencies.

## Files

| Path | Purpose |
|---|---|
| `app/`, `tests/`, `pytest.ini` | Application and unit tests |
| `requirements.txt`, `requirements-dev.txt` | Runtime / test dependencies |
| `Dockerfile`, `.dockerignore` | Hardened multi-stage image |
| `Dockerfile.before` | My first Dockerfile, kept to show what the image scan caught |
| `security/` | Bandit, Semgrep, Trivy, Gitleaks configs and the gate script |
| `k8s/` | Namespace (restricted PSA), Deployment, Service |
| `../../.github/workflows/piyush-session17-devsecops.yml` | The pipeline |
