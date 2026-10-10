#!/usr/bin/env bash
# 04-grafana: dashboards on top of the in-cluster Prometheus. Everything through Grafana's HTTP API + screenshots.
. "$(dirname "$0")/lib.sh"
M="$ME/01-monitoring"
pf "$MON" kube-prometheus-stack-grafana 19300:80
AUTH="admin:admin123"
x "curl -s http://localhost:19300/api/health"
x "curl -s -u $AUTH http://localhost:19300/api/datasources | python3 -c 'import sys,json; [print(d[\"uid\"], d[\"type\"], d[\"url\"], \"default\" if d[\"isDefault\"] else \"\") for d in json.load(sys.stdin)]'"
DSUID=$(curl -s -u $AUTH http://localhost:19300/api/datasources | python3 -c 'import sys,json; print([d for d in json.load(sys.stdin) if d["type"]=="prometheus"][0]["uid"])')
x "curl -s -u $AUTH 'http://localhost:19300/api/search?type=dash-db' | python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d), \"dashboards shipped by kube-prometheus-stack, e.g.\", [x[\"title\"] for x in d[:6]])'"
hr "Import my dashboard (JSON in 01-monitoring/grafana-dashboard.json)"
x "python3 -c 'import json; d=json.load(open(\"$M/grafana-dashboard.json\"))[\"dashboard\"]; [print(p[\"id\"], p[\"type\"], \"|\", p[\"title\"], \"|\", p[\"targets\"][0][\"expr\"]) for p in d[\"panels\"]]'"
x "curl -s -u $AUTH -X POST http://localhost:19300/api/dashboards/db -H 'Content-Type: application/json' -d @$M/grafana-dashboard.json; echo"
hr "Query the data source the way a panel does (/api/ds/query)"
q() { curl -s -u $AUTH -X POST http://localhost:19300/api/ds/query -H 'Content-Type: application/json' -d "{\"queries\":[{\"refId\":\"A\",\"datasource\":{\"uid\":\"$DSUID\"},\"expr\":\"$1\",\"instant\":true}],\"from\":\"now-5m\",\"to\":\"now\"}" | python3 -c '
import sys,json; fr=json.load(sys.stdin)["results"]["A"]["frames"]
for f in fr:
    if len(f["schema"]["fields"])<2 or not f["data"]["values"][1]: print("   (no data for this query right now)"); continue
    lab=f["schema"]["fields"][1].get("labels",{}); print("  ", {k:lab[k] for k in lab if k in ("pod","path","job")}, "=>", f["data"]["values"][1][-1])'; }
x "echo 'sum(up{job=\"s20-metrics-app\"})'; q 'sum(up{job=\\\"s20-metrics-app\\\"})'"
x "echo 'CPU cores by pod'; q 'sum by (pod)(rate(container_cpu_usage_seconds_total{namespace=\\\"$NS\\\",container=\\\"app\\\"}[2m]))'"
x "echo 'memory working set by pod'; q 'sum by (pod)(container_memory_working_set_bytes{namespace=\\\"$NS\\\",container=\\\"app\\\"})'"
x "echo 'requests/s by path'; q 'sum by (path)(rate(http_requests_total{job=\\\"s20-metrics-app\\\"}[5m]))'"
hr "Screenshots (logged in through the API, session cookie handed to headless Chrome)"
curl -s -c /tmp/s20-grafana.cookie -X POST http://localhost:19300/login -H 'Content-Type: application/json' -d '{"user":"admin","password":"admin123"}' >/dev/null
GS=$(awk '$6=="grafana_session"{print $7}' /tmp/s20-grafana.cookie); rm -f /tmp/s20-grafana.cookie
node "$ME/scripts/shot.mjs" "http://localhost:19300/d/s20-kushal/?orgId=1&from=now-30m&to=now&kiosk" "$ME/screenshots/04-grafana-my-dashboard.png" "grafana_session=$GS" 9000
node "$ME/scripts/shot.mjs" "http://localhost:19300/d/6581e46e4e5c7ba40a07646395ef7b23/kubernetes-compute-resources-pod?orgId=1&var-namespace=$NS&var-pod=$(kubectl -n $NS get pod -l app=s20-metrics-app -o jsonpath='{.items[0].metadata.name}')&from=now-30m&to=now&kiosk" "$ME/screenshots/04-grafana-builtin-pod-dashboard.png" "grafana_session=$GS" 9000
x "curl -s -u $AUTH http://localhost:19300/api/dashboards/uid/s20-kushal | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d[\"meta\"][\"url\"], \"version\", d[\"dashboard\"][\"version\"], \"panels\", len(d[\"dashboard\"][\"panels\"]))'"
pf_stop
