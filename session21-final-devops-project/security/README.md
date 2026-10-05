# Security controls

I placed the security checks before image delivery:

1. Bandit scans the Python source for unsafe patterns.
2. pip-audit checks Python dependencies against vulnerability advisories.
3. Gitleaks scans Git history for credentials.
4. Trivy scans both container images for fixed HIGH and CRITICAL vulnerabilities.
5. Helm and Kubernetes validation run before deployment.

The containers run as non-root users, Kubernetes probes stop unhealthy Pods from receiving traffic, and the chart sets resource requests and limits. Passwords in `values.yaml` are demonstration defaults only; a real deployment should supply them from an external secret manager or a protected values file.
