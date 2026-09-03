#!/usr/bin/env bash
# Task 2: Apache on the host network (no -p needed).
set -u
docker pull httpd:2.4
docker run -d --name apache-host --network host httpd:2.4
sleep 3
docker ps --filter name=apache-host --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Networks}}'
# On Linux this is enough:
curl -s http://localhost:80 || echo "(macOS: 'host' is the Docker Desktop VM, see README)"
# Works everywhere: look at port 80 from inside the same (host) network namespace
docker run --rm --network host alpine:3.20 sh -c 'netstat -ltn | grep ":80 "; wget -qO- http://localhost:80'
