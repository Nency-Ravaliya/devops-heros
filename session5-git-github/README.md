# Git & GitHub Homework Tasks

This document contains detailed explanations, step-by-step test cases, and command outputs for the Git homework tasks.

---

## Task 1: `git commit -a -m` vs `git commit -m`

### 1. Conceptual Difference

| Feature | `git commit -m "message"` | `git commit -a -m "message"` |
|---|---|---|
| **Staging requirement** | Only commits changes that have been explicitly staged using `git add` | Automatically stages **tracked** modified or deleted files and commits them |
| **Handling New (Untracked) Files** | Does not commit untracked files unless `git add` was run | **Ignores** new/untracked files (they remain untracked) |
| **Flag Meaning** | `-m` specifies the commit message inline | `-a` (all) stages modified tracked files; `-m` provides the commit message |
| **Workflow** | `git add <file>` followed by `git commit -m "msg"` | Single-step shortcut: `git commit -am "msg"` for already tracked files |

---

### 2. Practical Test & Demonstration

#### Step 1: Create an Initial Tracked File
```bash
echo "Original Content" > tracked_file.txt
git add tracked_file.txt
git commit -m "Initial commit of tracked_file"
```

#### Step 2: Modify the Tracked File & Create an Untracked File
```bash
echo "Updated Content" >> tracked_file.txt
echo "I am a brand new file" > new_untracked_file.txt
git status -s
```
*Output:*
```text
 M tracked_file.txt
?? new_untracked_file.txt
```

#### Step 3: Test `git commit -m` without `git add`
```bash
git commit -m "Attempting commit without add"
```
*Output:*
```text
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
	modified:   tracked_file.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	new_untracked_file.txt

no changes added to commit (use "git add" to track)
```
*(Result: The commit fails because nothing was staged).*

#### Step 4: Test `git commit -a -m`
```bash
git commit -a -m "Using -a flag to commit modified tracked file"
```
*Output:*
```text
[main a8921cf] Using -a flag to commit modified tracked file
 1 file changed, 1 insertion(+)
```

#### Step 5: Verify the Result
```bash
git status -s
```
*Output:*
```text
?? new_untracked_file.txt
```
*(Key observation: `tracked_file.txt` was automatically staged and committed, but `new_untracked_file.txt` was ignored because `-a` does not automatically track newly created files).*

---

## Task 2: Git Cherry-Pick

`git cherry-pick` is a powerful command that enables you to select an individual commit from one branch and apply its exact changes onto your current working branch without merging the whole branch.

---

### Step-by-Step Walkthrough

#### Step 1: Create Baseline Commits on the `main` Branch
```bash
git checkout main
echo "Main commit 1" >> main_log.txt && git commit -am "feat: main feature 1"
echo "Main commit 2" >> main_log.txt && git commit -am "feat: main feature 2"
echo "Main commit 3" >> main_log.txt && git commit -am "feat: main feature 3"
git log --oneline -n 3
```
*Output:*
```text
3c81e92 (HEAD -> main) feat: main feature 3
b528190 feat: main feature 2
f1092a4 feat: main feature 1
```

---

#### Step 2: Create a New Feature Branch
```bash
git checkout -b feature-cherry
```
*Output:*
```text
Switched to a new branch 'feature-cherry'
```

---

#### Step 3: Make Commits in the New Branch
```bash
echo "Feature work A" > feature.txt && git add feature.txt && git commit -m "feat(cherry): feature component A"
echo "Critical Bug Fix" > bugfix.txt && git add bugfix.txt && git commit -m "fix(cherry): critical security patch"
echo "Feature work B" >> feature.txt && git commit -am "feat(cherry): feature component B"
git log --oneline -n 3
```
*Output:*
```text
e91b423 (HEAD -> feature-cherry) feat(cherry): feature component B
d48f712 fix(cherry): critical security patch
7a32c01 feat(cherry): feature component A
```

---

#### Step 4: Identify the Specific Commit to Cherry-Pick
Suppose production on `main` immediately needs the bug fix (`d48f712: fix(cherry): critical security patch`), but the rest of `feature-cherry` is not ready to be merged.

---

#### Step 5: Cherry-Pick the Commit into `main`
```bash
# Switch back to the target branch (main)
git checkout main

# Cherry-pick the target commit
git cherry-pick d48f712
```
*Output:*
```text
[main 9d42f81] fix(cherry): critical security patch
 Date: Sun Sep 6 20:31:50 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 bugfix.txt
```

---

#### Step 6: Verify the Commit on `main`
```bash
git log --oneline -n 2
ls -l bugfix.txt
cat bugfix.txt
```
*Output:*
```text
9d42f81 (HEAD -> main) fix(cherry): critical security patch
3c81e92 feat: main feature 3

-rw-r--r-- 1 student student 18 Sep  6 20:32 bugfix.txt
Critical Bug Fix
```
*(Notice that `bugfix.txt` is now cleanly present in `main` with a newly generated commit hash `9d42f81`, while `feature.txt` remains isolated on `feature-cherry` without unintended code leakage).*
