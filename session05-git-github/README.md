![commit](image.png)

commit -a automatically stages the files that are already tracked by git.  
commit -m just commmits the files which are manually staged (git add)  (-m is to add a commit message)  

![new branch and log](image-1.png)
`git log` shows the commit history. Writing branch name shows commits on that branch

![show](image-2.png)

`git show <commit-hash>` shows details about a specific commit

![cherry-pick](image-3.png)
`git cherry-pick <commit-hash>` Adds a commit from another branch onto the  current branch  
