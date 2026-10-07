# Session 17: DevSecOps CI/CD Pipeline

**Name:** Ankita Tripathi  
**Roll Number:** 24BCS10062  

---

## Overview

This project demonstrates the implementation of a complete **DevSecOps CI/CD pipeline** for a Python web application.

The pipeline integrates automated testing, security scanning, containerization, container vulnerability scanning, image publishing, and Kubernetes deployment.

The complete workflow is automated using **GitHub Actions** and is triggered whenever code is pushed to the `main` branch or when a pull request is created against `main`.

### DevSecOps Pipeline

```text
Developer Push / Pull Request
            |
            v
      GitHub Actions
            |
            v
       Unit Tests
       (pytest)
            |
            +-------------------+
            |                   |
            v                   v
      SAST - CodeQL      SCA - pip-audit
            |                   |
            +---------+---------+
                      |
                      v
                Docker Build
                      |
                      v
              Trivy Image Scan
                      |
                      v
             Push to Docker Hub
                      |
                      v
            Kubernetes Deployment
                 using Kind
                      |
                      v
             Application Verification
```

---

# Technologies Used

| Technology | Purpose |
|---|---|
| Python | Application development |
| Flask | Web application/API |
| pytest | Unit testing |
| pytest-cov | Code coverage |
| Git | Version control |
| GitHub | Source code repository |
| GitHub Actions | CI/CD automation |
| CodeQL | Static Application Security Testing (SAST) |
| pip-audit | Software Composition Analysis (SCA) |
| Docker | Application containerization |
| Trivy | Docker image vulnerability scanning |
| Docker Hub | Container image registry |
| Kubernetes | Container orchestration |
| Kind | Temporary Kubernetes cluster for CI deployment |
| kubectl | Kubernetes deployment management |

---

# Project Structure

```text
hey-cicd/
│
├── .github/
│   └── workflows/
│       └── devsecops.yml
│
├── app/
│
├── k8s/
│   ├── deployment.yaml
│   └── service.yaml
│
├── tests/
│
├── Dockerfile
├── pytest.ini
├── requirements.txt
├── requirements-dev.txt
├── README.md
└── SECURITY.md
```

The `.github/workflows/devsecops.yml` file contains the complete DevSecOps CI/CD pipeline.

---

# Application

The project contains a Python web application exposing multiple API endpoints.

Some of the implemented endpoints include:

```text
GET  /
GET  /health
GET  /api/status
GET  /api/greet/<name>

POST /api/add
POST /api/calculate
POST /api/pipeline/run
```

The application can be started locally using:

```bash
python3 app/app.py
```

The application is available at:

```text
http://localhost:5001
```

---

# Local Setup

## 1. Clone the Repository

```bash
git clone https://github.com/vvsleepy/hey-cicd.git
cd hey-cicd
```

---

## 2. Create a Python Virtual Environment

```bash
python3 -m venv .venv
```

Activate it on macOS/Linux:

```bash
source .venv/bin/activate
```

---

## 3. Install Dependencies

Install the application and development dependencies:

```bash
pip install -r requirements-dev.txt
```

---

## 4. Run the Application

```bash
python3 app/app.py
```

Open the application in the browser using:

```text
http://localhost:5001
```

---

# Unit Testing

Unit testing is implemented using **pytest**.

Tests can be executed locally using:

```bash
pytest
```

Tests with code coverage can be executed using:

```bash
pytest --cov=app --cov-report=term-missing
```

The CI/CD pipeline automatically executes the tests before allowing the Docker build and deployment stages to continue.

This ensures that application code is validated before being packaged and deployed.

---

# DevSecOps CI/CD Pipeline

The complete pipeline is defined in:

```text
.github/workflows/devsecops.yml
```

The workflow is named:

```text
Python DevSecOps Pipeline
```

It runs automatically for:

```yaml
on:
  push:
    branches:
      - main

  pull_request:
    branches:
      - main
```

Therefore, pushes to `main` and pull requests targeting `main` automatically trigger the security and CI pipeline.

Deployment is restricted to actual pushes to the `main` branch.

---

# Step 1: Unit Tests

The first stage executes automated unit tests.

GitHub Actions performs the following operations:

