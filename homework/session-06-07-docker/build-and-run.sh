#!/usr/bin/env bash
# Build and run every Session 6/7 Hello World container on its own host port.
set -euo pipefail
cd "$(dirname "$0")"

build_and_run() {
  local name="$1" dir="$2" host_port="$3" container_port="$4"
  docker build -t "homework-${name}:local" "$dir"
  docker rm -f "homework-${name}" >/dev/null 2>&1 || true
  docker run -d --name "homework-${name}" -p "${host_port}:${container_port}" "homework-${name}:local"
}

build_and_run nodejs nodejs-app 3001 3000
build_and_run python python-app 5001 5000
build_and_run java java-app 8081 8080
build_and_run apache Apache-app 8082 80
build_and_run react React-app 8083 80
build_and_run nginx nginx-app 8084 80
build_and_run multistage multi-stage-app 8080 8080

echo
docker ps --filter "name=homework-" --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"
echo
echo "Open these URLs and screenshot each page plus the docker ps table above:"
echo "  http://localhost:3001  Node.js"
echo "  http://localhost:5001  Python"
echo "  http://localhost:8081  Java"
echo "  http://localhost:8082  Apache"
echo "  http://localhost:8083  React"
echo "  http://localhost:8084  Nginx"
echo "  http://localhost:8080  Multi-stage (must say: Hello World from Docker multi-stage build)"
