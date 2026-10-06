# Session 05 — Git & GitHub

| | |
|---|---|
| **Student** | Ujjawal Prabhat |
| **Enrollment No.** | 24BCS10267 |
| **Session** | 05 — Git & GitHub |

## Task checklist

- [x] Task 1 — `git commit -a -m` vs `git commit -m` (show that `-a` stages modified tracked files but **not** new untracked files, with `git status` before and after)
- [x] Task 2 — Cherry-pick: commits on `main`, a new branch with 3 commits, find one commit by hash, cherry-pick it into `main`, verify with `git log`, the file contents and `git log --oneline --graph --all`

## Setup

I did everything in a separate practice repo outside this course repo (`practice-repo/` in a scratch folder on my Mac, `git version 2.54.0 (Apple Git-157)`). The outputs below were copied from the terminal. I actually ran the git commands as `git -C <path-to-practice-repo> ...`, which does the same thing as running them inside that folder, so here they are shown in the shorter form.

```console
$ mkdir practice-repo && cd practice-repo
$ git init -b main
Initialized empty Git repository in /private/tmp/.../scratchpad/practice-repo/.git/
$ git config user.name "Ujjawal Prabhat"
$ git config user.email "ujjawalprabhat1@gmail.com"
```

---

## Task 1 — `git commit -a -m` vs `git commit -m`

### Theory

Git has three areas: the **working directory** (your files), the **staging area / index** (what will go into the next commit), and the **repository** (the commits).

- `git commit -m "msg"` commits **only what is already staged** with `git add`.
- `git commit -a -m "msg"` (or `-am`) first **automatically stages every modified or deleted file that Git already tracks**, then commits. It **does not** pick up **new, untracked files**. Those always need an explicit `git add`.

### Step 1 — initial commit

```console
$ echo "App version 1" > app.txt
$ echo "Notes v1" > notes.txt
$ git add app.txt notes.txt
$ git commit -m "Initial commit: add app.txt and notes.txt"
[main (root-commit) ad5b2f8] Initial commit: add app.txt and notes.txt
 2 files changed, 2 insertions(+)
 create mode 100644 app.txt
 create mode 100644 notes.txt
```

### Step 2 — modify a tracked file and create a new untracked file

```console
$ echo "App version 2 - edited" >> app.txt
$ echo "I am a brand new file" > newfile.txt
$ cat app.txt
App version 1
App version 2 - edited
$ git status
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   app.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	newfile.txt

no changes added to commit (use "git add" and/or "git commit -a")
```

### Step 3 — plain `git commit -m` with nothing staged → nothing is committed

```console
$ git commit -m "Try commit without staging"; echo "exit code: $?"
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   app.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	newfile.txt

no changes added to commit (use "git add" and/or "git commit -a")
exit code: 1
```

`git commit -m` refused (exit code 1) because the staging area was empty. Git even suggests `git commit -a`.

### Step 4 — `git commit -a -m` → the modified file is committed, the new file is not

```console
$ git commit -a -m "Update app.txt using commit -a"
[main 99b0c54] Update app.txt using commit -a
 1 file changed, 1 insertion(+)

$ git status
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	newfile.txt

nothing added to commit but untracked files present (use "git add" to track)

$ git show --stat --oneline HEAD
99b0c54 Update app.txt using commit -a
 app.txt | 1 +
 1 file changed, 1 insertion(+)
```

**Result:** `-a` staged and committed `app.txt` (tracked and modified), but `newfile.txt` is **still untracked**. It is not in the commit.

### Step 5 — `git commit -m` commits only what I staged

This time I changed **both** tracked files but only staged `notes.txt` (and the new file):

```console
$ echo "Notes v2" >> notes.txt
$ echo "App version 3" >> app.txt
$ git add notes.txt newfile.txt
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   newfile.txt
	modified:   notes.txt

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   app.txt

$ git commit -m "Add newfile.txt and update notes (staged with git add)"
[main dfa806d] Add newfile.txt and update notes (staged with git add)
 2 files changed, 2 insertions(+)
 create mode 100644 newfile.txt

$ git status --short
 M app.txt
```

