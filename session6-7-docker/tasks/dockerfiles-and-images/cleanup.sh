#!/bin/bash
# Stops and removes the containers created by build-and-run-all.sh.

set -u

for name in multi-stage-app node-container-v2 python-container-v2 java-container-v2; do
    docker rm -f "$name" 2>/dev/null && echo "removed $name"
done

echo
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
