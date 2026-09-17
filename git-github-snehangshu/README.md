# Session 5 — Git and GitHub

**Name:** Snehangshu Roy
**Enrollment No:** 24BCS10155
**Topic:** `git commit -a -m` vs `git commit -m`, and `git cherry-pick`

Every command below was run in a real local repository. All output blocks are the actual
terminal output.

---

## Task 1 — `git commit -a -m` vs `git commit -m`

### 1.1 The difference

| | `git commit -m "msg"` | `git commit -a -m "msg"` |
|---|---|---|
| What it commits | **Only what is already staged** (`git add`ed) | Everything staged **plus all modified/deleted tracked files** |
| Runs an implicit `git add`? | No | Yes — but only for files Git already tracks |
| Picks up **untracked** (brand-new) files? | No | **No** — still needs an explicit `git add` |
| Picks up deletions of tracked files? | Only if staged | Yes, automatically |
| Typical use | Deliberate, partial commits | Quick commit of edits to existing files |
| Risk | None — you chose exactly what goes in | Can sweep in unrelated edits you forgot about |

The single-sentence version: **`-a` means "stage every tracked file that changed, then
commit"**. It is a shortcut for `git add -u && git commit -m`. It is *not* a shortcut for
`git add -A`, because untracked files are left alone.

### 1.2 Setting up

```bash
git init -b main
echo "line 1" > app.txt
git add app.txt
git commit -m "Initial commit: add app.txt"
```

```
committed initial
```

### 1.3 Modify a tracked file WITHOUT staging it, then try `git commit -m`

```bash
echo "line 2 (modified, NOT staged)" >> app.txt
git status --short
git commit -m "try commit without -a"
```

```
 M app.txt

On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   app.txt

no changes added to commit (use "git add" and/or "git commit -a")
```

**`git commit -m` refused to make a commit.** The change was in the working directory but
never staged, so there was nothing in the index to commit. Git even tells you the fix in
the last line: *"use `git add` and/or `git commit -a`"*.

```bash
git status --short
```

```
 M app.txt
```

The `M` is in the **second** column — working-tree modified, index clean. Nothing changed.

### 1.4 Now the same situation with `git commit -a -m`

```bash
git commit -a -m "commit -a -m: stages tracked modifications automatically"
git status --short
```

```
[main ec0b75f] commit -a -m: stages tracked modifications automatically
 1 file changed, 1 insertion(+)
(clean)
```

**The commit went through in one step.** `-a` staged the modification to `app.txt` (a
tracked file) and committed it, and the working tree is now clean.

### 1.5 The important limitation — `-a` does NOT pick up untracked files

```bash
echo "brand new" > newfile.txt
git commit -a -m "does -a pick up untracked files?"
```

```
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	newfile.txt

nothing added to commit but untracked files present (use "git add" to track)
```

```bash
git status --short
```

```
?? newfile.txt
```

`??` = untracked. Even with `-a`, Git refused, because `newfile.txt` has never been added
to the repository. This is the part people get wrong in interviews.

```bash
git add newfile.txt
git commit -m "Add newfile.txt (needed explicit git add)"
```

### 1.6 Final history

```bash
git log --oneline
```

```
94f4d3d Add newfile.txt (needed explicit git add)
ec0b75f commit -a -m: stages tracked modifications automatically
dbefef9 Initial commit: add app.txt
```

### What I observed

1. `git commit -m` commits **only the staging area**; if you forgot to `git add`, it makes
   no commit at all and tells you so.
2. `git commit -a -m` auto-stages modifications and deletions to **already-tracked** files
   and commits them in a single step.
3. Neither form will commit a **new, untracked** file — that always needs `git add` first.
4. So `-a` is a convenience for editing existing files, but it is a blunt instrument: it
   sweeps in *every* tracked change, which is why deliberate `git add` + `git commit -m` is
   safer when you want a focused commit.

---

## Task 2 — Git Cherry-Pick

**Goal:** take one specific commit from a feature branch and apply just that commit onto
`main`, leaving the rest of the branch behind.

### 2.1 Create 4 commits on `main`

```bash
git init -b main
echo "# DevOps Heros - Cherry Pick Lab" > README.md   && git add . && git commit -m "main: C1 - add README"
echo "server { listen 80; }"            > nginx.conf  && git add . && git commit -m "main: C2 - add nginx.conf"
echo "APP_ENV=production"               > .env        && git add . && git commit -m "main: C3 - add .env"
echo "echo deploying..."                > deploy.sh   && git add . && git commit -m "main: C4 - add deploy.sh"
```

```
4 commits created on main
```

### 2.2 View the commits with `git log`

```bash
git log --oneline --decorate
```

```
d1c7ef7 (HEAD -> main) main: C4 - add deploy.sh
1084428 main: C3 - add .env
0f7784d main: C2 - add nginx.conf
3a8f32f main: C1 - add README
```

### 2.3 Create a new branch

```bash
git checkout -b feature/logging
git branch -vv
```

```
* feature/logging d1c7ef7 main: C4 - add deploy.sh
  main            d1c7ef7 main: C4 - add deploy.sh
```

Both branches point at the same commit right now — the branch is just a movable pointer.

### 2.4 Make 3 commits on the new branch

```bash
echo "log_level=debug"   > logging.conf    && git add . && git commit -m "feature: F1 - add logging.conf"
printf '#!/bin/bash\ncurl -sf localhost/health || exit 1\n' > healthcheck.sh
git add . && git commit -m "feature: F2 - add healthcheck.sh  <-- THE COMMIT TO CHERRY-PICK"
echo "rotate daily"      > logrotate.conf  && git add . && git commit -m "feature: F3 - add logrotate.conf"
```

```
3 commits created on feature/logging
```

### 2.5 Use `git log` to identify the specific commit

