# Session 16: CI/CD and GitHub Actions

Manually building, testing, and deploying code after every change breaks teams.

GitHub Actions solves this. It automates everything from code commit to production deployment.

---

## Why CI/CD?

Without CI/CD, deploying means: build locally, test manually, upload manually, deploy manually.

With CI/CD, every push to Git triggers automated build, test, and deploy.

---

## Topics Covered

| Folder | Topic |
|--------|-------|
| `01-ci-vs-cd/` | What is CI, what is CD, where they differ |
| `02-pipeline-concepts/` | Stages, steps, jobs, and how they connect |
| `03-github-actions-intro/` | What GitHub Actions is, how it works |
| `04-workflows/` | Workflow YAML syntax, triggers, on: push |
| `05-jobs-steps/` | Jobs, steps, uses, run, needs |
| `06-runners/` | GitHub-hosted runners, self-hosted runners |
| `07-secrets/` | Storing credentials, using secrets in workflows |
| `08-artifacts/` | Uploading and downloading build artifacts |
| `09-build-test-pipeline/` | Full CI pipeline: checkout, build, test, lint |
| `mini-project/` | Build a complete CI pipeline for a Python app |

---

## Core Concepts

**CI (Continuous Integration):** Every code push triggers automatic build and test.

**CD (Continuous Delivery):** After tests pass, the app is automatically deployable.

**CD (Continuous Deployment):** After tests pass, the app is automatically deployed to production.

**Workflow:** A YAML file in `.github/workflows/` that defines automation.

**Job:** A group of steps that runs on one runner machine.

**Step:** A single command or action within a job.

**Runner:** A machine (virtual or physical) that executes jobs.

---

## Key Commands

```bash
# Check workflow syntax locally
act --list

# Trigger a workflow via GitHub CLI
gh workflow run build.yml

# View workflow runs
gh run list

# View a specific run's logs
gh run view <run-id> --log

# List all workflows in the repo
gh workflow list
```

---

## Workflow Triggers

```text
push           = runs on every push
pull_request   = runs when a PR is opened or updated
schedule       = runs on a cron schedule
workflow_dispatch = manual trigger from GitHub UI
release        = runs when a release is created
```

---

## Interview Preparation

**Beginner:**

Q: What is the difference between CI and CD?
A: CI is Continuous Integration, where every code push triggers automated build and test. CD is either Continuous Delivery (code is always deployable) or Continuous Deployment (code is automatically pushed to production after tests pass).

Q: What is a GitHub Actions workflow?
A: A workflow is a YAML file stored in `.github/workflows/`. It defines automated processes triggered by events like push or pull_request. Each workflow contains one or more jobs, and each job contains steps.

**Intermediate:**

Q: What is the difference between `uses` and `run` in a step?
A: `uses` calls a pre-built action from GitHub Marketplace or another repository (e.g., `actions/checkout@v4`). `run` executes shell commands directly on the runner (e.g., `run: npm test`).

Q: How do you pass secrets to a workflow?
A: Store the secret in GitHub repository Settings > Secrets and variables > Actions. Reference it in the workflow YAML using `${{ secrets.SECRET_NAME }}`. Secrets are masked in logs.

**Scenario-Based:**

Q: Your workflow runs for 45 minutes but only 5 minutes of that is actual work. How do you speed it up?
A: Use caching with `actions/cache` to cache dependencies (node_modules, pip packages, Maven repository). Split independent jobs and run them in parallel using `needs` correctly. Use matrix builds only when necessary.

---

## Reference

* **GitHub Actions Documentation:** https://docs.github.com/en/actions
* **GitHub Actions Marketplace:** https://github.com/marketplace?type=actions
* **Workflow syntax reference:** https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
