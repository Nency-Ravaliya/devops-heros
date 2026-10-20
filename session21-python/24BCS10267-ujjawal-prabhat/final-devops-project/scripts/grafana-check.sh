#!/usr/bin/env bash
# Verify the StockPilot dashboard was imported by the Grafana sidecar and that
# its panels return data. Expects: kubectl -n monitoring port-forward svc/kps-grafana 13000:80
set -uo pipefail
G="${GRAFANA:-http://localhost:13000}"
NS="${NS:-final}"
PASS=$(kubectl -n monitoring get secret kps-grafana -o jsonpath='{.data.admin-password}' | base64 -d)
AUTH="admin:$PASS"
PY=$(command -v python3.12 || command -v python3)

echo "\$ curl -s -u admin:*** '$G/api/search?tag=stockpilot'"
curl -s -u "$AUTH" "$G/api/search?tag=stockpilot" | "$PY" -m json.tool
echo
echo "\$ curl -s -u admin:*** $G/api/dashboards/uid/stockpilot-$NS  (panel list)"
curl -s -u "$AUTH" "$G/api/dashboards/uid/stockpilot-$NS" | "$PY" -c '
import json,sys
d=json.load(sys.stdin)["dashboard"]
print("  title:", d["title"])
for p in d["panels"]:
    print("  - [%s] %s" % (p["type"], p["title"]))'
echo
DS=$(curl -s -u "$AUTH" "$G/api/datasources" | "$PY" -c 'import json,sys;print([d["uid"] for d in json.load(sys.stdin) if d["type"]=="prometheus"][0])')
echo "Evaluating each panel query through Grafana's datasource proxy (datasource uid=$DS):"
curl -s -u "$AUTH" "$G/api/dashboards/uid/stockpilot-$NS" | "$PY" -c '
import json,sys,urllib.request,urllib.parse,base64
d=json.load(sys.stdin)["dashboard"]
auth=base64.b64encode(sys.argv[1].encode()).decode()
for p in d["panels"]:
    for t in p["targets"]:
        url=sys.argv[2]+"/api/datasources/proxy/uid/"+sys.argv[3]+"/api/v1/query?"+urllib.parse.urlencode({"query":t["expr"]})
        req=urllib.request.Request(url, headers={"Authorization":"Basic "+auth})
        res=json.load(urllib.request.urlopen(req))["data"]["result"]
        vals=", ".join("%s=%.3g" % (",".join(v for k,v in r["metric"].items()) or "value", float(r["value"][1])) for r in res[:4])
        print("  %-30s %-4s %d series  %s" % (p["title"][:30], t.get("legendFormat","")[:4], len(res), vals[:110]))
' "$AUTH" "$G" "$DS"
