#!/bin/bash
# Session 8 - Task 2: Host Network
#
# Pull the Apache2 (httpd) image, run it on the host network, reach it on port 80.
#
# Run: bash task2-host-network.sh
#
# CAVEAT - Docker Desktop. On native Linux, --network host puts the container
# directly in the host's network namespace: no -p flag, no NAT, the container
# binds the host's port 80 itself. On Docker Desktop (Windows/macOS) the
# containers run inside a Linux VM, so "host" means that VM, not Windows. The
# port is only reachable from the host if Docker Desktop's host networking
# feature is switched on in Settings -> Resources -> Network.

set -u

command -v docker >/dev/null 2>&1 || { echo "docker not found"; exit 1; }
docker info >/dev/null 2>&1 || { echo "cannot reach the Docker daemon"; exit 1; }

run() { echo; echo "\$ $*"; "$@"; }

docker rm -f apache-host >/dev/null 2>&1

echo "############### STEP 1: pull the Apache2 image ###############"
# The official Apache HTTP Server image on Docker Hub is called httpd.
run docker pull httpd:latest

echo
echo "############### STEP 2: is port 80 free? ###############"
if ss -tln 2>/dev/null | grep -q ':80 '; then
    echo ">> WARNING: something is already listening on port 80:"
    ss -tlnp 2>/dev/null | grep ':80 '
    echo ">> Free it first, e.g.:  docker rm -f typeahead-frontend"
    echo ">> Continuing anyway - the container may start but be unreachable."
else
    echo "port 80 is free"
fi

echo
echo "############### STEP 3: run Apache on the host network ###############"
# Note there is no -p flag. With --network host there is nothing to publish:
# the container is not behind a NAT, so it binds port 80 directly.
run docker run -d --name apache-host --network host httpd:latest

sleep 3
run docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 

echo
echo "Note the empty PORTS column - there is no mapping, because there is no"
echo "NAT to map through. That is the signature of host networking."

echo
echo "############### STEP 4: reach it on port 80 ###############"
echo
echo "\$ curl -s http://localhost:80"
curl -s --max-time 5 http://localhost:80 || echo ">> no response on the host - see the Docker Desktop caveat in the README"

echo
echo "--- from inside the container's own namespace ---"
docker exec apache-host curl -s --max-time 5 http://localhost:80 2>/dev/null \
    || echo "(curl is not installed in the httpd image - checking with the logs instead)"
run docker logs --tail 5 apache-host

echo
echo "Remove with: docker rm -f apache-host"