```text
Checkout source code
        ↓
Setup Python 3.12
        ↓
Install development dependencies
        ↓
Run pytest
        ↓
Generate coverage report
```

The pipeline command is:

```bash
pytest --cov=app --cov-report=term-missing
```

This stage verifies that the application's expected functionality works correctly.

The Docker build is dependent on the successful completion of the testing and security stages.

---

# Step 2: SAST Using CodeQL

Static Application Security Testing is performed using **GitHub CodeQL**.

SAST analyzes the application's source code to identify potential security weaknesses without executing the application.

The workflow initializes CodeQL for Python:

```yaml
- name: Initialize CodeQL
  uses: github/codeql-action/init@v3
  with:
    languages: python
```

The source code is then analyzed using:

```yaml
- name: Analyze code
  uses: github/codeql-action/analyze@v3
```

The CodeQL job has the required permissions:

```yaml
permissions:
  contents: read
  security-events: write
```

This allows CodeQL security analysis results to be processed by GitHub.

---

# Step 3: SCA Using pip-audit

Software Composition Analysis is performed using **pip-audit**.

Modern applications depend heavily on third-party libraries. Even if application source code is secure, vulnerable dependencies can introduce security risks.

The pipeline installs:

```bash
pip install -r requirements.txt
pip install pip-audit
```

The dependency security scan is then performed using:

```bash
pip-audit
```

This checks the Python dependencies for known vulnerabilities.

Therefore:

```text
CodeQL
   ↓
Checks application source code

pip-audit
   ↓
Checks third-party Python dependencies
```

Using both provides better security coverage than relying on only one type of scan.

---

# Step 4: Docker Build

After the following jobs complete successfully:

```text
Unit Tests
SAST - CodeQL
SCA - Dependency Scan
```

the Docker build stage begins.

The dependency relationship is defined using:

```yaml
needs:
  - test
  - sast
  - sca
```

The application image is built using:

```bash
docker build -t session17-python:${{ github.sha }} .
```

Using `${{ github.sha }}` associates the image with the exact Git commit that triggered the workflow.

This improves traceability between:

```text
Source Code
    ↓
Git Commit
    ↓
Docker Image
```

---

# Dockerfile

The project contains a `Dockerfile` used to package the Python application and its dependencies into a portable container image.

The image can also be built locally using:

```bash
docker build -t hey-cicd:latest .
```

Run the container using:

```bash
docker run -p 5001:5001 hey-cicd:latest
```

The application can then be accessed at:

```text
http://localhost:5001
```

---

# Step 5: Docker Image Security Scan Using Trivy

Before the container image is published, it is scanned using **Trivy**.

Trivy scans container images and their installed packages for known security vulnerabilities.

The image is built in the image scanning job:

```bash
docker build -t session17-python:${{ github.sha }} .
```

The pipeline then performs the scan using:

```bash
trivy image --severity HIGH,CRITICAL session17-python:${{ github.sha }}
```

The scan focuses on:

```text
HIGH
CRITICAL
```

severity vulnerabilities.

This introduces container security scanning before the publishing and deployment stages.

---

# Step 6: Push Image to Docker Hub

After the image scanning stage completes, the pipeline publishes the application image to **Docker Hub**.

Docker Hub authentication is performed using:

```yaml
uses: docker/login-action@v3
```

with:

```yaml
username: ankeyy
password: ${{ secrets.DOCKERHUB_TOKEN }}
```

The image is built with two tags:

```bash
docker build \
  -t ankeyy/hey-cicd:${{ github.sha }} \
  -t ankeyy/hey-cicd:latest \
  .
```

The images are then pushed using:

```bash
docker push ankeyy/hey-cicd:${{ github.sha }}
docker push ankeyy/hey-cicd:latest
```

Therefore, two useful image tags are maintained:

```text
ankeyy/hey-cicd:latest
ankeyy/hey-cicd:<git-commit-sha>
```

The `latest` tag represents the most recently published image, while the commit SHA tag provides traceability to a specific version of the source code.

---

# GitHub Secret Configuration

Docker Hub credentials are not stored directly inside the workflow file.

A GitHub Actions secret is used:

```text
DOCKERHUB_TOKEN
```

The secret contains a Docker Hub access token.

It is configured from the repository settings under:

```text
Settings
→ Secrets and variables
→ Actions
→ Repository secrets
```

