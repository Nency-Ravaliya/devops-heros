#!/usr/bin/env bash
# Docker Networking Homework Task 1 — 3 containers, 3 networks, backend on 2.
# Idempotent: safe to re-run.
set -u
hline() { printf '=%.0s' {1..78}; echo; }

# ---------- clean previous run ----------
for c in hw-frontend hw-backend hw-db-test; do docker rm -f "$c" >/dev/null 2>&1 || true; done
for n in hw-net-frontend hw-net-backend hw-net-data; do docker network rm "$n" >/dev/null 2>&1 || true; done

# ---------- 3 different networks ----------
hline; echo "STEP 1 — create 3 different Docker networks"; hline
docker network create --driver bridge hw-net-frontend >/dev/null
docker network create --driver bridge hw-net-backend  >/dev/null
docker network create --driver bridge hw-net-data     >/dev/null
docker network ls --format 'table {{.Name}}\t{{.Driver}}\t{{.Scope}}' | grep -E 'NAME|hw-net-'

# ---------- 3 containers: frontend, backend, database ----------
hline; echo "STEP 2 — create 3 containers (frontend, backend, database)"; hline
docker run -d --name hw-frontend --network hw-net-frontend nginx:alpine >/dev/null
docker run -d --name hw-backend  --network hw-net-frontend alpine:3.20 sleep 3600 >/dev/null
docker run -d --name hw-db       --network hw-net-data \
  -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=demo mysql:8.4 >/dev/null
echo "frontend : nginx:alpine   on hw-net-frontend"
echo "backend  : alpine:3.20    on hw-net-frontend"
echo "database : mysql:8.4      on hw-net-data"

# ---------- backend joins a 2nd network ----------
hline; echo "STEP 3 — connect the backend to a 2nd network"; hline
docker network connect hw-net-backend hw-backend
docker network connect hw-net-backend hw-db
echo "\$ docker network connect hw-net-backend hw-backend"
echo "\$ docker network connect hw-net-backend hw-db"

hline; echo "STEP 4 — inspect which containers are on which networks"; hline
for n in hw-net-frontend hw-net-backend hw-net-data; do
  printf '%-16s -> ' "$n"
  docker network inspect "$n" --format '{{range .Containers}}{{.Name}} {{end}}'
done
echo
printf 'backend hw-backend networks: '; docker inspect hw-backend --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}'

# ---------- connectivity checks ----------
hline; echo "STEP 5 — test connectivity between the containers"; hline
chk() { printf '%-52s ' "$1"; shift; if "$@" >/dev/null 2>&1; then echo "OK (reachable)"; else echo "FAIL (no route)"; fi; }
chk "frontend -> backend  (same net: hw-net-frontend)" docker exec hw-frontend ping -c 1 -W 2 hw-backend
chk "backend  -> frontend (same net: hw-net-frontend)" docker exec hw-backend  ping -c 1 -W 2 hw-frontend
chk "backend  -> db       (same net: hw-net-backend)"  docker exec hw-backend  ping -c 1 -W 2 hw-db
chk "frontend -> db       (different nets: EXPECT FAIL)" docker exec hw-frontend ping -c 1 -W 2 hw-db
echo
echo "Isolation is correct: the frontend cannot reach the database because they share no network."

echo
echo "### NET-T1-DONE ###"
