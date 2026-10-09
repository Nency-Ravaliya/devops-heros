#!/bin/bash
# Stops and removes the six containers created by build-and-run-all.sh.
# Images are left in place; remove them too with:
#   docker rmi node-webapp python-webapp java-webapp apache-webapp react-webapp nginx-webapp

set -u

for name in node-container python-container java-container apache-container react-container nginx-container; do
    docker rm -f "$name" 2>/dev/null && echo "removed $name"
done

echo
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
