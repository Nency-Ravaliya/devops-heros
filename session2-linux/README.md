# Linux Fundamentals - Homework Tasks

This document contains detailed solutions, explanations, and command outputs for the Linux Fundamentals homework tasks.

---

## Task 1: Soft Link vs Hard Link

In Linux, a link is a pointer or reference to a file. There are two primary types of links: **Soft Links (Symbolic Links)** and **Hard Links**.

### Key Differences

| Feature | Soft Link (Symbolic Link) | Hard Link |
|---|---|---|
| **What it points to** | Points to the **path/filename** of the target file | Points directly to the **inode** of the target file |
| **Inode Number** | Has a **different inode** from the source file | Has the **exact same inode** as the source file |
| **Across Filesystems** | Can span across different filesystems/partitions | Can **only** exist on the same filesystem |
| **Linking Directories** | Can link files and directories | Can only link files (not directories, to prevent cycles) |
| **Target Deletion** | If source file is deleted, soft link becomes **broken/dangling** | If source file is deleted, hard link **still retains data** |
| **File Size** | Very small (stores only the file path string) | Same size as the target file (references same data blocks) |
| **Command** | `ln -s <target_file> <link_name>` | `ln <target_file> <link_name>` |

---

### Hands-on Practice & Verification

#### 1. Create a Source File
```bash
echo "Linux Fundamentals link demo" > original.txt
ls -li original.txt
```
*Sample Output:*
```
1441823 -rw-r--r-- 1 student student 28 Sep 6 20:30 original.txt
```
*(Notice inode number `1441823` and link count `1`)*

#### 2. Create a Hard Link
```bash
ln original.txt hardlink.txt
ls -li original.txt hardlink.txt
```
*Sample Output:*
```
1441823 -rw-r--r-- 2 student student 28 Sep 6 20:30 hardlink.txt
1441823 -rw-r--r-- 2 student student 28 Sep 6 20:30 original.txt
```
*(Both share inode `1441823`, and the link count increased to `2`)*

#### 3. Create a Soft Link (Symbolic Link)
```bash
ln -s original.txt softlink.txt
ls -li original.txt hardlink.txt softlink.txt
```
*Sample Output:*
```
1441823 -rw-r--r-- 2 student student 28 Sep 6 20:30 hardlink.txt
1441823 -rw-r--r-- 2 student student 28 Sep 6 20:30 original.txt
1441825 lrwxrwxrwx 1 student student 12 Sep 6 20:31 softlink.txt -> original.txt
```
*(Soft link has its own inode `1441825` and starts with file type `l`)*

#### 4. Delete the Original File & Observe Behavior
```bash
rm original.txt
cat hardlink.txt
# Output: Linux Fundamentals link demo  (Hard link still works!)

cat softlink.txt
# Output: cat: softlink.txt: No such file or directory  (Broken link!)
```

#### 5. Deleting Links
Deleting a link does not delete the original file:
```bash
rm softlink.txt
rm hardlink.txt
```

---

### Interview Preparation: Top Questions

1. **What happens under the hood when a hard link is deleted?**
   - The kernel decrements the file's link count (stored in the inode). The physical disk blocks are freed only when the link count reaches `0` and no open process holds a file descriptor to it.
2. **Why can't hard links cross filesystem boundaries?**
   - Inode numbers are only unique within a single filesystem/partition. Another partition has its own independent inode table.
3. **Why can't regular users create hard links to directories?**
   - To prevent infinite directory loops and cyclic graph structures which could break filesystem traversal tools (like `find` or `fsck`).

---

## Task 2: `adduser` vs `useradd`

Both commands are used to manage users in Linux, but they operate at very different levels of abstraction.

### Comparison Table

| Feature | `adduser` | `useradd` |
|---|---|---|
| **Type** | High-level interactive **Perl script** | Low-level native **compiled binary** (part of `shadow-utils`) |
| **Interactivity** | Interactive: Prompts for password, full name, room no, etc. | Non-interactive: Takes arguments via CLI flags |
| **Home Directory** | Automatically creates home directory (`/home/<user>`) | Does **NOT** create home directory by default (requires `-m` flag) |
| **Skeleton Files** | Copies `/etc/skel` files (`.bashrc`, `.profile`) automatically | Does not copy skeleton files unless `-m` is specified |
| **Shell Assignment** | Sets default login shell (e.g. `/bin/bash` from config) | Defaults to `/bin/sh` or system default |
| **Portability** | Debian/Ubuntu specific (friendly wrapper) | Standard across all Unix/Linux distributions |

