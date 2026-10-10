#!/usr/bin/env bash
# 00-course-compose-demo: the course's own Prometheus and Grafana demos (03-prometheus, 04-grafana) run with
# docker compose on my Mac, before moving to the in-cluster stack.
. "$(dirname "$0")/lib.sh"
hr "03-prometheus: Prometheus scraping itself"
x "cat 03-prometheus/docker-compose.yml"
x "cat 03-prometheus/prometheus.yml"
x "docker compose -f 03-prometheus/docker-compose.yml up -d"
for _ in $(seq 1 30); do curl -s http://localhost:9090/-/ready | grep -q Ready && break; sleep 2; done; sleep 12   # let it scrape itself a couple of times
x "docker compose -f 03-prometheus/docker-compose.yml ps"
x "curl -s http://localhost:9090/-/ready"
x "curl -s http://localhost:9090/api/v1/targets | python3 -c 'import sys,json; [print(t[\"scrapeUrl\"], t[\"health\"], t[\"lastScrape\"][:19]) for t in json.load(sys.stdin)[\"data\"][\"activeTargets\"]]'"
x "curl -s 'http://localhost:9090/api/v1/query?query=up' | python3 -m json.tool | sed -n '1,20p'"
x "curl -s 'http://localhost:9090/api/v1/query?query=prometheus_http_requests_total' | python3 -c 'import sys,json; r=json.load(sys.stdin)[\"data\"][\"result\"]; print(len(r), \"series; e.g.\", r[0][\"metric\"][\"handler\"], r[0][\"value\"][1])'"
x "curl -s http://localhost:9090/metrics | grep -E '^(prometheus_build_info|process_resident_memory_bytes|go_goroutines)'"
node "$ME/scripts/shot.mjs" 'http://localhost:9090/graph?g0.expr=rate(prometheus_http_requests_total%5B1m%5D)&g0.tab=0&g0.range_input=5m' "$ME/screenshots/00-compose-prometheus-graph.png" '' 4000
x "docker compose -f 03-prometheus/docker-compose.yml down"

hr "04-grafana: Prometheus + Grafana"
x "cat 04-grafana/docker-compose.yml"
x "cat $ME/00-compose/grafana-port-override.yml"
x "docker compose -f 04-grafana/docker-compose.yml -f $ME/00-compose/grafana-port-override.yml up -d"
for _ in $(seq 1 30); do curl -s http://localhost:19301/api/health | grep -q '"database": *"ok"' && break; sleep 2; done
x "docker compose -f 04-grafana/docker-compose.yml -f $ME/00-compose/grafana-port-override.yml ps"
x "curl -s http://localhost:19301/api/health"
x "curl -s -u admin:admin -X POST http://localhost:19301/api/datasources -H 'Content-Type: application/json' -d '{\"name\":\"Prometheus\",\"type\":\"prometheus\",\"url\":\"http://prometheus:9090\",\"access\":\"proxy\",\"isDefault\":true}'; echo"
x "curl -s -u admin:admin http://localhost:19301/api/datasources | python3 -c 'import sys,json; [print(d[\"uid\"], d[\"type\"], d[\"url\"]) for d in json.load(sys.stdin)]'"
DSUID=$(curl -s -u admin:admin http://localhost:19301/api/datasources | python3 -c 'import sys,json; print(json.load(sys.stdin)[0]["uid"])')
for _ in $(seq 1 20); do curl -s -u admin:admin "http://localhost:19301/api/datasources/proxy/uid/$DSUID/api/v1/query?query=up" | grep -q '"value"' && break; sleep 3; done
x "curl -s -u admin:admin 'http://localhost:19301/api/datasources/proxy/uid/$DSUID/api/v1/query?query=up' | python3 -m json.tool | sed -n '1,16p'    # Grafana -> Prometheus, through Grafana's datasource proxy"
x "curl -s -u admin:admin -X POST http://localhost:19301/api/ds/query -H 'Content-Type: application/json' -d '{\"queries\":[{\"refId\":\"A\",\"datasource\":{\"uid\":\"$DSUID\"},\"expr\":\"up\",\"instant\":true,\"intervalMs\":15000,\"maxDataPoints\":100}],\"from\":\"now-5m\",\"to\":\"now\"}' | python3 -c 'import sys,json; fr=json.load(sys.stdin)[\"results\"][\"A\"][\"frames\"]; print(len(fr), \"frame(s)\"); [print(\"  \", f[\"schema\"][\"fields\"][1].get(\"labels\"), \"=>\", f[\"data\"][\"values\"][1][-1]) if len(f[\"schema\"][\"fields\"])>1 else print(\"   (empty frame)\") for f in fr]'"
curl -s -c /tmp/s20-grafana-compose.cookie -X POST http://localhost:19301/login -H 'Content-Type: application/json' -d '{"user":"admin","password":"admin"}' >/dev/null
GS=$(awk '$6=="grafana_session"{print $7}' /tmp/s20-grafana-compose.cookie)
node "$ME/scripts/shot.mjs" "http://localhost:19301/explore?schemaVersion=1&panes=%7B%22a%22:%7B%22datasource%22:%22$DSUID%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22expr%22:%22rate(prometheus_http_requests_total%5B1m%5D)%22%7D%5D,%22range%22:%7B%22from%22:%22now-5m%22,%22to%22:%22now%22%7D%7D%7D" "$ME/screenshots/00-compose-grafana-explore.png" "grafana_session=$GS" 7000
rm -f /tmp/s20-grafana-compose.cookie
x "docker compose -f 04-grafana/docker-compose.yml -f $ME/00-compose/grafana-port-override.yml down -v"
x "docker ps --filter name=session20 --format '{{.Names}}' | wc -l"
