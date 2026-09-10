# Session 5 - Git and GitHub

**Dhruv Bansal - 24BCS10114**

`git commit -m` commits what is already staged. `git commit -a -m` also stages tracked modifications, but it never includes new untracked files. The safest habit is to inspect `git status` and stage intentionally.

The included lab creates a temporary repository, makes a commit on a feature branch, cherry-picks it back to the main branch, and verifies the selected change. It does not use a remote.

```bash
bash cherry-pick-lab.sh --self-test
```
