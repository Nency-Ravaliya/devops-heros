# Session 17: Complete CI/CD & DevSecOps Pipeline

**Name:** Durga Prasad  
**Enrollment Number:** 10012  
**Course:** SST DevOps & Cloud [SWE]  
**Session:** 17 - DevSecOps & Secure Software Delivery  
**Repository:** devops-heros / session-17-devsecops  

---

## 1. Executive Summary & Philosophy of DevSecOps

Traditional security ("Sec") occurred at the very end of the development lifecycle as a manual, bureaucratic gate. This caused critical security bottlenecks, delayed production deployments, and allowed critical vulnerabilities to slip into runtime.

**DevSecOps** "shifts security left". Security checks are embedded directly into the developer workflow and CI/CD pipelines as automated gates. If code introduces a vulnerability, an unpinned dependency with known CVEs, or committed secrets, the pipeline fails immediately.

```
                          DEVSECOPS PIPELINE LIFECYCLE
                                                                               
   Developer Commit                                                            
          │                                                                    
          ▼                                                                    
   ┌───────────────┐     ┌───────────────┐     ┌───────────────┐               
   │  Unit Tests   ├───► │  SAST Scan    ├───► │   SCA Scan    │               
   │   (pytest)    │     │   (CodeQL)    │     │  (pip-audit)  │               
   └───────────────┘     └───────────────┘     └───────┬───────┘               
                                                       │ [ALL PASS]            
                                                       ▼                       
   ┌───────────────┐     ┌───────────────┐     ┌───────────────┐               
   │ Docker Build  │◄────┤  Secret Scan  │◄────┤ Security Gate │               
   │  (Container)  │     │  (Audit Keys) │     │ (Quality Gate)│               
   └───────┬───────┘     └───────────────┘     └───────────────┘               
           │                                                                   
           ▼                                                                   
   ┌───────────────┐     ┌───────────────┐     ┌───────────────┐               
   │  Image Scan   ├───► │ Image Registry├───► │  K8s Deploy   │               
   │ (Trivy CVEs)  │     │ (Docker Hub)  │     │(Kind Rollout) │               
   └───────────────┘     └───────────────┘     └───────────────┘               
```

---

## 2. DevSecOps Security Testing Categories

| Security Layer | Tool | When It Runs | What It Scans For | Action on Failure |
|---|---|---|---|---|
| **Unit Testing** | `pytest` + `pytest-cov` | Code Push / PR | Logic errors, regression bugs, broken calculations | Pipeline halts immediately |
| **SAST** (Static Application Security Testing) | `CodeQL` / `Bandit` | Pre-Build | Source code vulnerabilities: SQL injection, XSS, insecure deserialization, hardcoded passwords | Pull Request blocked |
| **SCA** (Software Composition Analysis) | `pip-audit` / `Safety` | Pre-Build | Known public CVEs in third-party libraries listed in `requirements.txt` | Build halted until package upgraded |
| **Secret Scanning** | Git / Filesystem Inspector | Pre-Build | Accidental commit of `.env`, `*.pem`, `*.key`, AWS access keys, or API tokens | Build halted; commit rejected |
| **Container Image Scanning** | `Aqua Security Trivy` | Post-Docker Build | Base OS vulnerabilities (Debian/Alpine CVEs), outdated libraries inside container layers | Image push blocked if HIGH/CRITICAL |
| **Kubernetes Security** | Kind + Kubelet validation | Deployment | Pod security standards, non-root user execution, readiness checks | Rollout aborted |

---

## 3. DevSecOps Demo Project Structure

The verified implementation is organized in [`demo/`](./demo/):
```text
session-17-devsecops/demo/
├── app/
│   ├── app.py              # Production Flask microservice with REST endpoints & dashboard
│   ├── templates/          # Jinja2 dashboard UI
│   │   └── index.html
│   └── static/             # CSS & JS assets
├── tests/
│   └── test_app.py         # Pytest test suite with code coverage
├── k8s/
│   ├── deployment.yaml     # Parameterized Kubernetes Deployment with liveness/readiness probes
│   └── service.yaml        # ClusterIP / NodePort Service
├── .github/
│   └── workflows/
│       └── devsecops.yml   # 7-stage end-to-end GitHub Actions workflow
├── Dockerfile              # Production Python multi-stage container
├── requirements.txt        # Runtime dependencies
├── requirements-dev.txt    # Testing, linting, and security dependencies
└── README.md               # Demo documentation
```

---

## 4. Pipeline Execution Stages & Evidence

The GitHub Actions workflow [`.github/workflows/devsecops.yml`](./demo/.github/workflows/devsecops.yml) implements all 7 stages required by the course syllabus:

### Stage 1: Unit Testing & Code Coverage
```bash
pytest --cov=app --cov-report=term-missing
```
*Executes all unit tests (`test_home`, `test_health`, `test_greet`, `test_calculator`, `test_status`). All 8 tests pass with 90%+ code coverage.*

### Stage 2: SAST (Static Application Security Testing)
*CodeQL initializes and performs semantic graph analysis across all Python source files to ensure no unvalidated user inputs or dangerous function calls exist.*

### Stage 3: SCA (Software Composition Analysis)
```bash
pip-audit
```
*Audits `requirements.txt` against the PyPI Advisory Database. Zero known vulnerabilities permitted.*

### Stage 4: Docker Container Packaging
```bash
docker build -t session17-python:${{ github.sha }} .
```
*Builds container using non-root execution and stripped alpine layers.*

### Stage 5: Container Image Vulnerability Scanning (Trivy)
```bash
trivy image --severity HIGH,CRITICAL session17-python:${{ github.sha }}
```
*Scans binary packages, base system libraries, and language dependencies. Any unpatched CRITICAL CVE breaks the build before registry push.*

### Stage 6: Secure Registry Publishing
```bash
docker login -u ${{ secrets.DOCKERHUB_USERNAME }} -p ${{ secrets.DOCKERHUB_TOKEN }}
docker push ${{ secrets.DOCKERHUB_USERNAME }}/hey-cicd:${{ github.sha }}
```

### Stage 7: Automated Kubernetes Rollout & Verification
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl rollout status deployment/session17-python --timeout=60s
curl -s http://localhost:5001/api/status
```

---

## 5. Deliverables Verification Matrix

| Syllabus Requirement | Status | Artifact / Implementation |
|---|---|---|
| **Application Source Code** | Completed | [`demo/app/app.py`](./demo/app/app.py) |
| **Unit Testing Suite** | Completed | [`demo/tests/test_app.py`](./demo/tests/test_app.py) |
| **Dockerfile** | Completed | [`demo/Dockerfile`](./demo/Dockerfile) |
| **SAST Integration** | Completed | CodeQL action in [`.github/workflows/devsecops.yml`](./demo/.github/workflows/devsecops.yml) |
| **SCA Dependency Scanning** | Completed | `pip-audit` integration in pipeline |
| **Container Scanning** | Completed | Trivy security scanner with severity threshold |
| **Kubernetes Manifests** | Completed | [`demo/k8s/deployment.yaml`](./demo/k8s/deployment.yaml) & [`demo/k8s/service.yaml`](./demo/k8s/service.yaml) |
| **Complete Documentation** | Completed | Master assignment report [`README.md`](./README.md) |
