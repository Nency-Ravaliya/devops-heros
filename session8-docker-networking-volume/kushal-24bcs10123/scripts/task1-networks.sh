#!/usr/bin/env bash
# Task 1: three containers on three user-defined bridge networks; the backend sits on two of them.
set -u
docker network create ui-net
docker network create api-net
docker network create data-net

docker run -d --name web-ui   --network ui-net nginx:alpine                         # frontend
docker run -d --name api-svc  --network ui-net alpine:3.20 sleep infinity           # backend
docker network connect data-net api-svc                                             # backend joins a 2nd network
docker run -d --name db-mysql --network data-net -e MYSQL_ROOT_PASSWORD=secret -e MYSQL_DATABASE=appdb mysql:8.0

sleep 25
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Networks}}'
docker inspect -f '{{.Name}}: {{range $k,$v := .NetworkSettings.Networks}}{{$k}}={{$v.IPAddress}} {{end}}' web-ui api-svc db-mysql

echo "--- backend can reach both"
docker exec api-svc ping -c 2 -W 1 web-ui
docker exec api-svc ping -c 2 -W 1 db-mysql
docker exec api-svc nc -zv -w 3 db-mysql 3306
echo "--- frontend cannot see the database"
docker exec web-ui ping -c 2 -W 1 db-mysql || true
docker exec web-ui nslookup db-mysql || true
echo "--- database cannot see the frontend"
docker exec db-mysql bash -c 'getent hosts api-svc; getent hosts web-ui || echo "web-ui: not resolvable"'
