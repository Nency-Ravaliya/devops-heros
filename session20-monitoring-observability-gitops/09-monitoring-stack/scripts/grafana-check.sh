#!/usr/bin/env bash
# Verify Grafana provisioning through its HTTP API (no browser needed).
set -euo pipefail
G="${GRAFANA_URL:-http://localhost:3000}"; AUTH="${GRAFANA_AUTH:-admin:admin}"
py() { python3 -c "$1"; }
echo "== health";       curl -s "$G/api/health" | py 'import json,sys; d=json.load(sys.stdin); print(" database:", d["database"], " version:", d["version"])'
echo "== datasources";  curl -s -u "$AUTH" "$G/api/datasources" | py 'import json,sys; [print(f" {d["name"]} ({d["type"]}) uid={d["uid"]} url={d["url"]} default={d["isDefault"]}") for d in json.load(sys.stdin)]'
echo "== datasource health"; curl -s -u "$AUTH" "$G/api/datasources/uid/prometheus/health" | py 'import json,sys; d=json.load(sys.stdin); print(" ", d["status"], "-", d["message"])'
echo "== dashboards";   curl -s -u "$AUTH" "$G/api/search?type=dash-db" | py 'import json,sys; [print(f" [{d.get("folderTitle","General")}] {d["title"]}  {d["url"]}") for d in json.load(sys.stdin)]'
echo "== panels in s20-demo-app"; curl -s -u "$AUTH" "$G/api/dashboards/uid/s20-demo-app" | py 'import json,sys; [print(f"  {p["id"]:>2}. {p["type"]:<10} {p["title"]}") for p in json.load(sys.stdin)["dashboard"]["panels"]]'
