# Security tool configuration

| File | Tool | Stage in the pipeline | Fails the build when |
|---|---|---|---|
| `bandit.yaml` | bandit | SAST | any finding of medium+ severity and medium+ confidence |
| `semgrep.yaml` | semgrep (+ registry packs `p/python`, `p/owasp-top-ten`) | SAST | any ERROR-severity finding |
| `gitleaks.toml` | gitleaks | Secret scan | any secret-looking string outside the allow-listed paths |
| `trivy.yaml` + `.trivyignore` | trivy | SCA (`trivy fs`), misconfig (`trivy config`), image scan (`trivy image`) | CRITICAL/HIGH vulnerability that has a fix |

pip-audit runs without a config file (`pip-audit -r requirements.txt --strict`).
