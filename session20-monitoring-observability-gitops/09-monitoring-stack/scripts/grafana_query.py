#!/usr/bin/env python3
"""Run the dashboard's stat-panel queries through Grafana's /api/ds/query
(i.e. exactly the path a dashboard panel uses: Grafana -> datasource -> Prometheus)."""
import base64, json, os, urllib.request

G = os.getenv("GRAFANA_URL", "http://localhost:3000")
auth = base64.b64encode(os.getenv("GRAFANA_AUTH", "admin:admin").encode()).decode()
dash = json.load(urllib.request.urlopen(urllib.request.Request(
    f"{G}/api/dashboards/uid/s20-demo-app", headers={"Authorization": f"Basic {auth}"})))["dashboard"]
queries = [{"refId": str(p["id"]), "datasource": {"uid": "prometheus"}, "expr": p["targets"][0]["expr"],
            "instant": True} for p in dash["panels"] if p["type"] == "stat"]
titles = {str(p["id"]): p["title"] for p in dash["panels"]}
req = urllib.request.Request(f"{G}/api/ds/query", method="POST",
                             data=json.dumps({"from": "now-5m", "to": "now", "queries": queries}).encode(),
                             headers={"Authorization": f"Basic {auth}", "Content-Type": "application/json"})
res = json.load(urllib.request.urlopen(req))["results"]
print(f"{'PANEL':<22}{'VALUE':>12}   HTTP status per query")
for ref, r in res.items():
    frames = r.get("frames", [])
    val = frames[0]["data"]["values"][1][0] if frames and frames[0]["data"]["values"] else None
    print(f"{titles[ref]:<22}{(f'{val:,.2f}' if val is not None else 'n/a'):>12}   {r.get('status')}")
