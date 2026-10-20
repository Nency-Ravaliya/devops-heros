#!/usr/bin/env bash
# Issue 2: readiness probe points at a path that does not exist -> new pods never Ready
source "$(dirname "$0")/lib.sh"
baseline

step "BREAK: backend readiness probe path /readyz (the app serves /ready)"
break_with "--set backend.probes.readiness.path=/readyz"
sleep 30

step "SYMPTOM"
run "kubectl -n $NS get pods -l app.kubernetes.io/component=backend"
show_endpoints

step "INVESTIGATE"
run "kubectl -n $NS describe pod -l app.kubernetes.io/component=backend | grep -E 'Readiness:' | sort | uniq -c"
run "kubectl -n $NS get events --field-selector reason=Unhealthy | grep 'statuscode: 404' | tail -2 | cut -c1-200"
NEWPOD=$(kubectl -n $NS get pods -l app.kubernetes.io/component=backend --sort-by=.metadata.creationTimestamp -o name | tail -1)
run "kubectl -n $NS exec $NEWPOD -c backend -- python -c \"import urllib.request as u
for p in ('/readyz','/ready'):
    try: print(p, u.urlopen('http://127.0.0.1:8000'+p).status)
    except Exception as e: print(p, e)\""

step "ROOT CAUSE: kubelet probes GET /readyz -> 404, so the new pod never joins the Service endpoints and the rollout stalls."

step "FIX"
fix_release

step "VERIFY"
run "kubectl -n $NS get pods -l app.kubernetes.io/component=backend"
show_endpoints
curl_ingress
