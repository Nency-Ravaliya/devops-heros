#!/usr/bin/env bash
# Docker Networking Homework Task 3 — bind mount an index.html into Nginx and
# prove that editing the file on the host is reflected WITHOUT restarting.
set -u
DIR="$(dirname "$0")/../bind_mount_demo"
mkdir -p "$DIR"
hline() { printf '=%.0s' {1..78}; echo; }

docker rm -f hw-bind >/dev/null 2>&1 || true

hline; echo "STEP 1 — host folder + index.html containing 'Hello students'"; hline
echo '<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Bind mount</title></head>
<body><h1>Hello students</h1></body></html>' > "$DIR/index.html"
ls -l "$DIR"
echo "content before:"; cat "$DIR/index.html"

hline; echo "STEP 2 — bind mount the folder into an Nginx container"; hline
echo "\$ docker run -d --name hw-bind -p 8085:80 -v $DIR:/usr/share/nginx/html:ro nginx:alpine"
docker run -d --name hw-bind -p 8085:80 -v "$DIR":/usr/share/nginx/html:ro nginx:alpine >/dev/null
sleep 2
echo "\$ docker inspect hw-bind --format '{{json .Mounts}}'"
docker inspect hw-bind --format '{{range .Mounts}}{{.Source}} -> {{.Destination}} ({{.Mode}}){{end}}'

hline; echo "STEP 3 — verify the website shows the mounted content"; hline
printf 'BEFORE  ->  '; curl -s --max-time 8 http://127.0.0.1:8085/ | grep -io 'Hello students[^<]*'

hline; echo "STEP 4 — modify index.html on the host (container NOT restarted)"; hline
echo '<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Bind mount</title></head>
<body><h1>Hello students - updated live, no container restart!</h1></body></html>' > "$DIR/index.html"
echo "wrote new content at $(date '+%T')"
sleep 1

hline; echo "STEP 5 — verify the change is live immediately"; hline
printf 'AFTER   ->  '; curl -s --max-time 8 http://127.0.0.1:8085/ | grep -io 'Hello students[^<]*'
echo
echo "The container was never restarted (still: $(docker inspect -f '{{.State.StartedAt}}' hw-bind))"

echo
echo "### NET-T3-DONE ###"
