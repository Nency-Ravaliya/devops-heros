#!/usr/bin/env bash
# Argo CD selfHeal + prune demo on the GitOps environment (namespace final-gitops).
set -uo pipefail
APP=final-stockpilot-24bcs10267
NS=final-gitops
run() { echo "\$ $*"; bash -c "$*" 2>&1; echo; }
status() { kubectl -n argocd get application $APP -o jsonpath='{.status.sync.status}/{.status.health.status}'; }

echo "############ current state ############"; echo
run "kubectl -n $NS get deploy,po,svc,ing,hpa,pvc"
run "curl -s -H 'Host: stockpilot-gitops.local' localhost:8081/api/info"

echo "############ DRIFT 1: someone edits the ConfigMap by hand (LOG_LEVEL info -> debug) ############"; echo
run "kubectl -n $NS patch configmap stockpilot-config --type merge -p '{\"data\":{\"LOG_LEVEL\":\"debug\"}}'"
run "kubectl -n $NS get configmap stockpilot-config -o jsonpath='{.data.LOG_LEVEL}{\"\\n\"}'"
for i in $(seq 1 30); do v=$(kubectl -n $NS get configmap stockpilot-config -o jsonpath='{.data.LOG_LEVEL}'); [ "$v" = "info" ] && break; sleep 2; done
echo "(waited $((i*2))s)"
run "kubectl -n $NS get configmap stockpilot-config -o jsonpath='{.data.LOG_LEVEL}{\"\\n\"}'"

echo "############ DRIFT 2: someone deletes the Service ############"; echo
run "kubectl -n $NS delete service stockpilot-api"
run "curl -s -o /dev/null -w 'HTTP %{http_code}\n' -H 'Host: stockpilot-gitops.local' localhost:8081/api/info"
for i in $(seq 1 30); do kubectl -n $NS get svc stockpilot-api >/dev/null 2>&1 && break; sleep 2; done
echo "(waited $((i*2))s)"
sleep 5
run "kubectl -n $NS get svc stockpilot-api"
run "curl -s -o /dev/null -w 'HTTP %{http_code}\n' -H 'Host: stockpilot-gitops.local' localhost:8081/api/info"

echo "############ DRIFT 3: someone scales the HPA floor up by hand (minReplicas 2 -> 4) ############"; echo
run "kubectl -n $NS patch hpa stockpilot-api --type merge -p '{\"spec\":{\"minReplicas\":4}}'"
for i in $(seq 1 30); do v=$(kubectl -n $NS get hpa stockpilot-api -o jsonpath='{.spec.minReplicas}'); [ "$v" = "2" ] && break; sleep 2; done
echo "(waited $((i*2))s)"
run "kubectl -n $NS get hpa stockpilot-api"

echo "############ Argo CD history / events ############"; echo
run "kubectl -n argocd get application $APP -o jsonpath='{range .status.history[*]}{.id}  {.revision}  {.deployedAt}{\"\\n\"}{end}'"
run "kubectl -n argocd get events --field-selector involvedObject.name=$APP --sort-by=.lastTimestamp | tail -8 | cut -c1-220"
echo "final status: $(status)"
