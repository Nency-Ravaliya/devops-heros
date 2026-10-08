# Session 17: Complete CI/CD & DevSecOps

## Overview
This directory contains the application codebase, containerization specifications, Kubernetes deployment manifests, security scanning configurations, and GitHub Actions DevSecOps pipeline for Session 17: Complete CI/CD & DevSecOps.

---

## 1. DevSecOps Pipeline Flow

```text
Code
  │
  ▼
Build & Unit Tests
  │
  ▼
SAST (Bandit) ───► SCA (Safety) ───► Secret Scan (Trufflehog)
  │
  ▼
Docker Image Build
  │
  ▼
Container Image Scan (Trivy)
  │
  ▼
Security Gate (Enforce zero HIGH/CRITICAL vulnerabilities)
  │
  ▼
Push Image to Registry
  │
  ▼
Deploy to Kubernetes Cluster
```

---

## 2. Security Tools & Scanning Mechanisms

### SAST (Static Application Security Testing)
- **Tool**: Bandit
- **Purpose**: Analyzes Python source code AST for security vulnerabilities, hardcoded secrets, insecure imports, and unsafe SQL/command execution.
- **Configuration**: `bandit -r app/ -f txt`

### SCA (Software Composition Analysis)
- **Tool**: Safety / Dependabot
- **Purpose**: Scans project dependencies in `requirements.txt` against known CVE vulnerability databases.
- **Configuration**: `safety check -r requirements.txt`

### Secret Scanning
- **Tool**: TruffleHog / GitLeaks
- **Purpose**: Scans repository commit history and file diffs for exposed high-entropy strings, API keys, and SSH credentials.

### Container Image Scanning & Security Gate
- **Tool**: Aqua Security Trivy
- **Purpose**: Scans OS packages and application dependencies inside built Docker images.
- **Security Gate**: Configured with `exit-code: 1` and `severity: CRITICAL,HIGH` to automatically fail the pipeline if unmitigated high-risk vulnerabilities are detected.

---

## 3. Project File Structure

- **Application Source**: [`app/app.py`](./app/app.py)
- **Unit Test Suite**: [`tests/test_app.py`](./tests/test_app.py)
- **Container Build**: [`Dockerfile`](./Dockerfile)
- **Kubernetes Deployment**: [`k8s/deployment.yaml`](./k8s/deployment.yaml)
- **Kubernetes Service**: [`k8s/service.yaml`](./k8s/service.yaml)
- **Pipeline Workflow**: [`.github/workflows/devsecops.yml`](./.github/workflows/devsecops.yml)

---

## 4. Pipeline Execution Verification

### Terminal Screenshots:

- **DevSecOps Pipeline Execution Workflow**:
  ![DevSecOps Pipeline Overview](./screenshots/01-devsecops-pipeline.png)

- **Security Gate & Image Scanning Output**:
  ![Security Scan Verification](./screenshots/02-security-scan.png)
