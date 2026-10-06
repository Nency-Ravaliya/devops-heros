#!/usr/bin/env bash
# Issue 1: wrong image tag -> ErrImagePull / ImagePullBackOff
source "$(dirname "$0")/lib.sh"
baseline

step "BREAK: deploy a tag that does not exist"
break_with "--set image.tag=1.0.9-typo"
sleep 25

step "SYMPTOM"
run "kubectl -n $NS rollout status deploy/stockpilot-api --timeout=10s"
run "kubectl -n $NS get pods -l app.kubernetes.io/component=api"
curl_ingress

step "INVESTIGATE"
run "kubectl -n $NS describe pod -l app.kubernetes.io/component=api | grep -E '^Name:|Image:|Reason:|Failed|Back-off' | head -12"
run "kubectl -n $NS get events --sort-by=.lastTimestamp | grep -E 'Failed|BackOff' | tail -4 | cut -c1-260"
run "helm history $REL -n $NS | tail -3"

step "ROOT CAUSE: image stockpilot-api:1.0.9-typo does not exist (not in the node cache, not on docker.io)."
echo "Old ReplicaSet kept serving because maxUnavailable=0 - the outage was avoided by the rollout strategy."
echo

step "FIX: redeploy the known-good tag from values-dev.yaml"
fix_release

step "VERIFY"
run "kubectl -n $NS get pods -l app.kubernetes.io/component=api"
run "kubectl -n $NS get deploy stockpilot-api -o jsonpath='{.spec.template.spec.containers[0].image}{\"\\n\"}'"
curl_ingress