The workflow accesses the secret using:

```yaml
${{ secrets.DOCKERHUB_TOKEN }}
```

This prevents sensitive credentials from being hardcoded into the repository.

---

# Step 7: Kubernetes Deployment

After the Docker image has been published successfully, the deployment stage begins.

The deployment job depends on:

```yaml
needs:
  - push
```

Deployment occurs only for a push to the `main` branch:

```yaml
if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

Therefore, pull requests can execute testing and security validation without automatically performing a deployment.

---

# Kind Kubernetes Cluster

For CI deployment testing, the workflow automatically creates a temporary Kubernetes cluster using **Kind**.

The workflow uses:

```yaml
- name: Create k8s Kind Cluster (For testing deployment)
  uses: helm/kind-action@v1.10.0
```

Kind runs Kubernetes using Docker containers, making it suitable for temporary CI environments.

This means a separate permanent Kubernetes cluster or `KUBECONFIG` secret is not required for this CI deployment implementation.

The Kubernetes cluster is created dynamically on the GitHub Actions runner.

---

# Kubernetes Deployment Manifest

The deployment configuration is stored in:

```text
k8s/deployment.yaml
```

The image is defined using a placeholder:

```yaml
image: ankeyy/hey-cicd:__IMAGE_TAG__
```

During deployment, the pipeline replaces:

```text
__IMAGE_TAG__
```

with the Git commit SHA:

```bash
sed -i "s|__IMAGE_TAG__|${{ github.sha }}|g" k8s/deployment.yaml
```

Therefore, Kubernetes deploys the exact Docker image generated for that Git commit.

For example:

```text
ankeyy/hey-cicd:<git-commit-sha>
```

This provides strong deployment traceability.

---

# Kubernetes Service

The service configuration is stored in:

```text
k8s/service.yaml
```

The Kubernetes resources are applied using:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

The deployment status is then verified using:

```bash
kubectl rollout status deployment/session17-python --timeout=60s
```

A successful rollout confirms that Kubernetes successfully started the application deployment.

---

# Application Verification in CI

Deployment alone is not considered sufficient.

After Kubernetes deployment, the workflow performs an application-level verification.

The Kubernetes service is temporarily forwarded to the GitHub Actions runner:

```bash
kubectl port-forward service/session17-python 5001:80 &
```

The workflow waits briefly:

```bash
sleep 3
```

It then fetches the application:

```bash
curl -s http://localhost:5001 | head -n 15
```

The API status endpoint is also tested:

```bash
curl -s http://localhost:5001/api/status
```

This confirms that the deployed application is actually responding after deployment.

---

# Complete Pipeline Dependency Flow

The implemented workflow can be summarized as:

```text
                    Git Push / Pull Request
                             |
                             v
          +------------------+------------------+
          |                  |                  |
          v                  v                  v
     Unit Tests        SAST - CodeQL      SCA - pip-audit
          |                  |                  |
          +------------------+------------------+
                             |
                             v
                       Docker Build
                             |
                             v
                       Trivy Scan
                             |
                             v
                    Push to Docker Hub
                             |
                             v
                   Create Kind Cluster
                             |
                             v
                    Kubernetes Deploy
                             |
                             v
                     Rollout Verification
                             |
                             v
                       Curl Testing
