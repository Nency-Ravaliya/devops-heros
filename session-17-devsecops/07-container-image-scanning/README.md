# 07 - Container Image Scanning

Scan the final Docker image for known vulnerabilities before publishing or deploying it.

## Why Scan the Image?

Source code can be clean while the final image still contains vulnerable:

- OS packages
- Python packages
- System libraries
- Other installed components

Therefore, scan the container image itself.

## Tool: Trivy

Build the image:

```bash
docker build -t session17-python:1.0 .
```

Scan:

```bash
trivy image session17-python:1.0
```

Scan HIGH and CRITICAL findings:

```bash
trivy image \
  --severity HIGH,CRITICAL \
  session17-python:1.0
```

## Make the Scan a Gate

```bash
trivy image \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  session17-python:1.0
```

If the command exits with code `1`, the GitHub Actions step fails unless failure is explicitly allowed.

## Pipeline Flow

```text
Docker Build
     ↓
Trivy Scan
     ↓
Findings?
  /      \
FAIL     PASS
  ↓        ↓
STOP    Continue
```

## GitHub Actions Example

```yaml
- name: Scan image
  run: |
    trivy image \
      --severity HIGH,CRITICAL \
      --exit-code 1 \
      ghcr.io/${{ github.repository }}:${{ github.sha }}
```

## Important

HIGH/CRITICAL is a classroom example threshold, not a universal security policy. Organizations should define thresholds based on application risk and their security policy.

## Practice Questions

1. Build the image.
2. Run a normal Trivy scan.
3. Run a HIGH/CRITICAL scan.
4. Explain `--exit-code 1`.
