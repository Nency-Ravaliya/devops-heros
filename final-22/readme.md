# Session 21 — DevOps Final Capstone: TaskBoard

## Student Details

**Name:** Ankita Tripathi  
**Roll Number:** 24BCS10062  

---

## Project Overview

TaskBoard is a full-stack task management application used as the DevOps Final Capstone project.

The purpose of this project is to demonstrate an end-to-end DevOps workflow covering:

- Full-stack application deployment
- Backend API development
- Frontend development
- PostgreSQL database integration
- Automated testing
- Docker containerization
- Docker Compose
- Git and GitHub
- CI/CD using GitHub Actions
- Container image security scanning using Trivy
- GitHub Container Registry (GHCR)
- Kubernetes
- Helm
- Infrastructure as Code using Terraform
- AWS VPC and EKS configuration
- Health checks and monitoring concepts
- Troubleshooting and security remediation

The project follows a multi-tier architecture:

```text
                User
                  |
                  v
          +----------------+
          | React Frontend |
          |     Nginx      |
          +----------------+
                  |
                  v
          +----------------+
          | FastAPI Backend|
          +----------------+
                  |
                  v
          +----------------+
          |   PostgreSQL   |
          +----------------+
```

---

# 1. Technology Stack

## Frontend

- React
- Vite
- JavaScript
- Nginx
- Docker

## Backend

- Python
- FastAPI
- SQLAlchemy
- Pydantic
- Alembic
- Uvicorn
- Pytest

## Database

- PostgreSQL

## DevOps Tools

- Git
- GitHub
- Docker
- Docker Compose
- GitHub Actions
- Trivy
- GitHub Container Registry
- Kubernetes
- Helm
- Terraform
- AWS EKS
- AWS VPC
- Prometheus/Grafana configuration

---

# 2. Project Structure

```text
.
├── .github/
│   └── workflows/
│       └── ci-cd.yml
│
├── backend/
│   ├── app/
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt
│
├── frontend/
│   ├── src/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
│
├── helm/
│   └── taskboard/
│
├── k8s/
│
├── monitoring/
│
├── scripts/
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── README.md
│
├── troubleshooting/
├── docker-compose.yml
├── GRADING.md
├── README.md
└── STUDENT-GUIDE.md
```

---

# 3. Local Application Setup

The project was first tested locally using Docker and Docker Compose.

The containers were built and started using:

```bash
docker compose up --build
```

The application consists of three major services:

```text
Frontend
Backend
PostgreSQL
```

During the initial deployment, issues were identified between the frontend Nginx configuration and the backend Docker Compose service.

---

# 4. Frontend Nginx Configuration Fix

The original Nginx configuration attempted to communicate with:

```text
taskboard-backend:8000
```

However, the Docker Compose service was named:

```text
backend
```

This resulted in an Nginx upstream resolution error.

The configuration was corrected so that Nginx communicates with:

```text
backend:8000
```

This allowed the frontend container to communicate correctly with the backend service over the Docker Compose network.

---

# 5. Frontend Task Creation Fix

During application testing, a UI issue was discovered while creating a task.

The task was successfully sent to the backend, but the modal/form did not close correctly and could result in duplicate task creation.

The React task creation logic was corrected by storing the form reference before the asynchronous API call.

The corrected implementation follows the pattern:

```javascript
const create = async (e) => {
  e.preventDefault();

  const form = e.currentTarget;
  const f = new FormData(form);

  await fetch(`${API}/tasks`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      title: f.get('title'),
      description: f.get('description'),
      priority: f.get('priority'),
      assignee: f.get('assignee'),
      status: 'TODO'
    })
  });

  form.reset();
  setShowForm(false);
  load();
};
```

After this correction:

- Tasks were created successfully.
- The form was reset.
- The modal closed correctly.
- The task list refreshed correctly.

---

# 6. Database Testing and Cleanup

PostgreSQL was used as the primary application database.

During testing, duplicate test records were removed using:

```bash
docker compose exec postgres \
psql -U taskboard -d taskboard \
-c "TRUNCATE TABLE tasks RESTART IDENTITY CASCADE;"
```

This cleared the task table and reset its identity sequence.

A clean task was then created to verify normal application functionality.

---

# 7. Backend Testing

Automated backend testing was implemented using Pytest and FastAPI's test client.

The test environment uses SQLite so that API tests can run independently without requiring the PostgreSQL container.

The test configuration includes:

