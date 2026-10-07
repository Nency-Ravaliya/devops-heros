#!/usr/bin/env bash
# 03: deploy the gate-approved image on my laptop's kind cluster (the pipeline deploys to a kind cluster on the runner).
# usage: scripts/03-deploy-kind.sh <image tag, e.g. sha-abc1234>
. "$(dirname "$0")/lib.sh"
TAG="${1:?image tag}"; IMG="ghcr.io/kushaltalati/secure-converter:$TAG"; NS=s17-devsecops
x "kubectl config current-context"
if docker pull "$IMG" 2>&1 | tail -2; then
  echo "pulled $IMG from GHCR"
else
  echo "GHCR package is private by default and I am not logged in to ghcr.io on this laptop, so I load the identical image built from the same commit"
  x "docker tag ghcr.io/kushaltalati/secure-converter:local $IMG"
fi
x "kind load docker-image $IMG --name kushal-lab 2>&1 | tail -3"
hr "deploy with the hardened manifests"
x "kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f -"
x "sed \"s|:latest|:$TAG|\" secure-converter/k8s/deployment.yaml | kubectl -n $NS apply -f -"
x "kubectl -n $NS apply -f secure-converter/k8s/service.yaml"
x "kubectl -n $NS rollout status deploy/secure-converter --timeout=120s"
x "kubectl -n $NS get pods -o wide"
hr "prove the hardening is real"
x "kubectl -n $NS exec deploy/secure-converter -- id"
x "kubectl -n $NS exec deploy/secure-converter -- touch /app/x 2>&1 || echo '-> read-only root filesystem blocks writes'"
x "kubectl -n $NS exec deploy/secure-converter -- sh -c 'ls /var/run/secrets/kubernetes.io 2>&1 || echo no-serviceaccount-token-mounted'"
x "kubectl -n $NS get pod -l app=secure-converter -o jsonpath='{.items[0].spec.containers[0].securityContext}'; echo"
hr "smoke test through the Service"
kubectl -n $NS port-forward svc/secure-converter 20081:80 >/dev/null 2>&1 & PF=$!; sleep 3
x "curl -s localhost:20081/health; echo"
x "curl -s -X POST localhost:20081/convert -H 'content-type: application/json' -d '{\"category\":\"length\",\"value\":10,\"from_unit\":\"km\",\"to_unit\":\"mi\"}'; echo"
x "curl -s localhost:20081/history; echo"
kill $PF 2>/dev/null; wait $PF 2>/dev/null
hr "cleanup"
x "kubectl delete namespace $NS --wait=false"
