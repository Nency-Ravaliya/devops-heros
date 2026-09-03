#!/usr/bin/env bash
# Build, run and smoke-test all six Hello World apps.
#   ./run-all.sh        build + run + check
#   ./run-all.sh down   stop and remove the containers
set -u
cd "$(dirname "$0")"

# folder:host_port:container_port
apps=(
  nodejs-app:3000:3000
  python-app:5000:5000
  java-app:8080:8080
  Apache-app:8081:80
  React-app:8082:80
  nginx-app:8083:80
)

name_for() { echo "hello-$(echo "$1" | tr '[:upper:]' '[:lower:]')"; }

if [[ "${1:-}" == "down" ]]; then
  for spec in "${apps[@]}"; do docker rm -f "$(name_for "${spec%%:*}")" >/dev/null 2>&1 && echo "removed $(name_for "${spec%%:*}")"; done
  exit 0
fi

for spec in "${apps[@]}"; do
  IFS=: read -r dir host_port ctr_port <<<"$spec"
  name=$(name_for "$dir")
  echo "==> $dir  (image $name, http://localhost:$host_port)"
  docker build -q -t "$name" "./$dir"
  docker rm -f "$name" >/dev/null 2>&1
  docker run -d --name "$name" -p "$host_port:$ctr_port" "$name" >/dev/null
done

sleep 3
echo; docker ps --filter "name=hello-" --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
echo
for spec in "${apps[@]}"; do
  IFS=: read -r dir host_port _ <<<"$spec"
  printf '%-12s http://localhost:%-5s -> ' "$dir" "$host_port"
  curl -s --max-time 5 "http://localhost:$host_port" | grep -o '<h1>[^<]*</h1>' || echo "(React renders <h1> client-side; check title:) $(curl -s http://localhost:$host_port | grep -o '<title>[^<]*</title>')"
done
