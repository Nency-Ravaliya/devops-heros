# Session 17 — Complete CI/CD & DevSecOps

> **Goal:** Build a production-grade CI/CD pipeline that integrates security scanning (DevSecOps) at every stage of the software delivery lifecycle.

---

## 📁 Folder Structure

```
session-17-devsecops/
├── 02-container-registry/      # GHCR setup & image tagging
├── 03-kubernetes-deployment/   # K8s manifests & deployment strategy
├── 04-sast/                    # Static Application Security Testing (CodeQL)
├── 05-sca/                     # Software Composition Analysis (pip-audit)
├── 06-secret-scanning/         # Secret detection (Gitleaks / GitHub)
├── 07-container-image-scanning/# Container vulnerability scan (Trivy)
├── 08-security-gates/          # Security gate policy & failure thresholds
└── demo/                       # Full DevSecOps mini-project (Flask + GitHub Actions)
    ├── app/                    # Flask application source code
    ├── tests/                  # pytest unit tests
    ├── k8s/                    # Kubernetes manifests
    ├── .github/workflows/      # GitHub Actions pipeline
    ├── Dockerfile
    ├── requirements.txt
    └── README.md
```

---

## 🔁 DevSecOps Pipeline Flow

```
Code Push
    │
    ▼
┌───────────────────┐
│  1. Unit Tests    │  pytest — 8 tests, coverage report
└────────┬──────────┘
         │
┌────────▼──────────┐
│  2. SAST          │  GitHub CodeQL — static code analysis
└────────┬──────────┘
         │
┌────────▼──────────┐
│  3. SCA           │  pip-audit — dependency vulnerability check
└────────┬──────────┘
         │
┌────────▼──────────┐
│  4. Secret Scan   │  GitHub Secret Scanning — detect leaked secrets
└────────┬──────────┘
         │ (all security gates must pass)
┌────────▼──────────┐
│  5. Docker Build  │  docker build — multi-stage optimised image
└────────┬──────────┘
         │
┌────────▼──────────┐
│  6. Image Scan    │  Trivy — CVE scan on built Docker image
└────────┬──────────┘
         │
┌────────▼──────────┐
│  7. Push to GHCR  │  Push image to GitHub Container Registry
└────────┬──────────┘
         │ (only on push to main)
┌────────▼──────────┐
│  8. Deploy to K8s │  kubectl apply — rolling update on cluster
└───────────────────┘
```

---

## 🛡️ DevSecOps Concepts Covered

| # | Concept | Tool | Stage |
|---|---------|------|-------|
| 1 | **Unit Testing** | pytest + pytest-cov | Before build |
| 2 | **SAST** | GitHub CodeQL | Before build |
| 3 | **SCA** | pip-audit | Before build |
| 4 | **Secret Scanning** | GitHub built-in | Every push |
| 5 | **Container Build** | Docker | After all security checks pass |
| 6 | **Image Scanning** | Trivy | After build |
| 7 | **Container Registry** | GHCR (ghcr.io) | After scan |
| 8 | **K8s Deployment** | kubectl | Final stage |
| 9 | **Security Gates** | Pipeline conditions | Block on failure |

---

## 🚀 Quick Start

### Run the demo app locally

```bash
cd demo
pip install -r requirements.txt
python app/app.py
# → http://localhost:5001
```

### Run tests with coverage

```bash
pip install -r requirements-dev.txt
pytest --cov=app --cov-report=term-missing
```

**Expected output:**
```
tests/test_app.py::test_home                        PASSED
tests/test_app.py::test_health                      PASSED
tests/test_app.py::test_greet                       PASSED
tests/test_app.py::test_add_numbers                 PASSED
tests/test_app.py::test_add_numbers_missing_fields  PASSED
tests/test_app.py::test_calculator_multiply         PASSED
tests/test_app.py::test_calculator_divide_by_zero   PASSED
tests/test_app.py::test_status                      PASSED

---------- coverage: platform linux, python 3.12 ----------
Name            Stmts   Miss  Cover
-----------------------------------
app/app.py         62      4    94%
-----------------------------------
TOTAL              62      4    94%

8 passed in 1.23s
```

### Run SCA locally (pip-audit)

```bash
pip install pip-audit
pip-audit -r requirements.txt
```

### Run container image scan (Trivy)

```bash
docker build -t hey-cicd:latest .
trivy image hey-cicd:latest
```

### Deploy to Kubernetes

```bash
kubectl apply -f demo/k8s/deployment.yaml
kubectl apply -f demo/k8s/service.yaml
kubectl rollout status deployment/session17-python
kubectl get pods -l app=session17-python
```

---

## 📋 Pipeline Output Summary

### ✅ Unit Tests

```
8 passed, 0 failed — 94% coverage
```

### ✅ SAST (CodeQL)

```
No critical security issues found.
CodeQL analysis completed successfully.
```

### ✅ SCA (pip-audit)

```
No known vulnerabilities found in dependencies.
flask 3.0.3 — OK
pytest 8.2.2 — OK
```

### ✅ Container Image Scan (Trivy)

```
hey-cicd:latest (alpine 3.19.1)
Total: 0 (CRITICAL: 0, HIGH: 0)
```

### ✅ Deployment

```
deployment.apps/session17-python created
service/session17-python created
deployment.apps/session17-python condition met (Available)
NAME                                READY   STATUS    RESTARTS   AGE
session17-python-7d4b9f8c6d-xk2np   1/1     Running   0          30s
session17-python-7d4b9f8c6d-pq8mt   1/1     Running   0          30s
```

---

## 🔒 Security Gates

The pipeline enforces the following **security gates**. Any failure **blocks the build**:

| Gate | Tool | Threshold |
|------|------|-----------|
| Unit tests | pytest | 0 failures allowed |
| SAST | CodeQL | No HIGH/CRITICAL findings |
| SCA | pip-audit | No CRITICAL CVEs |
| Image scan | Trivy | No CRITICAL CVEs (configurable) |

---

## 📁 Key Files

| File | Description |
|------|-------------|
| `demo/.github/workflows/devsecops.yml` | Full CI/CD + security pipeline |
| `demo/Dockerfile` | Multi-stage production Docker image |
| `demo/app/app.py` | Flask application |
| `demo/tests/test_app.py` | pytest unit tests |
| `demo/k8s/deployment.yaml` | Kubernetes Deployment manifest |
| `demo/k8s/service.yaml` | Kubernetes Service manifest |
| `04-sast/README.md` | SAST concepts & CodeQL setup |
| `05-sca/README.md` | SCA concepts & pip-audit usage |
| `07-container-image-scanning/README.md` | Trivy image scanning guide |
| `08-security-gates/README.md` | Security gate policy |

---

## 👨‍💻 Built With

- **Python 3.12** + **Flask 3.x**
- **pytest** + **pytest-cov**
- **Docker** (multi-stage build)
- **GitHub Actions**
- **GitHub CodeQL** (SAST)
- **pip-audit** (SCA)
- **Trivy** (container image scanning)
- **Kubernetes** (kubectl, Deployment, Service)
- **GHCR** (GitHub Container Registry)
