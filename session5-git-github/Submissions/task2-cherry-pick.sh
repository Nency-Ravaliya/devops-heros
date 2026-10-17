#!/usr/bin/env bash
# Git Homework Task 2 — git cherry-pick
set -u
run() { echo "\$ $*"; "$@"; }
hline() { printf '=%.0s' {1..60}; echo; }

WORK="$(mktemp -d)"; cd "$WORK"
git init -q -b main cp-repo && cd cp-repo
git config user.name  "Samarth"
git config user.email "samarth@example.com"

hline; echo "STEP 1 — make 3 commits on main"; hline
echo "base" > base.txt
run git add base.txt
run git commit -m "C1: add base.txt"

echo "feature A" > featureA.txt
run git add featureA.txt
run git commit -m "C2: add featureA.txt"

echo "base updated" >> base.txt
run git commit -am "C3: update base.txt"

hline; echo "STEP 2 — view main commits (git log --oneline)"; hline
run git log --oneline

hline; echo "STEP 3 — create a new branch and make 2 commits there"; hline
run git checkout -b feature
echo "feature B" > featureB.txt
run git add featureB.txt
run git commit -m "F1: add featureB.txt (the one to cherry-pick)"

echo "feature C" > featureC.txt
run git add featureC.txt
run git commit -m "F2: add featureC.txt"

run git log --oneline
F1="$(git rev-parse HEAD~1)"
echo
echo "The commit to cherry-pick is F1 = $F1 ($(git log -1 --format='%s' "$F1"))"

hline; echo "STEP 4 — go back to main and cherry-pick ONLY F1"; hline
run git checkout main
run git log --oneline
echo
run git cherry-pick "$F1"

hline; echo "STEP 5 — verify the change is now on main"; hline
run git log --oneline
run git show --stat --oneline HEAD
echo
echo "featureB.txt present on main?  $([ -f featureB.txt ] && echo YES || echo NO)"
echo "featureC.txt present on main?  $([ -f featureC.txt ] && echo YES || echo no)"
cat featureB.txt

echo
echo "### GIT-T2-DONE ###"
