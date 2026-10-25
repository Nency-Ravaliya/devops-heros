#!/usr/bin/env bash
# 03-alerts: PrometheusRule -> Prometheus evaluates -> Alertmanager receives. Make S20HighCPU fire with /burn,
# then S20AppDown by scaling the app to zero, then watch both resolve.
. "$(dirname "$0")/lib.sh"
M="$ME/01-monitoring"
x "cat $M/prometheusrule.yaml"
x "kubectl apply -f $M/prometheusrule.yaml"
pf "$MON" kube-prometheus-stack-prometheus 19090:9090
for _ in $(seq 1 40); do curl -s http://localhost:19090/api/v1/rules | grep -q 'S20AppDown' && break; sleep 5; done
x "curl -s http://localhost:19090/api/v1/rules | python3 -c 'import sys,json; [print(r[\"name\"], r[\"state\"], \"for\", r.get(\"duration\")) for g in json.load(sys.stdin)[\"data\"][\"groups\"] if g[\"name\"]==\"s20-metrics-app.rules\" for r in g[\"rules\"]]'"
x "kubectl -n $MON get configmap prometheus-kube-prometheus-stack-prometheus-rulefiles-0 -o json | python3 -c 'import sys,json; [print(k) for k in json.load(sys.stdin)[\"data\"] if \"s20\" in k]'     # the operator copied my rule into the ConfigMap Prometheus mounts"
x "kubectl top pods -n $NS --containers"

hr "1) CPU alert: hammer /burn so the app container uses more than 200m CPU"
kubectl -n "$NS" port-forward svc/s20-metrics-app 19080:8000 >/dev/null 2>&1 & PF2=$!; sleep 2
( end=$((SECONDS+150)); while [ $SECONDS -lt $end ]; do curl -s -m 10 -o /dev/null 'http://localhost:19080/burn?seconds=5' & curl -s -m 10 -o /dev/null 'http://localhost:19080/burn?seconds=5'; wait; done ) &
BURN=$!
sleep 45
x "kubectl top pods -n $NS --containers"
x "echo 'sum(rate(container_cpu_usage_seconds_total{namespace=\"$NS\",container=\"app\"}[1m]))'; promql 'sum(rate(container_cpu_usage_seconds_total{namespace=\"$NS\",container=\"app\"}[1m]))'"
x "echo 'waiting for S20HighCPU (for: 30s) ...'; wait_alert S20HighCPU 40"
x "promql 'ALERTS{owner=\"kushal-24bcs10123\"}'"
node "$ME/scripts/shot.mjs" "http://localhost:19090/alerts?search=S20" "$ME/screenshots/03-prometheus-alerts-highcpu.png" '' 5000
kubectl -n "$MON" port-forward svc/kube-prometheus-stack-alertmanager 19093:9093 >/dev/null 2>&1 & PF3=$!; sleep 2
x "sleep 20; curl -s http://localhost:19093/api/v2/alerts | python3 -c 'import sys,json; [print(a[\"labels\"][\"alertname\"], a[\"status\"][\"state\"], a[\"labels\"].get(\"severity\"), a[\"annotations\"].get(\"summary\")) for a in json.load(sys.stdin) if a[\"labels\"].get(\"owner\")==\"kushal-24bcs10123\"]'"
node "$ME/scripts/shot.mjs" "http://localhost:19093/#/alerts?silenced=false&inhibited=false&active=true&filter=%7Bowner%3D%22kushal-24bcs10123%22%7D" "$ME/screenshots/03-alertmanager-highcpu.png" '' 5000
kill $BURN 2>/dev/null; wait $BURN 2>/dev/null; kill $PF2 2>/dev/null
x "sleep 60; echo 'after the load stopped:'; promql 'ALERTS{alertname=\"S20HighCPU\"}'"

hr "2) Down alert: scale the app to zero -> no target -> absent(up == 1)"
x "kubectl -n $NS scale deployment/s20-metrics-app --replicas=0"
x "kubectl -n $NS get pods -l app=s20-metrics-app"
x "sleep 20; curl -s http://localhost:19090/api/v1/targets | python3 -c 'import sys,json; t=[t for t in json.load(sys.stdin)[\"data\"][\"activeTargets\"] if \"s20\" in t[\"labels\"][\"job\"]]; print(len(t), \"s20 targets left\")'"
x "echo 'waiting for S20AppDown (for: 1m) ...'; wait_alert S20AppDown 40"
x "promql 'ALERTS{owner=\"kushal-24bcs10123\"}'"
x "curl -s http://localhost:19093/api/v2/alerts | python3 -c 'import sys,json; [print(a[\"labels\"][\"alertname\"], a[\"status\"][\"state\"], a[\"startsAt\"][:19], a[\"annotations\"].get(\"description\")) for a in json.load(sys.stdin) if a[\"labels\"].get(\"owner\")==\"kushal-24bcs10123\"]'"
node "$ME/scripts/shot.mjs" "http://localhost:19090/alerts?search=S20" "$ME/screenshots/03-prometheus-alerts-appdown.png" '' 5000
node "$ME/scripts/shot.mjs" "http://localhost:19093/#/alerts?silenced=false&inhibited=false&active=true&filter=%7Bowner%3D%22kushal-24bcs10123%22%7D" "$ME/screenshots/03-alertmanager-appdown.png" '' 5000

hr "3) Recover: scale back up, the alert resolves on its own"
x "kubectl -n $NS scale deployment/s20-metrics-app --replicas=1"
x "kubectl -n $NS rollout status deployment/s20-metrics-app --timeout=120s"
for _ in $(seq 1 30); do curl -s -G http://localhost:19090/api/v1/query --data-urlencode 'query=ALERTS{alertname="S20AppDown"}' | grep -q 'firing' || break; sleep 5; done
x "promql 'ALERTS{owner=\"kushal-24bcs10123\"}'"
x "promql 'up{job=\"s20-metrics-app\"}'"
kill $PF3 2>/dev/null; pf_stop
