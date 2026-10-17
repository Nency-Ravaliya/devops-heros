#!/usr/bin/env bash
# Task 4 — render the top half of the cheat sheet for the screenshot.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
CS="$HERE/cheat-sheet.md"
[ -f "$CS" ] || CS="/home/samarth/Desktop/Sam_N/devops-heros/homework-linux-basics/04-cheat-sheet/cheat-sheet.md"
printf '===== Linux Basic Commands - Cheat Sheet (part 1/2) =====\n'
printf '     credit: Nensi Ravaliya / Yatri Cloud\n\n'
sed -n '1,58p' "$CS"
echo
echo "### HW-CS1-DONE ###"
