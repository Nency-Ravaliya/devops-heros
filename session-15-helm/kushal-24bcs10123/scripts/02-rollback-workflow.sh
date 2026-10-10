#!/usr/bin/env bash
# 02-rollback-workflow: install -> upgrade -> verify -> upgrade again -> verify -> rollback -> verify.
# Chart = the professor's 07-install-upgrade/app-chart, unmodified. Each revision has its own values file
# in kushal-24bcs10123/02-rollback-workflow/.
. "$(dirname "$0")/lib.sh"
V="$ME/02-rollback-workflow"
CH=07-install-upgrade/app-chart
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
x "cat $CH/Chart.yaml"
x "cat $CH/templates/deployment.yaml"
x "head -20 $V/values-v1.yaml $V/values-v2.yaml $V/values-v3.yaml"

hr "1. INSTALL (revision 1)"
x "helm install web-app $CH -f $V/values-v1.yaml"
x "ready web-app-app"
x "pods web-app"
x "helm history web-app"

hr "2. UPGRADE (revision 2) -> 3. VERIFY"
x "helm upgrade web-app $CH -f $V/values-v2.yaml"
x "ready web-app-app"
x "pods web-app"
x "helm get values web-app"
x "helm history web-app"

hr "4. UPGRADE AGAIN (revision 3) -> 5. VERIFY"
x "helm upgrade web-app $CH -f $V/values-v3.yaml"
x "ready web-app-app"
x "pods web-app"
x "kubectl -n $NS rollout history deployment/web-app-app"
x "helm history web-app"

hr "6. ROLLBACK to revision 2 -> 7. VERIFY"
x "helm rollback web-app 2"
x "ready web-app-app"
x "pods web-app"
x "helm get values web-app      # the values of revision 2 are back"
x "helm history web-app          # rollback did not delete anything, it added revision 4"
x "helm diff 2>/dev/null || helm get manifest web-app --revision 2 | diff - <(helm get manifest web-app) && echo 'manifest of revision 4 == manifest of revision 2'"

hr "Bonus: a broken upgrade with --atomic rolls itself back"
x "helm upgrade web-app $CH -f $V/values-v2.yaml --set image.tag=doesnotexist --atomic --timeout 45s 2>&1 | tail -3"
x "helm history web-app"
x "pods web-app"

hr "Cleanup"
x "helm uninstall web-app"
x "helm list"
