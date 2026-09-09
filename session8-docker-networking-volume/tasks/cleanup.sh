#!/bin/bash
# Removes everything the three task scripts create.

set -u

docker rm -f frontend backend database apache-host bind-nginx 2>/dev/null
docker network rm frontend-net backend-net database-net 2>/dev/null

echo
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
echo
docker network ls
