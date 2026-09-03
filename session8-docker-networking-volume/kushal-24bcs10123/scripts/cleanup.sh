#!/usr/bin/env bash
docker rm -f web-ui api-svc db-mysql apache-host nginx-bind 2>/dev/null
docker network rm ui-net api-net data-net 2>/dev/null
