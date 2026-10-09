Security tooling used by the pipeline (`.github/workflows/final-devops-project.yml`):

| Stage | Tool | Gate |
|---|---|---|
| SAST | Bandit (`-r application/app -ll -ii`) | fails on MEDIUM+ severity & confidence |
| SAST | CodeQL (python) | results in the GitHub Security tab |
| SCA | pip-audit (`-r application/requirements.txt --strict`) | fails on any known CVE |
| Secret scanning | Gitleaks (config: `.gitleaks.toml`) | fails on any secret |
| Container image | Trivy | report HIGH/CRITICAL, **fail on fixable CRITICAL** |
| Kubernetes | runAsNonRoot, readOnlyRootFilesystem, drop ALL caps, Secret from the pipeline (never in Git) | enforced by manifests |
