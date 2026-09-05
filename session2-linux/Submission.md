## Name - Piyush Kumar Mahato
## Roll no- 10233

## Task 1
Links allow one file to be accessed through multiple names/paths. A soft link (symbolic link) is like a shortcut to another file.
While, a hard link is another directory entry pointing to the same underlying file/inode. i.e., If original is deleted, the link breaks in case of soft links, but hard link still works.
It is because soft link points to the file, while hard link points to the inode(both original and hardlink have same inode)
![alt text](image.png)

## Task 2
useradd is a low-level Linux utility used to create users and generally requires options to configure things such as the home directory and shell. adduser is a higher-level, more interactive utility, commonly used on Debian/Ubuntu, which simplifies user creation and performs additional setup.
On Ubuntu, adduser is generally preferred for manually creating normal users.
![alt text](image-1.png)

## Task 3
journalctl is used to view logs collected by systemd's journal.
View all logs - journalctl
View logs from the current boot - (journalctl -b)
View logs for a specific service - (journalctl -u nginx) or (journalctl -u docker) depending on the service
Logs since a particular time - (journalctl --since "1 hour ago") or (journalctl --since today)
or for a specific service since a time - (journalctl -u nginx --since today)

