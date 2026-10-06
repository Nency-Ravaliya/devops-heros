#!/usr/bin/env bash
# Evidence for troubleshooting issue #5 (found for real during the GitOps rollout).
set -uo pipefail
run() { echo "\$ $*"; "$@" 2>&1; echo; }
run kubectl -n argocd get application final-stockpilot-24bcs10267
run kubectl -n final-gitops get pods -l app.kubernetes.io/component=api
run kubectl -n final-gitops logs deploy/stockpilot-api --tail=5
echo "\$ kubectl -n final-gitops describe pod -l app.kubernetes.io/component=api | grep -E 'Image:|State:|Reason:|Exit Code:|Back-off' "
kubectl -n final-gitops describe pod -l app.kubernetes.io/component=api | grep -E 'Image:|State:|Reason:|Exit Code:|Back-off' | head -14
echo
run kubectl get nodes -o custom-columns=NAME:.metadata.name,ARCH:.status.nodeInfo.architecture
run docker buildx imagetools inspect ghcr.io/ujjawalprabhat/stockpilot-api:f9d09f1d0cd1a86a20a1711fda2d2d23f3171db5
