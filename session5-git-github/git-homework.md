# Session 5 - Git Homework

## Task 1: `git commit -a -m` vs `git commit -m`

### Difference
- `git commit -m "msg"`: commits only **staged** changes.
- `git commit -a -m "msg"`: auto-stages **tracked modified/deleted files** and commits.
- `-a` does **not** include new untracked files; they still need `git add`.

### Practice steps
```bash
git checkout -b git-commit-practice
echo "line1" > tracked.txt
git add tracked.txt
git commit -m "Add tracked file"

echo "line2" >> tracked.txt
git commit -a -m "Update tracked file using -a"

echo "new file" > untracked.txt
git commit -a -m "Try commit with untracked file"
# untracked.txt will not be included
git add untracked.txt
git commit -m "Add untracked file"
```

---

## Task 2: Cherry-pick

### Practice flow
```bash
# on main: create 2-4 commits
git checkout main
echo "main-1" > main1.txt
git add main1.txt
git commit -m "Main commit 1"

echo "main-2" > main2.txt
git add main2.txt
git commit -m "Main commit 2"

# create new branch and make 2-3 commits
git checkout -b feature-cherry
echo "feature-a" > feature-a.txt
git add feature-a.txt
git commit -m "Feature commit A"

echo "feature-b" > feature-b.txt
git add feature-b.txt
git commit -m "Feature commit B"

# identify commit hash
git log --oneline

# cherry-pick selected commit into main
git checkout main
git cherry-pick <commit-hash-from-feature-branch>

# verify
git log --oneline
ls
```

### What I understood
- `cherry-pick` copies one specific commit from another branch onto current branch.
- Useful when you need only one fix/feature, not full branch merge.
