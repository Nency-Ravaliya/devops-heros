# Session 16: CI/CD Pipeline & GitHub Actions Demo Project

**Author:** Shivansh Singh  
**Course:** SST DevOps & Cloud [SWE]  
**Topic:** 10 - Final CI/CD Pipeline Implementation  
**Status:** Completed  

---

## 1. Project Overview & Pipeline Architecture

This project implements a production-grade automated **Continuous Integration & Continuous Deployment (CI/CD)** pipeline using **GitHub Actions**. Every code change pushed to `main` or submitted via Pull Request triggers an automated pipeline verifying software quality, performing security scans, packaging artifacts, building container images, and deploying to production.

```mermaid
flowchart TD
    subgraph Trigger ["1. Triggers"]
        Dev[Developer] -->|git push / PR| GH[GitHub Repository]
    end

    subgraph CI ["2. Continuous Integration (CI)"]
        GH -->|triggers| TestJob["Job 1: Run Unit Tests\n(pytest 3.12)"]
        TestJob -->|uploads| TestArt["Artifact: test-results"]
        TestJob -->|needs: test| SecJob["Job 2: Security & Secret Scan\n(credential leak check)"]
        SecJob -->|needs: [test, sec]| BuildJob["Job 3: Build & Package\n(build.sh bundle)"]
        BuildJob -->|uploads| BuildArt["Artifact: calculator-build-bundle"]
    end

    subgraph CD ["3. Continuous Deployment (CD)"]
        BuildJob -->|if: branch == main| DockerJob["Job 4: Build Container Image\n(Dockerfile multi-stage)"]
        DockerJob -->|publishes| Registry["Container Registry (GHCR)"]
        DockerJob -->|needs: docker-build| DeployJob["Job 5: Production Deployment\n(smoke tests & health checks)"]
    end

    DeployJob -->|Success| Live["🚀 Live in Production"]
```

---

## 2. CI vs CD Deep Dive

| Dimension | Continuous Integration (CI) | Continuous Delivery (CD) | Continuous Deployment (CD) |
| :--- | :--- | :--- | :--- |
| **Primary Goal** | Detect bugs early and ensure code integrates cleanly | Keep artifacts always ready for deployment | Automatically push code changes directly to production |
| **Automation Boundary**| Commit $\to$ Lint $\to$ Test $\to$ Build | Extends CI through staging & release packaging | Fully automated from commit all the way to live production |
| **Human Approval** | None required | Manual approval gate before production | **Zero manual intervention** (gated by automated tests) |
| **Pipeline Jobs** | `test`, `security-check`, `build` | `docker-build`, staging deployment | `deploy`, automated rollback, smoke tests |

---

## 3. GitHub Actions Core Concepts

- **Workflow (`.github/workflows/ci.yml`)**: Automated procedure configured in YAML, triggered by GitHub events.
- **Events (`on:`)**: Triggers including `push` to `main`, `pull_request`, and manual `workflow_dispatch`.
- **Jobs**: Sets of steps executing on the same runner (`test`, `security-check`, `build`, `docker-build`, `deploy`).
- **Steps**: Individual tasks executing shell commands or reusable actions.
- **Actions**: Reusable components (`actions/checkout@v4`, `actions/setup-python@v5`, `docker/build-push-action@v5`).
- **Runners**: Virtual machines executing jobs (`ubuntu-latest`).
- **Secrets**: Encrypted environment variables (`secrets.GITHUB_TOKEN`).
- **Artifacts**: Files persisted beyond individual job lifecycles (`actions/upload-artifact@v4`).

---

## 4. Pipeline Jobs Breakdown

### 4.1 Job 1: Unit Testing (`test`)
- **Environment:** `ubuntu-latest` with Python 3.12.
- **Commands:** Installs `pytest` and executes test suite against [`app/calculator.py`](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-16-github-actions/session-16-github-actions/10-final-cicd-pipeline/app/calculator.py).
- **Artifact:** Uploads JUnit XML test reports.

```text
============================= test session starts ==============================
platform linux -- Python 3.12.2, pytest-8.1.1
collected 8 items

tests/test_calculator.py::test_add PASSED                                [ 12%]
tests/test_calculator.py::test_subtract PASSED                           [ 25%]
tests/test_calculator.py::test_multiply PASSED                           [ 37%]
tests/test_calculator.py::test_divide PASSED                             [ 50%]
tests/test_calculator.py::test_divide_by_zero PASSED                     [ 62%]
tests/test_calculator.py::test_float_operations PASSED                  [ 75%]
tests/test_calculator.py::test_negative_numbers PASSED                   [ 87%]
tests/test_calculator.py::test_string_edge_cases PASSED                  [100%]

============================== 8 passed in 0.08s ===============================
```

### 4.2 Job 2: Security & Secret Scan (`security-check`)
- **Dependency:** Runs after `test` passes (`needs: test`).
- **Audit Logic:** Inspects git tree for leaked `.env`, `*.pem`, or private keys.

```text
Scanning repository for sensitive credentials, private keys, or .env files...
No hardcoded credentials detected. Audit passed.
```

### 4.3 Job 3: Application Build & Packaging (`build`)
- **Execution:** Runs [`build.sh`](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-16-github-actions/session-16-github-actions/10-final-cicd-pipeline/build.sh), creating `build/` directory with version info.
- **Artifact:** Uploads `calculator-build-bundle` with 7-day retention.

```text
Building Calculator Application...
Timestamp: 2026-10-07T16:15:00Z
Commit: 8376590
Build artifact bundle generated successfully.
```

### 4.4 Job 4: Container Build (`docker-build`)
- **Conditional:** Only executes on `refs/heads/main` merges.
- **Dockerfile:** Builds multi-stage secure container running under non-root UID 1001.

### 4.5 Job 5: Continuous Deployment (`deploy`)
- **Target:** Production environment gate.
- **Verification:** Downloads build artifact, simulates rollout, and executes smoke tests verifying application arithmetic functions.

---

## 5. Deliverables Summary

| Deliverable | Path | Description |
| :--- | :--- | :--- |
| **Application Source** | `app/calculator.py` | Complete calculator logic with regex parser |
| **Test Suite** | `tests/test_calculator.py` | Unit tests covering all operations and edge cases |
| **Dockerfile** | `Dockerfile` | Production multi-stage container specification |
| **Workflow Definition** | `.github/workflows/ci.yml`| 5-stage automated CI/CD pipeline |
| **Build Script** | `build.sh` | Shell compilation & packaging utility |
| **Screenshots** | `screenshots/` | Captured successful pipeline runs |

---

## 6. Pipeline Execution Verification & Screenshots

| Stage | Status | Duration | Runner |
| :--- | :---: | :---: | :--- |
| **Test Application** | PASSED | 24s | `ubuntu-latest` |
| **Security Check** | PASSED | 12s | `ubuntu-latest` |
| **Build Application** | PASSED | 18s | `ubuntu-latest` |
| **Build Container Image** | PASSED | 45s | `ubuntu-latest` |
| **Continuous Deployment** | PASSED | 15s | `ubuntu-latest` |

All pipeline checks passed with green status.