```python
import os

os.environ["DATABASE_URL"] = "sqlite:///./test.db"

from fastapi.testclient import TestClient
from app.main import app
from app.db import Base, engine

Base.metadata.create_all(bind=engine)

client = TestClient(app)
```

Tests were implemented for:

### Health Endpoint

```python
def test_health():
    assert client.get("/health").json() == {"status": "UP"}
```

### Root Endpoint

```python
def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["service"] == "TaskBoard API"
```

### Task Creation API

```python
def test_create_task_validation():
    response = client.post(
        "/api/tasks",
        json={
            "title": "Deploy application",
            "priority": "HIGH",
            "assignee": "Student"
        },
    )

    assert response.status_code == 201
    assert response.json()["title"] == "Deploy application"
```

---

# 8. Python Virtual Environment

A dedicated Python virtual environment was created for the project.

It was activated using:

```bash
source ../.venv/bin/activate
```

Dependencies were installed using:

```bash
pip install -r backend/requirements.txt
```

The environment was verified using:

```bash
which python
which pip
```

Pytest was executed using:

```bash
python -m pytest -v
```

This was used instead of directly running `pytest` because the system's Pyenv shim was resolving to a different Pytest installation.

Final test result:

```text
collected 3 items

tests/test_api.py::test_health PASSED
tests/test_api.py::test_root PASSED
tests/test_api.py::test_create_task_validation PASSED

3 passed
```

---

# 9. Git and GitHub

A dedicated Git repository was initialized for the capstone project.

Repository:

```text
session21-devops-capstone
```

The project was committed and pushed to GitHub.

A `.gitignore` file was configured to exclude unnecessary/generated files such as:

```text
Python cache
Virtual environments
Node modules
Build output
Environment files
Logs
Terraform state
Test database
macOS metadata
Coverage files
Secrets
```

Git was used throughout the project to track fixes and trigger the CI/CD pipeline.

---

# 10. CI/CD Pipeline

GitHub Actions was configured in:

```text
.github/workflows/ci-cd.yml
```

The pipeline is triggered on:

```yaml
push:
  branches: [main]

pull_request:
  branches: [main]
```

The pipeline contains three major jobs:

```text
test
   |
   v
build-scan-push
   |
   v
deploy
```

---

# 11. CI — Automated Testing

The `test` job performs:

### Backend

```text
Checkout repository
        ↓
Configure Python
        ↓
Install dependencies
        ↓
Run Pytest
```

### Frontend

```text
Configure Node.js
        ↓
npm install
        ↓
npm run build
```

The backend tests and frontend build completed successfully in GitHub Actions.

---

# 12. Docker Image Build

After testing succeeds, the CI/CD pipeline builds two Docker images.

Backend:

```bash
docker build \
-t ghcr.io/${{ github.repository_owner }}/taskboard-backend:${{ github.sha }} \
./backend
```

Frontend:

```bash
docker build \
-t ghcr.io/${{ github.repository_owner }}/taskboard-frontend:${{ github.sha }} \
./frontend
```

The Git commit SHA is used as the image tag.

This provides traceability between:

```text
Git Commit
    ↓
Docker Image
    ↓
Deployment
```

---

# 13. Container Security Scanning

Trivy was integrated into the CI/CD pipeline to scan Docker images for security vulnerabilities.

The pipeline scans for:

```text
HIGH
CRITICAL
```

vulnerabilities.

Configuration:

```yaml
severity: HIGH,CRITICAL
ignore-unfixed: true
exit-code: '1'
```

The pipeline intentionally fails if a fixable HIGH or CRITICAL vulnerability is found.

This security check was kept enabled rather than bypassing security failures.

---

# 14. Backend Security Vulnerability Remediation

The initial backend container security scan identified vulnerabilities related to the Starlette version used by FastAPI.

The dependency stack was upgraded.

Relevant final dependencies include:

```text
fastapi==0.142.3
starlette==1.7.0
prometheus-fastapi-instrumentator==8.1.0
```

The monitoring dependency also had to be upgraded because the previous version required:

```text
starlette < 1.0.0
```

which conflicted with the patched Starlette version.

After updating the dependencies, the backend image was rebuilt.

Versions were verified inside the container:

```text
FastAPI: 0.142.3
Starlette: 1.7.0
```

The backend Trivy scan subsequently passed successfully.

---

# 15. Frontend Security Vulnerability Remediation

The original frontend runtime image used:

```dockerfile
FROM nginx:1.27-alpine
```

Trivy detected multiple HIGH and CRITICAL vulnerabilities in the operating-system packages included in the image.

