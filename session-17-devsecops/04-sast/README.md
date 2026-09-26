# 04 - SAST

Scan source code for security weaknesses before deployment.

SAST means **Static Application Security Testing**.

## What Does SAST Check?

```text
Source Code
    ↓
SAST Tool
    ↓
Security Analysis
    ↓
Findings
```

It analyzes source code without requiring the application to be running.

## Tool: GitHub CodeQL

```yaml
sast:
  name: SAST - CodeQL
  runs-on: ubuntu-latest
  permissions:
    contents: read
    security-events: write

  steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Initialize CodeQL
      uses: github/codeql-action/init@v3
      with:
        languages: python

    - name: Analyze code
      uses: github/codeql-action/analyze@v3
```

## Difference from Other Scans

| Scan | Checks |
|---|---|
| SAST | Source code |
| SCA | Dependencies |
| Secret scanning | Credentials/secrets |
| Image scanning | Container image |

## Classroom Practice

1. Add the CodeQL job.
2. Push the workflow.
3. Open the repository Security area.
4. Review code-scanning results.
5. Understand the reported file and line.
6. Fix the issue if applicable.
7. Push again.

## Key Point

SAST is one security layer. A clean SAST result does not mean the complete application is secure.
