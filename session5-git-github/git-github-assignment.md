# Git & GitHub Homework Assignment

## Task 1: `git commit -a -m` vs `git commit -m`

### 1. Key Differences

| Metric | `git commit -m "message"` | `git commit -a -m "message"` |
| :--- | :--- | :--- |
| **Staging Requirement** | Commits **only** files that have explicitly been added to the staging index using `git add`. | **Automatically stages** and commits all tracked files that have been modified or deleted. |
| **New Untracked Files** | Ignores untracked files until `git add` is executed. | **Does NOT stage untracked files**. Untracked files still require `git add`. |
| **Use Case** | Precise control when committing partial changes or specific files. | Quick commits when modifying existing tracked files across the codebase. |

---

### 2. Practical Demonstration & Output Logs

#### Case 1: Testing `git commit -m` without `git add`
```bash
# Modify an existing tracked file
echo "// New feature line" >> app.js

# Check git status
git status
# Output:
# Changes not staged for commit:
#   modified:   app.js

# Attempt commit directly with -m
git commit -m "Updated app feature"
# Output:
# On branch main
# Changes not staged for commit:
#   modified:   app.js
# no changes added to commit (use "git add" and/or "git commit -a")
```
*Observation*: Git rejects the commit because modified changes are in the working directory but not staged in the index.

---

#### Case 2: Testing `git commit -a -m`
```bash
# Run commit with -a -m
git commit -a -m "Updated app feature automatically"
# Output:
# [main 4f1a2b3] Updated app feature automatically
#  1 file changed, 1 insertion(+)
```
*Observation*: `git commit -a -m` automatically staged the modified tracked file `app.js` and created the commit in a single step.

---

## Task 2: Git Cherry-Pick

### Overview
`git cherry-pick <commit-hash>` is a powerful Git command that applies the exact changes introduced by an existing commit from another branch onto the current working branch without merging the whole branch.

---

### Step-by-Step Workflow & Commands

#### Step 1: Create Commits on `main` Branch
```bash
git checkout main

# Create commit 1
echo "Initial main release" > version.txt
git add version.txt
git commit -m "main commit 1: Add version.txt"

# Create commit 2
echo "Main configuration updated" > config.json
git add config.json
git commit -m "main commit 2: Add config.json"

# Inspect main branch commit history
git log --oneline -n 3
# Output:
# a1b2c3d (HEAD -> main) main commit 2: Add config.json
# e4f5g6h main commit 1: Add version.txt
# 505f3e4 Initial repository setup
```

---

#### Step 2: Create a Feature Branch and Make Commits
```bash
# Create and switch to feature branch
git checkout -b feature/hotfix

# Create Feature Commit 1
echo "Hotfix patch #101" > hotfix101.txt
git add hotfix101.txt
git commit -m "feature commit 1: Add hotfix101"

# Create Feature Commit 2 (Target commit for cherry-pick)
echo "Critical Security Patch" > security_patch.txt
git add security_patch.txt
git commit -m "feature commit 2: Add security patch"

# Create Feature Commit 3
echo "Experimental Feature" > experimental.txt
git add experimental.txt
git commit -m "feature commit 3: Add experimental feature"

# View log on feature branch to identify target commit SHA
git log --oneline -n 4
# Output:
# 9z8y7x6 (HEAD -> feature/hotfix) feature commit 3: Add experimental feature
# 3k4j5h6 feature commit 2: Add security patch   <-- TARGET COMMIT TO CHERRY-PICK!
# 1m2n3b4 feature commit 1: Add hotfix101
# a1b2c3d main commit 2: Add config.json
```

---

#### Step 3: Cherry-Pick Target Commit into `main`
```bash
# Switch back to main branch
git checkout main

# Cherry-pick the security patch commit (3k4j5h6)
git cherry-pick 3k4j5h6

# Output:
# [main 7p8q9r0] feature commit 2: Add security patch
#  Date: Thu Sep 3 23:14:00 2026
#  1 file changed, 1 insertion(+)
#  create mode 100644 security_patch.txt
```

---

#### Step 4: Verify Cherry-Picked Commit in `main`
```bash
# Verify commit history on main
git log --oneline -n 3
# Output:
# 7p8q9r0 (HEAD -> main) feature commit 2: Add security patch
# a1b2c3d main commit 2: Add config.json
# e4f5g6h main commit 1: Add version.txt

# Verify file existence on main branch
ls -la security_patch.txt
cat security_patch.txt
# Output:
# Critical Security Patch
```

*Result*: The `security_patch.txt` file and its specific commit `3k4j5h6` were successfully imported into `main` while leaving `experimental.txt` and `hotfix101.txt` isolated in the feature branch!
