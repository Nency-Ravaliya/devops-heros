# Session 5 - Git/GitHub Assignment

Both demos below were run in throwaway local git repos to produce real commands/output, then copied here
as transcripts.

## Task 1: `git commit -a -m` vs `git commit -m`

Full transcript: [`commit-a-vs-commit-m.txt`](commit-a-vs-commit-m.txt)

**Setup:** one tracked file, `file.txt`, already committed.

1. Modify `file.txt` (tracked), then run **`git commit -m "..."`** *without* staging it first:
   ```
   $ git commit -m "update via commit -m only"
   no changes added to commit (use "git add" and/or "git commit -a")
   ```
   Fails - `git commit -m` only commits what is already in the **staging area/index**. Since `file.txt` was
   modified but never `git add`-ed, there's nothing staged, so nothing gets committed.

2. Same modified file, now run **`git commit -a -m "..."`**:
   ```
   $ git commit -a -m "update via commit -a -m"
   [main 1eb546e] update via commit -a -m
    1 file changed, 1 insertion(+)
   ```
   Succeeds directly - `-a` automatically stages every file that is **already tracked** and
   modified/deleted (equivalent to running `git add -u` first), then commits.

3. Create a **brand-new, untracked** file and try `git commit -a -m` again:
   ```
   $ git status --short
   ?? newfile.txt
   $ git commit -a -m "trying to include newfile.txt via -a"
   nothing added to commit but untracked files present (use "git add" to track)
   ```
   Still fails for the new file - `-a` only auto-stages files Git **already knows about**. A brand-new
   file always needs an explicit `git add newfile.txt` first, no matter which commit flag is used.

### Summary

| | `git commit -m "msg"` | `git commit -a -m "msg"` |
|---|---|---|
| Commits what's in the index (staged via `git add`) | Yes | Yes |
| Auto-stages modified **tracked** files | No | Yes |
| Auto-stages **new/untracked** files | No | No |
| Typical use | After you've deliberately staged exactly what you want | Quick commit of all tracked-file edits |

## Task 2: Git Cherry-Pick

Full transcript: [`cherry-pick-demo.txt`](cherry-pick-demo.txt)

**Steps performed:**

1. **3 commits on `main`:**
   ```
   cdb71ef main: commit 3
   3bcd7dc main: commit 2
   647cc06 main: commit 1
   ```
2. **New branch `feature`** off `main`, with **3 commits**:
   ```
   1f7d1cb feature: important hotfix
   dd1f178 feature: extend feature.txt
   3f77a65 feature: add feature.txt
   ```
3. **Identified** the commit to pull into `main` via `git log --oneline feature`: `1f7d1cb feature: important hotfix`.
4. Switched back to `main` and **cherry-picked** it:
   ```
   $ git checkout main
   $ git cherry-pick 1f7d1cb
   [main 6ea1941] feature: important hotfix
    1 file changed, 1 insertion(+)
    create mode 100644 hotfix.txt
   ```
   Cherry-pick replays just that one commit's diff on top of `main` as a **new commit** (`6ea1941`, a
   different SHA than the original `1f7d1cb`, since it now has a different parent).
5. **Verified** on `main`:
   ```
   $ git log --oneline
   6ea1941 feature: important hotfix
   cdb71ef main: commit 3
   3bcd7dc main: commit 2
   647cc06 main: commit 1
   $ ls
   hotfix.txt
   work.txt
   ```
   `hotfix.txt` (from the cherry-picked commit) is now on `main`, while `feature.txt` (from the other two
   `feature`-only commits) is **not** - confirming cherry-pick brings over exactly one commit's changes,
   not the whole branch.

### Reference

Cheat sheets used: [`resources.md`](resources.md) (git-scm.com, GitHub Education, GeeksforGeeks cheat sheets).
