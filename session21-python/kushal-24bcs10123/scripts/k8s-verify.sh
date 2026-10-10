#!/usr/bin/env bash
# One-shot status dump of the studytrack namespace, used for the README evidence.
set -uo pipefail
NS="${1:-studytrack}"
x() { printf '\n$ %s\n' "$1"; eval "$1" 2>&1; }
x "kubectl get ns $NS"
x "helm list -n $NS"
x "kubectl -n $NS get pods -o wide"
x "kubectl -n $NS get svc"
x "kubectl -n $NS get ingress"
x "kubectl -n $NS get hpa"
x "kubectl -n $NS get pvc"
x "kubectl -n $NS get configmap,secret"
x "kubectl -n $NS get servicemonitor"
x "kubectl -n $NS get pods -o 'custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image,RESTARTS:.status.containerStatuses[0].restartCount'"
x "curl -s -H 'Host: studytrack.local' http://localhost/api/entries/summary"
x "curl -s -o /dev/null -w 'HTTP %{http_code}\n' -H 'Host: studytrack.local' http://localhost/"
