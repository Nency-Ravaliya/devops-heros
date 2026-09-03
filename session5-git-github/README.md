> **Submission for `session5-git-github`** — Kartikey, Enrollment No. **10121** ([@Json604](https://github.com/Json604)).
>
> Every command shown was actually executed and the output is copied in verbatim.
> Full working code, scripts and raw transcripts: <https://github.com/Json604/devops-assignments/tree/main/assignment-04-git>

# Assignment 4 — Git

**Session:** `session5-git-github` · **Author:** Kartikey (Json604) · **Enrollment No:** 10121

- **Task 1** — practice `git commit -a -m`, understand how it differs from `git commit -m`, and test both.
- **Task 2** — create commits on `main`, branch, commit there, then cherry-pick one specific commit back
  into `main` and verify it arrived.

Both exercises were run in throwaway repositories. Raw transcripts:
[`evidence/task1-commit-a-vs-m.txt`](https://github.com/Json604/devops-assignments/blob/main/assignment-04-git/evidence/task1-commit-a-vs-m.txt),
[`evidence/task2-cherry-pick.txt`](https://github.com/Json604/devops-assignments/blob/main/assignment-04-git/evidence/task2-cherry-pick.txt).

---

# Task 1 — `git commit -a -m` vs `git commit -m`

## First, the thing that makes it make sense: the staging area

Git has **three** places a file can be, not two:

```
  Working directory   →   Staging area (index)   →   Repository (commits)
   your edited files        `git add` puts            `git commit` records
                            files here                 what's here
```

`git commit` **only ever records what is in the staging area.** Every difference between the two commands
comes from how the staging area gets filled.

| | `git commit -m "msg"` | `git commit -a -m "msg"` |
|---|---|---|
| What it commits | **Only what you already staged** with `git add` | Stages all **modified** and **deleted tracked** files first, then commits |
| Needs `git add` first? | **Yes** | Not for files Git already tracks |
| Includes new/untracked files? | Only if you `git add` them | **No — never** |
| Includes deletions? | Only if staged (`git rm` / `git add -A`) | **Yes**, automatically |
| Steps | Two (`add` then `commit`) | One |
| Control | Full — you choose exactly what goes in | All-or-nothing across tracked files |
| Best for | Splitting work into clean, focused commits | Quick commits when you want everything you changed |

**In one line:** `-a` is a shortcut for "`git add` every tracked file that I modified or deleted, then
commit". It is *not* a shortcut for `git add .`, because it will not pick up files Git has never seen.

## Experiment 1 — plain `-m` with nothing staged

```console
########## EXPERIMENT 1: git commit -m WITH NOTHING STAGED ##########
--- modify a file that git is already TRACKING ---
$ echo "Line added to the tracked README" >> README.md

$ git status --short
 M README.md

$ git status
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")

--- now try to commit with plain -m (nothing was staged) ---
$ git commit -m "This will not work"; echo "exit code: $?"
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
exit code: 1

==> plain -m commits ONLY the staging area, and the staging area is empty.

```

The file was genuinely modified — `git status --short` shows ` M README.md` — yet the commit **failed with
exit code 1** and `no changes added to commit`. Git is not being difficult: the staging area was empty, and
`-m` commits the staging area, so there was literally nothing to record.

> The leading space in ` M` matters. `git status --short` prints **two** columns: the left is the *staging
> area*, the right is the *working directory*. ` M` means "modified, not staged". `M ` means "modified and
> staged". Reading that pair is the fastest way to know which command you need.

## Experiment 2 — the two-step way: `git add` then `git commit -m`

```console
########## EXPERIMENT 2: git add + git commit -m  (the two-step way) ##########
$ git add README.md

$ git status --short
M  README.md

$ git commit -m "Add a line to README (staged with git add first)"
[main 7353c4b] Add a line to README (staged with git add first)
 1 file changed, 1 insertion(+)

$ git log --oneline
7353c4b Add a line to README (staged with git add first)
5f95e7c Initial commit: add README

```

After `git add`, the status flipped from ` M` to `M ` — the change moved into the staging area — and the same
`git commit -m` that failed a moment ago now succeeded.

## Experiment 3 — the one-step way: `git commit -a -m`

```console
########## EXPERIMENT 3: git commit -a -m  (the one-step way) ##########
--- modify the tracked file again, and DO NOT run git add ---
$ echo "Another line, committed with -a" >> README.md

$ git status --short
 M README.md

$ git commit -a -m "Add another line using commit -a -m (no git add needed)"
[main 1e52131] Add another line using commit -a -m (no git add needed)
 1 file changed, 1 insertion(+)

$ git log --oneline
1e52131 Add another line using commit -a -m (no git add needed)
7353c4b Add a line to README (staged with git add first)
5f95e7c Initial commit: add README

==> -a automatically staged the modified TRACKED file, then committed it.

```

Same result, no `git add`. `-a` staged the tracked modification itself.

## Experiment 4 — the limit that catches people out

This is the part worth remembering. A tracked file was modified **and** a brand-new file was created, then
everything was committed with `-a`:

```console
########## EXPERIMENT 4: THE IMPORTANT LIMIT - -a IGNORES UNTRACKED FILES ##########
$ echo "brand new file" > newfile.txt

$ echo "modified again" >> README.md

$ git status --short
 M README.md
?? newfile.txt

--- ?? = untracked, M = modified tracked file ---
$ git commit -a -m "Trying to commit both a modified file and a NEW file with -a"
[main 94bc96d] Trying to commit both a modified file and a NEW file with -a
 1 file changed, 1 insertion(+)

--- what did that commit actually contain? ---
$ git show --stat --oneline HEAD
94bc96d Trying to commit both a modified file and a NEW file with -a
 README.md | 1 +
 1 file changed, 1 insertion(+)

$ git status --short
?? newfile.txt

==> README.md WAS committed. newfile.txt was NOT - it is still untracked.
==> -a means 'stage all modified and deleted TRACKED files'. It never adds new files.

```

`git status --short` before the commit showed both:

```
 M README.md      <- modified, tracked
?? newfile.txt    <- untracked; git has never seen this file
```

The commit reported **`1 file changed`**, and `git show --stat` confirms only `README.md` went in.
`newfile.txt` was left behind, still `??` after the commit.

**This is the classic mistake:** you write a new file, run `git commit -a -m "add feature"`, push, and the new
file is not there. `-a` means *"all modified and deleted **tracked** files"*. A file becomes tracked only when
you `git add` it at least once.

## Experiment 5 — new files require `git add`

```console
########## EXPERIMENT 5: NEW FILES NEED git add ##########
$ git add newfile.txt

$ git status --short
A  newfile.txt

$ git commit -m "Add newfile.txt (required an explicit git add)"
[main 740f37e] Add newfile.txt (required an explicit git add)
 1 file changed, 1 insertion(+)
 create mode 100644 newfile.txt

$ git show --stat --oneline HEAD
740f37e Add newfile.txt (required an explicit git add)
 newfile.txt | 1 +
 1 file changed, 1 insertion(+)

$ git status
On branch main
nothing to commit, working tree clean

```

Note the status code `A ` (added to the index) and the commit line `create mode 100644 newfile.txt`, which
appears only when a file enters the repository for the first time.

## Experiment 6 — `-a` does handle deletions

```console
########## EXPERIMENT 6: -a ALSO PICKS UP DELETIONS ##########
$ rm newfile.txt

$ git status --short
 D newfile.txt

$ git commit -a -m "Delete newfile.txt using -a"
[main b0907b2] Delete newfile.txt using -a
 1 file changed, 1 deletion(-)
 delete mode 100644 newfile.txt

$ git show --stat --oneline HEAD
b0907b2 Delete newfile.txt using -a
 newfile.txt | 1 -
 1 file changed, 1 deletion(-)

```

A plain `rm` showed as ` D newfile.txt`, and `-a` staged and committed the deletion without needing
`git rm`. So `-a` covers **modifications and deletions** of tracked files — everything except additions.

## Conclusion for Task 1

| Situation | Command |
|---|---|
| Edited existing files, want to commit all of it | `git commit -a -m "msg"` |
| Created new files | `git add <file>` then `git commit -m "msg"` |
| Want everything including new files | `git add -A` then `git commit -m "msg"` (or `git commit -am` after adding) |
| Want to commit only *some* of your changes | `git add <specific files>` then `git commit -m "msg"` |

`git add -A` (or `git add .`) is the true "everything" command; `-a` is not. My habit after this exercise:
run `git status` before committing, and if there is a `??` line, `-a` is the wrong command.

---

# Task 2 — Git Cherry-Pick

## What cherry-pick does

`git cherry-pick <commit>` takes the **diff introduced by one commit** and replays it on top of your current
branch as a **new commit**. Merge and rebase bring across a whole line of history; cherry-pick takes exactly
one commit and leaves the rest behind.

Typical reason to use it: a bug fix was committed on a long-running feature branch, and the fix is needed on
`main` now, but the rest of the unfinished feature is not.

## Step 1 — create 4 commits on `main`

```console
########## STEP 1: CREATE 4 COMMITS ON THE main BRANCH ##########
$ echo "<h1>My Shop</h1>" > index.html; git add index.html; git commit -m "Commit 1: add index.html homepage"
[main (root-commit) 6042c31] Commit 1: add index.html homepage
 1 file changed, 1 insertion(+)
 create mode 100644 index.html

$ echo "body { font-family: sans-serif; }" > style.css; git add style.css; git commit -m "Commit 2: add style.css"
[main ec29427] Commit 2: add style.css
 1 file changed, 1 insertion(+)
 create mode 100644 style.css

$ echo "console.log(\"app loaded\");" > app.js; git add app.js; git commit -m "Commit 3: add app.js"
[main f01431f] Commit 3: add app.js
 1 file changed, 1 insertion(+)
 create mode 100644 app.js

$ echo "# My Shop" > README.md; git add README.md; git commit -m "Commit 4: add README"
[main 6954eed] Commit 4: add README
 1 file changed, 1 insertion(+)
 create mode 100644 README.md

```

## Step 2 — view the commits with `git log`

```console
########## STEP 2: VIEW THE COMMITS WITH git log ##########
$ git log --oneline
6954eed Commit 4: add README
f01431f Commit 3: add app.js
ec29427 Commit 2: add style.css
6042c31 Commit 1: add index.html homepage

$ git log --oneline --graph --decorate
* 6954eed (HEAD -> main) Commit 4: add README
* f01431f Commit 3: add app.js
* ec29427 Commit 2: add style.css
* 6042c31 Commit 1: add index.html homepage

$ git log -2
commit 6954eed0e9e58f838b71dd9fccf5755a11b529f0
Author: Json604 <kartikey060105@gmail.com>
Date:   Thu Sep 3 01:24:01 2026 +0530

    Commit 4: add README

commit f01431f8e0052736aa5707bf07d6f095ff94aa56
Author: Json604 <kartikey060105@gmail.com>
Date:   Thu Sep 3 01:24:01 2026 +0530

    Commit 3: add app.js

--- files currently on main ---
$ ls -1
README.md
app.js
index.html
style.css

```

`git log --oneline` is the everyday form. `--graph --decorate` adds the branch topology and shows which
branch labels point where — essential once more than one branch exists.

## Step 3 — create a new branch

```console
########## STEP 3: CREATE A NEW BRANCH ##########
$ git branch feature-payments

$ git checkout feature-payments
Switched to branch 'feature-payments'

$ git branch -v
* feature-payments 6954eed Commit 4: add README
  main             6954eed Commit 4: add README

```

`git branch <name>` creates the branch; `git checkout <name>` switches to it. (`git checkout -b <name>` does
both, and modern Git also offers `git switch`.) `git branch -v` shows the `*` marking the current branch —
at this point both branches still point at the same commit, `6954eed`.

## Step 4 — make 3 commits on the new branch

```console
########## STEP 4: MAKE 3 COMMITS ON THE NEW BRANCH ##########
$ echo "function pay() { return \"paid\"; }" > payment.js; git add payment.js; git commit -m "Feature 1: add payment.js gateway stub"
[feature-payments 67f5f8e] Feature 1: add payment.js gateway stub
 1 file changed, 1 insertion(+)
 create mode 100644 payment.js

$ echo "function validateCard(n) { return n.length === 16; }" > validation.js; git add validation.js; git commit -m "Feature 2: add card validation helper"
[feature-payments f214b41] Feature 2: add card validation helper
 1 file changed, 1 insertion(+)
 create mode 100644 validation.js

$ echo "function checkout() { return true; }" > checkout.js; git add checkout.js; git commit -m "Feature 3: add checkout flow"
[feature-payments f342348] Feature 3: add checkout flow
 1 file changed, 1 insertion(+)
 create mode 100644 checkout.js

$ ls -1
README.md
app.js
checkout.js
index.html
payment.js
style.css
validation.js

```

## Step 5 — use `git log` to identify the specific commit

```console
########## STEP 5: USE git log TO IDENTIFY THE SPECIFIC COMMIT ##########
$ git log --oneline
f342348 Feature 3: add checkout flow
f214b41 Feature 2: add card validation helper
67f5f8e Feature 1: add payment.js gateway stub
6954eed Commit 4: add README
f01431f Commit 3: add app.js
ec29427 Commit 2: add style.css
6042c31 Commit 1: add index.html homepage

$ git log --oneline --graph --decorate --all
* f342348 (HEAD -> feature-payments) Feature 3: add checkout flow
* f214b41 Feature 2: add card validation helper
* 67f5f8e Feature 1: add payment.js gateway stub
* 6954eed (main) Commit 4: add README
* f01431f Commit 3: add app.js
* ec29427 Commit 2: add style.css
* 6042c31 Commit 1: add index.html homepage

--- I want ONLY the card-validation fix on main, not the whole feature branch ---
$ git log --oneline --grep="validation"
f214b41 Feature 2: add card validation helper

$ TARGET=$(git log --format="%H" --grep="card validation" -1)
Target commit: f214b41 (f214b41fd5359f6398e08d4dd7129b0d4d8c05b4)

$ git show --stat f214b41
commit f214b41fd5359f6398e08d4dd7129b0d4d8c05b4
Author: Json604 <kartikey060105@gmail.com>
Date:   Thu Sep 3 01:24:02 2026 +0530

    Feature 2: add card validation helper

 validation.js | 1 +
 1 file changed, 1 insertion(+)

```

The `--graph --decorate --all` view shows exactly the situation cherry-pick exists for: `main` is parked at
`6954eed` while `feature-payments` has moved three commits ahead.

Only the **card validation** work is wanted on `main` — not the payment gateway stub, not the checkout flow.
`git log --grep="validation"` located it as **`f214b41`**, and `git show --stat` confirmed it touches exactly
one file, `validation.js`.

> Useful ways to find a commit: `git log --oneline`, `git log --grep="text"` (search messages),
> `git log -S"code"` (search for commits that changed a string), `git log --author=...`,
> `git log -- <path>` (commits touching a file).

## Step 6 — switch back to `main` and cherry-pick

```console
########## STEP 6: SWITCH BACK TO main AND CHERRY-PICK ##########
$ git checkout main
Switched to branch 'main'

--- state of main BEFORE the cherry-pick ---
$ git log --oneline
6954eed Commit 4: add README
f01431f Commit 3: add app.js
ec29427 Commit 2: add style.css
6042c31 Commit 1: add index.html homepage

$ ls -1
README.md
app.js
index.html
style.css

$ cat validation.js
cat: validation.js: No such file or directory

--- cherry-pick that one commit ---
$ git cherry-pick f214b41
[main 77963a1] Feature 2: add card validation helper
 Date: Thu Sep 3 01:24:02 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 validation.js

```

Before the cherry-pick, `main` had four files and `cat validation.js` returned
`No such file or directory` — the change genuinely was not there.

## Step 7 — verify the change is now on `main`

```console
########## STEP 7: VERIFY THE CHANGE IS NOW ON main ##########
--- (a) the commit appears in main's history ---
$ git log --oneline
77963a1 Feature 2: add card validation helper
6954eed Commit 4: add README
f01431f Commit 3: add app.js
ec29427 Commit 2: add style.css
6042c31 Commit 1: add index.html homepage

--- (b) the file now exists on main ---
$ ls -1
README.md
app.js
index.html
style.css
validation.js

$ cat validation.js
function validateCard(n) { return n.length === 16; }

--- (c) the content is identical to the original commit ---
$ git show --stat HEAD
commit 77963a1b539a91df9241dd35582c725929e11b09
Author: Json604 <kartikey060105@gmail.com>
Date:   Thu Sep 3 01:24:02 2026 +0530

    Feature 2: add card validation helper

 validation.js | 1 +
 1 file changed, 1 insertion(+)

--- (d) but the HASH IS DIFFERENT - it is a NEW commit object ---
$ echo "original on feature-payments : f214b41"
original on feature-payments : f214b41
$ echo "new copy on main             : $(git rev-parse --short HEAD)"
new copy on main             : 77963a1

--- (e) the two commits introduce the SAME patch ---
$ git show f214b41 --format='' 
diff --git a/validation.js b/validation.js
new file mode 100644
index 0000000..722368c
--- /dev/null
+++ b/validation.js
@@ -0,0 +1 @@
+function validateCard(n) { return n.length === 16; }

$ git show HEAD --format=''
diff --git a/validation.js b/validation.js
new file mode 100644
index 0000000..722368c
--- /dev/null
+++ b/validation.js
@@ -0,0 +1 @@
+function validateCard(n) { return n.length === 16; }

--- (f) proof they are equivalent: identical patch-id ---
$ git show f214b41 | git patch-id --stable
a5b26a02c0ec4c26c72b31077b21fbc23290a9fa f214b41fd5359f6398e08d4dd7129b0d4d8c05b4

$ git show HEAD | git patch-id --stable
a5b26a02c0ec4c26c72b31077b21fbc23290a9fa 77963a1b539a91df9241dd35582c725929e11b09

--- (g) only THAT commit came across; the other two are still only on the branch ---
$ git log --oneline --graph --decorate --all
* f342348 (feature-payments) Feature 3: add checkout flow
* f214b41 Feature 2: add card validation helper
* 67f5f8e Feature 1: add payment.js gateway stub
| * 77963a1 (HEAD -> main) Feature 2: add card validation helper
|/  
* 6954eed Commit 4: add README
* f01431f Commit 3: add app.js
* ec29427 Commit 2: add style.css
* 6042c31 Commit 1: add index.html homepage

$ git branch --contains HEAD
* main

--- payment.js and checkout.js must NOT be on main ---
$ ls -1
README.md
app.js
index.html
style.css
validation.js

$ git log main --oneline -- payment.js checkout.js; echo "(empty above = those commits are not on main)"
(empty above = those commits are not on main)

```

## Verification summary

| # | Check | Result |
|---|---|---|
| a | Commit is in `main`'s history | `77963a1 Feature 2: add card validation helper` at the top of `git log` |
| b | The file exists on `main` | `validation.js` now present; `cat` returns the function |
| c | Same content as the original | `git show --stat` — `validation.js \| 1 +`, 1 insertion |
| d | Hash **differs** | original `f214b41` → new `77963a1` |
| e | Same patch | both diffs identical, both create `validation.js` with the same line |
| f | Provably equivalent | identical `patch-id` `a5b26a02…` for both commits |
| g | Nothing else came across | `payment.js` and `checkout.js` absent from `main`; `git log -- payment.js checkout.js` is empty on `main` |

## What I understood

**A cherry-pick creates a new commit, it does not move one.** The original `f214b41` is still on
`feature-payments`; `main` got `77963a1`, a *different* commit object. The hash differs because a commit hash
covers the parent, timestamp and author as well as the content — and the parent here is `6954eed` on `main`,
not `67f5f8e` on the branch.

**`git patch-id` is the proof that matters.** Both commits produce `a5b26a02c0ec4c26c72b31077b21fbc23290a9fa`,
which is the hash of the *diff alone*, ignoring parent and timestamp. Same patch, different commit. That is
precisely what a cherry-pick is.

**The graph shows the duplication:**

```
* f342348 (feature-payments) Feature 3: add checkout flow
* f214b41 Feature 2: add card validation helper      <- original
* 67f5f8e Feature 1: add payment.js gateway stub
| * 77963a1 (HEAD -> main) Feature 2: add card validation helper   <- the copy
|/
* 6954eed (main~1) Commit 4: add README
```

The same change now exists twice in the repository. That is the real cost of cherry-picking: when
`feature-payments` is eventually merged into `main`, Git has to reconcile the duplicate. It usually manages
(it recognises the identical patch), but it can produce a conflict — which is why cherry-pick is for genuine
"I need this one fix now" cases, not a substitute for merging.

**Cherry-pick is precise, merge is wholesale.** `git merge feature-payments` would have brought all three
feature commits and `payment.js`/`checkout.js` with them. Verified: after the cherry-pick, `main` has
`validation.js` and *only* `validation.js` from that branch.

## Cherry-pick options worth knowing

```bash
git cherry-pick <hash>              # replay one commit onto the current branch
git cherry-pick <h1> <h2> <h3>      # several commits, in the order given
git cherry-pick <start>..<end>      # a range (start exclusive)
git cherry-pick -n <hash>           # apply to working dir + index, but DON'T commit
git cherry-pick -x <hash>           # add "(cherry picked from commit ...)" to the message
git cherry-pick -e <hash>           # edit the commit message while picking
```

`-x` is genuinely worth using on shared branches — it records the provenance in the message, so six months
later you can see where a duplicated commit came from.

**When a cherry-pick conflicts:**

```bash
git status                  # see the conflicting files
# ... edit the files to resolve the conflict markers ...
git add <resolved files>
git cherry-pick --continue  # finish it
# or
git cherry-pick --abort     # give up, return to the state before the pick
git cherry-pick --skip      # skip this commit and continue a multi-commit pick
```

This pick applied cleanly because `validation.js` was a new file that `main` did not have — nothing to
conflict with.
