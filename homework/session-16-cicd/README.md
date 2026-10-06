# Session 16 — CI/CD and GitHub Actions

Student: Viraj Bhanage, roll 24BCS10274

## What the pipeline is

CI builds and tests every change. CD ships a build that passed CI. A workflow file is the pipeline. It has jobs. Jobs have steps. Jobs run on runners. Secrets are values the log must not print. Artifacts are files passed from one job to another or saved for download.

The course demo lives in `session-16-github-actions/session-16-github-actions/10-final-cicd-pipeline/`. GitHub only runs workflows stored at the repository root `.github/workflows/`, so this fork adds two root workflows:

- `.github/workflows/homework-ci.yml` builds the Session 6/7 images and validates the Terraform.
- `.github/workflows/taskboard-ci.yml` is the Session 21 pipeline: pytest, frontend build, Docker build, Trivy, push to GHCR, Helm deploy when `KUBE_CONFIG_DATA` exists.

## Screenshot

After this is pushed, open:

https://github.com/bhanage-viraj/devops-heros/actions

Screenshot the green **Homework CI** run. If **TaskBoard Python CI/CD** is red on the Trivy step, open the log, copy the CVE summary, and add two sentences on what Trivy scanned. The workflow is set to fail on unfixed HIGH or CRITICAL findings, which is the security gate from Session 17.
