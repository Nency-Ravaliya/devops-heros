#!/bin/bash
# Session 7 - Dockerfiles & Images
#
# Task 1: builds and runs the multi-stage app on host port 8080.
# Task 3: builds and runs three different application types.
#
# Run: bash build-and-run-all.sh
# Remove them afterwards with: bash cleanup.sh

set -u

command -v docker >/dev/null 2>&1 || { echo "docker not found - start Docker Desktop"; exit 1; }
docker info >/dev/null 2>&1 || { echo "cannot reach the Docker daemon - is Docker Desktop running?"; exit 1; }

# app dir | image tag | container name | host port : container port
APPS=(
  "multi-stage-dockerfile|multi-stage-webapp|multi-stage-app|8080:3000"
  "node-app|node-webapp-v2|node-container-v2|8097:8080"
  "python-app|python-webapp-v2|python-container-v2|8098:8080"
  "java-app|java-webapp-v2|java-container-v2|8099:8080"
)

cd "$(dirname "$0")" || exit 1

for entry in "${APPS[@]}"; do
    IFS='|' read -r dir tag name ports <<< "$entry"

    echo
    echo "=============== $dir ==============="

    docker rm -f "$name" >/dev/null 2>&1

    host_port="${ports%%:*}"
    if ss -tln 2>/dev/null | grep -q ":$host_port "; then
        echo ">> host port $host_port is already in use - skipping $dir"
        continue
    fi

    echo "\$ docker build -t $tag ./$dir"
    docker build -t "$tag" "./$dir" || { echo ">> build failed for $dir"; continue; }

    echo
    echo "\$ docker run -d --name $name -p $ports $tag"
    docker run -d --name "$name" -p "$ports" "$tag" \
        || echo ">> RUN FAILED for $dir - is host port $host_port free?"
done

echo
echo "=============== docker ps ==============="
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'

echo
echo "=============== image sizes: session 7 (multi-stage) vs session 6 ==============="
docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' \
    | grep -E 'REPOSITORY|multi-stage-webapp|node-webapp|python-webapp|java-webapp'

echo
echo "waiting for the servers to come up..."
sleep 5

echo
echo "=============== curl each app ==============="
for entry in "${APPS[@]}"; do
    IFS='|' read -r dir tag name ports <<< "$entry"
    host_port="${ports%%:*}"
    printf '%-22s http://localhost:%s  ->  ' "$dir" "$host_port"
    curl -s --max-time 5 "http://localhost:$host_port" || echo "(no response yet)"
    echo
done

echo
echo "Open these in a browser:"
for entry in "${APPS[@]}"; do
    IFS='|' read -r dir tag name ports <<< "$entry"
    echo "  http://localhost:${ports%%:*}   $dir"
done
echo
echo "Clean up with: bash cleanup.sh"
