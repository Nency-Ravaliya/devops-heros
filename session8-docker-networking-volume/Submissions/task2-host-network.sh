#!/usr/bin/env bash
# Docker Networking Homework Task 2 — Apache2 container on the HOST network.
# With `--network host` the container shares the host's network namespace,
# so there is no -p mapping: the app is directly on the host's port 80.
set -u
hline() { printf '=%.0s' {1..78}; echo; }

docker rm -f hw-apache-host >/dev/null 2>&1 || true

hline; echo "STEP 1 — run Apache (httpd) with --network host"; hline
echo "\$ docker run -d --name hw-apache-host --network host httpd:alpine"
docker run -d --name hw-apache-host --network host httpd:alpine
sleep 3

hline; echo "STEP 2 — no port mapping (host network shares the host stack)"; hline
echo "\$ docker ps --filter name=hw-apache-host"; docker ps --filter name=hw-apache-host --format 'table {{.Names}}\t{{.Ports}}\t{{.Status}}'
echo; echo "\$ docker port hw-apache-host   (empty — nothing to map)"
docker port hw-apache-host || true
echo; echo "container NetworkMode: $(docker inspect hw-apache-host --format '{{.HostConfig.NetworkMode}}')"

hline; echo "STEP 3 — access the Apache website directly on port 80"; hline
for i in $(seq 1 20); do curl -sf --max-time 3 http://127.0.0.1:80/ >/dev/null 2>&1 && break; sleep 1; done
echo "\$ curl -s http://127.0.0.1:80/"
curl -s --max-time 8 http://127.0.0.1:80/
echo
echo
echo "### NET-T2-DONE ###"
