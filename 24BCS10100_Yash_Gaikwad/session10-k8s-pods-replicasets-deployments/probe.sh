#!/bin/sh
# probe.sh URL COUNT [DELAY]
# Sends COUNT requests to URL (default one every 0.5 s) and prints each answer,
# or FAIL when the request does not get a reply. Runs inside a Pod of the cluster.
url=$1
count=$2
delay=${3:-0.5}
i=0
while [ "$i" -lt "$count" ]; do
  wget -T 2 -qO- "$url" 2>/dev/null || echo FAIL
  i=$((i + 1))
  sleep "$delay"
done
