# Session 2 - Linux Fundamentals

**Name:** Sourabh Srivastva
**Enrollment Number:** 24BCS10157

---

## Task 1: Soft Link & Hard Link

### What is a Link?

A **link** is a second name for a file. Linux has two kinds - they differ in *what* they point at.

| | Hard Link | Soft Link (Symbolic Link) |
|---|---|---|
| Points to | Inode (actual data) | File path (a string) |
| Cross filesystem | ❌ No | ✅ Yes |
| Can link directories | ❌ No | ✅ Yes |
| Survives if original deleted | ✅ Yes | ❌ No (becomes dangling) |
| Command | `ln source link` | `ln -s source link` |

### Commands

```bash
# Create a file
echo "hello world" > original.txt

# Create a hard link
ln original.txt hard.txt

# Create a soft link
ln -s original.txt soft.txt

# View inodes
ls -li
```

### Output

```text
total 0
16325548650738247 -rwxrwxrwx 2 sourabh sourabh 12 Sep  4 16:03 hard.txt
16325548650738247 -rwxrwxrwx 2 sourabh sourabh 12 Sep  4 16:03 original.txt
43065671436955513 lrwxrwxrwx 1 sourabh sourabh 12 Sep  4 16:03 soft.txt -> original.txt
```

- `hard.txt` and `original.txt` share inode **16325548650738247** - they point to the same data block.
- `soft.txt` has its own inode **43065671436955513** - it is a tiny file storing the path `original.txt`.
- The link count on `original.txt` and `hard.txt` is `2`, meaning two names point to that inode.

### Deleting the Original - What Happens?

```bash
$ rm original.txt
$ cat hard.txt
# hello world

$ cat soft.txt
# cat: soft.txt: No such file or directory

$ ls -li
# total 0
# 16325548650738247 -rwxrwxrwx 1 sourabh sourabh 12 Sep  4 16:03 hard.txt
# 43065671436955513 lrwxrwxrwx 1 sourabh sourabh 12 Sep  4 16:03 soft.txt -> original.txt
```

`rm original.txt` removed one *name*, not the data. Hard link still works; link count drops to 1. Soft link is now dangling.

### Deleting Links

```bash
$ rm soft.txt hard.txt
$ ls -l
# total 0
```

### Interview Answer

> A **hard link** is another directory entry pointing at the same inode, so the file data is only freed when every hard link is removed. It cannot cross filesystems and cannot link directories.  
> A **soft link** (symlink) is a tiny separate file containing a path string. It can cross filesystems and link directories, but breaks if the target is moved or deleted.

---

## Task 2: adduser vs useradd

### Difference

| | `useradd` | `adduser` |
|---|---|---|
| Type | Low-level binary (C program) | High-level Perl/shell script wrapper |
| Home directory | Not created by default | Created automatically |
| Password prompt | No | Yes (interactive) |
| Preferred on Ubuntu | ❌ | ✅ |

`adduser` is the **recommended command on Ubuntu** because it is interactive, creates a home directory, sets up dotfiles, and prompts for a password - everything you want in one step.

### Commands

```bash
$ sudo useradd testuser2
$ ls /home
# sourabh

$ sudo adduser testuser
# New password:
# Retype new password:
# passwd: password updated successfully
# Changing the user information for testuser
# Enter the new value, or press ENTER for the default
#         Full Name []: Sourabh
#         Room Number []:
#         Work Phone []:
#         Home Phone []:
#         Other []:
# Is the information correct? [Y/n] Y

$ ls -l /home
# total 8
# drwxr-x--- 7 sourabh  sourabh  4096 Aug 24 08:37 sourabh
# drwxr-x--- 2 testuser testuser 4096 Sep  4 16:34 testuser

$ tail -2 /etc/passwd
# testuser2:x:1001:1002::/home/testuser2:/bin/sh
# testuser:x:1003:1003:Sourabh,,,:/home/testuser:/bin/bash
```

`testuser2` (useradd) got `/bin/sh` as shell; `testuser` (adduser) got `/bin/bash` and a proper home directory.

---

## Task 3: journalctl

### What is journalctl?

`journalctl` is the command-line interface to **systemd's journal** - the centralised log system on modern Linux. It collects kernel messages, boot messages, and output from every systemd service into a binary log database at `/var/log/journal/`.

### Common Commands

