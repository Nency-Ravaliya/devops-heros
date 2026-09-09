#!/bin/bash
# Session 8 - Task 3: Bind Mount
#
# A folder on the host is mounted into an nginx container, the page is served,
# the file is edited on the host, and the change appears without restarting
# or rebuilding anything.
#
# Run: bash task3-bind-mount.sh

set -u

command -v docker >/dev/null 2>&1 || { echo "docker not found"; exit 1; }
docker info >/dev/null 2>&1 || { echo "cannot reach the Docker daemon"; exit 1; }

run() { echo; echo "\$ $*"; "$@"; }

cd "$(dirname "$0")" || exit 1
SITE_DIR="$(pwd)/site"
HOST_PORT=8100

docker rm -f bind-nginx >/dev/null 2>&1

echo "############### STEP 1: create the folder and index.html ###############"
mkdir -p "$SITE_DIR"
echo "<h1>Hello students</h1>" > "$SITE_DIR/index.html"
run cat "$SITE_DIR/index.html"
echo
echo "Host folder: $SITE_DIR"

echo
echo "############### STEP 2: bind mount it into nginx ###############"
# -v <host path>:<container path> is a bind mount: the host directory is
# mounted straight into the container. The host path must be absolute -
# a relative path would be read as a named volume instead.
run docker run -d --name bind-nginx -p "$HOST_PORT:80" \
    -v "$SITE_DIR:/usr/share/nginx/html" nginx

sleep 3
run docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'

echo
echo "############### STEP 3: read the page ###############"
echo
echo "\$ curl -s http://localhost:$HOST_PORT"
curl -s --max-time 5 "http://localhost:$HOST_PORT"

echo
echo "############### STEP 4: edit the file ON THE HOST ###############"
echo "<h1>Hello students - edited on the host, no restart</h1>" > "$SITE_DIR/index.html"
run cat "$SITE_DIR/index.html"

echo
echo "The container has NOT been restarted:"
run docker ps --format 'table {{.Names}}\t{{.Status}}'

echo
echo "############### STEP 5: read the page again ###############"
echo
echo "\$ curl -s http://localhost:$HOST_PORT"
curl -s --max-time 5 "http://localhost:$HOST_PORT"

echo
echo "############### STEP 6: the container sees the same file ###############"
run docker exec bind-nginx cat /usr/share/nginx/html/index.html
run docker exec bind-nginx ls -l /usr/share/nginx/html

echo
echo "Open http://localhost:$HOST_PORT in a browser."
echo "Remove with: docker rm -f bind-nginx"
