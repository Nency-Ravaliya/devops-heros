# Session 17 — DevSecOps

**Name:** Viraj Bhanage
**Roll number:** 24BCS10274

My pipeline order is tests, frontend build, Docker build, Trivy, push, then Helm only when a kubeconfig secret is present.

SAST reads the source. SCA reads dependencies. Secret scanning reads the git tree. Image scanning reads the built image. The gate in `.github/workflows/taskboard-ci.yml` fails the job on HIGH or CRITICAL findings, so that image is not pushed.

`demo/.github/workflows/devsecops.yml` also shows CodeQL and pip-audit. GitHub ignores it because it is not in the repository root. The root TaskBoard workflow is the one that runs.
