# Session 5: Git and GitHub

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

Run the commands below in a new empty directory, separate from the course repo.
Output is in `evidence/git.txt`.

```bash
git init -b main
git config user.name 'PENTA GUNA SAI KUMAR'
git config user.email 'student@example.invalid'
echo first > notes.txt
git add notes.txt
git commit -m 'Start practice notes'
echo second >> notes.txt
git commit -a -m 'Update tracked notes'
echo third >> notes.txt
echo untracked > new.txt
git commit -a -m 'Update only the tracked file'
git status --short
git add new.txt
git commit -m 'Add the new file explicitly'
git switch -c practice-feature
echo 'independent change' > selected.txt
git add selected.txt
git commit -m 'Add a change to cherry-pick'
selected_commit=$(git rev-parse HEAD)
echo 'leave on feature branch' > feature-only.txt
git add feature-only.txt
git commit -m 'Add a feature-only note'
git log --oneline --all --graph
git switch main
git cherry-pick "$selected_commit"
git log --oneline --all --graph
cat selected.txt
test ! -f feature-only.txt
echo 'Selected change is present; feature-only file is absent.'
```

`git commit -m` commits what is staged. `git commit -a -m` first stages changes
and deletions to tracked files, then commits. It does not add untracked files.
The exercise shows this with `new.txt`, which remains `??` until `git add`.

The main branch gets four commits. The feature branch gets two. I select the
first feature commit by hash and cherry-pick it onto main. The second feature
file stays absent on main. Cherry-pick replays one change; it does not merge the
entire branch. A replay normally has a different parent and commit ID.

If a cherry-pick conflicts, inspect `git status`, edit the conflict, `git add`
the resolved files, then `git cherry-pick --continue`. `--abort` cancels the replay.

## Verification

Tracked/untracked commit behavior and cherry-pick exercise ran in a temporary repository.

No pending local Git exercise.

Command output: [evidence/](evidence/).
