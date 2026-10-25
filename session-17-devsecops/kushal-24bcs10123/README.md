# Session 17 – Complete CI/CD & DevSecOps

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123  
**Environment:** GitHub Actions on `ubuntu-latest` (fork `kushaltalati/devops-heros`, branch `ci-kushal-s16-s17`), GHCR as the container registry, a kind cluster created on the runner for the deploy stage, and my own kind cluster `kushal-lab` (Kubernetes v1.37.0) on macOS / Apple Silicon for the final deployment. Tools: bandit 1.9.4, semgrep 1.179.0, pip-audit 2.10.1, gitleaks 8.30.1, trivy 0.75.0 – the same versions locally and in the pipeline.

The application is **secure-converter**: the session 16 unit-converter extended with input validation (pydantic `Field` patterns) and a bounded in-memory `/history`, packaged in a hardened image and deployed with hardened manifests. Everything was really run; raw output in [`logs/`](logs), local commands in [`scripts/`](scripts), the pipeline at [`.github/workflows/24bcs10123-session17-devsecops.yml`](../../.github/workflows/24bcs10123-session17-devsecops.yml) (copy in [`workflow/`](workflow)).

```text
kushal-24bcs10123/
├── README.md
├── secure-converter/
│   ├── app/                     # converter.py + main.py (FastAPI, 7 endpoints)
│   ├── tests/                   # 6 pytest tests
│   ├── k8s/                     # deployment.yaml (non-root, read-only fs, no caps, probes, limits) + service.yaml
│   ├── security/                # the security tools' configuration = deliverable
│   │   ├── bandit.yaml  semgrep.yaml  gitleaks.toml  trivy.yaml  .trivyignore  README.md
│   ├── Dockerfile               # multi-stage, apt upgrade, pip removed from runtime, uid 10001
│   └── requirements*.txt  pytest.ini  .dockerignore
├── workflow/24bcs10123-session17-devsecops.yml
├── scripts/
│   ├── 01-local-scans.sh        # bandit, semgrep, pip-audit, trivy fs, gitleaks, trivy config
│   ├── 02-local-image-scan.sh   # docker build + trivy image
│   ├── 03-deploy-kind.sh <tag>  # deploy the gate-approved GHCR image on my cluster and prove the hardening
│   ├── 04-pipeline-runs.sh      # gh run list / view evidence
│   └── 05-planted-secret-demo.sh# a fake key goes in, gitleaks catches it, it goes out
├── logs/                        # one .txt per script + full logs of every pipeline run
└── screenshots/
```

## 1. The pipeline

Exactly the flow the assignment asks for, one job per stage, each `needs:` the previous one:

```text
 code ─► 1.build ─► 2.unit-test ─► 3.sast ─► 4.sca ─► 5.secret-scan ─► 6.docker-build ─► 7.image-scan
                                                                                             │
                     ┌───────────────────────────────────────────────────────────────────────┘
                     ▼
              8.security-gate  (needs unit-test, sast, sca, secret-scan, image-scan; if: always())
                     │ GATE OPEN only when all five are "success"
                     ▼
              9.push-image (GHCR) ─► 10.deploy-kubernetes (kind on the runner, rollout + curl)
```

| Stage | Tool(s) | Config | Fails when |
|---|---|---|---|
| 1 build | `pip install`, `python -m compileall` | – | dependency or syntax problem |
| 2 unit test | pytest | `pytest.ini` | any test fails |
| 3 SAST | **bandit** (`-ll -ii`) + **semgrep** (`p/python`, `p/owasp-top-ten`, my [`semgrep.yaml`](secure-converter/security/semgrep.yaml)) | [`bandit.yaml`](secure-converter/security/bandit.yaml) skips only B104 (binding 0.0.0.0 is required inside a container) | medium+ bandit issue, any semgrep ERROR |
| 4 SCA | **pip-audit** `--strict` + **trivy fs** `--scanners vuln` | [`trivy.yaml`](secure-converter/security/trivy.yaml) | known CVE in a pinned dependency (HIGH/CRITICAL with a fix for trivy) |
| 5 secret scan | **gitleaks** `dir . --config security/gitleaks.toml --redact` | [`gitleaks.toml`](secure-converter/security/gitleaks.toml) extends the default rules, allow-lists `tests/` | any secret-shaped string |
| 6 docker build | `docker build` → `docker save` → artifact | Dockerfile | – (image is *not* pushed here) |
| 7 image scan | **trivy config** (Dockerfile + k8s misconfig) + **trivy image** | `trivy.yaml` + `.trivyignore` | HIGH/CRITICAL vulnerability with an available fix, or a misconfiguration |
| 8 gate | shell | – | any of stages 2–7 not `success` |
| 9 push | `docker load` + `docker push` | `GITHUB_TOKEN`, `packages: write` | – |
| 10 deploy | `helm/kind-action`, `kind load`, `kubectl apply/rollout`, `curl` | `k8s/` | rollout does not become ready |