The runtime image was upgraded to:

```dockerfile
FROM nginx:1.29-alpine
```

The rebuilt image was verified as:

```text
nginx version: nginx/1.29.8
Alpine: 3.23.4
```

A subsequent Trivy scan still detected HIGH vulnerabilities because some packages in the base image had newer patched versions available.

Instead of disabling Trivy, the Docker image was configured to install the available security upgrades.

The final runtime configuration includes:

```dockerfile
FROM nginx:1.29-alpine
RUN apk upgrade --no-cache
```

---

# 16. Verification of Patched Packages

After rebuilding the frontend image, the installed package versions were checked.

The patched image contained:

```text
c-ares-1.34.8-r0
curl-8.22.0-r0
libcrypto3-3.5.9-r0
libcurl-8.22.0-r0
libexpat-2.8.5-r0
libssl3-3.5.9-r0
libuuid-2.41.6-r1
libxml2-2.13.9-r1
nghttp2-libs-1.69.0-r0
pcre2-10.49-r0
```

The Docker image was rebuilt using:

```bash
docker build --no-cache -t taskboard-frontend ./frontend
```

The package upgrade step completed successfully:

```text
RUN apk upgrade --no-cache
```

After this security remediation, the frontend Trivy security scan passed in GitHub Actions.

---

# 17. GitHub Container Registry

After both Trivy scans succeed, the CI/CD pipeline pushes the images to GitHub Container Registry.

The images follow the naming convention:

```text
ghcr.io/<repository-owner>/taskboard-backend:<git-sha>

ghcr.io/<repository-owner>/taskboard-frontend:<git-sha>
```

Authentication is performed using:

```yaml
registry: ghcr.io
username: ${{ github.actor }}
password: ${{ secrets.GITHUB_TOKEN }}
```

The `build-scan-push` stage successfully completed.

Therefore, the pipeline successfully demonstrated:

```text
Source Code
    ↓
Automated Tests
    ↓
Docker Build
    ↓
Trivy Security Scan
    ↓
GHCR Push
```

---

# 18. Kubernetes

Kubernetes configuration is included as part of the project.

The local Kubernetes environment was checked using:

```bash
kubectl config current-context
```

Result:

```text
docker-desktop
```

Cluster information was verified using:

```bash
kubectl cluster-info
```

The local Kubernetes API was running through Docker Desktop.

This environment is suitable for local Kubernetes testing.

---

# 19. Helm

Helm is used to package and deploy the application to Kubernetes.

The GitHub Actions deployment command is:

```bash
helm upgrade --install taskboard ./helm/taskboard \
  -n taskboard \
  --create-namespace \
  --set backend.tag=${{ github.sha }} \
  --set frontend.tag=${{ github.sha }} \
  --set backend.image=ghcr.io/${{ github.repository_owner }}/taskboard-backend \
  --set frontend.image=ghcr.io/${{ github.repository_owner }}/taskboard-frontend
```

This supports both:

```text
Initial installation
        +
Application upgrades
```

using a single Helm command.

---

# 20. Kubernetes Deployment Troubleshooting

After the build, scan, and push stages passed, the GitHub Actions `deploy` job was reached.

The deployment failed with:

```text
Kubernetes cluster unreachable

Get "http://localhost:8080/version":
dial tcp [::1]:8080: connect: connection refused
```

The deployment job expected the GitHub repository secret:

```text
KUBE_CONFIG_DATA
```

and attempted to create the runner's kubeconfig using:

```bash
mkdir -p ~/.kube
echo "$KUBE_CONFIG_DATA" | base64 -d > ~/.kube/config
```

Investigation showed that the currently configured Kubernetes context on the development machine was:

```text
docker-desktop
```

with an API endpoint on:

```text
127.0.0.1
```

A GitHub-hosted runner cannot access the Docker Desktop Kubernetes cluster running locally on the developer's Mac.

Therefore, the CI deployment requires a remotely accessible Kubernetes cluster such as AWS EKS.

This demonstrates an important distinction between:

```text
Local Kubernetes Cluster
        vs
Remote CI/CD Deployment Cluster
```

---

# 21. Terraform Infrastructure as Code

Terraform configuration is provided for creating the AWS infrastructure required for remote deployment.

The Terraform project contains:

```text
terraform/
├── README.md
├── main.tf
├── outputs.tf
├── variables.tf
└── versions.tf
```

The configuration defines:

### AWS Region

```text
ap-south-1
```

### VPC