```bash
git log --oneline --decorate
```

```
570540a (HEAD -> feature/logging) feature: F3 - add logrotate.conf
9737cb7 feature: F2 - add healthcheck.sh  <-- THE COMMIT TO CHERRY-PICK
9280208 feature: F1 - add logging.conf
d1c7ef7 (main) main: C4 - add deploy.sh
1084428 main: C3 - add .env
0f7784d main: C2 - add nginx.conf
3a8f32f main: C1 - add README
```

The commit I want is **`9737cb7`** — the one that adds `healthcheck.sh`. I want *only* that
change on `main`; the logging config work is not ready yet.

```bash
git show --stat --oneline 9737cb7
```

```
9737cb7 feature: F2 - add healthcheck.sh  <-- THE COMMIT TO CHERRY-PICK
 healthcheck.sh | 2 ++
 1 file changed, 2 insertions(+)
```

### 2.6 History before the cherry-pick

```bash
git log --oneline --graph --all --decorate
```

```
* 570540a (HEAD -> feature/logging) feature: F3 - add logrotate.conf
* 9737cb7 feature: F2 - add healthcheck.sh  <-- THE COMMIT TO CHERRY-PICK
* 9280208 feature: F1 - add logging.conf
* d1c7ef7 (main) main: C4 - add deploy.sh
* 1084428 main: C3 - add .env
* 0f7784d main: C2 - add nginx.conf
* 3a8f32f main: C1 - add README
```

### 2.7 Switch to `main` — confirm the file is not there

```bash
git checkout main
ls -1
test -f healthcheck.sh && echo YES || echo "NO - not on main yet"
```

```
README.md
deploy.sh
nginx.conf
--- healthcheck.sh present on main? ---
NO - not on main yet
```

### 2.8 Cherry-pick the commit

```bash
git cherry-pick 9737cb7
```

```
[main f2699bd] feature: F2 - add healthcheck.sh  <-- THE COMMIT TO CHERRY-PICK
 Date: Thu Sep 17 20:51:52 2026 +0000
 1 file changed, 2 insertions(+)
 create mode 100644 healthcheck.sh
```

### 2.9 Verify the change is now on `main`

```bash
ls -1
cat healthcheck.sh
```

```
README.md
deploy.sh
healthcheck.sh
nginx.conf
--- healthcheck.sh present on main now? ---
YES - cherry-pick succeeded
--- content ---
#!/bin/bash
curl -sf localhost/health || exit 1
```

```bash
git log --oneline --decorate
```

```
f2699bd (HEAD -> main) feature: F2 - add healthcheck.sh  <-- THE COMMIT TO CHERRY-PICK
d1c7ef7 main: C4 - add deploy.sh
1084428 main: C3 - add .env
0f7784d main: C2 - add nginx.conf
3a8f32f main: C1 - add README
```

### 2.10 Verify ONLY that commit came across

```
logging.conf on main?   NO
logrotate.conf on main? NO
healthcheck.sh on main? YES
```

This is the whole point of cherry-pick: `F1` and `F3` stayed on the feature branch. Only
`F2` was transplanted.

### 2.11 The cherry-picked commit has a DIFFERENT hash

```
original commit on feature branch:
9737cb7 feature: F2 - add healthcheck.sh  <-- THE COMMIT TO CHERRY-PICK

cherry-picked commit on main:
f2699bd feature: F2 - add healthcheck.sh  <-- THE COMMIT TO CHERRY-PICK
```

Same message, same diff, **different SHA**. A commit hash is derived from its content *and*
its parent, and this copy has a different parent (`d1c7ef7` instead of `9280208`), so it is
a brand-new commit object. That is why cherry-picking the same work twice gives you
duplicate commits in history.

### 2.12 Final history graph

```bash
git log --oneline --graph --all --decorate
```

```
* 570540a (feature/logging) feature: F3 - add logrotate.conf
* 9737cb7 feature: F2 - add healthcheck.sh  <-- THE COMMIT TO CHERRY-PICK
* 9280208 feature: F1 - add logging.conf
| * f2699bd (HEAD -> main) feature: F2 - add healthcheck.sh  <-- THE COMMIT TO CHERRY-PICK
|/
* d1c7ef7 main: C4 - add deploy.sh
* 1084428 main: C3 - add .env
* 0f7784d main: C2 - add nginx.conf
* 3a8f32f main: C1 - add README
```

The graph shows the fork clearly: both branches share history up to `d1c7ef7`, then
diverge, and the same change now exists on both sides as two separate commits.

### Useful cherry-pick options

| Command | What it does |
|---|---|
| `git cherry-pick <sha>` | Apply one commit onto the current branch |
| `git cherry-pick A B C` | Apply several commits in order |
| `git cherry-pick A..B` | Apply a range (exclusive of `A`) |
| `git cherry-pick -n <sha>` | Apply the change but do **not** commit (stage only) |
| `git cherry-pick -x <sha>` | Append "cherry picked from commit …" to the message |
| `git cherry-pick --continue` | Resume after resolving a conflict |
| `git cherry-pick --abort` | Cancel and restore the previous state |

### When cherry-pick is the right tool

- Back-porting a **hotfix** from `main` onto a release branch.
- Pulling one urgent bug fix out of a long-running feature branch that is not ready to merge.
- Recovering a commit made on the wrong branch.

It is *not* a replacement for `merge` or `rebase` — because it duplicates commits, using it
for whole branches makes history confusing.

---

## Summary

| Task | Status |
|---|---|
| Task 1 — Practised `git commit -a -m`, compared against `git commit -m`, observed the difference including the untracked-file limitation | Done |
| Task 2 — 4 commits on `main`, branch created, 3 commits on the branch, commit identified with `git log`, cherry-picked onto `main` and verified | Done |
