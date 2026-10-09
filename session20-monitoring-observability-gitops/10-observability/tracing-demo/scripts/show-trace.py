#!/usr/bin/env python3
"""Print Jaeger traces as an indented span tree (stdlib only).

Uses Jaeger's HTTP query API (the same API the Jaeger UI uses):
  GET /api/services
  GET /api/traces?service=frontend&limit=N[&tags=..][&minDuration=..]
  GET /api/traces/<traceID>

Examples:
  scripts/show-trace.py --services
  scripts/show-trace.py --list --limit 5
  scripts/show-trace.py --latest
  scripts/show-trace.py --error            # newest trace containing an error span
  scripts/show-trace.py --slow 1s          # newest trace slower than 1s
  scripts/show-trace.py --trace-id 4bf92f3577b34da6a3ce929d0e0e4736
"""
import argparse
import json
import sys
import urllib.parse
import urllib.request

JAEGER = "http://localhost:16686"


def get(path, **params):
    qs = ("?" + urllib.parse.urlencode(params)) if params else ""
    with urllib.request.urlopen(f"{JAEGER}{path}{qs}", timeout=5) as r:
        return json.load(r)


def tags(span):
    return {t["key"]: t["value"] for t in span.get("tags", [])}


def is_error(span):
    t = tags(span)
    return t.get("error") is True or t.get("otel.status_code") == "ERROR"


def fmt_ms(us):
    return f"{us / 1000:8.1f} ms"


def print_tree(tr):
    spans = {s["spanID"]: s for s in tr["spans"]}
    procs = tr["processes"]
    children, roots = {}, []
    for s in tr["spans"]:
        parent = next((r["spanID"] for r in s.get("references", [])
                       if r["refType"] == "CHILD_OF" and r["spanID"] in spans), None)
        s["_parent"] = parent
        (children.setdefault(parent, []) if parent else roots).append(s)
    t0 = min(s["startTime"] for s in tr["spans"])
    total = max(s["startTime"] + s["duration"] for s in tr["spans"]) - t0
    services = sorted({procs[s["processID"]]["serviceName"] for s in tr["spans"]})
    print(f"trace_id={tr['traceID']}  spans={len(spans)}  "
          f"services={','.join(services)}  total={total / 1000:.1f} ms")
    print(f"{'SERVICE':10} {'OPERATION':38} {'DURATION':>11} {'START+':>9}  "
          f"{'SPAN_ID':16} {'PARENT':16} STATUS")

    def walk(s, depth):
        svc = procs[s["processID"]]["serviceName"]
        op = ("  " * depth + ("└─ " if depth else "") + s["operationName"])[:38]
        status = "ERROR" if is_error(s) else "ok"
        extra = ""
        if is_error(s):
            msg = tags(s).get("otel.status_description")
            extra = f"  ({msg})" if msg else ""
        print(f"{svc:10} {op:38} {fmt_ms(s['duration']):>11} "
              f"{(s['startTime'] - t0) / 1000:7.1f}ms  {s['spanID']:16} "
              f"{(s['_parent'] or '-'):16} {status}{extra}")
        for c in sorted(children.get(s["spanID"], []), key=lambda x: x["startTime"]):
            walk(c, depth + 1)

    for r in sorted(roots, key=lambda x: x["startTime"]):
        walk(r, 0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--service", default="frontend")
    ap.add_argument("--limit", type=int, default=20)
    ap.add_argument("--services", action="store_true", help="list services")
    ap.add_argument("--list", action="store_true", help="one line per trace")
    ap.add_argument("--latest", action="store_true")
    ap.add_argument("--error", action="store_true")
    ap.add_argument("--slow", metavar="DUR", help="e.g. 1s, 500ms")
    ap.add_argument("--trace-id")
    a = ap.parse_args()

    if a.services:
        for s in get("/api/services")["data"] or []:
            print(s)
        return
    if a.trace_id:
        print_tree(get(f"/api/traces/{a.trace_id}")["data"][0])
        return

    params = {"service": a.service, "limit": a.limit, "lookback": "1h"}
    if a.slow:
        params["minDuration"] = a.slow
    traces = get("/api/traces", **params)["data"] or []
    traces.sort(key=lambda t: min(s["startTime"] for s in t["spans"]), reverse=True)
    if a.error:
        traces = [t for t in traces if any(is_error(s) for s in t["spans"])]
    elif a.slow:  # "slow but successful" - errors have their own flag
        traces = [t for t in traces if not any(is_error(s) for s in t["spans"])]
    if not traces:
        sys.exit("no matching traces")

    if a.list:
        print(f"{'TRACE_ID':32} {'SPANS':>5} {'DURATION':>11}  ROOT / STATUS")
        for t in traces:
            root = min(t["spans"], key=lambda s: s["startTime"])
            err = "ERROR" if any(is_error(s) for s in t["spans"]) else "ok"
            print(f"{t['traceID']:32} {len(t['spans']):5} {fmt_ms(root['duration']):>11}"
                  f"  {root['operationName']} [{err}]")
        return
    print_tree(traces[0])


if __name__ == "__main__":
    main()