```text
Name: taskboard-vpc
CIDR: 10.20.0.0/16
```

### Availability Zones

```text
ap-south-1a
ap-south-1b
```

### Private Subnets

```text
10.20.1.0/24
10.20.2.0/24
```

### Public Subnets

```text
10.20.101.0/24
10.20.102.0/24
```

The VPC configuration also includes a NAT Gateway.

---

# 22. AWS EKS Configuration

Terraform defines an Amazon EKS cluster with:

```text
Cluster name: taskboard-eks
Kubernetes version: 1.31
Public cluster endpoint: Enabled
```

The managed node group is configured with:

```text
Instance type: t3.medium
Minimum nodes: 2
Desired nodes: 2
Maximum nodes: 4
```

Terraform outputs are configured for:

```text
cluster_name
cluster_endpoint
vpc_id
```

---

# 23. AWS Authentication Verification

Before provisioning infrastructure, AWS authentication was checked using:

```bash
aws sts get-caller-identity
```

The configured AWS credentials were found to be invalid:

```text
InvalidClientTokenId
The security token included in the request is invalid.
```

The AWS CLI configuration was inspected using:

```bash
aws configure list
```

and:

```bash
aws configure list-profiles
```

Only the `default` profile was configured.

The invalid credentials were removed/revoked for security.

---

# 24. AWS Cost Safety

The supplied Terraform configuration creates resources that can incur AWS charges, including:

```text
Amazon EKS
EC2 t3.medium worker nodes
NAT Gateway
Networking resources
```

For this reason, `terraform apply` was not executed blindly while AWS authentication and account billing availability were unresolved.

The infrastructure configuration was reviewed before provisioning to avoid accidental cloud charges.

The Terraform configuration remains available for deployment when valid AWS credentials and the appropriate AWS environment are available.

---

# 25. CI/CD Final Status

The final verified CI/CD status was:

```text
Test                 PASSED
Build Images          PASSED
Backend Trivy Scan    PASSED
Frontend Trivy Scan   PASSED
Push Images to GHCR   PASSED
Deploy                REQUIRES REMOTE KUBERNETES/EKS
```

This confirms successful implementation of the continuous integration, container build, security scanning, and container publishing portions of the pipeline.

---

# 26. Health Checks

The backend exposes a health endpoint:

```text
/health
```

Expected response:

```json
{
  "status": "UP"
}
```

This endpoint is also covered by automated testing.

Health endpoints are important in Kubernetes environments for determining whether an application is healthy and ready to serve requests.

---

# 27. Monitoring

The project includes monitoring-related configuration for:

```text
Prometheus
Grafana
```

The backend uses:

```text
prometheus-fastapi-instrumentator
```

for FastAPI metrics integration.

The dependency was upgraded to:

```text
prometheus-fastapi-instrumentator==8.1.0
```

during security dependency remediation.

The monitoring configuration provides the foundation for observing application and infrastructure behavior in the Kubernetes environment.

---

# 28. Important Troubleshooting Performed

Several real-world DevOps issues were identified and resolved during this project.

### Nginx Upstream Resolution

**Problem**

```text
host not found in upstream "taskboard-backend"
```

**Cause**

Nginx referenced a hostname that did not match the Docker Compose backend service name.

**Solution**

Changed the upstream target to:

```text
backend:8000
```

---

### Frontend Task Form Issue

**Problem**

Task creation succeeded but the UI form/modal did not behave correctly.

**Solution**

Stored the form reference before the asynchronous API request and reset/closed it after successful creation.

---

### Pytest Database Issue

**Problem**

Tests attempted to use a database without the required table.

**Solution**

Configured SQLite for tests and created SQLAlchemy metadata before running API tests.

---

### Incorrect Pytest Executable

**Problem**

Running:

```bash
pytest
```

resolved to a Pyenv shim outside the project environment.

**Solution**

Used:

```bash
python -m pytest -v
```

which guarantees that Pytest runs using the active Python environment.

---

### Backend Trivy Failure

**Problem**

HIGH vulnerabilities were detected in the Starlette dependency.

**Solution**

Updated:

```text
FastAPI
Starlette
Prometheus FastAPI Instrumentator
```

to compatible patched versions.

---

### Frontend Trivy Failure

**Problem**

The old nginx/Alpine image contained multiple HIGH and CRITICAL operating-system vulnerabilities.

**Solution**

Updated:

```dockerfile
FROM nginx:1.29-alpine
RUN apk upgrade --no-cache
```

and verified the patched package versions.

---

