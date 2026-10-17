#!/usr/bin/env bash
# Git Homework Task 1 — `git commit -a -m` vs `git commit -m`
set -u
run() { echo "\$ $*"; "$@"; }
hline() { printf '=%.0s' {1..60}; echo; }

WORK="$(mktemp -d)"; cd "$WORK"
git init -q -b main demo-repo && cd demo-repo
git config user.name  "Samarth"
git config user.email "samarth@example.com"

hline; echo "SETUP — create a repo with two tracked files"; hline
echo "line 1" > app.txt
echo "print('hello')" > app.py
run git add app.txt app.py
run git commit -m "Initial commit: add app files"

hline; echo "STEP 1 — modify a TRACKED file (not staged)"; hline
echo "line 2" >> app.txt
run git status -s
echo
echo "Now try \`git commit -m\` WITHOUT -a :"
run git commit -m "Update app.txt"
echo "^ nothing was staged, so the commit is aborted with 'no changes added to commit'."

hline; echo "STEP 2 — \`git commit -a -m\` stages tracked changes automatically"; hline
run git commit -a -m "Update app.txt (committed with -a)"
run git show --stat --oneline HEAD

hline; echo "STEP 3 — -a does NOT pick up NEW (untracked) files"; hline
echo "brand new" > newfile.txt
run git status -s
run git commit -a -m "try to add newfile with -a"
echo
echo "newfile.txt is still untracked (?? above) — it needs an explicit \`git add\`:"
run git add newfile.txt
run git commit -m "Add newfile.txt (needed git add, -a does not include new files)"
run git log --oneline

echo
echo "### GIT-T1-DONE ###"
