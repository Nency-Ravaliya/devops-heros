#!/usr/bin/env bash
# 03: the real "CD" target - my laptop's kind cluster. Deploy the image the pipeline pushed to GHCR.
# usage: scripts/03-deploy-kind.sh <image tag, e.g. sha-abc1234>
. "$(dirname "$0")/lib.sh"
TAG="${1:?image tag}"; IMG="ghcr.io/kushaltalati/unit-converter:$TAG"; NS=s16-unit-converter
x "kubectl config current-context"
hr "get the image the pipeline pushed"
if docker pull "$IMG" 2>&1 | tail -2; then
  echo "pulled $IMG from GHCR"
else
  echo "GHCR package is private by default and I am not logged in to ghcr.io on this laptop, so I load the identical image built from the same commit"
  x "docker tag ghcr.io/kushaltalati/unit-converter:local $IMG"
fi
x "kind load docker-image $IMG --name kushal-lab 2>&1 | tail -3"
hr "deploy"
x "kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f -"
x "sed \"s|:latest|:$TAG|\" unit-converter/k8s/deployment.yaml | kubectl -n $NS apply -f -"
x "kubectl -n $NS apply -f unit-converter/k8s/service.yaml"
x "kubectl -n $NS rollout status deploy/unit-converter --timeout=120s"
x "kubectl -n $NS get pods -o wide"
x "kubectl -n $NS get deploy unit-converter -o jsonpath='{.spec.template.spec.containers[0].image}'; echo"
hr "smoke test through the Service"
kubectl -n $NS port-forward svc/unit-converter 20080:80 >/dev/null 2>&1 & PF=$!; sleep 3
x "curl -s localhost:20080/health; echo"
x "curl -s localhost:20080/info; echo"
x "curl -s 'localhost:20080/convert/length?value=42&from_unit=km&to_unit=mi'; echo"
kill $PF 2>/dev/null; wait $PF 2>/dev/null
hr "cleanup"
x "kubectl delete namespace $NS --wait=false"
