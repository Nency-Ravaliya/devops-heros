# 05 - SCA

Scan third-party dependencies for known vulnerabilities.

SCA means **Software Composition Analysis**.

## Example Dependencies

Our Python application may use:

```text
Flask
pytest
pytest-cov
```

A vulnerability in a dependency can become a risk for the application.

## SAST vs SCA

```text
SAST → our source code
SCA  → our dependencies
```

## Tool: pip-audit

Install:

```bash
pip install pip-audit
```

Run:

```bash
pip-audit
```

## GitHub Actions

```yaml
sca:
  name: SCA - Dependency Scan
  runs-on: ubuntu-latest

  steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Python
      uses: actions/setup-python@v5
      with:
        python-version: "3.12"

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install pip-audit

    - name: Run dependency scan
      run: pip-audit
```

## Typical Remediation Flow

```text
Vulnerability found
       ↓
Identify package/version
       ↓
Check fixed version
       ↓
Update dependency
       ↓
Run tests
       ↓
Run SCA again
```

## Practice Questions

1. Run `pip-audit` locally.
2. Read the output.
3. Identify package and version information.
4. Explain how you would remediate a vulnerable dependency.
