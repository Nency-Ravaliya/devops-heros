#!/usr/bin/env bash
# Issue 5: Service targetPort does not match the container port -> 502 from ingress
source "$(dirname "$0")/lib.sh"
baseline

step "BREAK: someone hot-patches the Service to targetPort 9000"
run "kubectl -n $NS patch svc stockpilot-api --type=json -p \"\$(cat troubleshooting/patches/service-wrong-targetport.json)\""
sleep 5

step "SYMPTOM"
curl_ingress
run "kubectl -n $NS get pods -l app.kubernetes.io/component=api"

step "INVESTIGATE"
run "kubectl -n $NS get svc stockpilot-api -o jsonpath='port={.spec.ports[0].port} targetPort={.spec.ports[0].targetPort}{\"\\n\"}'"
run "kubectl -n $NS get endpointslices -l kubernetes.io/service-name=stockpilot-api"
run "kubectl -n $NS get pod -l app.kubernetes.io/component=api -o jsonpath='{range .items[*]}{.metadata.name} containerPort={.spec.containers[0].ports[0].containerPort}{\"\\n\"}{end}'"
run "kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=400 | grep -E 'server: $HOST.*:9000' | tail -1 | cut -c1-300"

step "ROOT CAUSE: pods are Ready, but the Service forwards to :9000 where nothing listens -> upstream connection refused -> 502."
echo

step "FIX attempt 1: re-apply the chart (Service uses the named port 'http')"
fix_release
run "kubectl -n $NS get svc stockpilot-api -o jsonpath='port={.spec.ports[0].port} targetPort={.spec.ports[0].targetPort}{\"\\n\"}'"
run "kubectl -n $NS get svc stockpilot-api --show-managed-fields -o jsonpath='{range .metadata.managedFields[*]}{.manager} {.operation}{\"\\n\"}{end}'"
echo "Helm 4 uses server-side apply: the kubectl-patch field manager now owns .spec.ports[].targetPort,"
echo "so Helm refuses to overwrite it. The drift has to be taken back explicitly."
echo

step "FIX attempt 2: helm upgrade --force-conflicts (Helm reclaims ownership of the field)"
run "helm upgrade $REL helm/stockpilot -n $NS -f helm/stockpilot/values-dev.yaml -f troubleshooting/values-trouble.yaml --force-conflicts --wait --timeout 5m | grep -E 'STATUS|REVISION'"
run "kubectl -n $NS get svc stockpilot-api -o jsonpath='port={.spec.ports[0].port} targetPort={.spec.ports[0].targetPort}{\"\\n\"}'"

step "VERIFY"
run "kubectl -n $NS get endpointslices -l kubernetes.io/service-name=stockpilot-api"
sleep 5   # give ingress-nginx a moment to sync the new upstream port
curl_ingress
