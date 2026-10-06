# Session 5 — Git

Student: Viraj Bhanage, roll 24BCS10274

## Task 1 — `git commit -m` and `git commit -a -m`

`git commit -m` records what is already staged. `git commit -a -m` also stages modifications to tracked files, then commits them. It does not add untracked files.

Real output from a throwaway repository:

```text
$ git status
 M tracked.txt

$ git commit -m "message only"
no changes added to commit (use "git add" and/or "git commit -a")

$ git commit -a -m "include tracked modifications"
[main 1381eef] include tracked modifications
 1 file changed, 1 insertion(+)
```

Full transcript: [commit-a-output.txt](commit-a-output.txt)

## Task 2 — Cherry-pick

Cherry-pick copies one commit onto the current branch as a new commit. The other commits on the source branch stay there.

Run:

```bash
chmod +x cherry-pick-demo.sh
./cherry-pick-demo.sh
```

The script creates `main` with four commits, creates `feature` with three commits that each add a different file, checks out `main`, and cherry-picks only `feature: document the API`. After that, `feature-b.txt` is on `main`. `feature-a.txt` and `feature-c.txt` stay only on the feature branch.

The transcript from the run on this machine is [cherry-pick-output.txt](cherry-pick-output.txt). `feature-b.txt` is the only feature file on `main` after the cherry-pick.
