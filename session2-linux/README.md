# Linux Homework Tasks

This document contains solutions, explanations, commands, and interview preparations for the Linux Homework Tasks.

---

## Task 1: Soft Link & Hard Link

### 1. Difference Between Soft Links and Hard Links

| Feature | Soft Link (Symbolic Link / Symlink) | Hard Link |
| :--- | :--- | :--- |
| **Inode** | Has a **different inode** than the target file. | Shares the **exact same inode** as the target file. |
| **Data Pointer** | Points to the file path of the target file. | Points directly to the physical storage location on disk. |
| **Target Deletion** | If target is deleted, the link becomes **broken (dangling)**. | If original file is deleted, data remains accessible via the hard link. |
| **Cross-Filesystem**| Can span across different filesystems / partitions. | Must reside on the **same filesystem**. |
| **Directories** | Can link to directories. | Cannot create hard links to directories (prevents loop cycles). |
| **File Size** | Tiny size (equals length of target path string). | Same size as the target file (same inode metadata). |

---

### 2. Commands to Create Both

#### Creating a Soft Link (Symbolic Link)
```bash
ln -s <target_file_or_directory> <soft_link_name>
```
*Example:*
```bash
ln -s /var/log/syslog my_syslog_symlink
```

#### Creating a Hard Link
```bash
ln <target_file> <hard_link_name>
```
*Example:*
```bash
ln file1.txt file1_hardlink.txt
```

---

### 3. Practice: Creating and Deleting Soft and Hard Links

#### Practical Terminal Demonstration:
```bash
# 1. Create a sample file
echo "Hello Linux DevOps World" > original.txt

# 2. Create a Soft Link
ln -s original.txt soft_link.txt

# 3. Create a Hard Link
ln original.txt hard_link.txt

# 4. View Inodes and Link Counts
ls -li original.txt soft_link.txt hard_link.txt
```

*Sample Terminal Output:*
```text
12938102 -rw-r--r-- 2 user user 24 Sep 02 16:00 hard_link.txt
12938102 -rw-r--r-- 2 user user 24 Sep 02 16:00 original.txt
12938103 lrwxrwxrwx 1 user user 12 Sep 02 16:00 soft_link.txt -> original.txt
```
*(Notice: `original.txt` and `hard_link.txt` share inode `12938102` and have link count `2`, whereas `soft_link.txt` has a distinct inode `12938103` pointing to `original.txt`)*

#### Deleting Links and Observing Behavior:
```bash
# Delete original file
rm original.txt

# Check Soft Link (Now Broken / Dangling)
cat soft_link.txt
# Output: cat: soft_link.txt: No such file or directory

# Check Hard Link (Data Intact!)
cat hard_link.txt
# Output: Hello Linux DevOps World
```

---

### 4. Interview Preparation Q&A

**Q1: What happens to a soft link when the target file is deleted?**  
**Ans:** The soft link remains on the filesystem but becomes a broken (dangling) link. Reading it will return a "No such file or directory" error because the target file path it points to no longer exists.

**Q2: Can hard links be created across different filesystems? Why or why not?**  
**Ans:** No. Inodes are unique only within a specific filesystem. Since a hard link directly references an inode number, hard links cannot cross filesystem boundaries. Soft links must be used instead.

**Q3: Can we create a hard link for a directory?**  
**Ans:** No, Linux restricts hard links to directories for regular users to prevent infinite loops in the directory tree structure during traversal (e.g., `find` or `du` operations).

---

## Task 2: `adduser` vs `useradd`

### 1. Key Differences

| Property | `useradd` | `adduser` |
| :--- | :--- | :--- |
| **Command Level** | Native, low-level binary utility standard in Linux kernel/POSIX. | High-level interactive Perl wrapper script. |
| **User Experience** | Non-interactive. Requires explicit flags (`-m`, `-s`, etc.). | Interactive walkthrough (prompts for password, full name, room no, etc.). |
| **Home Directory** | Does **NOT** create `/home/username` by default (requires `-m`). | Automatically creates `/home/username` and copies skeleton files (`/etc/skel`). |
| **Password Setup** | Does **NOT** prompt for password. Requires separate `passwd username`. | Prompts interactively to set and confirm the initial password. |
| **Default Shell** | Defaults to `/bin/sh` or system default unless `-s /bin/bash` is passed. | Defaults to `/bin/bash` (defined in `/etc/adduser.conf`). |
| **Primary Usage** | Automation scripts, CI/CD, Ansible, Dockerfiles, system account creation. | Manual administration on interactive Ubuntu/Debian server environments. |

---

### 2. Recommendation on Ubuntu / Linux

