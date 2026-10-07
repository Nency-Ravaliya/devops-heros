#!/usr/bin/env bash
# Print Argo CD + workload state whenever it changes (max ~4 min). usage: ./gitops/watch-sync.sh [until-pattern]
until="${1:-}"; prev=""
for i in $(seq 1 120); do
  a=$(kubectl -n argocd get app taskboard -o jsonpath='{.status.sync.status}/{.status.health.status} rev={.status.sync.revision}' 2>/dev/null | cut -c1-36)
  f=$(kubectl -n taskboard get deploy taskboard-frontend -o jsonpath='{.spec.replicas}/{.status.readyReplicas}' 2>/dev/null)
  b=$(kubectl -n taskboard get deploy taskboard-backend -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
  cur="argo=$a  frontend(spec/ready)=$f  backend=$b"
  [ "$cur" != "$prev" ] && echo "$(date +%T)  $cur"; prev="$cur"
  [ -n "$until" ] && [[ "$cur" == *$until* ]] && break
  sleep 2
done
