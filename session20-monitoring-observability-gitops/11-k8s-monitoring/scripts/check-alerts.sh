#!/usr/bin/env bash
# Tiny "alert rule" built on kubectl top (metrics-server).
# Prints ALERT for every pod whose CPU (millicores) or memory (Mi) is above a threshold.
#
# usage: scripts/check-alerts.sh [namespace] [cpu_threshold_m] [mem_threshold_Mi]
# env:   KUBE_CONTEXT (default: session20)
set -euo pipefail
NS="${1:-monitoring-demo}"
CPU_LIMIT="${2:-100}"
MEM_LIMIT="${3:-100}"
CTX="${KUBE_CONTEXT:-session20}"

echo "Checking pods in '$NS' (CPU > ${CPU_LIMIT}m or MEM > ${MEM_LIMIT}Mi)"
firing=0
while read -r pod cpu mem; do
  c="${cpu%m}"; m="${mem%Mi}"
  ok=1
  if (( c > CPU_LIMIT )); then
    echo "ALERT  [HighCPU]    pod=$pod cpu=${cpu} threshold=${CPU_LIMIT}m"; firing=$((firing+1)); ok=0
  fi
  if (( m > MEM_LIMIT )); then
    echo "ALERT  [HighMemory] pod=$pod mem=${mem} threshold=${MEM_LIMIT}Mi"; firing=$((firing+1)); ok=0
  fi
  if (( ok )); then
    echo "OK                  pod=$pod cpu=${cpu} mem=${mem}"
  fi
done < <(kubectl --context "$CTX" top pods -n "$NS" --no-headers)

echo "----"
echo "$firing alert(s) firing"
exit 0