Two design points I care about: the image that gets pushed in stage 9 is **the very tarball that was scanned** in stage 7 (passed as an artifact), not a rebuild; and the gate has `if: always()` so its verdict is visible even when an earlier stage is red, while 9 and 10 depend on the gate succeeding and are therefore *skipped*.

## 2. Pipeline runs (evidence)

All runs: <https://github.com/kushaltalati/devops-heros/actions/workflows/24bcs10123-session17-devsecops.yml> – `gh run list` / `gh run view` output in [logs/04-pipeline-runs.txt](logs/04-pipeline-runs.txt).

| # | Run | Result | What happened |
|---|---|---|---|
| 1 | [37660980791](https://github.com/kushaltalati/devops-heros/actions/runs/37660980791) | 1–6 ✓, **7 image-scan ✗, 8 gate CLOSED**, 9–10 skipped | a real block, not a staged one. trivy found `Total: 44 (HIGH: 44)` Debian findings (util-linux, ncurses, systemd, acl… all status *affected*, i.e. no fix exists yet) and `Total: 4 (HIGH: 4)` in Python packages: `setuptools 70.3.0 → 78.1.1 (CVE-2025-47273)`, `urllib3 2.7.0 → 2.8.0`, `msgpack 1.1.2 → 1.2.1` – those come from **pip** that the base image ships and the packages pip vendors. [log](logs/ci-run-37660980791-gate-blocked-image-scan.txt), [screenshot](screenshots/01-run1-image-scan-failed-gate-closed.png) |
| 2 | [37661828760](https://github.com/kushaltalati/devops-heros/actions/runs/37661828760) | **all 10 green** | the fix: (a) `vulnerability.ignore-unfixed: true` in `trivy.yaml` – a CVE without a fix cannot be a build-blocker, it is still in the full report; (b) the runtime image never installs anything, so the Dockerfile removes pip from the base image and from the venv (`rm -rf …/site-packages/pip* …/ensurepip /usr/local/bin/pip*`, `pip uninstall -y pip`). Result: `debian 0`, no Python findings. Image pushed, deployed on kind on the runner, `process runs as uid: 10001`. [log](logs/ci-run-37661828760-green.txt), [screenshot](screenshots/02-run2-all-stages-green.png) |
| 3 | [37663051240](https://github.com/kushaltalati/devops-heros/actions/runs/37663051240) | 1–4 ✓, **5 secret-scan ✗, 8 gate CLOSED**, 6,7,9,10 skipped | the planted secret: `app/config_example.py` with `AWS_ACCESS_KEY_ID = "AKIAQ3ZX7TP2M6VKL4WD"` (not a real key, it only has the AKIA + 16 base32 shape the rule looks for). gitleaks: `RuleID: aws-access-token`, `File: app/config_example.py`, value `REDACTED`, `leaks found: 1`. No image was built, nothing pushed. [log](logs/ci-run-37663051240-secret-scan-gate-closed.txt), [screenshot](screenshots/03-run3-secret-scan-failed-gate-closed.png) |
| 4 | [37663364916](https://github.com/kushaltalati/devops-heros/actions/runs/37663364916) | **all 10 green** | file removed → final run. [log](logs/ci-run-37663364916-final-green.txt), [screenshot](screenshots/04-run4-final-green.png) |

Excerpts from run 4 ([full log](logs/ci-run-37663364916-final-green.txt)):

```text
3. sast      bandit:  Total issues (by severity): High: 0  Medium: 0 ...
             semgrep: Ran 158 rules on 6 files: 0 findings.
4. sca       pip-audit: No known vulnerabilities found
5. secret    gitleaks: no leaks found
7. image     ghcr.io/kushaltalati/secure-converter:sha-780f6c2 (debian 13.7)  debian  0
8. gate      unit-test : success / sast : success / sca : success / secret-scan : success / image-scan : success
             GATE OPEN
9. push      sha-780f6c2, latest -> ghcr.io/kushaltalati/secure-converter
10. deploy   deployment "secure-converter" successfully rolled out
             {"category":"temperature","value":100.0,"from_unit":"c","to_unit":"f","result":212.0}
             process runs as uid: 10001
```

Registry: `ghcr.io/kushaltalati/secure-converter` tags `sha-a6dc7c2, sha-780f6c2, latest` (only gate-approved commits have a tag; the two blocked commits `67c014e` and `3f1d248` have none) – <https://github.com/kushaltalati/devops-heros/pkgs/container/secure-converter>.

## 3. The same scans on my laptop

Log: [logs/01-local-scans.txt](logs/01-local-scans.txt), [logs/02-local-image-scan.txt](logs/02-local-image-scan.txt)

```text
$ bandit -c security/bandit.yaml -r app -ll -ii -f txt
	Total issues (by severity): Undefined: 0  Low: 0  Medium: 0  High: 0
$ semgrep scan --config p/python --config p/owasp-top-ten --config security/semgrep.yaml --error --metrics=off app
Ran 158 rules on 6 files: 0 findings.
$ pip-audit -r requirements.txt --strict --desc
No known vulnerabilities found
$ gitleaks dir . --config security/gitleaks.toml --exit-code 1 --redact --no-banner
INF no leaks found
$ trivy config --config security/trivy.yaml --ignorefile security/.trivyignore .
│ Dockerfile          │ dockerfile │ 0 │
│ k8s/deployment.yaml │ kubernetes │ 0 │
│ k8s/service.yaml    │ kubernetes │ 0 │

$ docker image inspect ghcr.io/kushaltalati/secure-converter:local --format 'size={{.Size}} user={{.Config.User}}'
size=48746553 user=10001
$ trivy image --config security/trivy.yaml --scanners vuln ghcr.io/kushaltalati/secure-converter:local
exit=0
```

The planted-secret exercise, locally ([logs/05-planted-secret-demo.txt](logs/05-planted-secret-demo.txt)):

```text
$ printf 'AWS_ACCESS_KEY_ID = "AKIA..."  # fake, planted for the secret-scan demo\n' > app/config_example.py
$ gitleaks dir . --config security/gitleaks.toml --exit-code 1 --redact --no-banner --verbose
Finding:     ...WS_ACCESS_KEY_ID = "REDACTED"  # fake, planted f...
RuleID:      aws-access-token
File:        app/config_example.py
WRN leaks found: 1
exit=1
$ rm app/config_example.py
INF no leaks found
exit=0
```

## 4. Deploying the gate-approved image on my cluster, and proving the hardening

Log: [logs/03-deploy-kind.txt](logs/03-deploy-kind.txt) (`scripts/03-deploy-kind.sh sha-a6dc7c2`)

```text
$ docker pull ghcr.io/kushaltalati/secure-converter:sha-a6dc7c2
pulled ghcr.io/kushaltalati/secure-converter:sha-a6dc7c2 from GHCR
$ kubectl -n s17-devsecops rollout status deploy/secure-converter --timeout=120s
deployment "secure-converter" successfully rolled out
NAME                                READY   STATUS    NODE
secure-converter-67bb8d5c5c-m628j   1/1     Running   kushal-lab-worker2
secure-converter-67bb8d5c5c-x5ngd   1/1     Running   kushal-lab-worker

$ kubectl -n s17-devsecops exec deploy/secure-converter -- id
uid=10001(app) gid=10001 groups=10001
$ kubectl -n s17-devsecops exec deploy/secure-converter -- touch /app/x
touch: cannot touch '/app/x': Read-only file system
$ kubectl -n s17-devsecops exec deploy/secure-converter -- sh -c 'ls /var/run/secrets/kubernetes.io'
ls: cannot access '/var/run/secrets/kubernetes.io': No such file or directory   <- automountServiceAccountToken: false
$ kubectl -n s17-devsecops get pod -l app=secure-converter -o jsonpath='{.items[0].spec.containers[0].securityContext}'
{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}

$ curl -s -X POST localhost:20081/convert -d '{"category":"length","value":10,"from_unit":"km","to_unit":"mi"}'
{"category":"length","value":10.0,"from_unit":"km","to_unit":"mi","result":6.213712}
```

## Deliverables checklist

- [x] Application – `secure-converter/app`, 6 tests
- [x] Dockerfile – multi-stage, Debian security upgrades, pip removed, non-root uid 10001, HEALTHCHECK
- [x] GitHub Actions workflow – 10 jobs in the required order
- [x] Security tools configuration – `secure-converter/security/`
- [x] Kubernetes manifests – hardened Deployment + Service, `trivy config` clean
- [x] Successful pipeline output – runs #2 and #4
- [x] Blocked pipeline output – run #1 (image scan) and run #3 (secret scan)
- [x] Screenshots – `screenshots/`
- [x] Deployed on my cluster with the pipeline's image

## What I understood

* "Shift left" is literal here: the cheap checks (tests, SAST, SCA, secrets) run before an image even exists, and the expensive ones (image scan, deploy) only run on code that already passed. A leaked key was caught in 1m44s without building anything.
* SAST, SCA and image scanning answer three different questions – *is my code wrong*, *are my dependencies known-bad*, *is what I ship known-bad* – and one tool does not cover another. My code was clean every time; the base image was what blocked me.
* A scanner that fails on unfixable CVEs trains people to ignore it. `ignore-unfixed` plus a `.trivyignore` with written justifications keeps the gate meaningful. The right fix for the Python findings was not to ignore them but to notice the runtime image had no reason to contain pip at all.
* The gate must be a separate job that *aggregates* results, and the push must consume the scanned artifact. Otherwise "the scan passed" and "the image we pushed" are not provably the same thing.
* Hardening is cheap when it is in the manifest: non-root, read-only root filesystem, no capabilities, no service-account token, resource limits – and `trivy config` checks those for free on every push.
