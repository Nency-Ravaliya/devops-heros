> **Submission for `session5-git-github`** — Piyush Bansal.
>
> Every command below was actually executed in a scratch git repo and the output is copied in verbatim.

# Session 5 — Git/GitHub Homework

**Environment:** git 2.50.1, macOS, in a scratch repository created just for this demo.

## Contents

- [Task 1 — `git commit -a -m`](#task-1--git-commit--a--m)
- [Task 2 — Git Cherry-Pick](#task-2--git-cherry-pick)

---

# Task 1 — `git commit -a -m`

## The difference between `git commit -a -m` and `git commit -m`

`git commit -m "message"` commits **only what's already staged** (via `git add`). If nothing is staged, it
does nothing and tells you so.

`git commit -a -m "message"` **automatically stages every tracked file that has been modified or deleted**
before committing — it's a shortcut that skips `git add` for files git already knows about. It does **not**
stage brand-new, untracked files — those still need an explicit `git add`.

## Full transcript

```console
$ echo "line 2" >> file.txt   (modify a TRACKED file)

$ git status
On branch main
Changes not staged for commit:
	modified:   file.txt
no changes added to commit (use "git add" and/or "git commit -a")

$ git commit -m "try without -a"   (FAILS - nothing staged)
On branch main
Changes not staged for commit:
	modified:   file.txt
no changes added to commit (use "git add" and/or "git commit -a")

$ git commit -a -m "update file.txt via -a"   (auto-stages tracked, modified files)
[main da5bb9c] update file.txt via -a
 1 file changed, 1 insertion(+)

$ git log --oneline
da5bb9c update file.txt via -a
a6c5eb7 initial commit

########## -a does NOT pick up a brand-new untracked file ##########
$ echo "new file" > newfile.txt
$ git status
Untracked files:
	newfile.txt
nothing added to commit but untracked files present (use "git add" to track)

$ git commit -a -m "try to include newfile.txt"   (still nothing to commit - newfile.txt is untracked)
On branch main
Untracked files:
	newfile.txt
nothing added to commit but untracked files present (use "git add" to track)
```

**What this proves:** the plain `-m` commit failed with nothing staged, `-a -m` succeeded by auto-staging the
*modified, already-tracked* `file.txt`, and `-a -m` still refused to include `newfile.txt` because `-a` only
covers files git is already tracking — a genuinely new file always needs `git add` first.

---

# Task 2 — Git Cherry-Pick

## What cherry-pick does

`git cherry-pick <commit>` takes the *changes* introduced by one specific commit on another branch and applies
them as a **new commit** on your current branch — same diff and message, but a fresh commit hash, without
merging the rest of that branch's history.

## Full transcript

```console
########## Create 2-4 commits on main ##########
$ echo "feature A" >> file.txt && git commit -am "main: add feature A"
[main 5fe1aa4] main: add feature A
$ echo "feature B" >> file.txt && git commit -am "main: add feature B"
[main a656c01] main: add feature B
$ echo "feature C" >> file.txt && git commit -am "main: add feature C"
[main 043a1a1] main: add feature C

$ git log --oneline
043a1a1 main: add feature C
a656c01 main: add feature B
5fe1aa4 main: add feature A
da5bb9c update file.txt via -a
a6c5eb7 initial commit

########## Create a new branch ##########
$ git checkout -b feature-branch
Switched to a new branch 'feature-branch'

########## Make 3 commits on the new branch ##########
$ echo "urgent bugfix" > bugfix.txt && git add bugfix.txt && git commit -m "feature-branch: urgent bugfix"
[feature-branch fcfa347] feature-branch: urgent bugfix
$ echo "experimental feature" > experiment.txt && git add experiment.txt && git commit -m "feature-branch: experimental feature (not ready for main)"
[feature-branch b34e666] feature-branch: experimental feature (not ready for main)
$ echo "unrelated cleanup" > cleanup.txt && git add cleanup.txt && git commit -m "feature-branch: unrelated cleanup"
[feature-branch 97efb15] feature-branch: unrelated cleanup

########## git log to identify the specific commit to cherry-pick ##########
$ git log --oneline
97efb15 feature-branch: unrelated cleanup
b34e666 feature-branch: experimental feature (not ready for main)
fcfa347 feature-branch: urgent bugfix          <-- only this one is wanted on main
043a1a1 main: add feature C
...

########## Switch back to main ##########
$ git checkout main
Switched to branch 'main'

########## Cherry-pick ONLY the bugfix commit ##########
$ git cherry-pick fcfa347
[main f18c211] feature-branch: urgent bugfix
 1 file changed, 1 insertion(+)
 create mode 100644 bugfix.txt

########## Verify the change is now in main ##########
$ git log --oneline
f18c211 feature-branch: urgent bugfix
043a1a1 main: add feature C
a656c01 main: add feature B
5fe1aa4 main: add feature A
da5bb9c update file.txt via -a
a6c5eb7 initial commit

$ ls
bugfix.txt
file.txt

$ cat bugfix.txt
urgent bugfix

########## experiment.txt and cleanup.txt were correctly left behind ##########
$ ls experiment.txt cleanup.txt
ls: cleanup.txt: No such file or directory
ls: experiment.txt: No such file or directory

########## The cherry-picked commit is a genuinely NEW commit - different hash, same content ##########
$ git show --stat fcfa347
commit fcfa347219394e9daed23d16022f482726d5b8fc
    feature-branch: urgent bugfix
 bugfix.txt | 1 +

$ git show --stat HEAD
commit f18c21159246ab75f48689887a8655fcac630d43
    feature-branch: urgent bugfix
 bugfix.txt | 1 +
```

**What this proves:** `main` now has `bugfix.txt` (the cherry-picked change) but *not* `experiment.txt` or
`cleanup.txt` — only the one targeted commit was pulled over, not the whole branch. The commit on `main`
(`f18c211`) carries the same message and diff as the original (`fcfa347`) but has a different hash — it's a
brand new commit, not a pointer to the old one, which is exactly what cherry-pick is meant to do.

---

# Files in this folder

| File | Purpose |
|---|---|
| `README.md` | This file — full transcripts for both tasks |
