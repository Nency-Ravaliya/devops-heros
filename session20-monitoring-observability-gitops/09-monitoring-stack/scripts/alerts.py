#!/usr/bin/env python3
"""Show alert state in Prometheus (inactive -> pending -> firing) and what
Alertmanager has received. usage: scripts/alerts.py [prom|am|all]"""
import json, os, sys, urllib.request

PROM = os.getenv("PROM_URL", "http://localhost:9090")
AM = os.getenv("AM_URL", "http://localhost:9093")
what = sys.argv[1] if len(sys.argv) > 1 else "all"
get = lambda u: json.load(urllib.request.urlopen(u, timeout=30))

if what in ("prom", "all"):
    alerts = get(f"{PROM}/api/v1/alerts")["data"]["alerts"]
    print(f"== Prometheus /api/v1/alerts ({len(alerts)} active)")
    for a in alerts:
        print(f"  {a['labels']['alertname']:<16} {a['state'].upper():<8} since {a['activeAt'][11:19]}Z"
              f"  {a['annotations'].get('summary', '')}")
if what in ("am", "all"):
    alerts = get(f"{AM}/api/v2/alerts")
    print(f"== Alertmanager /api/v2/alerts ({len(alerts)} received)")
    for a in alerts:
        print(f"  {a['labels']['alertname']:<16} {a['status']['state']:<11} severity={a['labels'].get('severity')}"
              f"  receivers={','.join(r['name'] for r in a['receivers'])}  startsAt={a['startsAt'][11:19]}Z")
