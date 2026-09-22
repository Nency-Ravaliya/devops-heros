# Jobs and Steps

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Build
        run: make build
```

Jobs are groups of steps. Steps are individual actions.

---

## 1. What is a Job?

A job is a collection of steps that runs on one runner machine.

```text
Workflow
    │
    ├── job: build
    │       └── steps: checkout, install, compile
    │
    └── job: test
            └── steps: checkout, install, run-tests
```

By default, jobs run in **parallel**.

---

## 2. What is a Step?

A step is the smallest unit inside a job.

A step can be:

```text
run:   = executes a shell command
uses:  = calls a pre-built action
```

**run example:**

```yaml
- name: Install dependencies
  run: pip install -r requirements.txt
```

**uses example:**

```yaml
- name: Checkout code
  uses: actions/checkout@v4
```

---

## 3. Sequential Steps in a Job

Steps within a job run in order, one after another:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Step 1 - Checkout
        uses: actions/checkout@v4

      - name: Step 2 - Install
        run: pip install -r requirements.txt

      - name: Step 3 - Test
        run: pytest

      - name: Step 4 - Report
        run: echo "Tests done"
```

Step 2 waits for Step 1. Step 3 waits for Step 2.

---

## 4. Parallel Jobs

By default, jobs run in parallel:

```yaml
jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - run: pytest tests/unit/

  lint:
    runs-on: ubuntu-latest
    steps:
      - run: flake8 src/
```

`unit-tests` and `lint` both start at the same time.

---

## 5. Sequential Jobs with `needs`

Use `needs:` to make one job wait for another:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building..."

  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: echo "Testing..."

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying..."
```

Flow:

```text
build
  │
  ▼
test
  │
  ▼
deploy
```

---

## 6. Step Environment Variables

```yaml
- name: Build with custom variables
  env:
    BUILD_VERSION: "1.0.0"
    ENVIRONMENT: "production"
  run: echo "Building $BUILD_VERSION for $ENVIRONMENT"
```

---

## 7. Multiline Run Commands

```yaml
- name: Install and test
  run: |
    pip install -r requirements.txt
    pip install pytest
    pytest --verbose
```

The `|` character allows multiple shell lines.

---

## 8. Conditional Steps

```yaml
- name: Deploy only on main
  if: github.ref == 'refs/heads/main'
  run: echo "Deploying to production"
```

This step only runs when the branch is `main`.

---

## 9. uses: with: Parameters

```yaml
- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: '3.11'
    cache: 'pip'
```

`with:` passes parameters to the action being used.

---

## Key Learning

```text
Job     = group of steps on one runner
Step    = single command (run:) or action (uses:)
needs:  = makes one job wait for another
if:     = conditional step execution
with:   = parameters passed to uses: actions
|       = multiline shell command block
```

---

## Reference

* **Jobs reference:** https://docs.github.com/en/actions/using-jobs/using-jobs-in-a-workflow
* **Steps reference:** https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idsteps
