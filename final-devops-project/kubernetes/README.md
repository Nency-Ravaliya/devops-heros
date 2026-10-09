Plain Kubernetes manifests of the same application (what the Helm chart renders), used for
the troubleshooting challenge and for anyone who wants `kubectl apply -f .` without Helm.
`IMAGE_PLACEHOLDER` is replaced with the built image; the `notes-redis-auth` Secret is created
separately (never committed).
