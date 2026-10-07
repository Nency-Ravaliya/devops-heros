#!/usr/bin/env bash
# Task 4: overlay network on a single-node swarm (needs swarm mode).
set -u
docker swarm init
docker network create -d overlay --attachable app-overlay
docker network inspect -f 'driver={{.Driver}} scope={{.Scope}} subnet={{(index .IPAM.Config 0).Subnet}}' app-overlay
docker service create -d --name web-svc --network app-overlay --replicas 2 nginx:alpine
sleep 6
docker service ls
docker service ps web-svc
docker run --rm --network app-overlay alpine:3.20 sh -c 'nslookup tasks.web-svc; wget -qO- http://web-svc | grep -o "<h1>.*</h1>"'
docker service rm web-svc && docker network rm app-overlay
docker swarm leave --force
