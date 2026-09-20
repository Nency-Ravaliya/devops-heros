# Session 5 - Git and GitHub

Dhruv Bansal - 24BCS10114

I practised staging, committing, branching, merging, and cherry-picking. One thing I noted is that `git commit -m` commits only staged changes. `git commit -a -m` stages changes to tracked files, but it still ignores new untracked files.

The script in this folder makes a temporary Git repository, creates a feature branch, commits a change, and cherry-picks that commit onto the main branch.

```bash
bash cherry-pick-lab.sh --self-test
```

I used `git status`, `git log --oneline --graph --all`, and `git diff --staged` to check each step before moving ahead.
