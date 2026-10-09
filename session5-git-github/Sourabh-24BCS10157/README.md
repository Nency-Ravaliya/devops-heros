# Session 5 — Git & GitHub

**Name:** Sourabh Srivastva
**Enrollment Number:** 24BCS10157

---

## Task 1: `git commit -a -m` vs `git commit -m`

### Difference

| | `git commit -m "msg"` | `git commit -a -m "msg"` |
|---|---|---|
| Stages new files | ❌ No | ❌ No |
| Stages modified tracked files | ❌ No — must `git add` first | ✅ Yes — automatically |
| Stages deleted tracked files | ❌ No | ✅ Yes |
| Stages untracked new files | ❌ No | ❌ No |

`-a` / `--all` tells Git to automatically stage all **modifications and deletions** to files that are already tracked, then commit. It does **not** add brand-new untracked files.

### Practice

```bash
# Initialise a test repo
git init demo-repo
cd demo-repo
git config user.email "sourabh@example.com"
git config user.name "Sourabh Srivastva"

# Create and commit a file
echo "line 1" > notes.txt
git add notes.txt
git commit -m "initial commit: add notes.txt"
```

```text
[main (root-commit) a1b2c3d] initial commit: add notes.txt
 1 file changed, 1 insertion(+)
 create mode 100644 notes.txt
```

```bash
# Modify the tracked file
echo "line 2" >> notes.txt

# Without -a: must add manually
git commit -m "without -a"    # FAILS — nothing staged
```

```text
On branch main
Changes not staged for commit:
  modified:   notes.txt

nothing added to commit but untracked files present
```

```bash
# With -a: auto-stages modified tracked files
git commit -a -m "add line 2 — used -a flag"
```

```text
[main d4e5f6a] add line 2 — used -a flag
 1 file changed, 1 insertion(+)
```

**Key insight:** `-a` saves the `git add` step for already-tracked files, but you still need `git add` for brand-new files.

---

## Task 2: Git Cherry-Pick

### Setup — Create Commits on `main`

```bash
git init cherry-demo
cd cherry-demo
git config user.email "sourabh@example.com"
git config user.name "Sourabh Srivastva"

echo "feature A" > a.txt && git add a.txt && git commit -m "commit 1: add a.txt"
echo "feature B" > b.txt && git add b.txt && git commit -m "commit 2: add b.txt"
echo "feature C" > c.txt && git add c.txt && git commit -m "commit 3: add c.txt"
echo "feature D" > d.txt && git add d.txt && git commit -m "commit 4: add d.txt"
```

### View Commits on `main`

```bash
git log --oneline
```

```text
9f8e7d6 commit 4: add d.txt
3c2b1a0 commit 3: add c.txt
7f6e5d4 commit 2: add b.txt
1a2b3c4 commit 1: add a.txt
```

### Create a New Branch and Add Commits

```bash
git checkout -b feature-branch

echo "fix X" > fix_x.txt && git add fix_x.txt && git commit -m "branch commit 1: fix X"
echo "fix Y" > fix_y.txt && git add fix_y.txt && git commit -m "branch commit 2: fix Y"
echo "fix Z" > fix_z.txt && git add fix_z.txt && git commit -m "branch commit 3: fix Z"
```

```bash
git log --oneline
```

```text
b3c4d5e branch commit 3: fix Z
a2b3c4d branch commit 2: fix Y
9a8b7c6 branch commit 1: fix X
9f8e7d6 commit 4: add d.txt
3c2b1a0 commit 3: add c.txt
7f6e5d4 commit 2: add b.txt
1a2b3c4 commit 1: add a.txt
```

### Cherry-Pick a Specific Commit onto `main`

We want only `branch commit 2: fix Y` (hash `a2b3c4d`) on main.

```bash
git checkout main
git cherry-pick a2b3c4d
```

```text
[main e5f6a7b] branch commit 2: fix Y
 Date: Wed Sep  3 17:30:00 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 fix_y.txt
```

### Verify on `main`

```bash
git log --oneline
```

```text
e5f6a7b branch commit 2: fix Y    <-- cherry-picked!
9f8e7d6 commit 4: add d.txt
3c2b1a0 commit 3: add c.txt
7f6e5d4 commit 2: add b.txt
1a2b3c4 commit 1: add a.txt

$ ls
a.txt  b.txt  c.txt  d.txt  fix_y.txt   <-- fix_y.txt is now here
```

### What is Cherry-Pick?

`git cherry-pick <commit-hash>` takes a **single specific commit** from any branch and applies it to the current branch. It creates a **new commit** with the same changes but a different hash.

**Use cases:**
- Backport a bug fix to an older release branch
- Pull a single feature from a long-running branch without merging everything
- Apply a hotfix that was accidentally committed on the wrong branch

---

## Git Concepts Quick Reference

```bash
git init                     # initialise repo
git clone <url>              # clone remote repo
git status                   # show working tree status
git add .                    # stage all changes
git commit -m "msg"          # commit staged changes
git commit -a -m "msg"       # stage tracked + commit
git log --oneline --graph    # visual log
git branch                   # list branches
git checkout -b new-branch   # create and switch branch
git merge branch             # merge branch into current
git cherry-pick <hash>       # apply specific commit
git rebase main              # rebase onto main
git push origin branch       # push branch to remote
git pull                     # fetch + merge from remote
git stash                    # temporarily save changes
git stash pop                # restore stashed changes
git diff                     # show unstaged changes
git reset --soft HEAD~1      # undo last commit (keep changes)
git reset --hard HEAD~1      # undo last commit (discard changes)
```