`git commit -m` committed only the two staged files. `app.txt` stayed modified and was left out. This control is the reason to use `git add` + `git commit -m`: you choose exactly what goes into each commit.

### Step 6 — finish with `-am`

```console
$ git commit -am "Update app.txt to version 3"
[main 9483d14] Update app.txt to version 3
 1 file changed, 1 insertion(+)

$ git status
On branch main
nothing to commit, working tree clean

$ git log --oneline --stat
9483d14 Update app.txt to version 3
 app.txt | 1 +
 1 file changed, 1 insertion(+)
dfa806d Add newfile.txt and update notes (staged with git add)
 newfile.txt | 1 +
 notes.txt   | 1 +
 2 files changed, 2 insertions(+)
99b0c54 Update app.txt using commit -a
 app.txt | 1 +
 1 file changed, 1 insertion(+)
ad5b2f8 Initial commit: add app.txt and notes.txt
 app.txt   | 1 +
 notes.txt | 1 +
 2 files changed, 2 insertions(+)
```

### Summary

| | `git commit -m` | `git commit -a -m` |
|---|---|---|
| Commits staged changes | Yes | Yes |
| Auto-stages modified tracked files | No | **Yes** |
| Auto-stages deleted tracked files | No | **Yes** |
| Includes new untracked files | No (needs `git add`) | **No** (still needs `git add`) |
| Good for | Picking exactly what goes into a commit | Quickly committing all edits to files Git already knows |

---

## Task 2 — Cherry-pick

### Theory

`git cherry-pick <hash>` takes the **changes introduced by one commit** on another branch and applies them as a **new commit** on the current branch. Typical use: a bug fix was made on a feature branch that isn't ready to merge, but the fix is needed on `main` right now. Cherry-pick copies only that fix, not the whole branch.

### Step 1 — commits on `main`

From Task 1, `main` already has 4 commits:

```console
$ git log --oneline
9483d14 Update app.txt to version 3
dfa806d Add newfile.txt and update notes (staged with git add)
99b0c54 Update app.txt using commit -a
ad5b2f8 Initial commit: add app.txt and notes.txt
```

### Step 2 — new branch with 3 commits

```console
$ git checkout -b feature
Switched to a new branch 'feature'

$ printf "def login():\n    return 'login page (work in progress)'\n" > login.py
$ cat login.py
def login():
    return 'login page (work in progress)'
$ git add login.py
$ git commit -m "feature: start login page (WIP)"
[feature b523ede] feature: start login page (WIP)
 1 file changed, 2 insertions(+)
 create mode 100644 login.py

$ printf "def divide(a, b):\n    if b == 0:\n        return None  # fix: avoid ZeroDivisionError\n    return a / b\n" > utils.py
$ cat utils.py
def divide(a, b):
    if b == 0:
        return None  # fix: avoid ZeroDivisionError
    return a / b
$ git add utils.py
$ git commit -m "fix: handle division by zero in utils.divide"
[feature b9beb7e] fix: handle division by zero in utils.divide
 1 file changed, 4 insertions(+)
 create mode 100644 utils.py

$ printf "    # TODO: add password check\n" >> login.py
$ cat login.py
def login():
    return 'login page (work in progress)'
    # TODO: add password check
$ git commit -am "feature: add TODO for password check"
[feature d9ac522] feature: add TODO for password check
 1 file changed, 1 insertion(+)
```

### Step 3 — find the commit to pick by its hash

