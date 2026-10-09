# Session 17: Complete CI/CD & DevSecOps

This session demonstrates a complete, automated **CI/CD + DevSecOps Pipeline** using GitHub Actions, Trivy, Gitleaks, Semgrep, and Kubernetes.

---

## 1. End-to-End DevSecOps Pipeline Flow

```text
       [ Developer Code Commit ]
                   │
                   ▼
         [ 1. Build & Lint ]
                   │
                   ▼
         [ 2. Unit Testing ]
                   │
                   ▼
     [ 3. SAST (Static Analysis) ] (Semgrep / SonarQube)
                   │
                   ▼
    [ 4. SCA (Dependency Scan) ] (npm audit / pip-audit / Snyk)
                   │
                   ▼
    [ 5. Secret Scanning ] (Gitleaks / TruffleHog)
                   │
                   ▼
        [ 6. Docker Image Build ]
                   │
                   ▼
 [ 7. Container Image Scan ] (Trivy / Grype)
                   │
                   ▼
      [ 8. Security Quality Gate ] (Fail if Severity == CRITICAL)
                   │
                   ▼
  [ 9. Push to Container Registry ] (GitHub Packages / Docker Hub)
                   │
                   ▼
[ 10. Continuous Deployment ] (Kubernetes Cluster via kubectl/ArgoCD)
```

---

## 2. DevSecOps Tooling Breakdown

| Security Stage | Tool Used | Purpose | Pass / Fail Criteria |
|---|---|---|---|
| **Secret Scanning** | **Gitleaks** | Detects hardcoded API keys, JWTs, and AWS secrets | Fails if any valid secret found |
| **SAST** | **Semgrep** | Analyzes application source code for CWE flaws | Fails on High/Critical code vulnerabilities |
| **SCA** | **Pip-Audit / Snyk** | Audits open-source dependencies in `requirements.txt` | Fails on Known Vulnerable Packages |
| **Container Scan** | **Trivy** | Scans OS layers & installed packages inside container | Fails on `CRITICAL` CVEs |
| **Security Gate** | **GitHub Actions Step** | Enforces build-break threshold before deployment | Blocks deployment on policy breach |

---

## 3. Demo Application & GitHub Actions Workflow

The reference application is a microservices dashboard located in [`demo/`](file:///home/akshanshsinha/DevOps/devops-heros/session-17-devsecops/demo):
* **Source Application:** [demo/app/app.py](file:///home/akshanshsinha/DevOps/devops-heros/session-17-devsecops/demo/app/app.py)
* **Dockerfile:** [demo/Dockerfile](file:///home/akshanshsinha/DevOps/devops-heros/session-17-devsecops/demo/Dockerfile)
* **GitHub Actions Workflow:** [demo/.github/workflows/devsecops.yml](file:///home/akshanshsinha/DevOps/devops-heros/session-17-devsecops/demo/.github/workflows/devsecops.yml)
* **Kubernetes Manifests:** [demo/k8s/](file:///home/akshanshsinha/DevOps/devops-heros/session-17-devsecops/demo/k8s)

---

## 4. Pipeline Execution & Verification Commands

```bash
# 1. Run local secret scanning with Gitleaks
gitleaks detect --source . --verbose

# 2. Run local SAST with Semgrep
semgrep scan --config auto demo/

# 3. Build Docker container image locally
docker build -t devsecops-demo:v1 demo/

# 4. Scan image with Trivy (failing on CRITICAL vulnerabilities)
trivy image --severity CRITICAL --exit-code 1 devsecops-demo:v1

# 5. Apply deployment to Kubernetes
kubectl apply -f demo/k8s/
```

---

## 5. Deliverables & Screenshot Evidence

* **Screenshot 1: Successful GitHub Actions Pipeline Run**  
  <!-- Add screenshot: ![Pipeline Execution](screenshots/pipeline-run.png) -->

* **Screenshot 2: Trivy Security Scan Output**  
  <!-- Add screenshot: ![Trivy Scan](screenshots/trivy-scan.png) -->

* **Screenshot 3: Kubernetes Deployment Status (`kubectl get pods,svc`)**  
  <!-- Add screenshot: ![K8s Deployment](screenshots/k8s-deployment.png) -->