```

This ordering ensures that later stages depend on successful completion of earlier quality and security checks.

---

# Security Controls Implemented

This project integrates security throughout the CI/CD lifecycle instead of treating security as a final manual step.

| Stage | Security / Quality Control |
|---|---|
| Source code | Git version control |
| Testing | pytest |
| Code coverage | pytest-cov |
| Source security | CodeQL SAST |
| Dependency security | pip-audit SCA |
| Container security | Trivy |
| Credential protection | GitHub Secrets |
| Image versioning | Git SHA tagging |
| Deployment | Kubernetes |
| Deployment validation | kubectl rollout status |
| Runtime verification | curl |

This demonstrates the principle of **shifting security left** in the software development lifecycle.

---

# CI/CD vs DevSecOps

A traditional CI/CD pipeline focuses mainly on:

```text
Build
Test
Deploy
```

The implemented DevSecOps pipeline extends this by adding automated security checks:

```text
Build
Test
Security Scan
Dependency Scan
Container Scan
Publish
Deploy
Verify
```

Security therefore becomes part of the automated software delivery process.

---

# Benefits of the Implemented Pipeline

The project demonstrates several important DevSecOps practices:

- Automated unit testing
- Automated code coverage
- Static source-code security analysis
- Dependency vulnerability scanning
- Containerized application delivery
- Container image vulnerability scanning
- Secure credential handling using GitHub Secrets
- Automated Docker image publishing
- Immutable image identification using Git commit SHA
- Automated Kubernetes deployment
- Deployment rollout verification
- Post-deployment application testing

The pipeline also prevents later stages from executing when their required previous stages have not completed successfully.

---

# Running Security Checks Locally

## Dependency Scan

Install pip-audit:

```bash
pip install pip-audit
```

Run:

```bash
pip-audit
```

---

## Docker Image Scan

If Trivy is installed locally, the Docker image can be scanned using:

```bash
trivy image --severity HIGH,CRITICAL hey-cicd:latest
```

---

# Local Docker Workflow

Build:

```bash
docker build -t hey-cicd:latest .
```

Run:

```bash
docker run -p 5001:5001 hey-cicd:latest
```

Check the application:

```bash
curl http://localhost:5001
```

Check API status:

```bash
curl http://localhost:5001/api/status
```

---

# CI/CD Workflow Summary

| Step | Job | Tool | Purpose |
|---|---|---|---|
| 1 | Unit Tests | pytest | Verify application functionality |
| 2 | SAST | CodeQL | Analyze source code for security issues |
| 3 | SCA | pip-audit | Check dependencies for known vulnerabilities |
| 4 | Docker Build | Docker | Build container image |
| 5 | Image Scan | Trivy | Scan image for HIGH/CRITICAL vulnerabilities |
| 6 | Image Push | Docker Hub | Publish versioned container image |
| 7 | Deployment | Kubernetes + Kind | Deploy application |
| 8 | Verification | kubectl + curl | Verify rollout and application response |

---

# Screenshots / Execution Evidence

Screenshots of the practical execution have been captured separately as part of the assignment submission.

The screenshots provide evidence of the major stages, including:

```text
• Local application execution
• Unit test execution and coverage
• Dependency security scanning
• Docker image build
• GitHub Actions workflow execution
• CodeQL SAST analysis
• pip-audit SCA scan
• Trivy image scan
• Docker Hub image push
• Kubernetes deployment
• Kubernetes rollout verification
• Application/API verification
```

The screenshots are intentionally maintained separately and are not embedded directly in this README.

---

# Key Learning Outcomes

Through this session, I learned how DevOps and security practices can be integrated into one automated delivery pipeline.

The main concepts practiced were:

1. Creating CI/CD pipelines using GitHub Actions.
2. Running automated Python tests using pytest.
3. Generating test coverage using pytest-cov.
4. Performing SAST using GitHub CodeQL.
5. Performing Software Composition Analysis using pip-audit.
6. Building and tagging Docker images.
7. Scanning container images using Trivy.
8. Securely authenticating using GitHub repository secrets.
9. Publishing Docker images to Docker Hub.
10. Using Git commit SHA values for image versioning.
11. Creating a temporary Kubernetes cluster using Kind.
12. Deploying an application using Kubernetes manifests.
13. Verifying Kubernetes rollout status.
14. Testing the deployed application from inside the CI environment.
15. Understanding how DevSecOps introduces automated security checks throughout the software delivery lifecycle.

---

# Conclusion

This project implements an end-to-end **DevSecOps CI/CD pipeline** for a Python application.

The workflow combines:

```text
Python
   ↓
pytest
   ↓
CodeQL + pip-audit
   ↓
Docker
   ↓
Trivy
   ↓
Docker Hub
   ↓
Kubernetes / Kind
   ↓
Deployment Verification
```

The implementation demonstrates how testing, security analysis, containerization, image publishing, deployment, and verification can be automated through a single GitHub Actions workflow.

Instead of performing security checks only after development is complete, the pipeline integrates security directly into the CI/CD process. This provides faster feedback, improved traceability, safer dependency and container management, and a more reliable deployment process.

---

**Session:** 17 — DevSecOps  
**Name:** Ankita Tripathi  
**Roll Number:** 24BCS10062