# GitHub Actions Introduction

```yaml
# .github/workflows/hello.yml
name: Hello World

on: push

jobs:
  say-hello:
    runs-on: ubuntu-latest
    steps:
      - name: Print message
        run: echo "Hello from GitHub Actions"
```

Push this file. GitHub runs it automatically.

---

## 1. What is GitHub Actions?

GitHub Actions is a built-in automation platform inside GitHub.

```text
Without GitHub Actions:
  Jenkins server (you maintain it)
  CircleCI (external service)
  GitLab CI (separate platform)

With GitHub Actions:
  YAML file in .github/workflows/
  GitHub runs it
  No server to maintain
```

---

## 2. How It Works

```text
1. You create a YAML file in .github/workflows/
2. You push code to GitHub
3. GitHub detects the trigger
4. GitHub finds a runner machine
5. Runner clones the repository
6. Runner executes each step
7. GitHub shows you the result
```

---

## 3. Your First Workflow

Create the directory:

```bash
mkdir -p .github/workflows
```

Create the file `.github/workflows/hello.yml`:

```yaml
name: Hello World

on: push

jobs:
  say-hello:
    runs-on: ubuntu-latest
    steps:
      - name: Print message
        run: echo "Hello from GitHub Actions"
```

Push it:

```bash
git add .github/
git commit -m "Add hello world workflow"
git push
```

---

## 4. View the Run

Go to your GitHub repository.

Click the **Actions** tab.

You should see your workflow run. Click on it to view the logs.

Expected output in the step:

```text
Hello from GitHub Actions
```

---

## 5. Workflow File Location

```text
Repository root
    │
    └── .github/
            │
            └── workflows/
                    │
                    ├── build.yml
                    ├── test.yml
                    └── deploy.yml
```

GitHub reads all `.yml` files inside `.github/workflows/`.

---

## 6. Components at a Glance

```text
name:    = display name of the workflow
on:      = what triggers this workflow
jobs:    = list of jobs to run
  job-id:
    runs-on:  = which runner to use
    steps:    = list of steps
      - name: = display name of step
        run:  = shell command to run
```

---

## Key Learning

```text
GitHub Actions = automation built into GitHub
Workflow       = YAML file in .github/workflows/
Trigger        = on: push, pull_request, schedule
Job            = group of steps on one runner
Step           = single command or action
```

---

## Reference

* **GitHub Actions quickstart:** https://docs.github.com/en/actions/quickstart
* **GitHub Actions marketplace:** https://github.com/marketplace?type=actions
