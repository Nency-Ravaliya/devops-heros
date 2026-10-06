# Session 21 — TaskBoard

**Name:** Viraj Bhanage
**Roll number:** 24BCS10274

This directory is the capstone: React, FastAPI, PostgreSQL, Compose, Terraform for VPC and EKS, Helm, and the broken manifests in `troubleshooting/`.

GitHub runs `.github/workflows/taskboard-ci.yml` at the repository root. A workflow stored only inside this folder does not run.

`troubleshooting/broken-image.yaml` uses an image tag that does not exist, so the Pod stays in `ImagePullBackOff`. `troubleshooting/broken-service.yaml` selects a label no Pod has, so the Service has no endpoints.

I still need my own screenshots of the UI, `pytest -v`, the Actions run, and any Terraform apply. I will not submit someone else's pictures. If I apply the EKS stack, I destroy it the same day.