```console
$ git log --oneline
d9ac522 feature: add TODO for password check
b9beb7e fix: handle division by zero in utils.divide
b523ede feature: start login page (WIP)
9483d14 Update app.txt to version 3
dfa806d Add newfile.txt and update notes (staged with git add)
99b0c54 Update app.txt using commit -a
ad5b2f8 Initial commit: add app.txt and notes.txt

$ git log --oneline main..feature
d9ac522 feature: add TODO for password check
b9beb7e fix: handle division by zero in utils.divide
b523ede feature: start login page (WIP)

$ git show --stat b9beb7e
commit b9beb7ee36f1cc81dd25552e18a3f6e0216fdd7b
Author: Ujjawal Prabhat <ujjawalprabhat1@gmail.com>
Date:   Tue Oct 6 19:18:27 2026 +0800

    fix: handle division by zero in utils.divide

 utils.py | 4 ++++
 1 file changed, 4 insertions(+)
```

`main..feature` lists the commits that are on `feature` but not on `main`. The one I want on `main` is the bug fix, **`b9beb7e`**. The two login commits are unfinished work and must stay on the feature branch.

### Step 4 — cherry-pick it into `main`

```console
$ git checkout main
Switched to branch 'main'

$ ls
app.txt
newfile.txt
notes.txt

$ git cherry-pick b9beb7e
[main 4b61b9a] fix: handle division by zero in utils.divide
 Date: Tue Oct 6 19:18:27 2026 +0800
 1 file changed, 4 insertions(+)
 create mode 100644 utils.py
```

### Step 5 — verify

**`git log`:** the fix is on `main` as a **new commit with a new hash** (`4b61b9a`, not `b9beb7e`), because its parent is different. The original author date is kept.

```console
$ git log --oneline
4b61b9a fix: handle division by zero in utils.divide
9483d14 Update app.txt to version 3
dfa806d Add newfile.txt and update notes (staged with git add)
99b0c54 Update app.txt using commit -a
ad5b2f8 Initial commit: add app.txt and notes.txt
```

**File content:** `utils.py` is now on `main`. `login.py` is **not**, because only the one commit was copied.

```console
$ ls
app.txt
newfile.txt
notes.txt
utils.py

$ cat utils.py
def divide(a, b):
    if b == 0:
        return None  # fix: avoid ZeroDivisionError
    return a / b

$ git status
On branch main
nothing to commit, working tree clean
```

**Graph of all branches:**

```console
$ git log --oneline --graph --all
* 4b61b9a fix: handle division by zero in utils.divide
| * d9ac522 feature: add TODO for password check
| * b9beb7e fix: handle division by zero in utils.divide
| * b523ede feature: start login page (WIP)
|/  
* 9483d14 Update app.txt to version 3
* dfa806d Add newfile.txt and update notes (staged with git add)
* 99b0c54 Update app.txt using commit -a
* ad5b2f8 Initial commit: add app.txt and notes.txt
```

The graph shows the two branches splitting after `9483d14`. The fix appears on **both** branches (`b9beb7e` on feature, `4b61b9a` on main) with the same message, but `main` did **not** get the login commits.

**Extra check with `git cherry`:** it compares commits by their patch content, not their hash:

```console
$ git cherry -v main feature
+ b523ede20daef16351ba6e7b1565fa7295efcb24 feature: start login page (WIP)
- b9beb7ee36f1cc81dd25552e18a3f6e0216fdd7b fix: handle division by zero in utils.divide
+ d9ac522943f41220613879e35ad0fd277014f2d1 feature: add TODO for password check
```

`-` means the same change already exists on `main` (our cherry-pick), and `+` means not yet applied.

### Notes on cherry-pick

- It creates a **new commit**, so the same change has two hashes. If `feature` is merged later, Git usually notices the change is identical and handles it cleanly.
- If the picked change touches lines that differ on the target branch, you get a **conflict**: fix the files, `git add` them, then run `git cherry-pick --continue`. `git cherry-pick --abort` cancels.
- Use `git cherry-pick -x <hash>` to add "(cherry picked from commit ...)" to the message, which helps trace it later.
- You can pick several at once: `git cherry-pick A B` or a range `A^..B`.
