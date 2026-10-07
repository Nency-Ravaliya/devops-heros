# Session 16 — CI/CD Demo Project with GitHub Actions

**Submitted by:** Piyush Bansal
**Workflow:** [`.github/workflows/piyush-session16-cicd.yml`](../../.github/workflows/piyush-session16-cicd.yml)
**Runs on:** my fork `PiyushhBansal/devops-heros`, GitHub-hosted `ubuntu-latest` runners

| Run | Commit | Result |
|---|---|---|
| [#37658100637](https://github.com/PiyushhBansal/devops-heros/actions/runs/37658100637) | `003fa49` Restore add() | ✅ all 6 jobs green (CI + CD) |
| [#37657739414](https://github.com/PiyushhBansal/devops-heros/actions/runs/37657739414) | `2cc9048` add() broken on purpose | ❌ tests failed, build/CD skipped |
| [#37649814862](https://github.com/PiyushhBansal/devops-heros/actions/runs/37649814862) | `7e5039d` first version | ✅ all 6 jobs green |

I started from the `10-final-cicd-pipeline` example (calculator + test + build + artifact)
and extended it into a full CI/CD pipeline: the calculator is wrapped in a small Flask API,
packaged as a Docker image, pushed to GitHub Container Registry and deployed to a
Kubernetes cluster that the pipeline creates on the runner.

All output below is real: either from my laptop or copied from the GitHub Actions logs of
the runs linked above.

## CI vs CD

| | CI — Continuous Integration | CD — Continuous Delivery / Deployment |
|---|---|---|
| Question it answers | "Is this commit correct?" | "Can this commit be released / is it running?" |
| Runs | on every push | after CI passes |
| In my pipeline | lint, unit tests (2 Python versions), build package, Docker build + container test | push image to GHCR, deploy to Kubernetes (kind), smoke test the live Service |
| Output | test report + build artifacts | a versioned image in a registry and a running Deployment |

Delivery = always *ready* to release (image is in the registry). Deployment = it is actually
*released* automatically. My pipeline does both: it pushes the image and deploys it to a
throwaway kind cluster on the runner (I have no real cloud cluster for this course).

## The pipeline

```text
git push (submission/piyush-session-16, only if HW/ or the workflow changed)
   │
   ▼
┌──────────────────────── CI ────────────────────────┐
│ test (matrix: py3.12, py3.13)                      │
│   checkout → setup-python → pip install → flake8   │
│   → pytest + coverage → upload test-report artifact│
│        │                                           │
│        ├──► build: build.sh → upload calculator-build artifact
│        └──► docker: docker build → run container → curl smoke test
└────────────────────────────────────────────────────┘
   │ needs: [build, docker]
   ▼
┌──────────────────────── CD ────────────────────────┐
│ publish: login to ghcr.io with GITHUB_TOKEN        │
│          → build & push :<sha7> and :latest        │
│        │ needs: publish                            │
│        ▼                                           │
│ deploy:  kind cluster → pull secret from GITHUB_TOKEN
│          → kubectl apply → rollout status → curl through Service
└────────────────────────────────────────────────────┘
```

## Where each concept is in my workflow

| Concept | How I used it |
|---|---|
| **Workflow** | One YAML file in `.github/workflows/`. Triggers: `push` to my branch with a `paths:` filter, plus `workflow_dispatch` (manual "Run workflow" button). |
| **Jobs** | 6 jobs: `test` (×2 matrix), `build`, `docker`, `publish`, `deploy`. Each job gets a fresh VM. |
| **Steps** | Ordered list inside a job. Mix of `uses:` (marketplace actions: checkout, setup-python, upload-artifact, docker/login-action, docker/build-push-action, helm/kind-action) and `run:` (shell). |
| **needs** | `build` and `docker` need `test`; `publish` needs both; `deploy` needs `publish`. A failure stops everything after it (shown below). `build` and `docker` run in parallel. |
| **Runners** | `runs-on: ubuntu-latest` (GitHub-hosted). The test job prints `$RUNNER_OS / $RUNNER_ARCH / $RUNNER_NAME`. The matrix runs the tests on two Python versions at the same time. |
| **Secrets** | `secrets.GITHUB_TOKEN` (created by GitHub for every run). Used twice: to log in to ghcr.io and to create the Kubernetes `imagePullSecret` so the cluster can pull my image. Permissions are least-privilege: workflow default `contents: read`, only `publish` gets `packages: write`, `deploy` gets `packages: read`. GitHub masks the value in logs as `***`. |
| **Artifacts** | `test-report-py3.12`, `test-report-py3.13` (JUnit XML + coverage XML, uploaded even if tests fail via `if: always()`) and `calculator-build` (tarball + build-info). |
| **Build** | `build.sh` packages the app; the `docker` job builds the image; `publish` builds and pushes with Buildx. |
| **Test** | flake8 + 11 pytest tests (calculator functions and the HTTP API), with coverage. Plus a container smoke test (CI) and a live-deployment smoke test (CD). |
| **Pipeline execution** | Runs linked above; output below. |

## Application

| Path | What |
|---|---|
| `app/calculator.py` | `add/subtract/multiply/divide` (same as the class example) |
| `app/main.py` | Flask API: `GET /`, `GET /health`, `GET /api/<op>?a=&b=` |
| `tests/` | `test_calculator.py` (5 tests), `test_api.py` (6 tests) |
| `Dockerfile` | `python:3.13-slim`, gunicorn on 8080, runs as non-root uid 10001 |
| `build.sh` | builds `build/session16-calculator-<version>.tar.gz` + `build-info.txt` |
| `k8s/deployment.yaml` | Namespace `s16-cicd`, Deployment (2 replicas, probes, limits), ClusterIP Service |

### Run locally

```bash
pip install -r requirements-dev.txt
flake8 app tests
python -m pytest -v --cov=app
./build.sh 0.1.0
docker build -t s16-calc:local . && docker run -p 8080:8080 s16-calc:local
```

```text
$ flake8 app tests && echo "flake8: no issues"
flake8: no issues
$ python -m pytest -q --cov=app --cov-report=term-missing
...........                                                              [100%]
================================ tests coverage ================================
_______________ coverage: platform darwin, python 3.13.5-final-0 _______________

Name                Stmts   Miss  Cover   Missing
-------------------------------------------------
app/__init__.py         0      0   100%
app/calculator.py      11      0   100%
app/main.py            28      1    96%   45
-------------------------------------------------
TOTAL                  39      1    97%
11 passed in 2.70s
$ docker build -q -t s16-calc:local --build-arg APP_VERSION=local .
sha256:d41101f73762c07c4d6cc4890ada4d64583b9397542174bd238b53119e64c6ef
$ docker run -d --name s16-calc -p 18160:8080 s16-calc:local
2f88b8e0cd5f8178b12a1a1b9d95e56360ae5ff533c133d9868bc37db164020d
$ curl -s localhost:18160/health
{"status":"ok"}
$ curl -s localhost:18160/
{"app":"session16-calculator","operations":["add","divide","multiply","subtract"],"version":"local"}
$ curl -s "localhost:18160/api/multiply?a=6&b=7"
{"a":6.0,"b":7.0,"operation":"multiply","result":42.0}
$ curl -s "localhost:18160/api/divide?a=1&b=0"
{"error":"Cannot divide by zero"}
```

Line 45 is the `app.run(...)` under `if __name__ == "__main__"`, which only runs outside gunicorn.

## Pipeline execution (green run #37658100637)

```text
$ gh run view 37658100637 --json jobs --jq '.jobs[] | "\(.conclusion)\t\(.name)"'
success	CI - Lint & Unit Test (py 3.13)
success	CI - Lint & Unit Test (py 3.12)
success	CI - Docker build & container test
success	CI - Build package
success	CD - Push image to GHCR
success	CD - Deploy to Kubernetes (kind) & smoke test

$ gh api repos/PiyushhBansal/devops-heros/actions/runs/37658100637/artifacts --jq '.artifacts[] | "\(.name)\t\(.size_in_bytes) bytes"'
calculator-build	1690 bytes
test-report-py3.12	1126 bytes
test-report-py3.13	1124 bytes
PiyushhBansal~devops-heros~AON366.dockerbuild	45057 bytes
```

(The `.dockerbuild` artifact is the build record that `docker/build-push-action` uploads by itself.)

Job-log excerpts below were pulled with `gh` (with `GH_REPO=PiyushhBansal/devops-heros` set;
`cut -c30-` only strips the timestamp column).

### CI — build job

```text
$ gh run view --job 112918462996 --log | cut -f3- | cut -c30- | grep -A12 '^====' | head -13
============================
```

The version is `0.1.<github.run_number>`, and commit/actor/OS come from the runner's
default environment variables (`GITHUB_SHA`, `GITHUB_ACTOR`, `RUNNER_OS`).

### CI — docker job (container smoke test)

```text
Building session16-calculator 0.1.3
============================
```

### CD — publish job (GHCR, authenticated with GITHUB_TOKEN)

```text
total 8
-rw-r--r-- 1 runner runner  187 Oct  7 17:19 build-info.txt
-rw-r--r-- 1 runner runner 1232 Oct  7 17:19 session16-calculator-0.1.3.tar.gz
Application: session16-calculator
Version:     0.1.3
Commit:      003fa49f391e1ade3c2fcf43302312ce25fc377f
Built by:    PiyushhBansal
Runner OS:   Linux
Build date:  2026-10-07T17:19:20Z
Build completed successfully.
```

### CD — deploy job (kind cluster on the runner)

The token is masked by GitHub in the log (`--docker-***`):

```text
$ gh run view --job 112918808379 --log | cut -f3- | cut -c30- | grep -E -- '--docker-' | sed 's/\x1b\[[0-9;]*m//g'
  --docker-server=ghcr.io \
  --docker-username="PiyushhBansal" \
  --docker-*** \
```

```text
$ gh run view --job 112918462840 --log | cut -f3- | cut -c30- | grep -E '^(\{|smoke test|\[.*gunicorn)'
{"status":"ok"}
{"app":"session16-calculator","operations":["add","divide","multiply","subtract"],"version":"003fa49f391e1ade3c2fcf43302312ce25fc377f"}
smoke test passed
[2026-10-07 17:19:33 +0000] [1] [INFO] Starting gunicorn 26.2.0
[2026-10-07 17:19:33 +0000] [1] [INFO] Control socket listening at /home/appuser/.gunicorn/gunicorn.ctl
```

Smoke test through the Service (via `kubectl port-forward`):

```text
$ gh run view --job 112918601751 --log | cut -f3- | cut -c30- | grep -E '^(Will push|#12 pushing manifest.*done)'
Will push ghcr.io/piyushhbansal/session16-calculator:003fa49 and ghcr.io/piyushhbansal/session16-calculator:latest
#12 pushing manifest for ghcr.io/piyushhbansal/session16-calculator:003fa49@sha256:dd14ead0ca7ee497270b3b78bc0c8408df89697a6dd6ae658bcfd316dc770a6a 1.3s done
#12 pushing manifest for ghcr.io/piyushhbansal/session16-calculator:latest@sha256:dd14ead0ca7ee497270b3b78bc0c8408df89697a6dd6ae658bcfd316dc770a6a 0.6s done
```

The `version` field is the commit SHA passed in as a Docker build arg, so the response
proves the pod is running the image built from this exact commit.

## Failure scenario (run #37657739414)

Like section 11 of the class example, I broke `add()` on purpose (`return a + b + 1`),
pushed, then fixed it in the next commit.

```text
$ gh run view 37657739414 --json jobs --jq '.jobs[] | "\(.conclusion)\t\(.name)"'
failure	CI - Lint & Unit Test (py 3.12)
cancelled	CI - Lint & Unit Test (py 3.13)
skipped	CI - Build package
skipped	CI - Docker build & container test
skipped	CD - Push image to GHCR
skipped	CD - Deploy to Kubernetes (kind) & smoke test

$ gh run view 37657739414 --job 112917055094 --log | grep -oE '(tests/.*FAILED.*|FAILED tests.*|=+ 2 failed.*)'
tests/test_api.py::test_add_endpoint FAILED                              [ 27%]
tests/test_calculator.py::test_add FAILED                                [ 63%]
FAILED tests/test_api.py::test_add_endpoint - assert 6.0 == 5.0
FAILED tests/test_calculator.py::test_add - assert 6 == 5
========================= 2 failed, 9 passed in 0.36s ==========================
```

- Because of `needs:`, a red test job means nothing gets built, pushed or deployed.
- The py3.13 job was **cancelled**: a matrix has `fail-fast: true` by default, so when one
  leg fails GitHub stops the others.
- The test report artifact was still uploaded (`if: always()`), so the failing JUnit XML
  can be downloaded from the run.

## Notes

- Every job shows the warning `The process '/usr/bin/git' failed with exit code 128` in the
  checkout clean-up. The cause is in the course repo, not my workflow: there is a
  `session-16-github-actions/mini-project ...` gitlink without a `.gitmodules` entry
  (`fatal: No url found for submodule path ...`). It does not affect the run.
- I did not change any repo or package settings. The image package is created by the first
  push from the workflow; the cluster pulls it with the `ghcr-pull` secret, so it works
  whether the package is public or private.

## What I learned

- `needs:` is what turns separate jobs into a pipeline. Without it all jobs start in parallel
  and a failed test would not stop a deploy.
- `GITHUB_TOKEN` is enough for GHCR. No personal token needs to be stored; I only had to
  give the job `packages: write`. The same token (with `packages: read`) works as a
  Kubernetes pull secret during the run.
- `paths:` filters keep a shared repo quiet: this workflow only runs when my folder changes.
- gunicorn 26 creates a control socket in `$HOME`. My first image used `useradd --no-create-home`
  and logged `Permission denied: '/home/appuser'`; I caught it in the local `docker run`
  before pushing and switched to `--create-home`.

## Files

| File | Purpose |
|---|---|
| `app/`, `tests/` | Application and unit tests |
| `requirements.txt`, `requirements-dev.txt`, `setup.cfg` | Runtime / dev deps, flake8 + pytest config |
| `Dockerfile`, `.dockerignore` | Container image |
| `build.sh` | Build script used by the `build` job |
| `k8s/deployment.yaml` | Kubernetes Namespace, Deployment, Service used by the CD job |
| `../../.github/workflows/piyush-session16-cicd.yml` | The CI/CD workflow |
