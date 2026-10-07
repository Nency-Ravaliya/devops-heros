#!/usr/bin/env bash
# 04: pull the evidence of the pipeline runs from GitHub with the gh CLI.
. "$(dirname "$0")/lib.sh"
x "gh run list --repo kushaltalati/devops-heros --workflow '24bcs10123 session17 devsecops' --limit 10"
for id in "$@"; do
  hr "run $id"
  x "gh run view $id --repo kushaltalati/devops-heros"
done