**Which is preferred on Ubuntu?**
- **`adduser`** is preferred on Ubuntu for **manual interactive user creation** because it ensures home directories are initialized, password policies are prompted, skel configuration files are copied, and default user group options are set properly out-of-the-box.
- **`useradd`** is preferred for **shell scripts and system service accounts** (e.g. `useradd -r -s /bin/false nginxuser`) because it runs deterministically without expecting interactive stdout/stdin prompts.

---

### 3. Demonstration Commands

#### Creating a User with `useradd` (Scripting / Low-Level approach):
```bash
sudo useradd -m -s /bin/bash testuser_add
sudo passwd testuser_add
```

#### Creating a User with `adduser` (Recommended Ubuntu Interactive approach):
```bash
sudo adduser devops_user
```
*Output Prompts:*
```text
Adding user `devops_user' ...
Adding new group `devops_user' (1001) ...
Adding new user `devops_user' (1001) with group `devops_user' ...
Creating home directory `/home/devops_user' ...
Copying files from `/etc/skel' ...
New password: 
Retype new password: 
passwd: password updated successfully
Changing the user information for devops_user
Enter the new value, or press ENTER for the default
	Full Name []: DevOps Test User
	Room Number []: 101
	Work Phone []: 555-0199
	Home Phone []: 
	Other []: 
Is the information correct? [Y/n] y
```

---

## Task 3: `journalctl`

### 1. What is `journalctl`?
`journalctl` is a command-line utility used to query and view logs generated by `systemd-journald`, the centralized logging daemon in modern systemd-based Linux distributions. It unifies logs from kernel messages, system services, syslog, boot processes, and stdout/stderr of services into a single indexed binary journal.

---

### 2. Common Usage & Filtering Commands

```bash
# View all system logs (paginated using less)
journalctl

# View logs for the current boot
journalctl -b

# Follow logs in real-time (similar to tail -f)
journalctl -f

# View logs for a specific systemd service (e.g., nginx or ssh)
journalctl -u nginx.service

# View logs within a specific time range
journalctl --since "2026-09-02 12:00:00" --until "2026-09-02 16:00:00"

# View kernel logs only (dmesg equivalent)
journalctl -k

# View logs by priority (0=emerg, 1=alert, 2=crit, 3=err, 4=warning, 5=notice, 6=info, 7=debug)
journalctl -p err

# Output logs in JSON format for parsing
journalctl -u docker.service -o json-pretty -n 5
```

---

### 3. Practice: Checking Logs for a Specific Service

```bash
# Check recent 20 log entries for ssh / sshd service
journalctl -u sshd -n 20 --no-pager
```

*Sample Output:*
```text
-- Logs begin at Mon 2026-09-01 08:00:00 UTC, end at Wed 2026-09-02 16:00:00 UTC. --
Sep 02 14:10:05 ubuntu-server sshd[1204]: Server listening on 0.0.0.0 port 22.
Sep 02 14:10:05 ubuntu-server sshd[1204]: Server listening on :: port 22.
Sep 02 15:30:12 ubuntu-server sshd[3420]: Accepted publickey for ubuntu from 192.168.1.50 port 52312 ssh2
Sep 02 15:30:12 ubuntu-server sshd[3420]: pam_unix(sshd:session): session opened for user ubuntu by (uid=0)
```

---

## Task 4: Linux Command Cheat Sheet

### Essential DevOps Linux Commands Overview

| Command | Purpose | Basic Usage Example |
| :--- | :--- | :--- |
| `ls` | List directory contents | `ls -la /var/www` |
| `cd` | Change current directory | `cd /etc/nginx` |
| `pwd` | Print working directory | `pwd` |
| `cp` | Copy files or directories | `cp -r src/ dst/` |
| `mv` | Move or rename files/directories | `mv old.txt new.txt` |
| `rm` | Remove files or directories | `rm -rf temp_dir/` |
| `mkdir` | Create new directories | `mkdir -p app/src` |
| `touch` | Create empty file or update timestamp | `touch index.html` |
| `chmod` | Change file/directory permissions | `chmod 755 script.sh` |
| `chown` | Change file owner and group | `chown -R www-data:www-data /var/www` |
| `grep` | Search text patterns using regex | `grep -rn "ERROR" /var/log/` |
| `find` | Search for files in directory hierarchy | `find / -name "*.conf"` |
| `df` | Display disk space usage | `df -h` |
| `du` | Display file/directory disk usage | `du -sh /var/log` |
| `ps` | Display snapshot of current running processes | `ps aux \| grep node` |
| `top` / `htop` | Dynamic real-time process viewer | `top` |
| `systemctl` | Control systemd system and service manager | `systemctl status nginx` |
| `journalctl` | View logs from systemd-journald | `journalctl -u docker -f` |
| `curl` | Transfer data from or to a server via HTTP/S | `curl -I https://google.com` |
| `netstat` / `ss` | Investigate network sockets and ports | `ss -tulpn` |
