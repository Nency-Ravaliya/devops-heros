#!/bin/bash
# Session 5 - Task 1: git commit -a -m  vs  git commit -m
#
# Run: bash task1-commit-flags.sh
#
# Everything happens in a throwaway repo under /tmp, so this cannot touch the
# devops-heros checkout or any other repository.

set -u

command -v git >/dev/null 2>&1 || { echo "git not installed - run: sudo apt install -y git"; exit 1; }

WORKDIR="$(mktemp -d)"
cd "$WORKDIR" || exit 1

run() { echo; echo "\$ $*"; "$@"; }

echo "Scratch repository: $WORKDIR"

# -b main forces the branch name; without it git picks master and prints a hint.
run git init -b main

# Identity is set locally, on this scratch repo only - the global config is
# left untouched. Without an identity git refuses to commit at all.
git config user.name  "Pratyush Mishra"
git config user.email "pratyush@example.com"

echo
echo "############### PART 1: git commit -m  (staging required) ###############"

echo "First line" > file.txt
run git status --short
run git add file.txt
run git commit -m "Add file"

echo
echo "############### PART 2: git commit -a -m on a TRACKED file ###############"

# file.txt is already tracked, so -a stages the modification automatically.
echo "Second line" >> file.txt
run git status --short
run git commit -a -m "Update file"

echo
echo "############### PART 3: git commit -a -m on an UNTRACKED file ###############"

# newfile.txt has never been committed, so git is not tracking it and -a
# skips it entirely. This is the difference the task is about.
echo "New file" > newfile.txt
run git status --short
echo
echo "\$ git commit -a -m \"Add new file\"   # expected to commit NOTHING"
git commit -a -m "Add new file" || echo ">> nothing was committed, as expected"

echo
echo "############### PART 4: the untracked file needs git add ###############"

run git add newfile.txt
run git commit -m "Add new file"

echo
run git log --oneline

cd / && rm -rf "$WORKDIR"
echo
echo "Cleaned up $WORKDIR"
