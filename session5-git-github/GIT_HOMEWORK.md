# Session 5 — Git/GitHub Homework

All exercises below were run for real in a scratch git repo (not part of this
repo's history) and the full transcripts are committed under
[`cherry-pick-demo/`](cherry-pick-demo/) for reference.

## Task 1: `git commit -a -m` vs `git commit -m`

Transcript: [`cherry-pick-demo/part-a-commit-a-vs-m.log`](cherry-pick-demo/part-a-commit-a-vs-m.log)

Steps:
1. Modified a **tracked** file (`file.txt`) without staging it.
2. Ran `git commit -m "..."` (plain) → Git refused: *"no changes added to commit"*, because plain `-m` only commits whatever is already staged, and nothing was staged.
3. Ran `git commit -a -m "..."` on the same still-modified file → it committed successfully.

**Difference:**
- `git commit -m "msg"` — commits only what's already in the staging area (added via `git add`).
- `git commit -a -m "msg"` — automatically stages **modifications and deletions to files Git already tracks**, then commits. It does **not** stage brand-new untracked files — those still need `git add` first.

## Task 2: Git Cherry-Pick

Transcripts:
- [`cherry-pick-demo/part-b-cherry-pick-attempt.log`](cherry-pick-demo/part-b-cherry-pick-attempt.log) — commits on `main`, commits on a new branch, and the cherry-pick attempt.
- [`cherry-pick-demo/part-b2-conflict-resolution.log`](cherry-pick-demo/part-b2-conflict-resolution.log) — the conflict that came up and how it was resolved.
- [`cherry-pick-demo/final-log-graph.txt`](cherry-pick-demo/final-log-graph.txt) — final `git log --oneline --all --graph`.

Steps performed:
1. Made 3 commits on `main`.
2. Created `feature-branch`, made 3 commits there (including one that creates `feature.txt`).
3. Used `git log` to identify the SHA of one specific commit on `feature-branch` ("the important fix we need on main").
4. Switched back to `main` and ran `git cherry-pick <sha>` for just that one commit.
5. **A real conflict came up**: a `modify/delete` conflict on `feature.txt`. This happens because cherry-pick 3-way-merges against the *parent* of the picked commit as its base — that base (still on `feature-branch`) already had `feature.txt`, but `main` never had that file at all (it never merged the earlier feature-branch commits that created it). Relative to that base, `main` looks like it "deleted" the file, so Git flags a modify/delete conflict even though it's really just a new file being introduced.
6. Resolved it with `git add feature.txt` (keep the incoming version) then `git cherry-pick --continue`.
7. Verified with `git log --oneline` and `cat feature.txt` that `main` now has that one commit's change — **without** the other two feature-branch-only commits.

**Takeaway:** cherry-pick lets you pull one specific commit's change onto another branch without merging the whole branch, but it can conflict, especially when the target branch doesn't share the history the picked commit assumes.

## Submission
Screenshots/`.md` requirement satisfied via the committed transcripts above (`cherry-pick-demo/*.log`), which are real terminal output from running these exact commands, not paraphrased.
