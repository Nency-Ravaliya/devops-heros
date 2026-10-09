# Workflows

```yaml
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
```

The `on:` block controls exactly when your workflow runs.

---

## 1. What is a Workflow?

A workflow is a single YAML file in `.github/workflows/`.

One repository can have many workflows:

```text
.github/workflows/
    build.yml      = runs on every push
    deploy.yml     = runs when a release is created
    nightly.yml    = runs every night at midnight
```

Each workflow runs independently.

---

## 2. Workflow Triggers

**Push trigger:**

```yaml
on:
  push:
    branches:
      - main
      - develop
```

Runs when code is pushed to `main` or `develop`.

**Pull request trigger:**

```yaml
on:
  pull_request:
    branches:
      - main
```

Runs when a PR targets `main`.

**Schedule trigger:**

```yaml
on:
  schedule:
    - cron: '0 0 * * *'
```

Runs every day at midnight UTC.

**Manual trigger:**

```yaml
on:
  workflow_dispatch:
```

Adds a button in the GitHub Actions UI to run the workflow manually.

**Multiple triggers:**

```yaml
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
  workflow_dispatch:
```

---

## 3. Full Workflow Example

`.github/workflows/build.yml`:

```yaml
name: Build and Test

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Run tests
        run: pytest
```

---

## 4. Trigger Filter by Path

Run only when specific files change:

```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'tests/**'
```

This avoids running the pipeline when only documentation changes.

---

## 5. Environment Variables in Workflows

```yaml
env:
  APP_NAME: notes-app
  PYTHON_VERSION: '3.11'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Print app name
        run: echo "$APP_NAME"
```

---

## 6. Workflow Run Naming

```yaml
name: CI Pipeline
run-name: "Build ${{ github.ref_name }} by ${{ github.actor }}"
```

This makes runs easy to identify in the Actions tab.

---

## Key Learning

```text
on: push              = trigger on push
on: pull_request      = trigger on PR
on: schedule          = trigger on cron
on: workflow_dispatch = manual trigger
paths:                = only trigger when specific files change
```

---

## Reference

* **Workflow syntax:** https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
* **Triggering workflows:** https://docs.github.com/en/actions/using-workflows/triggering-a-workflow
