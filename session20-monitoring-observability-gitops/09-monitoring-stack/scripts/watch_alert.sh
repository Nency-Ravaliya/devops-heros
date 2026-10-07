#!/usr/bin/env bash
# Poll Prometheus every 5s and print the state of one alert until it is FIRING
# (or, with "cleared", until it disappears).  usage: scripts/watch_alert.sh <AlertName> [firing|cleared]
name="$1"; want="${2:-firing}"; dir="$(cd "$(dirname "$0")" && pwd)"
for _ in $(seq 1 40); do
  sleep 5
  line=$("$dir/alerts.py" prom | grep " $name ") || line=""
  state=$(echo "$line" | awk '{print $2}'); state="${state:-INACTIVE}"
  echo "$(date +%T)  $name  ${state}$(echo "$line" | sed -E 's/.*Z  /  /')"
  [ "$want" = firing ] && [ "$state" = FIRING ] && exit 0
  [ "$want" = cleared ] && [ "$state" = INACTIVE ] && exit 0
done
exit 1
