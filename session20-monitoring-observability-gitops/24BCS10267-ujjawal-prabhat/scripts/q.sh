#!/bin/bash
# usage: q.sh '<promql>'  -> prints the command and compact results (only a few labels kept)
P=http://localhost:19090
q="$1"
F='.data.result[] | (.metric | with_entries(select(.key|IN("__name__","namespace","pod","container","job","status","condition","alertname","alertstate")))) + {value: .value[1]}'
echo "\$ curl -s $P/api/v1/query --data-urlencode 'query=$q' | jq -c '<keep key labels + value>'"
curl -s "$P/api/v1/query" --data-urlencode "query=$q" | jq -c "$F"
echo
