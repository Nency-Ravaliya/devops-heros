ask 1: Understanding Commit Flags
Theoretical Difference
git commit -m "message": Commits only the changes that have been explicitly staged using git add. If a tracked file is modified but not staged, this command will ignore it.
git commit -a -m "message": Automatically stages any modified or deleted files that Git is already tracking, and commits them in one step. It does not stage newly created (untracked) files.
Practical Execution & Proof
Created a tracked file (test.txt) and modified it.
Attempted git commit -m without staging. As expected, Git threw a "Changes not staged for commit" error.
Ran git commit -a -m. Git successfully staged and committed the tracked modifications automatically.
Proof of Execution: 
amitabh@LAPTOP-3KF17VR3:~$ mkdir github-Assign
amitabh@LAPTOP-3KF17VR3:~$ cd github-Assign
amitabh@LAPTOP-3KF17VR3:~/github-Assign$ git init
hint: Using 'master' as the name for the initial branch. This default branch name
hint: will change to "main" in Git 3.0. To configure the initial branch name
hint: to use in all of your new repositories, which will suppress this warning,
hint: call:
hint:
hint:   git config --global init.defaultBranch <name>
hint:
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint:
hint:   git branch -m <name>
hint:
hint: Disable this message with "git config set advice.defaultBranchName false"
Initialized empty Git repository in /home/amitabh/github-Assign/.git/
amitabh@LAPTOP-3KF17VR3:~/github-Assign$ echo "Line 1" > test.txt
amitabh@LAPTOP-3KF17VR3:~/github-Assign$ git add test.txt
amitabh@LAPTOP-3KF17VR3:~/github-Assign$ git commit -m "Initial commit"
[master (root-commit) 46ffa1b] Initial commit
 1 file changed, 1 insertion(+)
 create mode 100644 test.txt
amitabh@LAPTOP-3KF17VR3:~/github-Assign$ echo "Line 2" >> test.txt
amitabh@LAPTOP-3KF17VR3:~/github-Assign$ git commit -m "Add Line 2"
On branch master
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   test.txt

no changes added to commit (use "git add" and/or "git commit -a")
amitabh@LAPTOP-3KF17VR3:~/github-Assign$ git commit -a -m "Add Line 2 using the -a flag"
[master 19b519c] Add Line 2 using the -a flag
 1 file changed, 1 insertion(+)

Task 2: Git Cherry-Pick
Workflow Performed
Generated baseline commits on the main branch.
Created and switched to feature-branch.
Made 2 additional isolated commits on feature-branch.
Used git log --oneline to identify the specific hash of the first commit on the new branch.
Switched back to main and executed git cherry-pick <commit-hash>.
Verified the selected commit was successfully duplicated onto main.
Proof of Execution
1. Identifying the target commit on feature-branch: Feature Branch Log:
commit 19b519c80d5caccb77e90d544c56d2416cc5d1fc (HEAD -> master)
Author: Amitabh-Ozymandias <amitabh10b26.hts21@gmail.com>
Date:   Thu Sep 3 14:40:45 2026 +0000

    Add Line 2 using the -a flag

commit 46ffa1ba9c7ce773f1fa4b1581a5df4948200523
Author: Amitabh-Ozymandias <amitabh10b26.hts21@gmail.com>
Date:   Thu Sep 3 14:39:53 2026 +0000

    Initial commit

2. Successful cherry-pick execution and verification on main: Main Branch Cherry Pick:
amitabh@LAPTOP-3KF17VR3:~/github-Assign$ git checkout master
Already on 'master'
amitabh@LAPTOP-3KF17VR3:~/github-Assign$ git cherry-pick  19b519c80d5caccb77e90d544c56d2416cc5d1fc
On branch master
You are currently cherry-picking commit 19b519c.
  (all conflicts fixed: run "git cherry-pick --continue")
  (use "git cherry-pick --skip" to skip this patch)
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

nothing to commit, working tree clean
The previous cherry-pick is now empty, possibly due to conflict resolution.
If you wish to commit it anyway, use:

    git commit --allow-empty

Otherwise, please use 'git cherry-pick --skip'
amitabh@LAPTOP-3KF17VR3:~/github-Assign$ git log
commit 19b519c80d5caccb77e90d544c56d2416cc5d1fc (HEAD -> master)
Author: Amitabh-Ozymandias <amitabh10b26.hts21@gmail.com>
Date:   Thu Sep 3 14:40:45 2026 +0000

    Add Line 2 using the -a flag

commit 46ffa1ba9c7ce773f1fa4b1581a5df4948200523
Author: Amitabh-Ozymandias <amitabh10b26.hts21@gmail.com>
Date:   Thu Sep 3 14:39:53 2026 +0000

    Initial commit