```bash
# View all logs (newest last)
journalctl

# View logs from this boot only
journalctl -b

# View last 50 lines
journalctl -n 50

# Follow live (like tail -f)
journalctl -f

# Logs for a specific service
journalctl -u ssh.service

# Logs since a specific time
journalctl --since "2026-09-03 17:00:00"

# Show only errors and above
journalctl -p err

# Kernel messages only
journalctl -k
```

### Output - Checking SSH service logs

```bash
sudo journalctl -u ssh.service -n 20
```

```text
Sep 04 16:44:19 DESKTOP-E0F3569 systemd[1]: Starting ssh.service - OpenBSD Secure Shell server...
Sep 04 16:44:19 DESKTOP-E0F3569 sshd[1230]: Server listening on 0.0.0.0 port 22.
Sep 04 16:44:19 DESKTOP-E0F3569 sshd[1230]: Server listening on :: port 22.
Sep 04 16:44:19 DESKTOP-E0F3569 systemd[1]: Started ssh.service - OpenBSD Secure Shell server.
```

### Output — View boot logs

```bash
journalctl -b -n 30
```

```text
Sep 04 16:43:20 DESKTOP-E0F3569 kernel: Linux version 6.18.33.2-microsoft-standard-WSL2 (root@f1bbfb02316b) (gcc (GCC) 13.2.0, GNU ld (GNU Binutils) 2.41) #1 SMP PREEMPT_DYNAMIC Thu Jun 18 21:54:43 UTC 2026
Sep 04 16:43:20 DESKTOP-E0F3569 kernel: Command line: initrd=\initrd.img WSL_ROOT_INIT=1 panic=-1 nr_cpus=16 hv_utils.timesync_implicit=1 console=hvc0 debug pty.legacy_count=0 WSL_ENABLE_CRASH_DUMP=1
Sep 04 16:43:20 DESKTOP-E0F3569 kernel: KERNEL supported cpus:
Sep 04 16:43:20 DESKTOP-E0F3569 kernel:   Intel GenuineIntel
Sep 04 16:43:20 DESKTOP-E0F3569 kernel:   AMD AuthenticAMD
```

---

## Task 4: Linux Command Cheat Sheet

### File & Directory

```bash
ls -la              # list with hidden files and details
pwd                 # print working directory
cd /path/to/dir     # change directory
mkdir -p dir/sub    # create nested directories
rm -rf dir          # remove directory recursively
cp -r src dst       # copy directory
mv old new          # move / rename
find / -name "*.sh" # find files by name
```

### File Content

```bash
cat file.txt        # print file
less file.txt       # paginate
head -n 20 file     # first 20 lines
tail -f file.log    # follow live
grep -i "error" log # case-insensitive search
wc -l file          # count lines
```

### Permissions

```bash
chmod 755 script.sh # rwxr-xr-x
chmod +x script.sh  # add execute bit
chown user:group f  # change owner
```

### Process Management

```bash
ps aux              # all processes
top / htop          # interactive process viewer
kill -9 PID         # force-kill process
jobs                # background jobs
nohup cmd &         # run in background
```

### Networking

```bash
ip addr             # show IP addresses
ip route            # routing table
ping google.com     # check connectivity
curl -I url         # HTTP headers
ss -tuln            # open ports
```

### System Info

```bash
uname -a            # kernel info
df -h               # disk usage
free -h             # memory usage
uptime              # system uptime
whoami              # current user
hostname            # machine name
```

### Package Management (Ubuntu/Debian)

```bash
sudo apt update         # refresh package list
sudo apt install pkg    # install package
sudo apt remove pkg     # remove package
sudo apt upgrade        # upgrade all packages
```

### Users & Groups

```bash
adduser username        # create user (interactive)
usermod -aG sudo user   # add user to sudo group
passwd username         # change password
su - username           # switch user
id username             # show user/group IDs
```

### Text Processing

```bash
awk '{print $1}' f      # print first column
sed 's/old/new/g' f     # replace text
sort file               # sort lines
uniq -c file            # count unique lines
cut -d: -f1 /etc/passwd # cut by delimiter
```

### Redirection & Pipes

```bash
cmd > file          # redirect stdout to file (overwrite)
cmd >> file         # redirect stdout (append)
cmd 2> err.log      # redirect stderr
cmd1 | cmd2         # pipe output to next command
cmd &               # run in background
```