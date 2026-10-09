# Session 16: CI/CD & GitHub Actions Automation

**Name:** Durga Prasad  
**Enrollment Number:** 10012  
**Course:** SST DevOps & Cloud [SWE]  
**Session:** 16 - CI/CD & GitHub Actions  
**Repository:** devops-heros / session-16-github-actions  

---

## Executive Summary

Software teams cannot afford manual testing, build procedures, and error-prone production deployments. 

**CI/CD (Continuous Integration & Continuous Delivery/Deployment)** automates the entire software delivery lifecycle from the moment an engineer issues `git push` to deployment in production.

This session provides end-to-end mastery over **GitHub Actions**, the native automation and CI/CD platform built into GitHub.

```
                         GITHUB ACTIONS AUTOMATION ARCHITECTURE
                                                                               
   git push origin main                                                        
            │                                                                  
            ▼                                                                  
   ┌────────────────────────────────────────────────────────┐                  
   │                  GitHub Event Queue                    │                  
   └──────────────────────────┬─────────────────────────────┘                  
                              │ Trigger Workflow                               
                              ▼                                                
   ┌────────────────────────────────────────────────────────┐                  
   │       Workflow: CI Pipeline (.github/workflows/ci.yml)  │                  
   │                                                        │                  
   │  ┌──────────────────┐            ┌──────────────────┐  │                  
   │  │  Job 1: Lint     │            │  Job 2: Test     │  │                  
   │  │  Runner: Ubuntu  ├───[PASS]──►│  Runner: Ubuntu  │  │                  
   │  │  (flake8)        │            │  (pytest + cov)  │  │                  
   │  └──────────────────┘            └────────┬─────────┘  │                  
   │                                           │            │                  
   │  ┌──────────────────┐                     │ [PASS]     │                  
   │  │  Job 4: Build    │◄────────────────────┴─────────┐  │                  
   │  │  Package Artifact│◄───────────┐                  │  │                  
   │  └────────┬─────────┘            │ [PASS]           │  │                  
   │           │                      │                  │  │                  
   │           ▼              ┌───────┴──────────┐       │  │                  
   │     Upload Artifact      │Job 3: Sec Scan   │       │  │                  
   │     (build-info.json)    │(Secret / Creds)  │       │  │                  
   │                          └──────────────────┘       │  │                  
   └─────────────────────────────────────────────────────┼──┘                  
                                                         │ Trigger CD          
                                                         ▼                     
   ┌────────────────────────────────────────────────────────┐                  
   │       Workflow: CD Pipeline (.github/workflows/cd.yml) │                  
   │  ┌──────────────────────────────────────────────────┐  │                  
   │  │  Job: Build & Push Docker Container Image        │  │                  
   │  │  Tags: devops-calculator:sha-xxxx, :latest       │  │                  
   │  └──────────────────────────────────────────────────┘  │                  
   └────────────────────────────────────────────────────────┘                  
```

---

## Topics & Directory Layout

| Directory | Topic & Deliverables |
|---|---|
| [`01-ci-vs-cd/`](./01-ci-vs-cd/) | What is CI, what is CD, automated bash simulation scripts |
| [`02-pipeline-concepts/`](./02-pipeline-concepts/) | Pipeline architecture: Stages, steps, jobs, sequential vs parallel execution |
| [`03-github-actions-intro/`](./03-github-actions-intro/) | First GitHub Actions workflow (`hello.yml`) |
| [`04-workflows/`](./04-workflows/) | Workflow triggers (`push`, `pull_request`, `schedule` cron, `workflow_dispatch`, `paths`) |
| [`05-jobs-steps/`](./05-jobs-steps/) | Job dependency management (`needs:`), conditional execution (`if:`), multiline steps |
| [`06-runners/`](./06-runners/) | GitHub-hosted runners (`ubuntu-latest`) vs self-hosted runners, matrix builds across OS/Python versions |
| [`07-secrets/`](./07-secrets/) | Secrets management (`${{ secrets.TOKEN }}`), environment protection rules |
| [`08-artifacts/`](./08-artifacts/) | Uploading test results, coverage XML, and distribution packages via `actions/upload-artifact@v4` |
| [`09-build-test-pipeline/`](./09-build-test-pipeline/) | Full Python CI pipeline: Checkout -> Setup -> Flake8 -> Pytest -> Artifacts |
| [`10-final-cicd-pipeline/`](./10-final-cicd-pipeline/) | Master CI/CD demo project with Dockerfile, pytest, secrets scanning, build metadata |
| [`mini-project/`](./mini-project/) | Complete implementation of the CI/CD Python calculator demo |

