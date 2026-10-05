# 08 - Security Gates

Turn security and quality checks into decisions that control whether the pipeline can continue.

A scan finds a problem. A **gate** decides what happens next.

## Without a Gate

```text
SCA finds vulnerability
        ↓
Pipeline continues
        ↓
Docker Build
        ↓
Push
        ↓
Deploy
```

## With a Gate

```text
Security Check
      ↓
   ┌──┴──┐
 PASS   FAIL
  ↓       ↓
Continue STOP
```

## GitHub Actions `needs`

Example:

```yaml
docker-build:
  needs:
    - test
    - sast
    - sca
```

Then:

```yaml
image-scan:
  needs:
    - docker-build
```

Then:

```yaml
push:
  needs:
    - image-scan
```

Finally:

```yaml
deploy:
  needs:
    - push
```

## Complete Flow

```text
Git Push
   ↓
Unit Tests
   ↓
SAST
   ↓
SCA
   ↓
Docker Build
   ↓
Container Image Scan
   ↓
Security Gate
   ├── FAIL → STOP
   └── PASS
         ↓
      GHCR Push
         ↓
 Kubernetes Deploy
         ↓
 Rollout Verification
```

## Example Image Security Gate

```bash
trivy image \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  session17-python:1.0
```

## What Should Be Gated?

| Check | Example Pipeline Behavior |
|---|---|
| Unit tests | Failure blocks next stage |
| SAST | Policy-defined findings can block |
| SCA | Policy-defined vulnerabilities can block |
| Secret scanning | Supported exposed secrets can block pushes |
| Image scan | Example HIGH/CRITICAL threshold |
| Docker build | Build failure blocks push |
| Registry push | Failure blocks deployment |
| Kubernetes rollout | Failed rollout makes deployment unsuccessful |

## DevSecOps Mindset

```text
Detect
  ↓
Evaluate
  ↓
Enforce
  ↓
Remediate
  ↓
Deploy
```

The goal is not simply to run security tools. The pipeline should use their results to control delivery according to defined policy.

## Practice Questions

Create a pipeline where:

1. Unit tests run.
2. SAST runs.
3. SCA runs.
4. Docker image is built.
5. Image is scanned.
6. Required security gates are enforced.
7. The image is pushed to GHCR only after required gates pass.
8. Kubernetes deployment happens only after the image is published.
9. The deployment waits for rollout completion.
