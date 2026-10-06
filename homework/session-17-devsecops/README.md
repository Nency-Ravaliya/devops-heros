# Session 17 — DevSecOps pipeline

Student: Viraj Bhanage, roll 24BCS10274

The course sample is `session-17-devsecops/demo/.github/workflows/devsecops.yml`. The pipeline that actually runs on this fork is `.github/workflows/taskboard-ci.yml`.

## Flow

```text
Code
  -> unit tests (pytest)
  -> frontend build
  -> Docker build
  -> Trivy image scan (fail on HIGH or CRITICAL)
  -> push to GHCR
  -> Helm deploy to Kubernetes, when the kubeconfig secret is present
```

The course demo also shows the other gates:

| Gate | Tool in the course workflow | What it looks for |
|---|---|---|
| SAST | CodeQL | Dangerous patterns in first-party code |
| SCA | `pip-audit` | Known CVEs in dependencies |
| Secret scanning | GitHub secret scanning / a scanner step | Tokens committed by mistake |
| Image scanning | Trivy | CVEs in the built image and OS packages |
| Security gate | `exit-code: 1` on HIGH,CRITICAL | Stop the push and the deploy |

SAST reads source. SCA reads the lockfile or installed packages. Secret scanning reads the git tree. Image scanning reads the built filesystem. A gate is the rule that turns a finding into a failed job so a bad image is not deployed.

Kubernetes manifests for the demo app are in `session-17-devsecops/demo/k8s/`. The capstone chart is `session21-python/helm/taskboard/`.

Screenshot the Trivy step from the Actions run and write which image was scanned and whether the result was clean or which CVE failed the gate.
