#!/usr/bin/env bash
# Issue 1: wrong image tag -> ErrImagePull / ImagePullBackOff
source "$(dirname "$0")/lib.sh"
baseline

step "BREAK: deploy an image tag that does not exist"
break_with "--set image.tag=2.0.9-typo"
sleep 25

step "SYMPTOM"
run "kubectl -n $NS get pods"
curl_ingress

step "INVESTIGATE"
run "kubectl -n $NS describe pod -l app.kubernetes.io/component=backend | grep -E '^Name:|Image:|Reason:|Back-off' | head -12"
run "kubectl -n $NS get events --sort-by=.lastTimestamp | grep -E 'Failed|BackOff' | tail -4 | cut -c1-220"
run "helm history $REL -n $NS | tail -3"

step "ROOT CAUSE: tag 2.0.9-typo was never built (not on the nodes, not in any registry)."
echo "The old ReplicaSets keep serving because maxUnavailable=0, so users see no outage."

step "FIX: redeploy the known-good values from Git"
fix_release

step "VERIFY"
run "kubectl -n $NS get pods"
run "kubectl -n $NS get deploy -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image"
curl_ingress
