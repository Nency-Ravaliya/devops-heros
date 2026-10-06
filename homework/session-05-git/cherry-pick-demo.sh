#!/usr/bin/env bash
# Creates a throwaway repository, cherry-picks one feature commit onto main,
# prints the evidence, then deletes the throwaway repository.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DEMO="$(mktemp -d "${TMPDIR:-/tmp}/git-cherry.XXXXXX")"
cleanup() { rm -rf "$DEMO"; }
trap cleanup EXIT

cd "$DEMO"
git init -b main >/dev/null
git config user.email "student@example.com"
git config user.name "bhanage-viraj"

echo "base" > app.txt
git add app.txt && git commit -q -m "main: initial app"
echo "main-2" >> app.txt && git add app.txt && git commit -q -m "main: second commit"
echo "main-3" >> app.txt && git add app.txt && git commit -q -m "main: third commit"
echo "main-4" >> app.txt && git add app.txt && git commit -q -m "main: fourth commit"

git checkout -q -b feature
echo "feature-a" > feature-a.txt && git add feature-a.txt && git commit -q -m "feature: add feature file"
echo "feature-b" > feature-b.txt && git add feature-b.txt && git commit -q -m "feature: document the API"
echo "feature-c" > feature-c.txt && git add feature-c.txt && git commit -q -m "feature: extra experiment"

PICK="$(git rev-list --grep='document the API' --max-count=1 HEAD)"
git checkout -q main

{
  echo "\$ git log --oneline --all --decorate"
  git --no-pager log --oneline --all --decorate
  echo
  echo "\$ git cherry-pick $PICK"
  git cherry-pick "$PICK"
  echo
  echo "\$ git log --oneline --decorate"
  git --no-pager log --oneline --decorate
  echo
  echo "\$ ls feature-*.txt"
  ls feature-*.txt
  echo "\$ cat feature-b.txt"
  cat feature-b.txt
} | tee "$ROOT/cherry-pick-output.txt"
