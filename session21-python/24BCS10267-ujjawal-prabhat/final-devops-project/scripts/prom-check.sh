#!/usr/bin/env bash
# Query Prometheus (kube-prometheus-stack) for StockPilot metrics, targets and
# alert rules. Expects: kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 19090:9090
set -uo pipefail
P="${PROM:-http://localhost:19090}"
NS="${NS:-final}"
PY=$(command -v python3.12 || command -v python3)

q() {
  echo "\$ curl -s $P/api/v1/query --data-urlencode 'query=$1'"
  curl -s "$P/api/v1/query" --data-urlencode "query=$1" | "$PY" -c '
import json,sys
d=json.load(sys.stdin)
for r in d["data"]["result"]:
    m=r["metric"]; v=r["value"][1]
    lbl=",".join(f"{k}=\"{m[k]}\"" for k in sorted(m) if k in ("pod","route","status","job","direction","__name__","alertname","alertstate","severity"))
    print(f"  {{{lbl}}} => {v}")
print("  (%d series)" % len(d["data"]["result"]))'
  echo
}

echo "\$ curl -s $P/api/v1/targets  (filtered: namespace=$NS)"
curl -s "$P/api/v1/targets?state=active" | "$PY" -c '
import json,sys
for t in json.load(sys.stdin)["data"]["activeTargets"]:
    if t["labels"].get("namespace")=="'"$NS"'":
        print("  ", t["scrapePool"], t["scrapeUrl"], "health="+t["health"], "lastScrape="+t["lastScrape"][:19])'
echo
q "up{namespace=\"$NS\"}"
q "sum by (route) (rate(stockpilot_http_requests_total{namespace=\"$NS\"}[2m]))"
q "histogram_quantile(0.95, sum by (le) (rate(stockpilot_http_request_duration_seconds_bucket{namespace=\"$NS\"}[5m])))"
q "max(stockpilot_low_stock_items{namespace=\"$NS\"})"
q "sum by (direction) (stockpilot_stock_adjustments_total{namespace=\"$NS\"})"
q "stockpilot:http_requests:rate5m{namespace=\"$NS\",status=\"200\"}"

echo "\$ curl -s $P/api/v1/rules  (group stockpilot.rules)"
curl -s "$P/api/v1/rules" | "$PY" -c '
import json,sys
for g in json.load(sys.stdin)["data"]["groups"]:
    if g["name"]=="stockpilot.rules" and "'"$NS"'" in g["file"]:
        print("  file:", g["file"])
        for r in g["rules"]:
            print("  - %-9s %-28s health=%-3s state=%s" % (r["type"], r.get("name"), r["health"], r.get("state","-")))'
echo
echo "\$ curl -s $P/api/v1/alerts  (StockPilot alerts)"
curl -s "$P/api/v1/alerts" | "$PY" -c '
import json,sys
for a in json.load(sys.stdin)["data"]["alerts"]:
    if a["labels"]["alertname"].startswith("StockPilot"):
        print("  ", a["labels"]["alertname"], a["labels"].get("namespace",""), a["state"], "value="+a["value"], "-", a["annotations"].get("description",""))'
