# Linux Fundamentals - Homework Tasks

This document contains detailed solutions, technical explanations, command outputs, and interview preparation guides for **Linux Fundamentals Homework Tasks**.

---

## Task 1: Soft Link & Hard Link

### 1. Key Differences Between Soft Links and Hard Links

| Feature | Soft Link (Symbolic Link / Symlink) | Hard Link |
| :--- | :--- | :--- |
| **Inode Number** | Has its **own unique inode number** distinct from the target file. | Shares the **exact same inode number** as the target file. |
| **Target Reference** | Points to the **path/filename** of the target file. | Points directly to the **underlying data block on disk**. |
| **Directory Support** | Can link to both **files and directories**. | Can only link to **files** (cannot link directories to avoid loops). |
| **Cross-Filesystem** | Can span across **different filesystems/partitions**. | Must reside on the **same filesystem/partition**. |
| **Target Deletion** | If original file is deleted, the soft link becomes a **dangling/broken link**. | If original file is deleted, data remains accessible via the hard link until all link counts reach 0. |
| **File Size** | Size equal to the length of the target path string (few bytes). | Size is identical to the original file (refers to the same data). |

---

### 2. Commands to Create and Manage Links

- **Create a Hard Link:**
  ```bash
  ln <original_file> <hard_link_name>
  ```

- **Create a Soft Link:**
  ```bash
  ln -s <original_file> <soft_link_name>
  ```

- **Inspect Inodes and Link Counts:**
  ```bash
  ls -li
  ```

---

### 3. Practical Exercise & Demonstration

#### Step 1: Create a original file and check its inode
```bash
$ echo "Linux Link Practice Data" > original.txt
$ ls -li original.txt
10485761 -rw-r--r-- 1 root root 25 Sep  6 10:00 original.txt
```
*(Inode: `10485761`, Link Count: `1`)*

#### Step 2: Create a Hard Link and inspect
```bash
$ ln original.txt hard_link.txt
$ ls -li original.txt hard_link.txt
10485761 -rw-r--r-- 2 root root 25 Sep  6 10:00 hard_link.txt
10485761 -rw-r--r-- 2 root root 25 Sep  6 10:00 original.txt
```
*(Notice both files share Inode `10485761` and Link Count increased to `2`)*

#### Step 3: Create a Soft Link and inspect
```bash
$ ln -s original.txt soft_link.txt
$ ls -li original.txt soft_link.txt
10485761 -rw-r--r-- 2 root root 25 Sep  6 10:00 original.txt
10485763 lrwxrwxrwx 1 root root 12 Sep  6 10:01 soft_link.txt -> original.txt
```
*(Soft link has its own Inode `10485763` and points to `original.txt`)*

#### Step 4: Delete the Original File and observe behavior
```bash
$ rm original.txt

# Reading Hard Link (Data is still intact!)
$ cat hard_link.txt
Linux Link Practice Data

# Reading Soft Link (Broken Link!)
$ cat soft_link.txt
cat: soft_link.txt: No such file or directory
```

---

### 4. Top Interview Q&A on Soft Links vs Hard Links

1. **Q: What happens to a hard link when the original file is deleted?**
   - **A:** The file data remains completely safe on disk. Hard links are simply pointers to the same inode. The inode link count decreases by 1. Only when all hard links to an inode are removed (link count reaches 0) does the OS mark the data blocks as free.

2. **Q: Can you create a hard link for a directory? Why or why not?**
   - **A:** No, standard Linux filesystems do not allow hard-linking directories to prevent recursive infinite loops in directory tree structures and system traversal tools (`find`, `du`).

3. **Q: Can a soft link point to a non-existent file?**
   - **A:** Yes, soft links store path strings. If the path does not exist, it creates a dangling (broken) link. If a file with that name is recreated later, the link works again.

---

## Task 2: adduser vs useradd

### 1. Difference Between `useradd` and `adduser`

| Criteria | `useradd` | `adduser` |
| :--- | :--- | :--- |
| **Command Type** | Native **low-level binary** (`/usr/sbin/useradd`). | High-level **interactive Perl script** (`/usr/sbin/adduser`). |
| **Portability** | Standard across almost **all Linux distributions** (RHEL, CentOS, Debian, Arch). | Specific to **Debian / Ubuntu** systems as a user-friendly wrapper. |
| **Home Directory Creation** | Does **NOT** create home directory by default (requires `-m` flag). | Creates `/home/username` **automatically**. |
| **Default Shell** | Defaults to `/bin/sh` or `/bin/false` unless specified with `-s`. | Defaults to `/bin/bash` interactive shell. |
| **Password Prompt** | Does **NOT** prompt for password (account created locked until `passwd` is run). | Prompts interactively for **password and user details** (GECOS info). |
| **Configuration File** | Reads `/etc/default/useradd` and `/etc/login.defs`. | Reads `/etc/adduser.conf`. |

---

### 2. Which command is preferred on Ubuntu/Linux and why?

- **On Ubuntu/Debian Interactive Administration:**
  - **`adduser` is preferred** because it automates user account creation cleanly: it creates `/home/username`, copies files from `/etc/skel`, prompts for password setup, sets up user groups, and assigns `/bin/bash` in a single user-friendly step.

- **In Automation / DevOps Shell Scripts:**
  - **`useradd` is preferred** because it is a non-interactive low-level utility standard across all distros, making script execution deterministic and silent.

---

### 3. Practical Example: Creating a Test User

#### Method 1: Using `adduser` (Recommended for Ubuntu interactive management)
```bash
$ sudo adduser testuser
Adding user `testuser' ...
Adding new group `testuser' (1001) ...
Adding new user `testuser' (1001) with group `testuser' ...
Creating home directory `/home/testuser' ...
Copying files from `/etc/skel' ...
New password: ********
Retype new password: ********
passwd: password updated successfully
Changing the user information for testuser
Enter the new value, or press ENTER for the default
	Full Name []: Test User
	Room Number []: 101
	Work Phone []: 
	Home Phone []: 
	Other []: 
