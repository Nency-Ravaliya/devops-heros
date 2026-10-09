#!/bin/bash
# Session 6 - Docker Fundamentals
# Builds all six Hello World images and runs all six containers at once.
#
# Run: bash build-and-run-all.sh
# Stop and remove them afterwards with: bash cleanup.sh
#
# Each app gets its own host port so they can all run together - one docker ps
# shows every container, and all six pages can be opened side by side.

set -u

command -v docker >/dev/null 2>&1 || { echo "docker not found - start Docker Desktop"; exit 1; }
docker info >/dev/null 2>&1 || { echo "cannot reach the Docker daemon - is Docker Desktop running?"; exit 1; }

# app dir | image tag | container name | host port : container port
# Ports start at 8091 to stay clear of anything already published on this
# machine - 80, 8081 and 5433 are taken by other containers here.
APPS=(
  "node-app|node-webapp|node-container|8091:8080"
  "python-app|python-webapp|python-container|8092:8080"
  "java-app|java-webapp|java-container|8093:8080"
  "apache-app|apache-webapp|apache-container|8094:80"
  "react-app|react-webapp|react-container|8095:80"
  "nginx-app|nginx-webapp|nginx-container|8096:80"
)

cd "$(dirname "$0")" || exit 1

for entry in "${APPS[@]}"; do
    IFS='|' read -r dir tag name ports <<< "$entry"

    echo
    echo "=============== $dir ==============="

    # Remove any container left over from an earlier run, so the script is
    # safe to re-run. -f also stops it if it is still up.
    docker rm -f "$name" >/dev/null 2>&1

    echo "\$ docker build -t $tag ./$dir"
    docker build -t "$tag" "./$dir" || { echo ">> build failed for $dir"; continue; }

    # Refuse to start if something else already holds the host port - otherwise
    # docker run fails and the curl further down silently hits the other service.
    host_port="${ports%%:*}"
    if ss -tln 2>/dev/null | grep -q ":$host_port "; then
        echo ">> host port $host_port is already in use - skipping $dir"
        continue
    fi

    echo
    echo "\$ docker run -d --name $name -p $ports $tag"
    docker run -d --name "$name" -p "$ports" "$tag"         || echo ">> RUN FAILED for $dir - is host port $host_port free?"
done

echo
echo "=============== docker ps ==============="
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'

echo
echo "=============== docker images ==============="
docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' \
    | grep -E 'REPOSITORY|node-webapp|python-webapp|java-webapp|apache-webapp|react-webapp|nginx-webapp'

# Give the slower runtimes a moment to finish starting before curling them.
echo
echo "waiting for the servers to come up..."
sleep 5

echo
echo "=============== curl each app ==============="
for entry in "${APPS[@]}"; do
    IFS='|' read -r dir tag name ports <<< "$entry"
    host_port="${ports%%:*}"
    printf '%-12s http://localhost:%s  ->  ' "$dir" "$host_port"
    curl -s --max-time 5 "http://localhost:$host_port" || echo "(no response yet)"
    echo
done

echo
echo "All six are running. Open these in a browser:"
for entry in "${APPS[@]}"; do
    IFS='|' read -r dir tag name ports <<< "$entry"
    echo "  http://localhost:${ports%%:*}   $dir"
done
echo
echo "Clean up with: bash cleanup.sh"
