# Session 17: CI/CD and DevSecOps

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

The root workflow tests → Bandit SAST → pip-audit SCA → Trivy secret scan →
Docker build → HIGH/CRITICAL image scan → GHCR push → optional Kubernetes deployment.
Scan failures stop the job before publication. There is no continue-on-error.
Bandit B104 is documented because a container HTTP server intentionally binds
its container interface. This app uses only the standard library, so the
requirements audit has no third-party runtime dependencies; the image scan also
checks installed operating-system packages.

Run `python -m unittest -v`, `python app.py`, and curl `/health` locally.
Configure Actions, GHCR pull access, and environment KUBE_CONFIG as in Session 16.
Use Run workflow with deploy checked for the full pipeline against a reachable cluster.

The workflow also runs for relevant pushes to the combined submission branch.
GHCR publication and deployment are restricted to this student's fork. The
runtime uses Python Alpine, matching the capstone's smaller base-image approach.

On HIGH/CRITICAL findings, update the affected dependency or base image and rerun
the scans. A clean result means no matching findings in the scanner's database,
not proof of complete security. Pipeline scan output is pending. Local checks are in `evidence/`.

## Verification

Five HTTP endpoint tests passed; Docker build and HTTP check passed. The local Trivy secret scan found no issues.

SAST/SCA/image vulnerability scans, GitHub Actions, registry publication and cluster deployment are pending.

Command output: [evidence/](evidence/).
