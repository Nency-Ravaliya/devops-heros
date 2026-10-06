# Session 16 — GitHub Actions

**Name:** Viraj Bhanage
**Roll number:** 24BCS10274

GitHub runs only the workflows in `.github/workflows` at the root of the repo. The samples in this session folder do not run by themselves. On my fork the live files are:

- `.github/workflows/homework-ci.yml` builds the Hello World images and validates Terraform
- `.github/workflows/taskboard-ci.yml` runs pytest, builds images, scans them with Trivy, and pushes to GHCR

A workflow contains jobs, a job contains steps, and a runner executes the steps. Secrets must not be printed. Artifacts are files handed from one job to another.

https://github.com/bhanage-viraj/devops-heros/actions