Is the information correct? [Y/n] Y
```

#### Method 2: Using `useradd` (Non-interactive / Scripting)
```bash
$ sudo useradd -m -s /bin/bash testuser
$ sudo passwd testuser
```

#### Verification:
```bash
$ grep testuser /etc/passwd
testuser:x:1001:1001:Test User,101,,:/home/testuser:/bin/bash

$ ls -la /home/testuser
total 20
drwxr-x--- 2 testuser testuser 4096 Sep  6 10:15 .
drwxr-xr-x 4 root     root     4096 Sep  6 10:15 ..
-rw-r--r-- 1 testuser testuser  220 Sep  6 10:15 .bash_logout
-rw-r--r-- 1 testuser testuser 3771 Sep  6 10:15 .bashrc
-rw-r--r-- 1 testuser testuser  807 Sep  6 10:15 .profile
```

---

## Task 3: journalctl

### 1. What is `journalctl`?
`journalctl` is a command-line utility used to query and view logs generated by `systemd-journald`, the system logging daemon in modern Linux operating systems utilizing `systemd`. It collects logs from the Linux kernel, system services, system startup, and stdout/stderr of services.

---

### 2. Common `journalctl` Commands & Options

| Command | Purpose |
| :--- | :--- |
| `journalctl` | View all system logs from oldest to newest. |
| `journalctl -u <service_name>` | Filter logs for a specific systemd unit/service (e.g., `nginx`, `docker`). |
| `journalctl -f` | Real-time log tailing (follow mode). |
| `journalctl -n <lines>` | Display the last N lines of logs (e.g., `journalctl -n 50`). |
| `journalctl -b` | Show logs for the current system boot. |
| `journalctl -k` | View kernel logs (equivalent to `dmesg`). |
| `journalctl --since "YYYY-MM-DD HH:MM:SS"` | Filter logs generated after a specific timestamp. |
| `journalctl -p err` | Filter logs by priority level (`emerg`, `alert`, `crit`, `err`, `warning`, `notice`, `info`, `debug`). |
| `journalctl --disk-usage` | Check disk space occupied by journal log files. |

---

### 3. Practice: Checking Logs for a Specific Service

#### Example 1: Check Nginx service logs
```bash
$ sudo journalctl -u nginx -n 20 --no-pager
-- Logs begin at Sat 2026-09-06 00:00:00 UTC, end at Sat 2026-09-06 10:30:00 UTC. --
Sep 06 08:00:00 server systemd[1]: Starting Nginx - high performance web server...
Sep 06 08:00:01 server nginx[1234]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Sep 06 08:00:01 server nginx[1234]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Sep 06 08:00:01 server systemd[1]: Started Nginx - high performance web server.
```

#### Example 2: Filter Docker service logs for errors in the last hour
```bash
$ sudo journalctl -u docker --since "1 hour ago" -p err --no-pager
```

---

## Task 4: Linux Command Cheat Sheet

### 1. File & Directory Operations
- `pwd` - Print current working directory path.
- `ls -la` - List all files including hidden ones with detailed permissions and file size.
- `cd /path` - Change current working directory.
- `mkdir -p dir1/dir2` - Create nested directory structure.
- `rm -rf dir` - Recursively and forcefully remove files/directories.
- `cp -r src dst` - Copy file or directory recursively.
- `mv src dst` - Move or rename file/directory.
- `touch file.txt` - Create empty file or update access timestamp.
- `find /path -name "*.log"` - Search for files matching patterns.
- `du -sh dir` - Summary of directory disk usage in human-readable format.
- `df -h` - View filesystem disk space usage.

---

### 2. File Contents & Processing
- `cat file.txt` - Concatenate and display file content.
- `less file.txt` - Paginated interactive view of large text files.
- `head -n 20 file.txt` - Display first 20 lines of a file.
- `tail -f -n 50 app.log` - Follow real-time output of last 50 lines of log file.
- `grep -rn "ERROR" /var/log/` - Recursively search for string "ERROR" with line numbers.
- `awk '{print $1, $4}' file.txt` - Pattern scanning and column extraction.
- `sed -i 's/foo/bar/g' file.txt` - In-place stream editing (replace 'foo' with 'bar').

---

### 3. Permissions & Ownership
- `chmod 755 script.sh` - Grant `rwxr-xr-x` permissions (Read/Write/Exec for owner, Read/Exec for group & others).
- `chmod +x script.sh` - Add executable permission.
- `chown -R user:group /var/www` - Change file ownership recursively.
- `umask` - Display default file creation mask.

---

### 4. Process Management & System Info
- `ps aux` / `ps -ef` - Display snapshot of all active system processes.
- `top` / `htop` - Dynamic real-time system monitor.
- `kill -9 <PID>` - Forcefully terminate process by Process ID.
- `pkill -f nginx` - Terminate process by name.
- `free -h` - Display free and used memory (RAM) in human-readable format.
- `uptime` - View system running time, active users, and load average.
- `uname -a` - Display system architecture and Linux kernel details.

---

### 5. Networking & Services
- `ping -c 4 8.8.8.8` - Test ICMP network reachability.
- `curl -I https://example.com` - Fetch HTTP headers from URL.
- `wget https://example.com/file.zip` - Download file from remote web server.
- `ss -tulpn` / `netstat -tulpn` - View listening ports and socket statistics.
- `ip addr show` - View network interface IP addresses.
- `systemctl status service_name` - Check systemd service status.
- `systemctl restart service_name` - Restart systemd service.
