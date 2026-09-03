# Session 5 – Git & GitHub

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123

Both tasks were done in throwaway repositories created with `git init`. The complete, unedited terminal sessions are in [`transcripts/`](transcripts); the notes below pull out the interesting parts.

## Task 1 – `git commit -m` vs `git commit -a -m`

Transcript: [`transcripts/task1-commit-a-vs-m.txt`](transcripts/task1-commit-a-vs-m.txt)

### Setup

```bash
git init -b main commit-flags-demo && cd commit-flags-demo
echo 'version 1' > notes.txt
git add notes.txt
git commit -m 'Add notes.txt'
```

### Experiment 1: modify a tracked file, commit with plain `-m`

```text
$ echo 'version 2' >> notes.txt
$ git status --short
 M notes.txt                       <- M in the second column = modified, NOT staged

$ git commit -m 'Update notes (plain -m, nothing staged)'
On branch main
Changes not staged for commit:
        modified:   notes.txt
no changes added to commit (use "git add" and/or "git commit -a")
```

Nothing was committed. `-m` only commits what is already in the staging area (index), and I had not run `git add`.

### Experiment 2: same state, `-a -m`

```text
$ git commit -a -m 'Update notes (with -a)'
[main 8c33a42] Update notes (with -a)
 1 file changed, 1 insertion(+)
```

`-a` (`--all`) automatically stages every **tracked** file that was modified or deleted, then commits. Two steps in one.

### Experiment 3: the catch – untracked files

```text
$ echo 'brand new' > todo.txt        # never added before
$ echo 'version 3' >> notes.txt
$ git status --short
 M notes.txt
?? todo.txt                          <- ?? = untracked

$ git commit -a -m 'Try to commit both files with -a'
 1 file changed, 1 insertion(+)      <- only notes.txt went in
$ git status --short
?? todo.txt                          <- still sitting there
```

`-a` ignores untracked files completely. A new file always needs an explicit `git add` once. After that first commit, `-a` will pick up its future edits and even its deletion (`rm todo.txt && git commit -a -m ...` worked).

### Summary

| | `git commit -m "msg"` | `git commit -a -m "msg"` |
|---|---|---|
| What gets committed | only what is staged with `git add` | staged changes **plus** every modified/deleted tracked file |
| New (untracked) files | no | no |
| Lets you commit part of your changes | yes (stage selectively, `git add -p`) | no, it grabs everything tracked |
| Typical use | careful, curated commits | quick "save everything" commits |

## Task 2 – `git cherry-pick`

Transcript: [`transcripts/task2-cherry-pick.txt`](transcripts/task2-cherry-pick.txt)

### 1. Three commits on `main`

```text
$ git log --oneline
93bd124 Add salad recipe
2aeb14a Add pasta recipe
7dfba10 Initial commit: README
```

### 2. A feature branch with three more commits

```bash
git switch -c feature/desserts
# ... Add cake recipe / Fix pasta recipe: serve hot / Add ice cream recipe
```

```text
$ git log --oneline main..feature/desserts
594d423 Add ice cream recipe
ab07a67 Fix pasta recipe: serve hot        <- the ONE commit main needs
3ab68fd Add cake recipe
```

`main..feature/desserts` lists only the commits that are on the branch and not on main, which is the quickest way to find the hash you want.

### 3. Pick just the fix onto `main`

```text
$ git switch main
$ cat pasta.txt
pasta: boil, sauce, serve

$ git cherry-pick ab07a67
[main 14c9e0f] Fix pasta recipe: serve hot
 Date: Thu Sep 3 21:08:36 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
```

### 4. Verify

```text
$ cat pasta.txt
pasta: boil, sauce, serve hot              <- the fix is here

$ ls
pasta.txt README.md salad.txt              <- but NOT cake.txt / icecream.txt

$ git log --oneline --graph --all --decorate
* 594d423 (feature/desserts) Add ice cream recipe
* ab07a67 Fix pasta recipe: serve hot
* 3ab68fd Add cake recipe
| * 14c9e0f (HEAD -> main) Fix pasta recipe: serve hot
|/
* 93bd124 Add salad recipe
* 2aeb14a Add pasta recipe
* 7dfba10 Initial commit: README
```

Observations:

* The cherry-picked commit has a **new hash** (`14c9e0f` vs `ab07a67`) because it has a different parent, but the same message, author and diff. Git records the original author date; `-x` would append "(cherry picked from commit ab07a67)" to the message.
* Only the selected change moved. `git diff main feature/desserts --stat` shows the branch still has 2 files main does not.
* Useful variants: `git cherry-pick A B` (several), `git cherry-pick A^..B` (a range), `--no-commit` (stage only), `--abort`/`--continue` when there are conflicts.

### When to use it

Hot-fixes that must go to `main`/`release` right now while the rest of the feature is unfinished, or back-porting a fix to an older release branch. For everything else, `merge` or `rebase` keeps history simpler.
