#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "--verify" ]]; then
  echo "Usage: $0 --verify" >&2
  exit 2
fi

lab_dir="$(mktemp -d)"
trap 'rm -rf "$lab_dir"' EXIT
cd "$lab_dir"
printf 'link-lab\n' > original.txt
ln original.txt hard.txt
ln -s original.txt soft.txt

[[ "$(stat -c '%i' original.txt)" == "$(stat -c '%i' hard.txt)" ]]
rm original.txt
[[ "$(cat hard.txt)" == 'link-lab' ]]
[[ ! -e soft.txt && -L soft.txt ]]
echo 'Hard and symbolic link behaviour verified in a temporary directory.'
