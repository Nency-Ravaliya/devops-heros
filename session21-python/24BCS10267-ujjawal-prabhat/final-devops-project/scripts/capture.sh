#!/usr/bin/env bash
# capture.sh <outfile> <command string>
# Runs a command, echoes it with a "$ " prompt, and appends prompt+output to
# <outfile> (used to collect the real outputs embedded in the README).
set -o pipefail
out="$1"; shift
mkdir -p "$(dirname "$out")"
{
  echo "\$ $*"
  bash -c "$*" 2>&1
  rc=$?
  echo
  exit $rc
} | tee -a "$out"
