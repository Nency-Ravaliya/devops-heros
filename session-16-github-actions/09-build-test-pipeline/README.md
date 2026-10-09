# Build and Test Pipeline

```text
Push to main
      │
      ▼
Checkout code
      │
      ▼
Set up Python
      │
      ▼
Install dependencies
      │
      ▼
Run lint (flake8)
      │
      ▼
Run tests (pytest)
      │
      ▼
Upload coverage report
```

---

## 1. The Goal

Build a complete CI pipeline that:

```text
[CHECK] Checks out the latest code
[CHECK] Sets up the correct Python version
[CHECK] Installs all dependencies
[CHECK] Lints the code for style errors
[CHECK] Runs unit tests
[CHECK] Uploads a test report as an artifact
```

---

## 2. The Application

Create a simple Python application:

`app.py`:

```python
def add(a, b):
    return a + b


def subtract(a, b):
    return a - b


def divide(a, b):
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b
```

---

## 3. The Tests

`tests/test_app.py`:

```python
import pytest
from app import add, subtract, divide


def test_add():
    assert add(2, 3) == 5


def test_subtract():
    assert subtract(10, 4) == 6


def test_divide():
    assert divide(10, 2) == 5.0


def test_divide_by_zero():
    with pytest.raises(ValueError):
        divide(10, 0)
```

---

## 4. The Requirements File

`requirements.txt`:

```text
pytest==7.4.0
pytest-cov==4.1.0
flake8==6.1.0
```

---

## 5. The Full CI Workflow

`.github/workflows/ci.yml`:

```yaml
name: CI Pipeline

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main

jobs:
  lint:
    name: Code Lint
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'

      - name: Install lint tool
        run: pip install flake8

      - name: Run flake8
        run: flake8 app.py tests/

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Run tests with coverage
        run: |
          pytest tests/ \
            --junitxml=test-results/results.xml \
            --cov=app \
            --cov-report=xml:coverage.xml \
            --cov-report=term-missing

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: test-results/
          retention-days: 7

      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage-report
          path: coverage.xml
          retention-days: 7
```

---

## 6. Run It Locally First

Before pushing to GitHub, run the same commands manually:

```bash
pip install -r requirements.txt
flake8 app.py tests/
pytest tests/ --junitxml=test-results/results.xml --cov=app --cov-report=term-missing
```

Expected output:

```text
collected 4 items

tests/test_app.py ....

---------- coverage: platform linux, python 3.11 ----------
Name     Stmts   Miss  Cover
-------------------------------
app.py       8      0   100%
-------------------------------
TOTAL        8      0   100%

4 passed in 0.12s
```

---

## 7. Push and Observe

```bash
git add .
git commit -m "Add CI pipeline"
git push origin main
```

Go to GitHub > Actions tab.

You should see:

```text
CI Pipeline
  └── lint    [PASS]
  └── test    [PASS]
```

---

## 8. Simulate a Failing Test

Change `app.py`:

```python
def add(a, b):
    return a - b     # intentionally wrong
```

Push again. In GitHub Actions you will see:

```text
CI Pipeline
  └── lint    [PASS]
  └── test    [FAIL]
```

The test job will show:

```text
FAILED tests/test_app.py::test_add - AssertionError: assert 1 == 5
```

This is CI doing its job. It caught the bug before it reached anyone else.

Revert the change:

```python
def add(a, b):
    return a + b
```

---

## 9. Pipeline Flow

```text
Push to main
      │
      ▼
  lint job
    flake8 runs
      │
  [PASS] or [FAIL]
      │ (only on PASS)
      ▼
  test job
    pytest runs
      │
  [PASS] or [FAIL]
      │ (only on PASS)
      ▼
Artifacts uploaded
  test-results.xml
  coverage.xml
```

---

## What You Practiced

```text
[PASS] Created a Python app with unit tests
[PASS] Wrote a full CI workflow YAML
[PASS] Used lint + test as separate jobs with needs:
[PASS] Uploaded test results and coverage as artifacts
[PASS] Simulated a failing test and watched CI catch it
[PASS] Pushed code and verified GitHub Actions ran correctly
```

---

## Reference

* **actions/checkout:** https://github.com/actions/checkout
* **actions/setup-python:** https://github.com/actions/setup-python
* **pytest documentation:** https://docs.pytest.org/
* **flake8 documentation:** https://flake8.pycqa.org/