### Why `adduser` is Preferred on Ubuntu/Debian
On Ubuntu/Debian desktop and server systems, `adduser` is preferred for manual administrative user creation because:
1. It is user-friendly and guided.
2. It enforces consistent system configuration policies defined in `/etc/adduser.conf`.
3. It automatically assigns the user to their own default group, sets up home directories with appropriate permissions, and prompts to set a strong password immediately.

*(Note: `useradd` is still preferred in automation scripts, Ansible playbooks, and Dockerfiles to avoid interactive prompt hangs).*

### Creating a Test User
```bash
# Recommended on Ubuntu/Debian:
sudo adduser testuser

# Alternative using useradd with equivalent manual flags:
sudo useradd -m -s /bin/bash testuser
sudo passwd testuser
```

*Verification:*
```bash
id testuser
grep testuser /etc/passwd
```
*Sample Output:*
```
uid=1001(testuser) gid=1001(testuser) groups=1001(testuser)
testuser:x:1001:1001:Test User,,,:/home/testuser:/bin/bash
```

---

## Task 3: `journalctl`

`journalctl` is the command-line utility used to query and view system logs collected by `systemd-journald`, the centralized logging service in systemd-based Linux systems.

### Key Capabilities
- Collects logs from kernel, boot processes, standard output/error of systemd services, and syslog.
- Stores logs in structured binary format, allowing fast indexing, time-based filtering, and field-based queries.

### Essential `journalctl` Commands

| Purpose | Command |
|---|---|
| View entire log | `journalctl` |
| View logs for a specific service | `journalctl -u <service-name>` |
| Follow logs in real time (tail -f mode) | `journalctl -f -u <service-name>` |
| View logs from the current boot only | `journalctl -b` |
| View logs from previous boot | `journalctl -b -1` |
| View logs with explanations and error details | `journalctl -xe` |
| Filter by priority (e.g. errors only) | `journalctl -p err..emerg` |
| Filter by time range | `journalctl --since "1 hour ago"` |

### Practice: Checking Logs for a Specific Service

Checking logs for the `ssh` service (or `systemd-resolved` / `cron`):
```bash
sudo journalctl -u ssh -n 20 --no-pager
```

*Sample Output:*
```
Sep 06 18:15:02 devops-vm systemd[1]: Starting OpenBSD Secure Shell server...
Sep 06 18:15:02 devops-vm sshd[952]: Server listening on 0.0.0.0 port 22.
Sep 06 18:15:02 devops-vm sshd[952]: Server listening on :: port 22.
Sep 06 18:15:02 devops-vm systemd[1]: Started OpenBSD Secure Shell server.
Sep 06 19:10:45 devops-vm sshd[1420]: Accepted publickey for student from 192.168.1.50 port 52341 ssh2
```

---

## Task 4: Linux Command Cheat Sheet

### 1. File and Directory Management
- `pwd`: Print working directory.
- `ls -la`: List all files with permissions, hidden files, and details.
- `cd <dir>`: Change directory (`cd ..` moves one level up, `cd ~` goes home).
- `mkdir -p dir1/dir2`: Create directory structure recursively.
- `touch file.txt`: Create an empty file or update its timestamp.
- `cp -r src/ dest/`: Copy files or directories recursively.
- `mv old.txt new.txt`: Move or rename files.
- `rm -rf dir/`: Remove files or directories recursively and forcefully.
- `find /path -name "*.log"`: Search files by name or attributes.

### 2. File Viewing and Text Processing
- `cat file.txt`: Display entire file contents.
- `less file.txt` / `more file.txt`: View file paginated.
- `head -n 10 file.txt`: View first 10 lines.
- `tail -n 10 -f file.log`: View last 10 lines and follow live changes.
- `grep -rn "search_term" .`: Search text recursively with line numbers.
- `awk '{print $1}' file.txt`: Print first column of text.
- `sed -i 's/old/new/g' file.txt`: Replace text inline.

### 3. Permissions & Ownership
- `chmod 755 script.sh`: Set permissions (rwxr-xr-x).
- `chmod +x script.sh`: Make a script executable.
- `chown user:group file.txt`: Change file owner and group.

### 4. Process Management
- `ps aux`: Display all running processes on the system.
- `top` / `htop`: Interactive real-time process monitoring.
- `kill -9 <PID>`: Forcefully terminate process with PID.
- `killall <process_name>`: Terminate processes by name.

### 5. Disk & System Info
- `df -h`: Show disk space usage in human-readable format.
- `du -sh *`: Show size of files and directories in current folder.
- `free -h`: Show RAM and swap memory usage.
- `uname -a`: Show OS kernel and system architecture.
- `uptime`: Show system uptime and load average.
