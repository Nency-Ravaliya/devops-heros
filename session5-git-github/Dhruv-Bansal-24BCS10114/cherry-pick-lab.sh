#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "--self-test" ]]; then
  echo "Usage: $0 --self-test" >&2
  exit 2
fi

repo="$(mktemp -d)"
trap 'rm -rf "$repo"' EXIT
git -C "$repo" init -q -b main
git -C "$repo" config user.name 'Dhruv Bansal'
git -C "$repo" config user.email 'dhruv.bansal@example.invalid'
printf 'base\n' > "$repo/notes.txt"
git -C "$repo" add notes.txt
git -C "$repo" commit -qm 'Add base note'
git -C "$repo" switch -qc feature/observability
printf 'healthcheck\n' > "$repo/healthcheck.txt"
git -C "$repo" add healthcheck.txt
git -C "$repo" commit -qm 'Add health check note'
picked_commit="$(git -C "$repo" rev-parse HEAD)"
git -C "$repo" switch -q main
git -C "$repo" cherry-pick -q "$picked_commit"
[[ "$(cat "$repo/healthcheck.txt")" == 'healthcheck' ]]
echo 'Cherry-pick self-test passed.'
