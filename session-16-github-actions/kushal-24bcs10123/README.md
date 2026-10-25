# Session 16 – CI/CD & GitHub Actions

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123  
**Environment:** GitHub Actions on `ubuntu-latest` runners (fork `kushaltalati/devops-heros`, branch `ci-kushal-s16-s17`), images pushed to GitHub Container Registry, local checks on macOS / Apple Silicon with Docker Desktop 29.0.1 and the kind cluster `kushal-lab` from sessions 9–12.

The demo project is **unit-converter**, a small FastAPI service I wrote for this session (length / weight / temperature conversions, 5 endpoints). Every command and every pipeline run here was actually executed; raw terminal output is in [`logs/`](logs), the exact local commands in [`scripts/`](scripts), and the pipeline itself is [`.github/workflows/24bcs10123-session16-ci-cd.yml`](../../.github/workflows/24bcs10123-session16-ci-cd.yml) at the repo root (GitHub only runs workflows from there; [`workflow/`](workflow) holds a copy).

```text
kushal-24bcs10123/
├── README.md
├── unit-converter/                 # the application
│   ├── app/                        #   converter.py (pure logic) + main.py (FastAPI)
│   ├── tests/                      #   11 pytest tests (unit + API)
│   ├── k8s/                        #   deployment.yaml + service.yaml
│   ├── Dockerfile                  #   multi-stage, non-root (uid 10001), HEALTHCHECK
│   ├── build.sh                    #   "build" step: byte-compile + bundle + build-info.txt
│   ├── requirements.txt / requirements-dev.txt / pytest.ini / .dockerignore
├── workflow/24bcs10123-session16-ci-cd.yml   # copy of the root workflow file
├── scripts/
│   ├── 01-local-test-and-build.sh  # same steps as the test/build jobs, on my laptop
│   ├── 02-local-docker.sh          # build + run + curl the image locally
│   ├── 03-deploy-kind.sh <tag>     # the real CD target: pull the GHCR image, deploy on my kind cluster
│   └── 04-pipeline-runs.sh         # gh run list / gh run view evidence
├── logs/                           # one .txt per script + full `gh run view --log` of every run
└── screenshots/                    # Actions run pages
```

## 1. CI vs CD, and how the pipeline maps to it

```text
   git push
      │
      ▼
 ┌─────────────────────────── CI (continuous integration) ────────────────────────────┐
 │  test (python 3.11)  ┐                                                              │
 │                      ├──► build ──► artifact unit-converter-build-<run>             │
 │  test (python 3.12)  ┘                                                              │
 └──────────────────────────────────────────────────────────────────────────────────────┘
      │ only if every CI job passed
      ▼
 ┌─────────────────────────── CD (continuous delivery/deployment) ───────────────────┐
 │  docker  ──► ghcr.io/kushaltalati/unit-converter:sha-<7> + :latest                 │
 │  cd      ──► pull that image, run it, curl it, deploy it to a kind cluster          │
 │              on the runner, curl it through the Service                            │
 └──────────────────────────────────────────────────────────────────────────────────────┘
```

* **CI** = every push is integrated and verified automatically: dependencies installed, tests run, a build artifact produced. If a test fails nothing downstream runs.
* **CD** = the verified build is packaged and delivered to where it runs: the image is pushed to a registry and deployed. The deployment target in the workflow is a kind cluster created on the runner (`helm/kind-action`), because the "real" cluster is the kind cluster on my laptop, which GitHub cannot reach. The last step of the real delivery is therefore `scripts/03-deploy-kind.sh <tag>`, which pulls the exact image the pipeline pushed and deploys it locally ([logs/03-deploy-kind.txt](logs/03-deploy-kind.txt)).

## 2. The workflow, concept by concept

