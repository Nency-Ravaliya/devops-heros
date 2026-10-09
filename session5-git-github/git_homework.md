git commit -m : Is used  to commit the -m is used to write a message to the commit but it doesnt work if we dont stage  that is git add

git commit -a -m: Is used to stage and commit the changes

git cherry-pick : Is used to pick a commit from one branch and apply it to another branch

durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git add .
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git commit -m "Add test_commit.txt"
U       session6-7-docker/CINERA_DOCKER_GUIDE.md
U       session6-7-docker/docker_system_df.png
U       session6-7-docker/execCmd.png
U       session6-7-docker/java-app/Dockerfile
U       session6-7-docker/java-app/Main.java
U       session6-7-docker/multi-stage-dockerfile/README.md
U       session6-7-docker/multi-stage-dockerfile/multi_stage_ps.png
U       session6-7-docker/node-app/README.md
U       session6-7-docker/node-app/node_app_ps.png
U       session6-7-docker/test.md
error: Committing is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git merge --abort
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git add .
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git commit -m "Resolve merge conflicts and add test_commit.txt"
On branch main
Your branch is ahead of 'origin/main' by 2 commits.
  (use "git push" to publish your local commits)

Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        deleted:    ../session2-linux/CINERA_LINUX_GUIDE.md

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        ../DevOps Homework (1).pdf
        ../session2-linux/hardlink.txt
        ../session2-linux/journalctl_guide.md
        ../session2-linux/shortlink.txt
        ../session2-linux/soft_hard_links.md
        ../session2-linux/user_management.md
        ../session3-shell-scripting/README.md
        ../session3-shell-scripting/dp/
        ../session3-shell-scripting/sys_info.sh
        ../session4-networking/networking_tasks.md

no changes added to commit (use "git add" and/or "git commit -a")
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git commit -a
Aborting commit due to empty commit message.
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ echo "Initial content" > test_commit.txt
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git add test_commit.txt
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git commit -m "Add test_commit.txt"
[main 293d27a] Add test_commit.txt
 1 file changed, 1 insertion(+)
 create mode 100644 session5-git-github/test_commit.txt
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ echo "Updated content" >> test_commit.txt
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git commit -m "Attempt commit"
On branch main
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   test_commit.txt

no changes added to commit (use "git add" and/or "git commit -a")
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git commit -a -m "Updated test_commit.txt automatically"
[main ad4a73f] Updated test_commit.txt automatically
 1 file changed, 1 insertion(+)
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git branch
* main
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git checkout -b feature-cherry
Switched to a new branch 'feature-cherry'
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git branch
* feature-cherry
  main
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ echo "Feature code for cherry pick" > cherry_feature.txt
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git add cherry_feature.txt 
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git commit -m "Add feature for cherry pick"
[feature-cherry d56918e] Add feature for cherry pick
 1 file changed, 1 insertion(+)
 create mode 100644 session5-git-github/cherry_feature.txt
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git log -n 1 --oneline
d56918e (HEAD -> feature-cherry) Add feature for cherry pick
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git checkout main
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 2 commits.
  (use "git push" to publish your local commits)
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git branch
  feature-cherry
* main
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git cherry-pick d56918e
[main 454ac05] Add feature for cherry pick
 Date: Wed Sep 2 19:01:50 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 session5-git-github/cherry_feature.txt
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git log -n 2 --oneline
454ac05 (HEAD -> main) Add feature for cherry pick
ad4a73f Updated test_commit.txt automatically
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ ls -l cherry_feature.txt
-rw-rw-r-- 1 durga-prasad durga-prasad 29 Sep  2 19:03 cherry_feature.txt
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ git branch -D feature-cherry
Deleted branch feature-cherry (was d56918e).
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session5-git-github$ 


