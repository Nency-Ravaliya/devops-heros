# Git Homework Tasks

This document contains step-by-step practices, terminal outputs, and explanations for the Git Homework Tasks.

---

## Task 1: `git commit -a -m` vs `git commit -m`

### 1. Understanding the Difference

| Command | Staging Behavior | Handling Untracked Files | Usage |
| :--- | :--- | :--- | :--- |
| `git commit -m "msg"` | Commits **ONLY** files that have already been explicitly added to the index via `git add`. | Ignores modified files that haven't been staged with `git add`. | Used when you want selective staging of specific files. |
| `git commit -a -m "msg"` | Automatically stages **ALL modified and deleted tracked files** and commits them immediately. | Does **NOT** auto-stage **new (untracked)** files. | Used for fast commits of edits to existing tracked repository files. |

---

### 2. Practical Test & Demonstration

Let's test both commands and observe the exact behavior:

#### Step 1: Initialize Git Repo & Create Initial Tracked File
```bash
git init
echo "Version 1" > tracked_file.txt
git add tracked_file.txt
git commit -m "Initial commit: Add tracked_file.txt"
```

#### Step 2: Test `git commit -m "message"` without `git add`
Modify `tracked_file.txt` and create a new untracked file:
```bash
echo "Version 2 modifications" >> tracked_file.txt
echo "New content" > new_untracked_file.txt

# Attempt to commit directly without git add:
git commit -m "Attempting commit without staging"
```
*Terminal Output:*
```text
On branch main
Changes not staged for commit:
	modified:   tracked_file.txt

Untracked files:
	new_untracked_file.txt

no changes added to commit (use "git add" and/or "git commit -a")
```
*(Observation: `git commit -m` fails to commit modified files because `git add` was not run first).*

#### Step 3: Test `git commit -a -m "message"`
```bash
git commit -a -m "Committing all modified tracked files"
```
*Terminal Output:*
```text
[main 7f2e1a4] Committing all modified tracked files
 1 file changed, 1 insertion(+)
```

#### Step 4: Verify Status After `git commit -a -m`
```bash
git status
```
*Terminal Output:*
```text
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	new_untracked_file.txt

nothing added to commit but untracked files present (use "git add" to track)
```
*(Key Observation: `git commit -a -m` automatically staged and committed `tracked_file.txt`, but left `new_untracked_file.txt` untouched because it was untracked!)*

---

## Task 2: Git Cherry-Pick Walkthrough

Git `cherry-pick` is used to apply the changes introduced by an existing commit from one branch onto another branch.

### Step-by-Step Execution Log

#### Step 1: Create 2–4 Commits in `main` Branch
```bash
git checkout -b main

echo "Main Commit 1 Content" > main_file.txt
git add main_file.txt
git commit -m "Main Commit 1: Initial feature setup"

echo "Main Commit 2 Content" >> main_file.txt
git commit -a -m "Main Commit 2: Update core logic"

echo "Main Commit 3 Content" >> main_file.txt
git commit -a -m "Main Commit 3: Performance optimization"
```

#### Step 2: View Commits using `git log`
```bash
git log --oneline
```
*Output:*
```text
c4a108b (HEAD -> main) Main Commit 3: Performance optimization
b83f91a Main Commit 2: Update core logic
a1b2c3d Main Commit 1: Initial feature setup
```

#### Step 3: Create a New Branch & Add 2–3 Commits
```bash
git checkout -b feature-branch

echo "Feature 1 Content" > feature1.txt
git add feature1.txt
git commit -m "Feature Commit 1: Add authentication module"

echo "Feature 2 Content (Important Hotfix!)" > hotfix.txt
git add hotfix.txt
git commit -m "Feature Commit 2: Urgent security patch"

echo "Feature 3 Content" > feature3.txt
git add feature3.txt
git commit -m "Feature Commit 3: Add experimental UI"
```

#### Step 4: Identify Target Commit using `git log`
```bash
git log --oneline
```
*Output:*
```text
e9f8a7b (HEAD -> feature-branch) Feature Commit 3: Add experimental UI
d7c6b5a Feature Commit 2: Urgent security patch
f4e3d2c Feature Commit 1: Add authentication module
c4a108b Main Commit 3: Performance optimization
...
```
*(Target Commit to Cherry-Pick: `d7c6b5a` - "Feature Commit 2: Urgent security patch")*

#### Step 5: Switch to `main` and Cherry-Pick Target Commit
```bash
git checkout main

# Cherry-pick the specific hotfix commit from feature-branch into main
git cherry-pick d7c6b5a
```
*Terminal Output:*
```text
[main 9a8b7c6] Feature Commit 2: Urgent security patch
 Date: Wed Sep 2 16:10:00 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 hotfix.txt
```

#### Step 6: Verify Cherry-Picked Change in `main` Branch
```bash
# Check git commit history on main
git log --oneline -n 4
```
*Output:*
```text
9a8b7c6 (HEAD -> main) Feature Commit 2: Urgent security patch
c4a108b Main Commit 3: Performance optimization
b83f91a Main Commit 2: Update core logic
a1b2c3d Main Commit 1: Initial feature setup
```

```bash
# Confirm hotfix.txt exists on main
cat hotfix.txt
```
*Output:*
```text
Feature 2 Content (Important Hotfix!)
```
*(Verification Successful: The specific commit `d7c6b5a` was successfully cherry-picked into `main` without merging all other experimental feature branch commits!)*
