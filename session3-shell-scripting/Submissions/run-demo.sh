#!/usr/bin/env bash
# Non-interactive demo: feeds answers to the read -p prompts via pipe.
# Used to produce the screenshot.
set -u

# Resolve the script directory BEFORE changing to temp dir
HERE="$(cd "$(dirname "$0")" && pwd)"

WORK="$(mktemp -d)"
cd "$WORK"
printf 'Krushna\nsysinfo-demo\n' | bash "$HERE/system-info.sh"
echo
echo "(demo workdir: $WORK)"