| Concept | Where in [the YAML](workflow/24bcs10123-session16-ci-cd.yml) | What I learned |
|---|---|---|
| **Workflow** | the whole file, `name: 24bcs10123 session16 ci-cd` | one YAML file in `.github/workflows/` = one pipeline. |
| **Trigger / event** | `on.push.branches` + `on.push.paths` + `workflow_dispatch` | runs on pushes to `ci-kushal-*` and `sessions-13-21-kushal`, but only when my files change (`paths:` filter) so other students' pushes never start it. `workflow_dispatch` adds the "Run workflow" button. I did not use `pull_request`, because that would execute in the professor's upstream repo. |
| **Jobs** | `jobs: test / build / docker / cd` | a job is a group of steps on one runner. Jobs run in parallel unless `needs:` says otherwise. |
| **`needs:`** | `build: needs: test`, `docker: needs: build`, `cd: needs: docker` | this is what turns four jobs into a pipeline. When `test` failed (run #4) `build`, `docker` and `cd` were *skipped*, not run. |
| **Steps** | every `- name:` under `steps:` | a step is either `uses:` (a reusable action from the marketplace: checkout, setup-python, upload-artifact, docker/login-action, docker/build-push-action, helm/kind-action) or `run:` (a shell command). |
| **Runners** | `runs-on: ubuntu-latest` | a fresh GitHub-hosted Ubuntu VM per job. Nothing survives between jobs except artifacts and the registry. `build-info.txt` prints `runner: Linux / X64` on GitHub and `Darwin / arm64` when I run `build.sh` on my Mac. |
| **Matrix / strategy** | `strategy.matrix.python: ["3.11", "3.12"]` | the same `test` job is expanded into two jobs on two runners. `fail-fast: false` lets both report even if one fails. |
| **Secrets** | `${{ secrets.GITHUB_TOKEN }}` in the docker/cd jobs | the token GitHub creates for every run; I only gave it `permissions: packages: write`. I did **not** add any repository secret of my own for this homework. The "show how GitHub masks secrets" step prints the token on purpose and the log shows `***` ([logs/ci-run-37663364936-final-green.txt](logs/ci-run-37663364936-final-green.txt)): `the token has 377 characters` / `printing it on purpose: ***`. A custom secret would be added under *Settings → Secrets and variables → Actions → New repository secret* and used exactly the same way, `${{ secrets.MY_NAME }}`. |
| **Artifacts** | `actions/upload-artifact@v4` in `test` (junit report, `if: always()`) and `build`; `actions/download-artifact@v4` in `docker` | files that outlive the runner. The build job uploads `build/` (sources + `build-info.txt`), the docker job downloads it again to prove jobs only share data through artifacts. Retention 7 days. |
| **Build** | `./build.sh` | for a Python service "build" means byte-compile, bundle the sources with the Dockerfile and write metadata (git sha, run number, runner, python version). |
| **Test** | `pytest -v --junitxml=…` | 11 tests: pure conversion maths + the HTTP API via FastAPI's `TestClient`, including a 400 for an unknown unit. |
| **Container image** | `docker/build-push-action@v6` with `build-args` GIT_SHA / BUILD_NUMBER | multi-stage Dockerfile: stage 1 builds a virtualenv, stage 2 is `python:3.12-slim` + the venv + the code, runs as uid 10001, has a HEALTHCHECK. Tagged `sha-<short sha>` and `latest`. |
| **Pipeline execution** | the Actions tab | 5 runs, 3 green and 2 red for different reasons, all listed below. |

## 3. Pipeline runs (evidence)

All runs: <https://github.com/kushaltalati/devops-heros/actions/workflows/24bcs10123-session16-ci-cd.yml> – screenshot [05-actions-tab-all-runs.png](screenshots/05-actions-tab-all-runs.png), `gh run list` / `gh run view` output in [logs/04-pipeline-runs.txt](logs/04-pipeline-runs.txt).

| # | Run | Result | What happened |
|---|---|---|---|
| 1 | [37660981058](https://github.com/kushaltalati/devops-heros/actions/runs/37660981058) | test ✓ build ✓ docker ✓ **cd ✗** | first version. Test, build and the GHCR push worked; my `kubectl apply --dry-run=client` step failed because even a client dry-run wants to download the OpenAPI schema from a cluster (`connection refused localhost:8080`). [log](logs/ci-run-37660981058-cd-failed.txt), [screenshot](screenshots/01-run1-cd-failed.png) |
| 2 | [37661828713](https://github.com/kushaltalati/devops-heros/actions/runs/37661828713) | **cd ✗** | `--validate=false` was not enough either: `kubectl apply` still needs API discovery. [log](logs/ci-run-37661828713-cd-dry-run-failed.txt) |
| 3 | [37662547827](https://github.com/kushaltalati/devops-heros/actions/runs/37662547827) | **all green** | replaced the dry-run with a real deployment: `helm/kind-action` creates a kind cluster on the runner, `kind load docker-image`, `kubectl apply`, `rollout status`, `curl` through the Service. [log](logs/ci-run-37662547827-green.txt), [screenshot](screenshots/02-run3-green.png) |
| 4 | [37663051248](https://github.com/kushaltalati/devops-heros/actions/runs/37663051248) | **test ✗**, build/docker/cd *skipped* | the intentional failure: I changed one assertion to `pytest.approx(10)` for 1 ft → in. Both matrix legs failed with `assert 12.000000000000002 == 10 ± 1.0e-05`, and because of `needs:` nothing was built or pushed. [log](logs/ci-run-37663051248-test-failed-on-purpose.txt), [screenshot](screenshots/03-run4-test-failed-build-skipped.png) |
| 5 | [37663364936](https://github.com/kushaltalati/devops-heros/actions/runs/37663364936) | **all green** | test fixed → final run. [log](logs/ci-run-37663364936-final-green.txt), [screenshot](screenshots/04-run5-final-green.png) |

Excerpt from run 5, `cd` job ([full log](logs/ci-run-37663364936-final-green.txt)):

```text
$ docker pull ghcr.io/kushaltalati/unit-converter:sha-780f6c2
$ docker run -d --name uc -p 8000:8000 ghcr.io/kushaltalati/unit-converter:sha-780f6c2
{"status":"ok","version":"1.0.0","uptime_seconds":0.3}
{"app":"unit-converter","version":"1.0.0","python":"3.12.15","git_sha":"780f6c23fdd5814f4c9580e04ac08eb9506352d6","build_number":"5"}
{"category":"length","value":5.0,"from":"km","to":"mi","result":3.106856}
container runs as: uid=10001(app) gid=999(app) groups=999(app)

$ kind load docker-image ghcr.io/kushaltalati/unit-converter:sha-780f6c2 --name ci
$ kubectl -n unit-converter apply -f k8s/
$ kubectl -n unit-converter rollout status deploy/unit-converter --timeout=120s
deployment "unit-converter" successfully rolled out
{"category":"weight","value":1.0,"from":"kg","to":"lb","result":2.204623}
```

Images in the registry (public, anonymous pull works): `ghcr.io/kushaltalati/unit-converter` with tags `sha-67c014e, sha-a6dc7c2, sha-805881e, sha-780f6c2, latest` – <https://github.com/kushaltalati/devops-heros/pkgs/container/unit-converter>.

## 4. The same steps on my laptop

Log: [logs/01-local-test-and-build.txt](logs/01-local-test-and-build.txt), [logs/02-local-docker.txt](logs/02-local-docker.txt)

```text
$ pytest -v
tests/test_api.py::test_health PASSED
tests/test_api.py::test_units_lists_all_categories PASSED
tests/test_api.py::test_convert_get PASSED
tests/test_api.py::test_convert_post PASSED
tests/test_api.py::test_bad_unit_is_400 PASSED
tests/test_converter.py::test_km_to_m PASSED
... 11 passed

$ ./build.sh
app:          unit-converter
version:      1.0.0
git_sha:      67c014e
build_number: local
runner:       Darwin / arm64          <- on GitHub this line says Linux / X64

$ docker run -d --rm --name uc-local -p 20016:8000 ghcr.io/kushaltalati/unit-converter:local
$ curl -s 'localhost:20016/convert/temperature?value=37&from_unit=c&to_unit=f'
{"category":"temperature","value":37.0,"from":"c","to":"f","result":98.6}
$ docker exec uc-local id
uid=10001(app) gid=999(app) groups=999(app)
```

## 5. Delivering the pipeline's image to my real cluster

Log: [logs/03-deploy-kind.txt](logs/03-deploy-kind.txt) (`scripts/03-deploy-kind.sh sha-805881e`)

```text
$ docker pull ghcr.io/kushaltalati/unit-converter:sha-805881e
pulled ghcr.io/kushaltalati/unit-converter:sha-805881e from GHCR
$ kind load docker-image ghcr.io/kushaltalati/unit-converter:sha-805881e --name kushal-lab
$ sed "s|:latest|:sha-805881e|" unit-converter/k8s/deployment.yaml | kubectl -n s16-unit-converter apply -f -
$ kubectl -n s16-unit-converter rollout status deploy/unit-converter --timeout=120s
deployment "unit-converter" successfully rolled out
NAME                              READY   STATUS    NODE
unit-converter-8675f8c5c5-nbq47   1/1     Running   kushal-lab-worker
unit-converter-8675f8c5c5-xrlm2   1/1     Running   kushal-lab-worker2
$ curl -s localhost:20080/health
{"status":"ok","version":"1.0.0","uptime_seconds":4.2}
```

The same manifest, the same image digest the runner tested – that is the point of building the image once in CI and deploying *that* artifact everywhere.

## Deliverables checklist

- [x] Application source code – `unit-converter/app`, `tests`
- [x] Dockerfile – multi-stage, non-root, HEALTHCHECK
- [x] GitHub Actions workflow – `.github/workflows/24bcs10123-session16-ci-cd.yml`
- [x] CI pipeline – test (matrix) → build (artifact)
- [x] CD pipeline – docker → GHCR → run + deploy to kind on the runner, then to my cluster
- [x] Secrets – `GITHUB_TOKEN` with `packages: write`, masking shown in the log
- [x] Artifacts – junit reports + build bundle, uploaded and downloaded
- [x] Screenshots of successful pipeline execution – `screenshots/02-run3-green.png`, `04-run5-final-green.png`
- [x] One failing run to show the gate between CI and CD – run #4

## What I understood

* A pipeline is just jobs + `needs:`. Without `needs:` GitHub runs everything in parallel; with it, a red test job means the build, the image and the deploy never happen – that is the whole value of CI.
* Runners are disposable. Anything I want to keep has to leave the runner as an artifact or an image in a registry. The `docker` job downloading the `build` job's artifact made that concrete.
* "Deploy" in CD is only as real as the target. A `--dry-run` against no cluster is not a deployment and does not even work; creating a kind cluster on the runner gave me a real `rollout status`. For my own cluster the delivery is the image tag, and `03-deploy-kind.sh` pulls exactly that tag.
* The matrix is cheap insurance: the same test job on two Python versions costs one extra runner and catches version-specific breakage.
* Secrets should never be echoed, but it is reassuring to see GitHub replace the value with `***` even when a step prints it by mistake. Permissions on `GITHUB_TOKEN` are per job, so only the two jobs that talk to GHCR get `packages: write`.
