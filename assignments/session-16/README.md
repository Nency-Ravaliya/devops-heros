# Session 16: CI/CD & GitHub Actions

## Overview
This directory contains the application codebase, unit test suite, Docker containerization manifest, GitHub Actions pipeline configuration, and pipeline execution output screenshots for Session 16: CI/CD & GitHub Actions.

---

## 1. CI vs CD Concepts

### Continuous Integration (CI)
- **Definition**: The practice of automatically building, testing, and validating code changes as soon as developers commit or raise pull requests.
- **Goal**: Catch integration issues, bugs, and breaking changes early in the development lifecycle.

### Continuous Delivery / Continuous Deployment (CD)
- **Continuous Delivery**: Automatically packages and prepares validated code changes for production deployment, requiring manual approval to release.
- **Continuous Deployment**: Automatically deploys validated code directly to production target environments without human intervention.

---

## 2. GitHub Actions Core Concepts

- **Workflow**: Automated configurable process defined in a `.github/workflows/*.yml` YAML file.
- **Jobs**: A set of steps executed sequentially on the same runner instance. Jobs can execute in parallel or sequentially using `needs`.
- **Steps**: Individual execution units within a job. Can be shell commands or external pre-built GitHub Actions.
- **Runners**: Virtual machines hosted by GitHub (e.g. `ubuntu-latest`) or self-hosted servers that execute workflow jobs.
- **Secrets**: Encrypted environment variables configured at the repository or environment level for sensitive credentials (e.g., Docker Hub tokens, SSH keys).
- **Artifacts**: Files or binaries generated during job execution (e.g., test reports, compiled packages) uploaded and persisted for later retrieval.

---

## 3. Pipeline Architecture & Implementation

### Repository Components:
- **Application Source**: [`app/calculator.py`](./app/calculator.py)
- **Unit Test Suite**: [`tests/test_calculator.py`](./tests/test_calculator.py)
- **Container Build**: [`Dockerfile`](./Dockerfile)
- **Workflow Configuration**: [`.github/workflows/ci.yml`](./.github/workflows/ci.yml)

### Workflow Steps Breakdown:
1. **Source Checkout**: Uses `actions/checkout@v3` to fetch repository code.
2. **Environment Setup**: Configures Python 3.11 environment via `actions/setup-python@v4`.
3. **Dependency Installation**: Upgrades `pip` and installs required packages from `requirements.txt`.
4. **Test Execution**: Executes `pytest` unit test suite to validate functionality.
5. **Container Image Build**: Builds Docker image `calculator-app:latest` using local `Dockerfile`.
6. **Artifact Archiving**: Uploads test results using `actions/upload-artifact@v3`.
7. **Deployment Stage**: Triggers conditional continuous deployment step on branch merges.

---

## 4. Pipeline Execution Verification

### Execution Screenshots:

- **GitHub Actions Workflow Execution**:
  ![CI/CD Pipeline Overview](./screenshots/01-cicd-pipeline.png)

- **Job Steps & Execution Logs**:
  ![Pipeline Execution Logs](./screenshots/02-pipeline-execution.png)