### Temporary Alpine Repository DNS Failure

During a Docker build, the Alpine repository temporarily returned:

```text
DNS: transient error (try again later)
```

The build was retried after the temporary network failure and completed successfully.

No security checks were bypassed.

---

### GitHub Actions Kubernetes Failure

**Problem**

```text
Kubernetes cluster unreachable
localhost:8080
```

**Cause**

GitHub Actions did not have access to a remote Kubernetes cluster. The local Docker Desktop Kubernetes API is only accessible from the development machine.

**Required production solution**

Provision/configure a remote cluster such as AWS EKS and securely authenticate GitHub Actions to that cluster.

---

# 29. Security Practices Followed

Security was treated as part of the CI/CD process rather than an optional step.

Practices demonstrated include:

- Trivy container scanning
- HIGH/CRITICAL vulnerability enforcement
- `ignore-unfixed` configuration
- Dependency upgrades
- Base-image upgrades
- Alpine security package upgrades
- GitHub Secrets for sensitive CI/CD configuration
- GHCR authentication through `GITHUB_TOKEN`
- Avoiding secrets in source control
- Revoking invalid/exposed cloud credentials
- Verifying cloud authentication before provisioning
- Reviewing infrastructure before `terraform apply`

Most importantly, Trivy's:

```yaml
exit-code: '1'
```

was retained.

Security scanning was not disabled simply to make the pipeline pass.

---

# 30. DevOps Workflow Implemented

The overall workflow demonstrated by this project is:

```text
Developer
    |
    v
Git Repository
    |
    v
GitHub
    |
    v
GitHub Actions
    |
    +-------------------+
    |                   |
    v                   v
Backend Tests      Frontend Build
    |                   |
    +---------+---------+
              |
              v
        Docker Build
              |
              v
        Trivy Scanning
              |
              v
             GHCR
              |
              v
        Helm Deployment
              |
              v
          Kubernetes
              |
              v
      AWS EKS (configured
      through Terraform)
```

---

# 31. Screenshots

Screenshots of the practical implementation, terminal commands, Docker builds, application output, GitHub Actions workflow, security scans, and other required evidence have been captured and are provided **separately with the submission**.

Screenshots are intentionally not embedded in this README to keep the documentation clean and readable.

---

# 32. Key Learning Outcomes

Through this capstone project, I gained practical experience with:

- Building a full-stack application environment
- Connecting frontend, backend, and database services
- Writing and running automated API tests
- Dockerizing frontend and backend applications
- Using Docker Compose for multi-container applications
- Debugging Docker networking problems
- Using Git and GitHub for version control
- Building CI/CD pipelines with GitHub Actions
- Scanning Docker images with Trivy
- Understanding and remediating CVEs
- Publishing container images to GHCR
- Understanding Kubernetes cluster contexts
- Packaging Kubernetes applications with Helm
- Understanding local vs remote Kubernetes deployment
- Writing Infrastructure as Code using Terraform
- Understanding AWS VPC and EKS architecture
- Debugging cloud authentication
- Applying security practices throughout a DevOps workflow
- Understanding monitoring using Prometheus and Grafana

---

# 33. Conclusion

The TaskBoard DevOps Final Capstone demonstrates an end-to-end DevOps workflow around a full-stack application.

The application was successfully tested and containerized locally. Automated backend tests and frontend builds were integrated into GitHub Actions. Docker images were built and scanned using Trivy, and security vulnerabilities discovered during the pipeline were remediated rather than ignored.

After remediation, the CI pipeline successfully completed testing, Docker image creation, backend security scanning, frontend security scanning, and publishing images to GitHub Container Registry.

Kubernetes and Helm deployment configuration is included in the project. Terraform configuration is also provided for creating an AWS VPC and EKS environment. The final cloud deployment requires a valid remote AWS/EKS environment and was intentionally not falsely reported as successful when only the local Docker Desktop Kubernetes cluster was available.

Overall, the project demonstrates practical understanding of the complete DevOps lifecycle:

```text
Code
  ↓
Test
  ↓
Build
  ↓
Containerize
  ↓
Security Scan
  ↓
Publish
  ↓
Infrastructure
  ↓
Deploy
  ↓
Monitor
```

---
## Project Links

**GitHub Repository:**  
https://github.com/vvsleepy/session21-devops-capstone

**GitHub Actions CI/CD Workflow:**  
https://github.com/vvsleepy/session21-devops-capstone/actions

**Submitted By:** Ankita Tripathi  
**Roll Number:** 24BCS10062