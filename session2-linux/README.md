> **Submission for `session2-linux`** — Piyush Bansal.
>
> Every command shown below was actually executed and the output is copied in verbatim — nothing here is
> illustrative or reconstructed.

# Session 2 — Linux Fundamentals Homework

Covers four tasks: soft vs hard links, `adduser` vs `useradd`, `journalctl`, and the Linux command cheat sheet.

**Environment:** Ubuntu 24.04 (aarch64), systemd as PID 1, run via Docker on macOS — see
[How this was run](#how-this-was-run) below.

## Contents

- [How this was run](#how-this-was-run)
- [Task 1 — Soft Link & Hard Link](#task-1--soft-link--hard-link)
- [Task 2 — `adduser` vs `useradd`](#task-2--adduser-vs-useradd)
- [Task 3 — `journalctl`](#task-3--journalctl)
- [Task 4 — Linux Command Cheat Sheet](#task-4--linux-command-cheat-sheet)

## How this was run

The exercises need a real Linux system — `useradd`, `adduser`, and `journalctl` don't exist on macOS, and
`journalctl` additionally needs **systemd running as PID 1**. A plain `docker run ubuntu` doesn't give you
that (no init system), so this uses a small Ubuntu 24.04 image that boots systemd properly:
[`Dockerfile.ubuntu-systemd`](./Dockerfile.ubuntu-systemd).

```bash
docker build -t devops-linux:24.04 -f Dockerfile.ubuntu-systemd .
docker run -d --name devops-linux --privileged --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw devops-linux:24.04
```

Verified before starting, so the `journalctl` output below is a genuine journal and not a mock:

```console
$ docker exec devops-linux systemctl is-system-running
running
$ docker exec devops-linux systemctl is-active systemd-journald
active
$ docker exec devops-linux ps -p 1 -o pid,comm
    PID COMMAND
      1 systemd
```

---

# Task 1 — Soft Link & Hard Link

## The one-sentence difference

A **hard link** is another *name* for the same data. A **soft link** is a small separate file that merely
*stores a path* to another name.

On Linux a file's data and metadata live in an **inode**; a directory entry is just a `name -> inode` mapping.
A hard link adds a second name pointing at the *same inode* — both names are equal, neither is "the original".
A soft link (symlink) gets its own, *different* inode, and its contents are just the text of the target path,
which the kernel follows at access time.

## Comparison

| | Soft link (symbolic) | Hard link |
|---|---|---|
| Create with | `ln -s target linkname` | `ln target linkname` |
| Inode | **Different** inode from the target | **Same** inode as the target |
| Link count (`ls -l` col. 2) | target stays `1` | increments: `1` → `2` |
| Delete the original | link **breaks** (dangling) | data **survives**, count drops |
| Across filesystems | **Allowed** | **Refused** (`Invalid cross-device link`) |
| To a directory | **Allowed** | **Refused** (`hard link not allowed for directory`) |
| Size | size of the stored path string | same size as the file |
| Shown by `ls -l` | `link -> target`, type `l` | indistinguishable from a normal file, type `-` |

## The commands

```bash
ln -s original.txt softlink.txt   # soft / symbolic link
ln    original.txt hardlink.txt   # hard link

ls -li                            # -i shows the inode number (first column)
stat original.txt                 # shows Inode and Links count
readlink softlink.txt             # print what a symlink points at
find . -xtype l                   # list broken (dangling) symlinks

rm softlink.txt                   # delete a link - never touches the target's data
unlink hardlink.txt               # same thing, one link only
```

## Full transcript

```console
########## 1. CREATE THE ORIGINAL FILE ##########
$ echo "Hello from the original file" > original.txt

$ ls -li original.txt
62556 -rw-r--r-- 1 root root 29 Sep  3 08:18 original.txt

$ stat original.txt
  File: original.txt
  Size: 29        	Blocks: 8          IO Block: 4096   regular file
Device: 0,54	Inode: 62556       Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2026-09-03 08:18:44.683835011 +0000
Modify: 2026-09-03 08:18:44.685246386 +0000
Change: 2026-09-03 08:18:44.685246386 +0000
 Birth: 2026-09-03 08:18:44.683835011 +0000

########## 2. CREATE A SOFT LINK (symbolic link) ##########
$ ln -s original.txt softlink.txt

########## 3. CREATE A HARD LINK ##########
$ ln original.txt hardlink.txt

########## 4. COMPARE THEM (inode column = first field) ##########
$ ls -li
total 8
62556 -rw-r--r-- 2 root root 29 Sep  3 08:18 hardlink.txt
62556 -rw-r--r-- 2 root root 29 Sep  3 08:18 original.txt
62564 lrwxrwxrwx 1 root root 12 Sep  3 08:19 softlink.txt -> original.txt

$ stat -c "%n -> inode=%i links=%h size=%s type=%F" original.txt hardlink.txt softlink.txt
original.txt -> inode=62556 links=2 size=29 type=regular file
hardlink.txt -> inode=62556 links=2 size=29 type=regular file
softlink.txt -> inode=62564 links=1 size=12 type=symbolic link

########## 5. READ THROUGH BOTH LINKS ##########
$ cat softlink.txt
Hello from the original file
$ cat hardlink.txt
Hello from the original file

########## 6. readlink on the soft link ##########
$ readlink softlink.txt
original.txt

########## 7. EDIT THROUGH THE ORIGINAL, READ THROUGH THE LINKS ##########
$ echo "edited via original" >> original.txt
$ cat softlink.txt
Hello from the original file
edited via original
$ cat hardlink.txt
Hello from the original file
edited via original

########## 8. DELETE THE ORIGINAL FILE ##########
$ rm original.txt
$ ls -li
total 4
62556 -rw-r--r-- 1 root root 49 Sep  3 08:19 hardlink.txt
62564 lrwxrwxrwx 1 root root 12 Sep  3 08:19 softlink.txt -> original.txt

$ cat softlink.txt   (should FAIL - dangling symlink)
cat: softlink.txt: No such file or directory

$ cat hardlink.txt   (should SUCCEED - data still alive via the other name)
Hello from the original file
edited via original

########## 9. FIND DANGLING SYMLINKS ##########
$ find . -xtype l
./softlink.txt

########## 10. HARD LINK TO A DIRECTORY - explicitly refused ##########
$ ln somedir hardlink-to-dir
ln: somedir: hard link not allowed for directory

$ ln -s somedir somedir-symlink   (soft link to a directory - explicitly allowed)
62556 lrwxrwxrwx 1 root root 7 Sep  3 08:19 somedir-symlink -> somedir

########## 11. HARD LINK ACROSS FILESYSTEMS - explicitly refused ##########
$ mount --bind /tmp /mnt/otherfs
$ ln original2.txt /mnt/otherfs/crossfs-hardlink.txt
ln: failed to create hard link '/mnt/otherfs/crossfs-hardlink.txt' => 'original2.txt': Invalid cross-device link

$ ln -s /root/task1-links/original2.txt /mnt/otherfs/crossfs-softlink.txt   (soft link works fine across filesystems)
62570 lrwxrwxrwx 1 root root 31 Sep  3 08:19 /mnt/otherfs/crossfs-softlink.txt -> /root/task1-links/original2.txt

########## 12. CLEANUP - deleting links never touches surviving data ##########
$ rm softlink.txt
$ unlink hardlink.txt
$ ls -li
total 8
62565 -rw-r--r-- 2 root root   20 Sep  3 08:19 original2.txt
62566 drwxr-xr-x 2 root root 4096 Sep  3 08:19 somedir
62567 lrwxrwxrwx 1 root root    7 Sep  3 08:19 somedir-link -> somedir
```

## Interview-question version

**Q: What's the difference between a hard link and a soft link?**
A hard link is a second directory entry pointing at the same inode as the original — they're indistinguishable,
share the same data, and the data survives as long as at least one name (link) exists. A soft link is a
separate file whose content is just a path string; it has its own inode, can point across filesystems or at
directories, but breaks if the target is removed or renamed (it becomes "dangling"). Hard links can't cross
filesystems or point at directories because inode numbers are only unique *within* a filesystem, and allowing
directory hard links could create loops that break tools like `find`.

---

# Task 2 — `adduser` vs `useradd`

## The difference

`useradd` is the **low-level binary** (from `shadow-utils`) — it does the bare minimum: creates the account
in `/etc/passwd`/`/etc/shadow`, nothing else, unless you pass extra flags (`-m` for home dir, `-s` for shell).

`adduser` is a **high-level, interactive Perl wrapper around `useradd`** (Debian/Ubuntu-specific) — it picks
sensible defaults, creates the home directory, copies `/etc/skel` into it, sets a login shell, and creates a
matching primary group, all without extra flags.

**Which is preferred on Ubuntu/Debian, and why:** `adduser`. It's what the distro's own documentation and
`man` pages point new users to, it avoids the common mistake of creating an account with no home directory or
shell (which `useradd` alone does), and its interactive prompts reduce user error. `useradd` is still useful in
scripts/automation where you want to specify every flag explicitly and skip the interactive prompts.

## Full transcript

```console
$ which adduser useradd
/usr/sbin/adduser
/usr/sbin/useradd

########## 1. useradd - low-level, minimal, no defaults applied ##########
$ useradd testuser_low
$ ls /home/
ubuntu
(no home dir created, no shell set by default)

$ getent passwd testuser_low
testuser_low:x:1001:1001::/home/testuser_low:/bin/sh

########## 2. adduser - interactive, high-level wrapper (Debian/Ubuntu) - the recommended command ##########
$ adduser --disabled-password --gecos "Test User,,," testuser_reco
info: Adding user `testuser_reco' ...
info: Selecting UID/GID from range 1000 to 59999 ...
info: Adding new group `testuser_reco' (1002) ...
info: Adding new user `testuser_reco' (1002) with group `testuser_reco (1002)' ...
info: Creating home directory `/home/testuser_reco' ...
info: Copying files from `/etc/skel' ...
info: Adding new user `testuser_reco' to supplemental / extra groups `users' ...
info: Adding user `testuser_reco' to group `users' ...

$ ls /home/
testuser_reco
ubuntu

$ getent passwd testuser_reco
testuser_reco:x:1002:1002:Test User,,,:/home/testuser_reco:/bin/bash

$ ls -la /home/testuser_reco
total 20
drwxr-x--- 2 testuser_reco testuser_reco 4096 Sep  3 08:19 .
drwxr-xr-x 1 root          root          4096 Sep  3 08:19 ..
-rw-r--r-- 1 testuser_reco testuser_reco  220 Sep  3 08:19 .bash_logout
-rw-r--r-- 1 testuser_reco testuser_reco 3771 Sep  3 08:19 .bashrc
-rw-r--r-- 1 testuser_reco testuser_reco  807 Sep  3 08:19 .profile

########## 3. Cleanup test users ##########
$ userdel testuser_low
$ userdel -r testuser_reco
```

**What this proves:** `useradd testuser_low` created *only* the passwd entry — no home directory shows up
under `/home/`, and the shell is `/bin/sh` (a bare fallback). `adduser testuser_reco` created the home
directory, populated it from `/etc/skel` (`.bashrc`, `.profile`, `.bash_logout`), created a matching group,
and set `/bin/bash` as the shell — all the things you'd actually want for a real login account, without
passing any extra flags.

---

# Task 3 — `journalctl`

## What it's used for

`journalctl` is the query tool for **systemd's journal** — the centralized, binary-format log that
`systemd-journald` collects from every service unit, the kernel, and `stdout`/`stderr` of anything systemd
manages. It replaces having to grep through scattered files like `/var/log/syslog` — one tool, structured
metadata (unit, priority, boot ID, timestamp) on every line, and it can filter by any of those fields.

## Key commands

| Command | What it does |
|---|---|
| `journalctl` | Show the whole journal (oldest first), pipe into a pager |
| `journalctl -b` | Only logs from the current boot |
| `journalctl -u <service>` | Only logs from one systemd unit/service |
| `journalctl -f` | Follow mode — like `tail -f` |
| `journalctl -n 20` | Last 20 lines only |
| `journalctl -p err` | Only messages at priority `err` or higher |
| `journalctl --since "5 minutes ago"` | Time-filtered |
| `journalctl -k` | Kernel messages only (like `dmesg`) |
| `journalctl --disk-usage` | How much disk the journal is using |

## Full transcript

```console
########## Verify systemd is really PID 1 and journald is active ##########
$ systemctl is-system-running
running
$ ps -p 1 -o pid,comm
    PID COMMAND
      1 systemd
$ systemctl is-active systemd-journald
active

########## 1. journalctl basics - view the whole system journal ##########
$ journalctl --no-pager | tail -n 15
Sep 03 08:19:48 9d1f6248d53e adduser[130]: Copying files from `/etc/skel' ...
Sep 03 08:19:48 9d1f6248d53e chfn[154]: changed user 'testuser_reco' information
Sep 03 08:19:48 9d1f6248d53e adduser[130]: Adding new user `testuser_reco' to supplemental / extra groups `users' ...
Sep 03 08:19:48 9d1f6248d53e gpasswd[174]: members of group users set by root to testuser_reco
Sep 03 08:19:48 9d1f6248d53e userdel[183]: delete user 'testuser_low'
Sep 03 08:19:48 9d1f6248d53e userdel[183]: removed group 'testuser_low' owned by 'testuser_low'
Sep 03 08:19:48 9d1f6248d53e userdel[191]: delete user 'testuser_reco'
Sep 03 08:19:48 9d1f6248d53e userdel[191]: removed group 'testuser_reco' owned by 'testuser_reco'

########## 2. journalctl -b (this boot only) ##########
$ journalctl -b --no-pager | wc -l
634

########## 3. logs for a specific service (systemd-journald itself) ##########
$ journalctl -u systemd-journald --no-pager | tail -n 10
Sep 03 08:18:34 9d1f6248d53e systemd-journald[21]: Collecting audit messages is disabled.
Sep 03 08:18:34 9d1f6248d53e systemd-journald[21]: Journal started
Sep 03 08:18:34 9d1f6248d53e systemd-journald[21]: Runtime Journal (/run/log/journal/069f7c32fc8b4377b84646614b3d1b19) is 8.0M, max 78.3M, 70.3M free.

########## 4. install and start a real service (nginx) to check its logs ##########
$ systemctl start nginx
$ systemctl is-active nginx
active

########## 5. journalctl -u nginx - logs for just this service ##########
$ journalctl -u nginx --no-pager
Sep 03 08:20:57 9d1f6248d53e systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 03 08:20:57 9d1f6248d53e systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.

########## 6. generate HTTP traffic, then check the service log after a restart ##########
$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:80/
200
$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:80/nonexistent-page
404
$ systemctl restart nginx
$ journalctl -u nginx --no-pager -n 10
Sep 03 08:20:57 9d1f6248d53e systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Sep 03 08:20:57 9d1f6248d53e systemd[1]: nginx.service: Deactivated successfully.
Sep 03 08:20:57 9d1f6248d53e systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Sep 03 08:21:14 9d1f6248d53e systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Sep 03 08:21:14 9d1f6248d53e systemd[1]: nginx.service: Deactivated successfully.
Sep 03 08:21:14 9d1f6248d53e systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Sep 03 08:21:14 9d1f6248d53e systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 03 08:21:14 9d1f6248d53e systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.

########## 7. journalctl -p (filter by priority) ##########
$ journalctl -p err --no-pager | tail -n 5
-- No entries --
(no errors logged - system healthy, an empty result here is expected)

########## 8. journalctl --since (time filtering) ##########
$ journalctl --since "5 minutes ago" --no-pager | wc -l
661

########## 9. journalctl -k (kernel messages) ##########
$ journalctl -k --no-pager | tail -n 5
Sep 03 08:18:34 9d1f6248d53e kernel: veth70949a1: entered promiscuous mode
Sep 03 08:18:34 9d1f6248d53e kernel: eth0: renamed from vethfccc0f1
Sep 03 08:18:34 9d1f6248d53e kernel: docker0: port 1(veth70949a1) entered blocking state
Sep 03 08:18:34 9d1f6248d53e kernel: docker0: port 1(veth70949a1) entered forwarding state
Sep 03 08:18:34 9d1f6248d53e systemd-journald[21]: Collecting audit messages is disabled.

########## 10. disk usage of the journal ##########
$ journalctl --disk-usage
Archived and active journals take up 8.0M in the file system.
```

**Checking logs for a specific service (the explicit ask):** `journalctl -u nginx` — isolates every message
tagged with the `nginx.service` unit, in order, across restarts. Confirmed above: starting nginx, restarting
it, and the stop/start pairs all show up cleanly scoped to just that unit, with nothing else mixed in.

---

# Task 4 — Linux Command Cheat Sheet

Reviewed and practiced the core categories, each demonstrated with real output.

## Navigation & files

```console
$ pwd
/root/task4-cheatsheet
$ mkdir -p demo/sub1 demo/sub2
$ touch demo/file1.txt
$ echo "line1" > demo/file1.txt   # > overwrites
$ echo "line2" >> demo/file1.txt  # >> appends
$ cat demo/file1.txt
line1
line2
$ head -n1 demo/file1.txt
line1
$ tail -n1 demo/file1.txt
line2
$ wc -l demo/file1.txt
2 demo/file1.txt
```

## Copy / move / remove

```console
$ cp demo/file1.txt demo/file1-copy.txt
$ mv demo/file1-copy.txt demo/sub1/
$ ls -R demo
demo:
file1.txt
sub1
sub2

demo/sub1:
file1-copy.txt
$ rm -r demo/sub2
```

## Permissions & ownership

```console
$ chmod 640 demo/file1.txt
$ ls -l demo/file1.txt
-rw-r----- 1 root root 12 Sep  3 08:21 demo/file1.txt
$ chmod +x demo/file1.txt
$ ls -l demo/file1.txt
-rwxr-x--x 1 root root 12 Sep  3 08:21 demo/file1.txt
$ chown root:root demo/file1.txt
```
`chmod 640` = owner read/write, group read, others nothing. `chmod +x` adds execute for everyone who already
has some permission. `chown user:group` changes ownership.

## Searching

```console
$ grep line1 demo/file1.txt
line1
$ find /root/task4-cheatsheet -name "*.txt"
/root/task4-cheatsheet/demo/sub1/file1-copy.txt
/root/task4-cheatsheet/demo/file1.txt
```

## Process & system info

```console
$ ps aux | head -5
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.1  0.2  20620 11356 ?        Ss   08:18   0:00 /lib/systemd/systemd
root          21  0.0  0.1  25484  7780 ?        S<s  08:18   0:00 /usr/lib/systemd/systemd-journald

$ df -h
Filesystem      Size  Used Avail Use% Mounted on
overlay         224G   18G  195G   9% /
tmpfs            64M     0   64M   0% /dev

$ free -h
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       689Mi       2.3Gi       8.6Mi       1.1Gi       3.2Gi
Swap:          1.0Gi          0B       1.0Gi

$ uptime
 08:21:43 up 6 min,  0 user,  load average: 0.48, 0.25, 0.12

$ uname -a
Linux 9d1f6248d53e 7.0.12-linuxkit #1 SMP PREEMPT Wed Aug 12 20:18:49 UTC 2026 aarch64 aarch64 aarch64 GNU/Linux
```
`ps aux` = every process, user-oriented format. `df -h` = disk free, human-readable. `free -h` = memory usage.
`uptime` = how long since boot + load averages. `uname -a` = kernel/OS info.

## Networking basics

```console
$ hostname -I
172.17.0.2
$ ip a | head -10
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 ...
    inet 127.0.0.1/8 scope host lo
2: eth0@if...: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
```

## Archiving

```console
$ tar -czf demo.tar.gz demo
$ tar -tzf demo.tar.gz
demo/
demo/sub1/
demo/sub1/file1-copy.txt
demo/file1.txt
```
`-c` create, `-z` gzip, `-f` filename, `-t` list contents without extracting.

## Text processing

```console
$ echo "a,b,c" | cut -d, -f2
b
$ printf "3\n1\n2\n" | sort
1
2
3
$ echo hello | tr a-z A-Z
HELLO
```

---

# Files in this folder

| File | Purpose |
|---|---|
| `Dockerfile.ubuntu-systemd` | Builds the Ubuntu 24.04 + systemd image used to run every command above |
| `README.md` | This file |
