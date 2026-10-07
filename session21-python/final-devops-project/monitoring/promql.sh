#!/usr/bin/env bash
# Run an instant PromQL query against the Prometheus HTTP API and print one line per series.
# usage: PROM=http://localhost:9090 ./monitoring/promql.sh '<query>'
#   (first: kubectl -n monitoring port-forward svc/prometheus-server 9090:80 &)
set -euo pipefail
PROM="${PROM:-http://localhost:9090}"
curl -s --get "$PROM/api/v1/query" --data-urlencode "query=$1" | python3 -c '
import json, sys
r = json.load(sys.stdin)
if r.get("status") != "success":
    sys.exit("error: " + r.get("error", "unknown"))
res = r["data"]["result"]
if not res:
    print("(no data)")
for s in res:
    m = s["metric"]
    name = m.pop("__name__", "")
    q = chr(34)
    labels = ",".join(k + "=" + q + v + q for k, v in sorted(m.items()))
    val = float(s["value"][1])
    print(f"{name}{{{labels}}}  =>  {val:.4g}")
'
