#!/usr/bin/env bash
# 02: build the image locally and smoke test it like the "cd" job does on the runner.
. "$(dirname "$0")/lib.sh"
cd unit-converter
x "docker build --build-arg GIT_SHA=$(git rev-parse --short HEAD) --build-arg BUILD_NUMBER=local -t ghcr.io/kushaltalati/unit-converter:local . 2>&1 | tail -3"
x "docker image inspect ghcr.io/kushaltalati/unit-converter:local --format 'size={{.Size}} user={{.Config.User}} cmd={{.Config.Cmd}}'"
x "docker run -d --rm --name uc-local -p 20016:8000 ghcr.io/kushaltalati/unit-converter:local"
sleep 3
x "curl -s localhost:20016/health; echo"
x "curl -s localhost:20016/info; echo"
x "curl -s 'localhost:20016/convert/temperature?value=37&from_unit=c&to_unit=f'; echo"
x "curl -s -X POST localhost:20016/convert -H 'content-type: application/json' -d '{\"category\":\"weight\",\"value\":70,\"from_unit\":\"kg\",\"to_unit\":\"lb\"}'; echo"
x "curl -s -o /dev/null -w 'HTTP %{http_code}\n' 'localhost:20016/convert/length?value=1&from_unit=m&to_unit=cubit'"
x "docker exec uc-local id"
x "docker stop uc-local"
