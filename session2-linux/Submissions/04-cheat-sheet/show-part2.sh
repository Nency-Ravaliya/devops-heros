#!/usr/bin/env bash
# Task 4 — render the bottom half of the cheat sheet for the screenshot.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
CS="$HERE/cheat-sheet.md"
[ -f "$CS" ] || CS="/home/samarth/Desktop/Sam_N/devops-heros/homework-linux-basics/04-cheat-sheet/cheat-sheet.md"
printf '===== Linux Basic Commands - Cheat Sheet (part 2/2) =====\n\n'
sed -n '59,113p' "$CS"
echo
echo "### HW-CS2-DONE ###"
