# Security gates

The repository-root workflow `session21-capstone.yml` runs API tests, Bandit SAST, pip-audit and npm audit dependency checks, a Trivy secret scan, then Trivy scans of both built images. HIGH/CRITICAL container findings stop publication; frontend dependency findings at HIGH or above also fail the build. Python dependency findings fail pip-audit.

Images are tagged with the Git commit SHA and pushed to GHCR only after the gates pass. A passing scan means no matching findings in that scanner's current database, not proof that the application is vulnerability-free. The workflow has to run on GitHub before a successful result can be claimed.

The supplied database password is for the local classroom demo. Do not reuse it for cloud deployment. Terraform state, local environment files and credentials are excluded from Git.

## Local findings and repair

Bandit found no issues in the backend source. The first pip-audit run reported 16 advisory entries across the starter's pytest 8.3.4 and transitive Starlette 0.41.3 (some entries were duplicates). Dependencies were updated to pytest 9.0.3, FastAPI 0.142.2 and Starlette 1.3.1. The follow-up pip-audit reported no known vulnerabilities, Bandit reported no issues, and all 9 regression tests passed. The metrics instrumentator was also upgraded to 8.1.0 for compatibility with Starlette 1.x. Container-image Trivy results still require a scan run.
