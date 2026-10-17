#!/usr/bin/env bash
# Dockerfiles & Images Task 3 — deploy 3 different application types with Docker.
set -u
hline() { printf '=%.0s' {1..78}; echo; }

hline; echo "TASK 3 — 3 application types deployed with Docker"; hline
echo "Node.js, Python and Java each built as an image and run as a container."
echo
docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | grep -E 'REPOSITORY|^hw-(nodejs|python|java)$'

echo
hline; echo "RUNNING CONTAINERS"; hline
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}' | grep -E 'NAMES|^hw-(nodejs|python|java)'

echo
hline; echo "LIVE RESPONSES"; hline
printf '%-22s ' "nodejs (:3001)"; curl -s --max-time 8 http://127.0.0.1:3001/ | grep -io 'Hello World from [A-Za-z.]*'
printf '%-22s ' "python (:5001)"; curl -s --max-time 8 http://127.0.0.1:5001/ | grep -io 'Hello World from [A-Za-z.]*'
printf '%-22s ' "java   (:8081)"; curl -s --max-time 8 http://127.0.0.1:8081/ | grep -io 'Hello World from [A-Za-z.]*'

echo
echo "### THREE-APPS-DONE ###"