---

## Core Concept Reference

### 1. CI vs CD

* **CI (Continuous Integration):** Automates building, linting, and testing on every code push or pull request to identify defects early before code is merged into main.
* **CD (Continuous Delivery):** Ensures code passing CI is packaged (Docker containers, Helm charts, binaries) and deployed to staging environments, ready for 1-click production release.
* **CD (Continuous Deployment):** Bypasses manual approval gates and deploys automatically to production whenever all CI/CD stages pass.

### 2. GitHub Actions YAML Architecture

```yaml
name: Example Pipeline          # Display name in GitHub UI

on:                             # Trigger events
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:                           # Set of jobs executed in parallel by default
  test:
    runs-on: ubuntu-latest      # Virtual environment runner
    steps:                      # Ordered list of tasks
      - name: Checkout Code
        uses: actions/checkout@v4   # Pre-built marketplace action

      - name: Run Test Command
        run: pytest -v              # Shell command executed directly on runner
```

### 3. Key Pipeline Directives

* `uses:`: References a reusable action from GitHub Marketplace or another Git repository (e.g. `actions/setup-python@v5`).
* `run:`: Executes commands directly in the runner's shell (`bash`, `powershell`, `zsh`).
* `needs:`: Enforces job dependencies (e.g. `needs: [lint, test]` ensures `build` only runs after both succeed).
* `if: always()`: Ensures steps like test result uploads execute even if a previous step failed.
* `env:`: Declares environment variables scoped to workflow, job, or step level.
* `${{ secrets.SECRET_NAME }}`: Injects encrypted secrets securely without exposing raw values in console logs.

---

## Demo Project & Assignment Walkthrough

The complete assignment project is implemented in [`10-final-cicd-pipeline/`](./10-final-cicd-pipeline/) and [`mini-project/`](./mini-project/):

### Features & Capabilities Implemented:
1. **Application Code:** Robust math engine [`app/calculator.py`](./10-final-cicd-pipeline/app/calculator.py) supporting addition, subtraction, multiplication, division (with zero-division checks), power, and modulo, paired with CLI argument parsing.
2. **Unit Test Suite:** Pytest suite [`tests/test_calculator.py`](./10-final-cicd-pipeline/tests/test_calculator.py) validating positive, negative, and exception handling cases with code coverage.
3. **Multi-Stage Dockerfile:** [`Dockerfile`](./10-final-cicd-pipeline/Dockerfile) utilizing Python 3.12 builder + Python 3.12 alpine runtime with non-root security principles.
4. **CI Pipeline:** [`.github/workflows/ci.yml`](./10-final-cicd-pipeline/.github/workflows/ci.yml) orchestrating 4 jobs: Lint -> Unit Tests & Coverage -> DevSecOps Secret Scan -> Package Application.
5. **CD Pipeline:** [`.github/workflows/cd.yml`](./10-final-cicd-pipeline/.github/workflows/cd.yml) triggered on successful CI run, building the production container and running self-check smoke tests.
6. **Artifact Management:** [`build.sh`](./10-final-cicd-pipeline/build.sh) generating build metadata (`build-info.json` and `build-info.txt`) and uploading the build package.

---

## Assignment Deliverables Verification Matrix

| Syllabus Requirement | Status | Verification & Artifact |
|---|---|---|
| **Application Source Code** | Completed | [`app/calculator.py`](./10-final-cicd-pipeline/app/calculator.py) |
| **Unit Tests & Pytest** | Completed | [`tests/test_calculator.py`](./10-final-cicd-pipeline/tests/test_calculator.py) |
| **Requirements Specification** | Completed | [`requirements.txt`](./10-final-cicd-pipeline/requirements.txt) |
| **Dockerfile Implementation** | Completed | [`Dockerfile`](./10-final-cicd-pipeline/Dockerfile) (Multi-stage, alpine, non-root) |
| **CI Workflow Definition** | Completed | [`.github/workflows/ci.yml`](./10-final-cicd-pipeline/.github/workflows/ci.yml) |
| **CD Workflow Definition** | Completed | [`.github/workflows/cd.yml`](./10-final-cicd-pipeline/.github/workflows/cd.yml) |
| **Packaging Script** | Completed | [`build.sh`](./10-final-cicd-pipeline/build.sh) |
| **Demonstration README** | Completed | [`10-final-cicd-pipeline/README.md`](./10-final-cicd-pipeline/README.md) |
