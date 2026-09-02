# Git Fundamentals - Homework

Practice of `git commit -a -m` vs `git commit -m`, and `git cherry-pick`, with the actual commands and output.

## Task 1: git commit -a -m vs git commit -m

### The difference
- `git commit -m "message"` commits **only the changes that are already staged** (added with `git add`).
- `git commit -a -m "message"` automatically **stages all modified/deleted tracked files** and commits them in one step. (Note: `-a` does **not** include brand-new untracked files; those still need `git add`.)

### Test and output
Start with a committed file, then modify it:
```bash
echo "line1" > notes.txt
git add notes.txt
git commit -m "Initial commit with notes.txt"

echo "line2 added" >> notes.txt
git status -s
```
Output:
```
 M notes.txt
```

Try to commit with `-m` alone (no `-a`):
```bash
$ git commit -m "try without -a"
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   notes.txt
```
Nothing was committed, because the change was never staged.

Now use `-a -m`:
```bash
$ git commit -a -m "commit tracked change with -a"
[main 2a47f0b] commit tracked change with -a
 1 file changed, 1 insertion(+)

$ git log --oneline
2a47f0b commit tracked change with -a
b16997c Initial commit with notes.txt
```

**What I understood:** `-a` is a shortcut that stages all tracked file changes so I don't have to run `git add` separately. Plain `git commit -m` only records what I already staged. `-a` still won't pick up new (untracked) files.



## Task 2: git cherry-pick

Cherry-pick copies a **single specific commit** from one branch onto the current branch, without merging the whole branch.

### Step 1 - Create commits on main
```bash
echo "featureA" > a.txt; git add a.txt; git commit -m "Add feature A"
echo "featureB" > b.txt; git add b.txt; git commit -m "Add feature B"
git log --oneline
```
```
b536f04 Add feature B
5a40d21 Add feature A
2a47f0b commit tracked change with -a
b16997c Initial commit with notes.txt
```

### Step 2 - Create a new branch and make commits on it
```bash
git checkout -b feature
echo "x" > x.txt; git add x.txt; git commit -m "Feature branch: add x.txt"
echo "important fix" > fix.txt; git add fix.txt; git commit -m "Feature branch: IMPORTANT fix in fix.txt"
echo "y" > y.txt; git add y.txt; git commit -m "Feature branch: add y.txt"
git log --oneline
```
```
7aa7fa8 Feature branch: add y.txt
48d103f Feature branch: IMPORTANT fix in fix.txt
92def40 Feature branch: add x.txt
b536f04 Add feature B
5a40d21 Add feature A
...
```

### Step 3 - Identify the specific commit
The commit I want is the IMPORTANT fix: `48d103f`.

### Step 4 - Cherry-pick that one commit onto main
```bash
git checkout main
git cherry-pick 48d103f
```
```
[main b7d3296] Feature branch: IMPORTANT fix in fix.txt
 1 file changed, 1 insertion(+)
 create mode 100644 fix.txt
```

### Step 5 - Verify
```bash
$ git log --oneline
b7d3296 Feature branch: IMPORTANT fix in fix.txt
b536f04 Add feature B
5a40d21 Add feature A
2a47f0b commit tracked change with -a
b16997c Initial commit with notes.txt

$ ls
a.txt  b.txt  fix.txt  notes.txt
```
`fix.txt` is now on main, but `x.txt` and `y.txt` are **not** - proving only the one selected commit was copied over, not the whole branch.

**What I understood:** `cherry-pick` lets me pull just one useful commit from another branch into my current branch by its commit hash, instead of merging everything. Great for grabbing a single bug fix without the rest of the work.

