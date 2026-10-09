#!/usr/bin/env bash
# print deployment + Argo status only when it changes, until 3/3 ready again
prev=""; for i in $(seq 1 60); do
  d=$(kubectl --context session20 -n session20 get deploy session20-gitops-app -o jsonpath='spec.replicas={.spec.replicas} ready={.status.readyReplicas}' 2>/dev/null || echo "deployment=absent")
  a=$(kubectl --context session20 -n argocd get app session20-app -o jsonpath='{.status.sync.status}/{.status.health.status}')
  cur="$d  argo=$a"; [ "$cur" != "$prev" ] && echo "$(date +%T)  $cur"; prev="$cur"
  [ $i -gt 2 ] && [[ "$cur" == *"spec.replicas=3 ready=3  argo=Synced/Healthy"* ]] && break; sleep 2; done
