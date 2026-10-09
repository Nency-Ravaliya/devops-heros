#!/usr/bin/env python3
"""Run an instant PromQL query against Prometheus' HTTP API and print it as a table.
usage: scripts/promql.py '<expr>' [label,label,...]
  e.g. scripts/promql.py 'up' job
       scripts/promql.py 'sum by (endpoint,status) (rate(http_requests_total[1m]))'
PROM_URL defaults to http://localhost:9090 (stdlib only, no jq needed)."""
import json, os, sys, urllib.parse, urllib.request

prom = os.getenv("PROM_URL", "http://localhost:9090")
expr = sys.argv[1]
keep = sys.argv[2].split(",") if len(sys.argv) > 2 else None
url = f"{prom}/api/v1/query?" + urllib.parse.urlencode({"query": expr})
data = json.load(urllib.request.urlopen(url, timeout=30))
if data["status"] != "success":
    sys.exit(f"error: {data.get('error')}")
res = data["data"]["result"]
if not res:
    print("(empty result)")
for r in res:
    m = {k: v for k, v in r["metric"].items() if keep is None or k in keep}
    labels = ", ".join(f'{k}="{v}"' for k, v in sorted(m.items()))
    v = float(r["value"][1])
    print(f"{{{labels}}}".ljust(60), f"{v:,.4f}".rstrip("0").rstrip("."))
