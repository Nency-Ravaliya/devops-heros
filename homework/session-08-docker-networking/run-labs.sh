#!/usr/bin/env bash
# Session 8 hands-on. Requires a running Docker daemon.
set -euo pipefail
cd "$(dirname "$0")"

echo "== Task 1: three networks, backend attached to two =="
docker compose up -d
docker network ls | grep hw- || true
echo "-- frontend can reach backend --"
docker exec hw-frontend ping -c 2 backend
echo "-- backend can reach database --"
docker exec hw-backend ping -c 2 database
echo "-- frontend cannot reach database (expected failure) --"
docker exec hw-frontend ping -c 2 database || true

echo "== Task 2: Apache on the host network =="
docker rm -f hw-apache-host >/dev/null 2>&1 || true
docker run -d --name hw-apache-host --network host httpd:2.4-alpine
echo "Open http://localhost and screenshot the Apache page."

echo "== Task 3: Nginx bind mount =="
docker rm -f hw-nginx-bind >/dev/null 2>&1 || true
docker run -d --name hw-nginx-bind -p 8088:80 \
  -v "$(pwd)/bind-mount:/usr/share/nginx/html:ro" \
  nginx:1.27-alpine
echo "Open http://localhost:8088 — page must say Hello students."
echo "Then edit bind-mount/index.html and refresh. Do not restart the container."

echo
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"
