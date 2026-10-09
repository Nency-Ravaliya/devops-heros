#!/bin/bash
# Session 5 - Task 2: git cherry-pick
#
# Run: bash task2-cherry-pick.sh
#
# Creates commits on main, more commits on a feature branch, then lifts ONE
# feature commit onto main and verifies it landed. Throwaway repo under /tmp.

set -u

command -v git >/dev/null 2>&1 || { echo "git not installed - run: sudo apt install -y git"; exit 1; }

WORKDIR="$(mktemp -d)"
cd "$WORKDIR" || exit 1

run() { echo; echo "\$ $*"; "$@"; }

echo "Scratch repository: $WORKDIR"

git init -b main -q
git config user.name  "Pratyush Mishra"
git config user.email "pratyush@example.com"

echo
echo "############### STEP 1: three commits on main ###############"

for n in 1 2 3; do
    echo "Main commit $n" >> main.txt
    git add main.txt
    git commit -q -m "Main commit $n"
done
run git log --oneline

echo
echo "############### STEP 2: a feature branch with three commits ###############"

run git checkout -b feature
# Each commit creates its OWN file. If all three appended to one shared file,
# cherry-picking only the middle commit onto main would fail with a
# modify/delete conflict - main has no such file, because the commit that
# created it is not being picked.
for n in 1 2 3; do
    echo "Feature commit $n" > "feature$n.txt"
    git add "feature$n.txt"
    git commit -q -m "Feature commit $n"
done
run git log --oneline
run ls

echo
echo "############### STEP 3: pick out ONE commit to transplant ###############"

# Grab the hash of "Feature commit 2" - the middle one, so it is clear that
# cherry-pick takes exactly the commit asked for and not the ones around it.
TARGET=$(git log --format='%h %s' | grep 'Feature commit 2' | cut -d' ' -f1)
echo
echo "Target commit: $TARGET  (Feature commit 2)"
run git show --stat --oneline "$TARGET"

echo
echo "############### STEP 4: cherry-pick it onto main ###############"

run git checkout main
echo
echo "main before the cherry-pick:"
run ls
run git log --oneline

run git cherry-pick "$TARGET"

echo
echo "############### STEP 5: verify it landed on main ###############"

echo
echo "main after the cherry-pick:"
run ls
run git log --oneline
run cat feature2.txt

echo
echo "Only feature2.txt is here - feature1.txt and feature3.txt stayed on the"
echo "feature branch. Cherry-pick moved exactly the one commit that was named."
echo
echo "The commit hash for 'Feature commit 2' on main also differs from $TARGET on"
echo "the feature branch - cherry-pick creates a NEW commit with the same changes."

cd / && rm -rf "$WORKDIR"
echo
echo "Cleaned up $WORKDIR"
