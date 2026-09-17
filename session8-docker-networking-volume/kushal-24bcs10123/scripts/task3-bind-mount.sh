#!/usr/bin/env bash
# Task 3: bind-mount a host folder into nginx and edit it live.
set -u
cd "$(dirname "$0")/../bind-mount"
docker run -d --name nginx-bind -p 8085:80 -v "$PWD/site:/usr/share/nginx/html:ro" nginx:alpine
sleep 2
curl -s http://localhost:8085
printf '<h1>Hello students</h1>\n<p>edited on the host at %s - no container restart</p>\n' "$(date +%T)" > site/index.html
curl -s http://localhost:8085
docker ps --filter name=nginx-bind --format '{{.Names}} {{.Status}}'
git checkout -- site/index.html 2>/dev/null || printf '<h1>Hello students</h1>\n' > site/index.html
