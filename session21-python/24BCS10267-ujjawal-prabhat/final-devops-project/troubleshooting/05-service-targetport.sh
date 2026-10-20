#!/usr/bin/env bash
# Issue 5: Service targetPort does not match the container port -> connection refused via the Service
source "$(dirname "$0")/lib.sh"
baseline
svc_check() { run "kubectl -n $NS exec deploy/stockpilot-frontend -- wget -q -O- -T 3 http://stockpilot-backend/api/summary"; }

step "BREAK: someone hot-patches the backend Service to targetPort 9000"
run "kubectl -n $NS patch svc stockpilot-backend --type=json -p \"\$(cat troubleshooting/patches/service-wrong-targetport.json)\""
sleep 5

step "SYMPTOM: in-cluster clients of the Service (here the frontend pod) get connection refused"
svc_check
run "kubectl -n $NS get pods -l app.kubernetes.io/component=backend"

step "INVESTIGATE"
run "kubectl -n $NS get svc stockpilot-backend -o jsonpath='port={.spec.ports[0].port} targetPort={.spec.ports[0].targetPort}{\"\\n\"}'"
run "kubectl -n $NS get endpointslices -l kubernetes.io/service-name=stockpilot-backend -o jsonpath='{.items[*].ports}{\"\\n\"}'"
run "kubectl -n $NS get pod -l app.kubernetes.io/component=backend -o jsonpath='{range .items[*]}{.metadata.name} containerPort={.spec.containers[0].ports[0].containerPort}{\"\\n\"}{end}'"
curl_ingress

step "ROOT CAUSE: pods are Ready on :8000, but the Service forwards to :9000 where nothing listens."

step "FIX attempt 1: re-apply the chart (the Service uses the named port 'http')"
fix_release
run "kubectl -n $NS get svc stockpilot-backend -o jsonpath='targetPort={.spec.ports[0].targetPort}{\"\\n\"}'"
run "kubectl -n $NS get svc stockpilot-backend --show-managed-fields -o jsonpath='{range .metadata.managedFields[*]}{.manager} {.operation}{\"\\n\"}{end}'"
echo "Helm 4 uses server-side apply: the kubectl-patch field manager owns .spec.ports[].targetPort now,"
echo "so Helm refuses to overwrite it. The drift has to be taken back explicitly."

step "FIX attempt 2: --force-conflicts (Helm takes ownership of the field back)"
fix_release --force-conflicts
run "kubectl -n $NS get svc stockpilot-backend -o jsonpath='targetPort={.spec.ports[0].targetPort}{\"\\n\"}'"

step "FIX step 3: make ingress-nginx re-read the Service port (touch the Ingress, then remove the mark)"
run "kubectl -n $NS annotate ingress stockpilot resync=now --overwrite && kubectl -n $NS annotate ingress stockpilot resync-"
sleep 5

step "VERIFY"
svc_check
curl_ingress
