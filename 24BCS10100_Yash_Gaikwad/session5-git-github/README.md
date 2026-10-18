# Session 5: Git and GitHub

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

This file shows the commands and their real output for both Git homework tasks:

1. [`git commit -a -m` vs `git commit -m`](#task-1-git-commit--a--m)
2. [Git cherry-pick](#task-2-git-cherry-pick)

Both were practised in throw-away repositories on Ubuntu (WSL2). Commit hashes will differ if you repeat the steps, everything else is the same.

---

## Task 1: `git commit -a -m`

### Concept

| | `git commit -m "msg"` | `git commit -a -m "msg"` (or `-am`) |
|---|---|---|
| What gets committed | Only what is already **staged** with `git add` | Every **modified or deleted tracked** file is staged automatically, then committed |
| New (untracked) files | Only if you `git add` them first | **Never** included, they must still be added once with `git add` |
| Nothing staged | Fails: "no changes added to commit" | Works if any tracked file changed |
| Control | Fine-grained, can commit just some files or hunks | Quick, but commits all tracked changes at once |

`-m` only supplies the message inline (instead of opening an editor); `-a` is the part that changes *what* is committed.

### Practice

_Create a repository and set my identity for it._

```console
$ git init -q -b main demo && cd demo && git config user.name "Yash Gaikwad" && git config user.email "gaikwad17yash@gmail.com" && git config color.ui false && git config core.pager cat && pwd
/home/gaikw/git-lab/demo
```

_Initial commit with three tracked files._

```console
$ cd demo && echo "version 1" > a.txt && echo "version 1" > b.txt && echo "keep me" > e.txt && git add . && git commit -m "Initial commit with a, b, e" && git log --oneline
[main (root-commit) cb69e96] Initial commit with a, b, e
 3 files changed, 3 insertions(+)
 create mode 100644 a.txt
 create mode 100644 b.txt
 create mode 100644 e.txt
cb69e96 Initial commit with a, b, e
```

### Experiment 1: `git commit -m` without `git add`

_a.txt is modified (" M" = changed, not staged) and c.txt is new (untracked "??")._

```console
$ cd demo && echo "version 2" >> a.txt && echo "brand new" > c.txt && git status -s
 M a.txt
?? c.txt
```

_Plain commit -m with nothing staged: Git refuses, it only commits staged changes._

```console
$ cd demo && git commit -m "Try commit without add"; echo "exit code: $?"
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   a.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	c.txt

no changes added to commit (use "git add" and/or "git commit -a")
exit code: 1
```

_After git add a.txt, commit -m works. c.txt is still untracked because I never added it._

```console
$ cd demo && git add a.txt && git commit -m "Update a.txt (staged with git add)" && git status -s
[main c4496ec] Update a.txt (staged with git add)
 1 file changed, 1 insertion(+)
?? c.txt
```

### Experiment 2: `git commit -a -m`

_b.txt modified, e.txt deleted (both tracked), d.txt is a new untracked file (c.txt is still untracked from before)._

```console
$ cd demo && echo "version 2" >> b.txt && echo "another new file" > d.txt && rm e.txt && git status -s
 M b.txt
 D e.txt
?? c.txt
?? d.txt
```

_One command stages and commits the modified and deleted tracked files, with no git add._

```console
$ cd demo && git commit -a -m "Update b.txt and delete e.txt using -a"
[main e3f01cb] Update b.txt and delete e.txt using -a
 2 files changed, 1 insertion(+), 1 deletion(-)
 delete mode 100644 e.txt
```

_The new files c.txt and d.txt were NOT committed: -a ignores untracked files._

```console
$ cd demo && git status -s
?? c.txt
?? d.txt
```

_The commit contains only b.txt (changed) and e.txt (deleted)._

```console
$ cd demo && git show --stat --format="%h %s" HEAD
e3f01cb Update b.txt and delete e.txt using -a

 b.txt | 1 +
 e.txt | 1 -
 2 files changed, 1 insertion(+), 1 deletion(-)
```

_New files must be added once with git add. History of the experiment:_

```console
$ cd demo && git add c.txt d.txt && git commit -m "Add c.txt and d.txt explicitly" && git log --oneline
[main a232a8b] Add c.txt and d.txt explicitly
 2 files changed, 2 insertions(+)
 create mode 100644 c.txt
 create mode 100644 d.txt
a232a8b Add c.txt and d.txt explicitly
e3f01cb Update b.txt and delete e.txt using -a
c4496ec Update a.txt (staged with git add)
cb69e96 Initial commit with a, b, e
```

### What I observed

- `git commit -m` alone commits **nothing** unless something is staged.
- `git commit -a -m` saves the `git add` step for files Git already tracks, including deletions.
- Neither command picks up brand-new files; `git add <new file>` is always needed first.
- Use `-m` when I want a precise, reviewed commit; use `-a -m` for quick commits of known tracked changes.

---

## Task 2: Git cherry-pick

### Concept

`git cherry-pick <commit>` copies **one commit's change** from anywhere onto the current branch as a *new* commit (new hash, same patch, same message). It is used to move a single bug fix between branches without merging the rest of the branch.

### Step 1: Create 3 commits on `main`

_Three commits on main. app.py has a typo ("Helo") that I will fix on the feature branch._

```console
$ git init -q -b main cherry && cd cherry && git config user.name "Yash Gaikwad" && git config user.email "gaikwad17yash@gmail.com" && git config color.ui false && git config core.pager cat && echo "# Cherry-pick demo" > README.md && git add README.md && git commit -m "Add README" && printf "print(\"Helo DevOps\")\n" > app.py && git add app.py && git commit -m "Add app.py (has a typo)" && echo "debug=false" > config.txt && git add config.txt && git commit -m "Add config.txt"
[main (root-commit) 3250aec] Add README
 1 file changed, 1 insertion(+)
 create mode 100644 README.md
[main 7a2f624] Add app.py (has a typo)
 1 file changed, 1 insertion(+)
 create mode 100644 app.py
[main 865e363] Add config.txt
 1 file changed, 1 insertion(+)
 create mode 100644 config.txt
```

_git log shows the 3 commits on main._

```console
$ cd cherry && git log --oneline
865e363 Add config.txt
7a2f624 Add app.py (has a typo)
3250aec Add README
```

### Step 2: Create a branch and make 3 commits

_New branch "feature" with 3 commits. The middle one fixes the typo (note I used commit -am here, from Task 1)._

```console
$ cd cherry && git switch -c feature && echo "login page" > feature1.txt && git add feature1.txt && git commit -m "Add feature 1 login page" && sed -i "s/Helo/Hello/" app.py && git commit -am "Fix typo in app.py" && echo "search page" > feature3.txt && git add feature3.txt && git commit -m "Add feature 3 search page"
Switched to a new branch 'feature'
[feature 8ee3a9f] Add feature 1 login page
 1 file changed, 1 insertion(+)
 create mode 100644 feature1.txt
[feature 20097b2] Fix typo in app.py
 1 file changed, 1 insertion(+), 1 deletion(-)
[feature 86f6f8b] Add feature 3 search page
 1 file changed, 1 insertion(+)
 create mode 100644 feature3.txt
```

### Step 3: Use `git log` to identify the commit to pick

_The graph shows main (3 commits) and feature (3 more on top). The commit I want is "Fix typo in app.py"._

```console
$ cd cherry && git log --oneline --graph --all
* 86f6f8b Add feature 3 search page
* 20097b2 Fix typo in app.py
* 8ee3a9f Add feature 1 login page
* 865e363 Add config.txt
* 7a2f624 Add app.py (has a typo)
* 3250aec Add README
```

_Find its hash by searching the message._

```console
$ cd cherry && git log feature --oneline --grep="Fix typo"
20097b2 Fix typo in app.py
```

_Inspect exactly what that commit changes: only app.py._

```console
$ cd cherry && git show --stat --format="commit %H%nAuthor: %an%nMessage: %s" $(git log feature --grep="Fix typo" -1 --format=%h)
commit 20097b2afe2ff081aa1f3f447bc0f1a37b671eaa
Author: Yash Gaikwad
Message: Fix typo in app.py

 app.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

_The patch itself._

```console
$ cd cherry && git show $(git log feature --grep="Fix typo" -1 --format=%h) --format= 
diff --git a/app.py b/app.py
index 7c8b687..a7f8e04 100644
--- a/app.py
+++ b/app.py
@@ -1 +1 @@
-print("Helo DevOps")
+print("Hello DevOps")
```

### Step 4: Cherry-pick that one commit into `main`

_Back on main before picking: the typo is still there and feature files do not exist._

```console
$ cd cherry && git switch main && cat app.py && ls
Switched to branch 'main'
print("Helo DevOps")
README.md
app.py
config.txt
```

_Apply only that commit onto main._

```console
$ cd cherry && git cherry-pick $(git log feature --grep="Fix typo" -1 --format=%h)
[main 1c9c464] Fix typo in app.py
 Date: Sun Oct 18 12:29:12 2026 +0000
 1 file changed, 1 insertion(+), 1 deletion(-)
```

### Step 5: Verify

_main now has a new commit "Fix typo in app.py" with a different hash than the original on feature (same change, new commit). The other feature commits are still only on feature._

```console
$ cd cherry && git log --oneline --graph --all
* 86f6f8b Add feature 3 search page
* 20097b2 Fix typo in app.py
* 8ee3a9f Add feature 1 login page
| * 1c9c464 Fix typo in app.py
|/  
* 865e363 Add config.txt
* 7a2f624 Add app.py (has a typo)
* 3250aec Add README
```

_The fix is in main (Hello), but feature1.txt and feature3.txt are NOT: only the selected commit was picked._

```console
$ cd cherry && cat app.py && echo "--- files on main:" && ls
print("Hello DevOps")
--- files on main:
README.md
app.py
config.txt
```

_Same message, two different hashes: the original on feature and the copy on main._

```console
$ cd cherry && git log main --format="%h %s" -1 && git log feature --format="%h %s" --grep="Fix typo" -1
1c9c464 Fix typo in app.py
20097b2 Fix typo in app.py
```

_The branches still differ by the two commits I did not pick._

```console
$ cd cherry && git diff main feature --stat
 feature1.txt | 1 +
 feature3.txt | 1 +
 2 files changed, 2 insertions(+)
```

### Notes for interviews

- A cherry-picked commit gets a **new hash** because its parent is different.
- If the change touches lines that differ on the target branch, Git stops with a conflict: fix the files, `git add`, then `git cherry-pick --continue` (or `--abort` to cancel).
- `git cherry-pick -x <hash>` appends "(cherry picked from commit ...)" to the message, useful for hotfix back-ports.
- Several commits: `git cherry-pick A B C` or a range `A^..C`.
