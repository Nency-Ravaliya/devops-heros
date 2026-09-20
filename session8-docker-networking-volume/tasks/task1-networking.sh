#!/bin/bash
# Session 8 - Task 1: Docker Container Networking
#
# Three containers, three networks, backend attached to two of them, then
# connectivity checks proving which containers can reach which.
#
# Run: bash task1-networking.sh

set -u

command -v docker >/dev/null 2>&1 || { echo "docker not found"; exit 1; }
docker info >/dev/null 2>&1 || { echo "cannot reach the Docker daemon"; exit 1; }

run() { echo; echo "\$ $*"; "$@"; }

echo "############### CLEANUP FROM ANY EARLIER RUN ###############"
docker rm -f frontend backend database >/dev/null 2>&1
docker network rm frontend-net backend-net database-net >/dev/null 2>&1
echo "done"

echo
echo "############### STEP 1: create three networks ###############"
# No --driver given, so each uses the default: bridge. A user-defined bridge
# differs from the built-in one in a way that matters here - it provides
# automatic DNS between containers, so they can reach each other by name.
run docker network create frontend-net
run docker network create backend-net
run docker network create database-net
run docker network ls

echo
echo "############### STEP 2: start the three containers ###############"
# -d detached, -i keeps stdin open, -t allocates a TTY. alpine needs -it or
# its shell exits immediately and the container stops.
run docker run -dit --name frontend --network frontend-net nginx
run docker run -dit --name backend  --network backend-net  alpine
run docker run -dit --name database --network database-net -e MYSQL_ROOT_PASSWORD=root mysql:8.0
run docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'

echo
echo "############### STEP 3: attach backend to a SECOND network ###############"
# A container can be on several networks at once, getting one IP per network.
# This is how a middle tier talks to both sides while keeping them apart.
run docker network connect frontend-net backend

echo
echo "backend is now on two networks:"
run docker inspect backend --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} -> {{$conf.IPAddress}}{{"\n"}}{{end}}'

echo
echo "############### STEP 4: connectivity checks ###############"

echo
echo "--- backend -> frontend (SAME network frontend-net: expected to WORK) ---"
docker exec backend ping -c 2 frontend || echo ">> unexpected failure"

echo
echo "--- backend -> database (DIFFERENT networks: expected to FAIL) ---"
docker exec backend ping -c 2 database || echo ">> unreachable, as expected - no shared network"

# The nginx image ships no ping, so these two use getent instead. getent asks
# the container's own resolver for a name, which is the thing being tested: a
# user-defined bridge network resolves the names of containers ON that network
# and nothing else. Resolving proves a shared network; failing to resolve
# proves there is none.
echo
echo "--- frontend -> backend (SAME network frontend-net: expected to RESOLVE) ---"
echo "\$ docker exec frontend getent hosts backend"
docker exec frontend getent hosts backend     && echo ">> resolved - frontend and backend share frontend-net"     || echo ">> unexpected failure"

echo
echo "--- frontend -> database (DIFFERENT networks: expected to NOT RESOLVE) ---"
echo "\$ docker exec frontend getent hosts database"
docker exec frontend getent hosts database     && echo ">> unexpected: resolved"     || echo ">> did not resolve, as expected - no shared network, so the name does not exist here"

echo
echo "############### STEP 5: inspect a network ###############"
run docker network inspect frontend-net --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'

echo
echo "Containers left running. Remove with:"
echo "  docker rm -f frontend backend database"
echo "  docker network rm frontend-net backend-net database-net"
