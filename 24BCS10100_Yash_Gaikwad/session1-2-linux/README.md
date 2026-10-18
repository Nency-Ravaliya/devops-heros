# Sessions 1 & 2: Linux Fundamentals

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

This README covers the four Linux homework tasks:

1. [Soft link and hard link](#task-1-soft-link-and-hard-link)
2. [`adduser` vs `useradd`](#task-2-adduser-vs-useradd)
3. [`journalctl`](#task-3-journalctl)
4. [Linux command cheat sheet](#task-4-linux-command-cheat-sheet)

**Environment:** Ubuntu 26.04 LTS running in WSL2 on Windows 11 (systemd enabled). Every block below is real output copied from my terminal, not typed by hand. Task 2 needs root, so it was run inside a disposable `ubuntu:24.04` Docker container instead of changing the user list of my own machine.

---

## Task 1: Soft Link and Hard Link

### Concepts

Every file on a Linux filesystem is really an **inode** (metadata + pointers to data blocks). A file *name* is just a directory entry that points to an inode number.

| | Hard link | Soft (symbolic) link |
|---|---|---|
| What it is | Another directory entry for the **same inode** | A tiny separate file whose content is the **path** of the target |
| Inode | Same inode number as the original | Its own new inode |
| Original deleted | Data survives (link count just drops) | Link becomes **dangling / broken** |
| Works across filesystems | No | Yes |
| Can point to a directory | No (normal users) | Yes |
| Can point to a file that does not exist | No | Yes (dangling) |
| Size | Same as the file | Length of the path string |
| Command | `ln target linkname` | `ln -s target linkname` |

Rule of thumb: a hard link is a second *name* for the data, a soft link is a *shortcut* to a name.

### Practice (run in WSL Ubuntu)

_Work in a throw-away lab folder._

```console
$ pwd
/home/gaikw/links-lab
```

_Create a file and look at its inode number (first column) and link count (third column)._

```console
$ echo "Hello DevOps - original file" > original.txt && ls -li original.txt
14155 -rw-r--r-- 1 gaikw gaikw 29 Oct 18 12:14 original.txt
```

_Create a soft link with ln -s._

```console
$ ln -s original.txt soft.txt
```

_Create a hard link with ln._

```console
$ ln original.txt hard.txt
```

_hard.txt shares the inode of original.txt and the link count is now 2; soft.txt has its own inode and shows an arrow to its target._

```console
$ ls -li
total 8
14155 -rw-r--r-- 2 gaikw gaikw 29 Oct 18 12:14 hard.txt
14155 -rw-r--r-- 2 gaikw gaikw 29 Oct 18 12:14 original.txt
14156 lrwxrwxrwx 1 gaikw gaikw 12 Oct 18 12:14 soft.txt -> original.txt
```

_stat confirms it: same inode for original/hard, soft link is a "symbolic link" whose size is the length of the path "original.txt" (12 bytes)._

```console
$ stat -c "%n  inode=%i  links=%h  type=%F  size=%s" original.txt hard.txt soft.txt
original.txt  inode=14155  links=2  type=regular file  size=29
hard.txt  inode=14155  links=2  type=regular file  size=29
soft.txt  inode=14156  links=1  type=symbolic link  size=12
```

_Changing the data through one name changes it for every name (same inode)._

```console
$ echo "appended through the hard link" >> hard.txt && cat original.txt
Hello DevOps - original file
appended through the hard link
```

_Delete the original name. The hard link keeps the data alive (link count drops to 1) and the soft link now points at nothing._

```console
$ rm original.txt && ls -li
total 4
14155 -rw-r--r-- 1 gaikw gaikw 60 Oct 18 12:14 hard.txt
14156 lrwxrwxrwx 1 gaikw gaikw 12 Oct 18 12:14 soft.txt -> original.txt
```

_The hard link still works._

```console
$ cat hard.txt
Hello DevOps - original file
appended through the hard link
```

_The soft link is broken: the target path no longer exists._

```console
$ cat soft.txt
cat: soft.txt: No such file or directory
```

_readlink shows what the symlink stores._

```console
$ readlink soft.txt; ls -l soft.txt
original.txt
lrwxrwxrwx 1 gaikw gaikw 12 Oct 18 12:14 soft.txt -> original.txt
```

_Recreate a file with the same name: the soft link works again because it only stores a path._

```console
$ echo "a brand new original" > original.txt && cat soft.txt
a brand new original
```

_Hard links to directories are not allowed._

```console
$ mkdir mydir && ln mydir mydir-hard
ln: mydir: hard link not allowed for directory
```

_Soft links to directories are fine._

```console
$ ln -s mydir mydir-soft && ls -ld mydir-soft
lrwxrwxrwx 1 gaikw gaikw 5 Oct 18 12:14 mydir-soft -> mydir
```

_/dev/shm is a different filesystem (tmpfs), so a hard link cannot cross to it._

```console
$ ln original.txt /dev/shm/hard-cross-fs.txt
ln: failed to create hard link 'original.txt' => '/dev/shm/hard-cross-fs.txt': Invalid cross-device link
```

_A soft link (using an absolute path) crosses filesystems without trouble._

```console
$ ln -s "$PWD/original.txt" /dev/shm/soft-cross-fs.txt && cat /dev/shm/soft-cross-fs.txt && ls -l /dev/shm/soft-cross-fs.txt
a brand new original
lrwxrwxrwx 1 gaikw gaikw 34 Oct 18 12:14 /dev/shm/soft-cross-fs.txt -> /home/gaikw/links-lab/original.txt
```

### Deleting links

`rm` and `unlink` remove just the link (the name), never the target of a soft link.

_Remove the links. unlink and rm both work._

```console
$ unlink soft.txt && rm hard.txt mydir-soft /dev/shm/soft-cross-fs.txt && ls -li
total 8
14454 drwxr-xr-x 2 gaikw gaikw 4096 Oct 18 12:14 mydir
14410 -rw-r--r-- 1 gaikw gaikw   21 Oct 18 12:14 original.txt
```

_Clean up the lab folder._

```console
$ rm -rf mydir original.txt && cd ~ && rm -rf ~/links-lab && echo "lab cleaned up"
lab cleaned up
```

### Interview answer (short version)

> A **hard link** is an additional directory entry pointing to the same inode, so the file's data stays until the *last* name is removed; it cannot span filesystems or point to directories. A **soft link** is a separate file holding a path; it can span filesystems and point to directories, but it breaks if the target is moved or deleted.

Follow-ups worth remembering: `ls -i` shows inode numbers, `find / -samefile file` finds all hard links of a file, `ln -sf` forces an overwrite of an existing symlink, and `/etc/alternatives` and `/usr/bin/python3` style paths on Debian/Ubuntu are common real-world symlinks.

---

## Task 2: `adduser` vs `useradd`

Both create users, but they sit at different levels.

| | `useradd` | `adduser` |
|---|---|---|
| What it is | Low-level binary from the `shadow`/`passwd` package | Friendly Perl **wrapper script** around `useradd` (Debian/Ubuntu) |
| Home directory | **Not** created unless you pass `-m` | Created automatically, copied from `/etc/skel` |
| Login shell | System default (often `/bin/sh`) unless `-s` | `/bin/bash` (from `/etc/adduser.conf`) |
| Password | Not set, account locked until `passwd` is run | Prompts interactively for password and details |
| Group | Depends on `USERGROUPS_ENAB` | Creates a matching private group by default |
| Interactive | No, flags only | Yes, asks questions (can be silenced with flags) |
| Portable | Present on every distro (RHEL, CentOS, Alpine, Ubuntu) | Debian family only (on RHEL it is just a symlink to `useradd`) |
| Best for | Scripts and automation where you control every flag | Day-to-day use by humans on Ubuntu/Debian |

**Which one is preferred on Ubuntu?** `adduser`. Ubuntu's own documentation recommends it because sensible defaults are applied for you (home folder, skeleton files, shell, group, password prompt) and you cannot forget a flag such as `-m`. `useradd` is still the right tool inside shell scripts, Dockerfiles and on non-Debian distros, but then you must write `useradd -m -s /bin/bash name` yourself.

> The commands below need root. To avoid touching the user database of my own machine they were run as root inside a throw-away `ubuntu:24.04` Docker container that was deleted afterwards.

### Practice

_Environment: Ubuntu container, running as root._

```console
$ grep PRETTY_NAME /etc/os-release; whoami
PRETTY_NAME="Ubuntu 24.04.5 LTS"
root
```

_The minimal Ubuntu container image does not ship adduser (a normal Ubuntu server has it preinstalled), so install it (with perl, which deluser --remove-home needs) first._

```console
$ apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq adduser perl >/dev/null 2>&1 && echo "adduser package installed"
adduser package installed
```

_useradd is a compiled binary, adduser is a Perl script._

```console
$ ls -l $(command -v useradd adduser); head -1 $(command -v adduser)
-rwxr-xr-x 1 root root  55191 Jul  5  2023 /usr/sbin/adduser
-rwxr-xr-x 1 root root 143232 May 30  2024 /usr/sbin/useradd
#! /usr/bin/perl
```

_Plain useradd: user line is created._

```console
$ useradd testuser1 && getent passwd testuser1
testuser1:x:1001:1001::/home/testuser1:/bin/sh
```

_No home directory was created for plain useradd._

```console
$ ls -ld /home/testuser1
ls: cannot access '/home/testuser1': No such file or directory
```

_The password field is "!" which means locked: nobody can log in until passwd is run._

```console
$ grep testuser1 /etc/shadow | cut -d: -f1,2
testuser1:!
```

_useradd done properly needs -m (home) and -s (shell)._

```console
$ useradd -m -s /bin/bash testuser1b && getent passwd testuser1b && ls -ld /home/testuser1b
testuser1b:x:1002:1002::/home/testuser1b:/bin/bash
drwxr-x--- 2 testuser1b testuser1b 4096 Oct 18 12:17 /home/testuser1b
```

_adduser with defaults. (Without --disabled-password it also asks for a password and the finger details interactively.)_

```console
$ adduser --disabled-password --gecos "Yash Test User" testdevops
info: Adding user `testdevops' ...
info: Selecting UID/GID from range 1000 to 59999 ...
info: Adding new group `testdevops' (1003) ...
info: Adding new user `testdevops' (1003) with group `testdevops (1003)' ...
info: Creating home directory `/home/testdevops' ...
info: Copying files from `/etc/skel' ...
info: Adding new user `testdevops' to supplemental / extra groups `users' ...
info: Adding user `testdevops' to group `users' ...
```

_Home directory, bash shell and the /etc/skel files (.bashrc, .profile, .bash_logout) all appear automatically._

```console
$ getent passwd testdevops && ls -ld /home/testdevops && ls -A /home/testdevops
testdevops:x:1003:1003:Yash Test User,,,:/home/testdevops:/bin/bash
drwxr-x--- 2 testdevops testdevops 4096 Oct 18 12:17 /home/testdevops
.bash_logout
.bashrc
.profile
```

_adduser made a private group (gid = uid); useradd followed the system default._

```console
$ id testdevops; id testuser1
uid=1003(testdevops) gid=1003(testdevops) groups=1003(testdevops),100(users)
uid=1001(testuser1) gid=1001(testuser1) groups=1001(testuser1)
```

_The defaults adduser applies (shell, home base, skeleton folder, private groups, directory mode, first UID) live in /etc/adduser.conf; commented lines are the built-in defaults._

```console
$ grep -E "^#?(DSHELL|DHOME|SKEL|USERGROUPS|DIR_MODE|FIRST_UID)=" /etc/adduser.conf
#DSHELL=/bin/bash
#SKEL=/etc/skel
#FIRST_UID=1000
#USERGROUPS=yes
#DIR_MODE=0750
```

_Switch into the new test user to prove it works._

```console
$ su - testdevops -c "whoami; pwd; echo shell=\$SHELL"
testdevops
/home/testdevops
shell=/bin/bash
```

_Account status: L = locked, P = usable password. Both are locked here because no password was set._

```console
$ for u in testdevops testuser1; do passwd -S $u; done
testdevops L 2026-10-18 0 99999 7 -1
testuser1 L 2026-10-18 0 99999 7 -1
```

### Cleanup (delete the test users)

_deluser (friendly) and userdel (low-level) are the matching delete commands. The mail spool warning is harmless (a container has no mail spool); the final 0 means no test users remain._

```console
$ deluser --remove-home testdevops; userdel -r testuser1b; userdel testuser1; getent passwd | grep -c test || true
info: Looking for files to backup/remove ...
info: Removing files ...
warn: `/usr/bin/crontab' not executed. Skipping crontab removal. Package `cron' required.
info: Removing user `testdevops' ...
userdel: testuser1b mail spool (/var/mail/testuser1b) not found
0
```

### Takeaway

- Humans on Ubuntu: `sudo adduser <name>`.
- Scripts, containers, other distros: `useradd -m -s /bin/bash <name>` followed by `passwd <name>`.
- Interview one-liner: *adduser is an interactive, opinionated front-end to useradd; useradd is the portable low-level tool that does only what you tell it.*

---

## Task 3: `journalctl`

`journalctl` reads the **systemd journal**, the binary log database written by `systemd-journald`. It collects kernel messages, service stdout/stderr, syslog and boot messages in one searchable place, so you do not have to hunt through `/var/log/*.log`.

Handy options:

| Option | Meaning |
|---|---|
| `-u <unit>` | Logs of one service/unit (e.g. `nginx`, `ssh`, `docker`) |
| `-n <N>` | Last N lines |
| `-f` | Follow live, like `tail -f` |
| `-p err` | Only priority err and worse (emerg, alert, crit, err) |
| `-b` / `-b -1` | This boot / previous boot |
| `--since` / `--until` | Time filter, e.g. `"1 hour ago"`, `"2026-10-18 10:00"` |
| `-k` | Kernel messages (like `dmesg`) |
| `-o json-pretty` | Change output format |
| `--disk-usage`, `--vacuum-time=7d` | See size / clean old logs (clean needs root) |

### Practice (WSL Ubuntu, systemd enabled)

_Version and how much space the journal uses._

```console
$ journalctl --version | head -1; journalctl --disk-usage
systemd 259 (259.5-0ubuntu3.4)
Archived and active journals take up 232.7M in the file system.
```

_The last 5 log lines of the whole system._

```console
$ journalctl -n 5 --no-pager
Oct 18 12:13:49 Yashg-Laptop wsl-pro-service[210]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/gaikw/.ubuntupro/.address": open /mnt/c/Users/gaikw/.ubuntupro/.address: no such file or directory
Oct 18 12:14:06 Yashg-Laptop systemd-resolved[91]: Clock change detected. Flushing caches.
Oct 18 12:14:36 Yashg-Laptop systemd-resolved[91]: Clock change detected. Flushing caches.
Oct 18 12:14:49 Yashg-Laptop wsl-pro-service[210]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/gaikw/.ubuntupro/.address": open /mnt/c/Users/gaikw/.ubuntupro/.address: no such file or directory
Oct 18 12:15:06 Yashg-Laptop systemd-resolved[91]: Clock change detected. Flushing caches.
```

_Pick a service to inspect: list running services._

```console
$ systemctl list-units --type=service --state=running --no-pager --no-legend | head -8 | awk "{print \$1, \$3, \$4}"
chrony.service active running
console-getty.service active running
cron.service active running
dbus.service active running
getty@tty1.service active running
networkd-dispatcher.service active running
rsyslog.service active running
systemd-journald.service active running
```

_Service status also prints the latest journal lines for the unit._

```console
$ systemctl status systemd-logind --no-pager | head -6
● systemd-logind.service - User Login Management
     Loaded: loaded (/usr/lib/systemd/system/systemd-logind.service; static)
    Drop-In: /usr/lib/systemd/system/systemd-logind.service.d
             └─dbus.conf
     Active: active (running) since Sun 2026-10-18 12:11:43 UTC; 3min 37s ago
 Invocation: b2c3b4eb87ef476a82086fe0275233ca
```

_Logs of one specific service with -u._

```console
$ journalctl -u systemd-logind -n 5 --no-pager
Oct 18 12:11:43 Yashg-Laptop systemd[1]: Started systemd-logind.service - User Login Management.
Oct 18 12:11:48 Yashg-Laptop systemd-logind[189]: New session 'c1' of user 'gaikw' with class 'user' and type 'tty'.
Oct 18 12:11:48 Yashg-Laptop systemd-logind[189]: New session 'c2' of user 'gaikw' with class 'manager' and type 'unspecified'.
Oct 18 12:11:49 Yashg-Laptop systemd-logind[189]: New session 'c3' of user 'root' with class 'user-early' and type 'tty'.
Oct 18 12:11:50 Yashg-Laptop systemd-logind[189]: New session 'c4' of user 'root' with class 'manager-early' and type 'unspecified'.
```

_Service logs for today with ISO timestamps._

```console
$ journalctl -u systemd-logind --since "today" -o short-iso -n 3 --no-pager
2026-10-18T12:11:48+00:00 Yashg-Laptop systemd-logind[189]: New session 'c2' of user 'gaikw' with class 'manager' and type 'unspecified'.
2026-10-18T12:11:49+00:00 Yashg-Laptop systemd-logind[189]: New session 'c3' of user 'root' with class 'user-early' and type 'tty'.
2026-10-18T12:11:50+00:00 Yashg-Laptop systemd-logind[189]: New session 'c4' of user 'root' with class 'manager-early' and type 'unspecified'.
```

_Only errors and worse across the system._

```console
$ journalctl -p err -n 5 --no-pager
Oct 18 12:11:51 Yashg-Laptop addgroup[582]: The group `docker' already exists.
Oct 18 12:11:51 Yashg-Laptop addgroup[605]: addgroup with two arguments is an unspecified operation.
Oct 18 12:11:52 Yashg-Laptop chronyd[275]: Could not step system clock
Oct 18 12:11:53 Yashg-Laptop chronyd[275]: Could not step system clock
Oct 18 12:12:57 Yashg-Laptop chronyd[275]: Could not step system clock
```

_Time filter: the last hour._

```console
$ journalctl --since "1 hour ago" -n 5 --no-pager
Oct 18 12:13:49 Yashg-Laptop wsl-pro-service[210]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/gaikw/.ubuntupro/.address": open /mnt/c/Users/gaikw/.ubuntupro/.address: no such file or directory
Oct 18 12:14:06 Yashg-Laptop systemd-resolved[91]: Clock change detected. Flushing caches.
Oct 18 12:14:36 Yashg-Laptop systemd-resolved[91]: Clock change detected. Flushing caches.
Oct 18 12:14:49 Yashg-Laptop wsl-pro-service[210]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/gaikw/.ubuntupro/.address": open /mnt/c/Users/gaikw/.ubuntupro/.address: no such file or directory
Oct 18 12:15:06 Yashg-Laptop systemd-resolved[91]: Clock change detected. Flushing caches.
```

_Logs from the current boot._

```console
$ journalctl -b -n 3 --no-pager
Oct 18 12:14:36 Yashg-Laptop systemd-resolved[91]: Clock change detected. Flushing caches.
Oct 18 12:14:49 Yashg-Laptop wsl-pro-service[210]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/gaikw/.ubuntupro/.address": open /mnt/c/Users/gaikw/.ubuntupro/.address: no such file or directory
Oct 18 12:15:06 Yashg-Laptop systemd-resolved[91]: Clock change detected. Flushing caches.
```

_Kernel ring buffer messages._

```console
$ journalctl -k -n 3 --no-pager
Oct 18 12:11:57 Yashg-Laptop kernel: veth5ebdbec (unregistering): left promiscuous mode
Oct 18 12:11:57 Yashg-Laptop kernel: br-7f0a088f77de: port 2(veth5ebdbec) entered disabled state
Oct 18 12:12:19 Yashg-Laptop kernel: hv_balloon: Max. dynamic memory size: 11896 MB
```

_Machine readable format: every log line is a structured record with fields (_SYSTEMD_UNIT, PRIORITY ...)._

```console
$ journalctl -u systemd-logind -n 1 -o json-pretty --no-pager | head -12
{
	"_HOSTNAME" : "Yashg-Laptop",
	"_RUNTIME_SCOPE" : "system",
	"LEADER" : "511",
	"MESSAGE_ID" : "8d45620c1a4348dbb17410da57c60c66",
	"_CAP_EFFECTIVE" : "24420020f",
	"PRIORITY" : "6",
	"MESSAGE" : "New session 'c4' of user 'root' with class 'manager-early' and type 'unspecified'.",
	"_SOURCE_REALTIME_TIMESTAMP" : "1792325510007936",
	"SESSION_ID" : "c4",
	"__SEQNUM_ID" : "5c64223c68f448bb952cfcc2f9f04786",
	"_GID" : "0",
```

_Follow mode (-f) streams new lines live; it was stopped after 3 seconds._

```console
$ timeout 3 journalctl -f -n 2 --no-pager; echo "(stopped follow mode after 3 s)"
Oct 18 12:14:49 Yashg-Laptop wsl-pro-service[210]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/gaikw/.ubuntupro/.address": open /mnt/c/Users/gaikw/.ubuntupro/.address: no such file or directory
Oct 18 12:15:06 Yashg-Laptop systemd-resolved[91]: Clock change detected. Flushing caches.
(stopped follow mode after 3 s)
```

### Troubleshooting pattern I will use

1. `systemctl status <service>` to see if it is active and the last few lines.
2. `journalctl -u <service> -n 100 --no-pager` for recent history.
3. `journalctl -u <service> -p err -b` to isolate errors since boot.
4. `journalctl -u <service> -f` while reproducing the problem.

---

## Task 4: Linux Command Cheat Sheet

I went through the two cheat sheets shared in the course repo (*Basic Linux commands* and *Advanced Linux commands*) plus the `ip` command sheet and ran the important commands in a scratch folder in WSL Ubuntu. Each block shows the real output.

### 1. Files and directories (`ls cd pwd mkdir touch cp mv rm`)

_mkdir -p creates nested folders, pwd prints where I am._

```console
$ mkdir -p project/logs && cd project && pwd
/home/gaikw/cheat-lab/project
```

_touch creates empty files, ls -l lists with permissions, owner, size._

```console
$ cd project && touch index.html app.log && echo "hello" > notes.txt && ls -l
total 8
-rw-r--r-- 1 gaikw gaikw    0 Oct 18 12:19 app.log
-rw-r--r-- 1 gaikw gaikw    0 Oct 18 12:19 index.html
drwxr-xr-x 2 gaikw gaikw 4096 Oct 18 12:19 logs
-rw-r--r-- 1 gaikw gaikw    6 Oct 18 12:19 notes.txt
```

_cp copies, mv moves or renames, ls -R lists recursively._

```console
$ cd project && cp notes.txt logs/notes.bak && mv app.log logs/backup_app.log && ls -R
.:
index.html
logs
notes.txt

./logs:
backup_app.log
notes.bak
```

_rm -rf removes a folder and everything inside it (use with care)._

```console
$ cd project && rm -rf logs && ls
index.html
notes.txt
```

### 2. Viewing and searching files (`cat head tail grep`)

_cat prints a file._

```console
$ cat /etc/os-release | head -4
PRETTY_NAME="Ubuntu 26.04 LTS"
NAME="Ubuntu"
VERSION_ID="26.04"
VERSION="26.04 (Resolute Raccoon)"
```

_head shows the top, tail the bottom of a file._

```console
$ seq 1 20 > nums.txt; head -n 3 nums.txt; echo ...; tail -n 3 nums.txt
1
2
3
...
18
19
20
```

_grep searches text; -c counts matches._

```console
$ printf "INFO start\nERROR disk full\nINFO retry\nERROR timeout\n" > app.log; grep ERROR app.log; grep -c INFO app.log
ERROR disk full
ERROR timeout
2
```

### 3. Processes and jobs (`ps top kill pkill nice nohup bg fg`)

_ps aux lists every process._

```console
$ ps aux | head -5
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.7  0.1  24300 14448 ?        Ss   12:11   0:03 /sbin/init
root           2  0.0  0.0   3120  2048 ?        Sl   12:11   0:00 /init
root           8  0.0  0.0   3120  1792 ?        Sl   12:11   0:00 plan9 --control-socket 7 --log-level 4 --server-fd 8 
root          54  0.1  0.1  50380 15744 ?        S<s  12:11   0:00 /usr/lib/systemd/systemd-journald
```

_top in batch mode (-b) prints one snapshot of load, tasks and CPU._

```console
$ top -bn1 | head -5
top - 12:19:00 up 7 min,  2 users,  load average: 0.22, 0.27, 0.16
Tasks:  43 total,   1 running,  42 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st 
MiB Mem :  11575.2 total,   8999.8 free,    993.3 used,   1795.2 buff/cache     
MiB Swap:   3072.0 total,   3072.0 free,      0.0 used.  10581.9 avail Mem 
```

_Start a background job, then kill it by PID._

```console
$ sleep 300 & pid=$!; ps -p $pid -o pid,stat,cmd; kill $pid; sleep 0.3; ps -p $pid >/dev/null || echo "process $pid has been killed"
    PID STAT CMD
   1331 S+   sleep 300
process 1331 has been killed
```

_pkill kills by process name._

```console
$ sleep 300 & sleep 0.2; pkill sleep; sleep 0.3; pgrep sleep || echo "no sleep process left"
no sleep process left
```

_nice starts a command with lower priority (NI = 10)._

```console
$ nice -n 10 bash -c "ps -o pid,ni,cmd -p \$\$"
    PID  NI CMD
   1341  10 ps -o pid,ni,cmd -p 1341
```

_nohup keeps a command running after the terminal closes._

```console
$ nohup sleep 1 >/dev/null 2>&1 & echo "started in background with nohup, pid $!"
started in background with nohup, pid 1343
```

### 4. Services (`systemctl`)

_systemctl status shows a service state (restart/stop need root)._

```console
$ systemctl status systemd-logind --no-pager | head -5
● systemd-logind.service - User Login Management
     Loaded: loaded (/usr/lib/systemd/system/systemd-logind.service; static)
    Drop-In: /usr/lib/systemd/system/systemd-logind.service.d
             └─dbus.conf
     Active: active (running) since Sun 2026-10-18 12:11:43 UTC; 7min ago
```

### 5. Networking (`ping ip ss netstat curl`)

_ping tests reachability (loopback here)._

```console
$ ping -c 2 127.0.0.1
PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.037 ms
64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.055 ms

--- 127.0.0.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1021ms
rtt min/avg/max/mdev = 0.037/0.046/0.055/0.009 ms
```

_ping a real host: DNS lookup + round trip time._

```console
$ ping -c 2 google.com
PING google.com (142.250.143.100) 56(84) bytes of data.
64 bytes from pt-in-f100.1e100.net (142.250.143.100): icmp_seq=1 ttl=112 time=48.2 ms
64 bytes from pt-in-f100.1e100.net (142.250.143.100): icmp_seq=2 ttl=112 time=28.5 ms

--- google.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 28.483/38.341/48.199/9.858 ms
```

_ip a (brief) lists interfaces and their IPs._

```console
$ ip -brief addr
lo               UNKNOWN        127.0.0.1/8 10.255.255.254/32 ::1/128 
eth0             UP             172.28.10.180/20 fe80::215:5dff:feb5:b4a9/64 
```

_The routing table._

```console
$ ip route
default via 172.28.0.1 dev eth0 proto kernel 
172.28.0.0/20 dev eth0 proto kernel scope link src 172.28.10.180 
```

_ss lists listening TCP/UDP sockets (modern netstat)._

```console
$ ss -tuln | head -6
Netid        State         Recv-Q        Send-Q                Local Address:Port               Peer Address:Port       
udp          UNCONN        0             0                        127.0.0.54:53                      0.0.0.0:*          
udp          UNCONN        0             0                     127.0.0.53%lo:53                      0.0.0.0:*          
udp          UNCONN        0             0                    10.255.255.254:53                      0.0.0.0:*          
udp          UNCONN        0             0                         127.0.0.1:323                     0.0.0.0:*          
udp          UNCONN        0             0                         127.0.0.1:323                     0.0.0.0:*          
```

_netstat does the same with the older tool._

```console
$ netstat -tuln | head -6
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State      
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN     
tcp        0      0 127.0.0.54:53           0.0.0.0:*               LISTEN     
tcp        0      0 10.255.255.254:53       0.0.0.0:*               LISTEN     
udp        0      0 127.0.0.54:53           0.0.0.0:*                          
```

_curl -I fetches only the HTTP response headers._

```console
$ curl -sI https://example.com | head -4
HTTP/2 200 
date: Sun, 18 Oct 2026 12:19:02 GMT
content-type: text/html; charset=utf-8
server: cloudflare
```

### 6. Permissions and ownership (`chmod chown umask`)

_Before chmod the script is not executable; chmod 755 gives rwx for owner and r-x for others._

```console
$ printf "#!/bin/bash\necho hi\n" > run.sh; ls -l run.sh; chmod 755 run.sh; ls -l run.sh; ./run.sh
-rw-r--r-- 1 gaikw gaikw 20 Oct 18 12:19 run.sh
-rwxr-xr-x 1 gaikw gaikw 20 Oct 18 12:19 run.sh
hi
```

_chown sets owner:group (changing to another user needs sudo). umask shows the default permission mask._

```console
$ chown $(id -un):$(id -gn) run.sh && ls -l run.sh; umask
-rwxr-xr-x 1 gaikw gaikw 20 Oct 18 12:19 run.sh
0022
```

### 7. Disk and storage (`df du lsblk find`)

_df -h shows free space per filesystem._

```console
$ df -h | head -5
Filesystem                                Size  Used Avail Use% Mounted on
none                                      5.7G     0  5.7G   0% /usr/lib/modules/6.6.87.2-microsoft-standard-WSL2
none                                      5.7G  4.0K  5.7G   1% /mnt/wsl
none                                      5.7G  624K  5.7G   1% /mnt/wsl/docker-desktop/shared-sockets/host-services
/dev/sdd                                  136M   71M   54M  57% /mnt/wsl/docker-desktop/docker-desktop-user-distro
```

_du -sh gives the size of each item, sort -h orders them._

```console
$ du -sh * | sort -h
4.0K	app.log
4.0K	nums.txt
4.0K	run.sh
8.0K	project
```

_find searches for files by name._

```console
$ find /etc -maxdepth 1 -name "*.conf" | head -4
/etc/e2scrub.conf
/etc/pam.conf
/etc/deluser.conf
/etc/wsl-distribution.conf
```

### 8. Users and system information (`id groups who w last uname hostname uptime whoami date`)

_Who am I and which groups do I belong to._

```console
$ whoami; id; groups
gaikw
uid=1000(gaikw) gid=1000(gaikw) groups=1000(gaikw),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),100(users),1001(docker)
gaikw adm cdrom sudo dip plugdev users docker
```

_Who is logged in._

```console
$ who; w | head -3
 12:19:04 up 7 min,  2 users,  load average: 0.28, 0.28, 0.17
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
root     pts/3    -                12:11    7:15   0.05s  0.05s -bash
```

_System boot time. (The login-history command last is not installed on this WSL image, and who -b prints nothing because WSL has no boot record in utmp, so I use uptime -s.)_

```console
$ uptime -s
2026-10-18 12:11:28
```

_Kernel and system info._

```console
$ uname -a
Linux Yashg-Laptop 6.6.87.2-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Thu Jun  5 18:30:46 UTC 2025 x86_64 GNU/Linux
```

_Hostname, uptime and load, current date/time._

```console
$ hostname; uptime; date
Yashg-Laptop
 12:19:04 up 7 min,  2 users,  load average: 0.28, 0.28, 0.17
Sun Oct 18 12:19:04 UTC 2026
```

_Memory in human readable form and vmstat samples (1 second apart)._

```console
$ free -h; vmstat 1 3
               total        used        free      shared  buff/cache   available
Mem:            11Gi       985Mi       8.8Gi       4.6Mi       1.8Gi        10Gi
Swap:          3.0Gi          0B       3.0Gi
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 0  0      0 9223444 195168 1643088    0    0  2807  1370 2490    3  1  2 96  1  0  0
 1  0      0 9223516 195168 1643092    0    0     0     0  132   97  0  0 100  0  0  0
 0  0      0 9223092 195180 1643080    0    0     0    92  148  251  0  0 100  0  0  0
```

### 9. Package management (`apt`)

Installing needs root, so I only queried the package database:

_apt lists installed packages; apt-cache policy shows installed vs available version._

```console
$ apt list --installed 2>/dev/null | head -4; apt-cache policy curl | head -3
Listing...
adduser/resolute,now 3.153ubuntu1 all [installed,automatic]
adwaita-icon-theme/resolute,now 50.0-1 all [installed,automatic]
apparmor/resolute,now 5.0.0~beta1-0ubuntu7 amd64 [installed,upgradable to: 5.0.2-0ubuntu1~26.04.1]
curl:
  Installed: 8.18.0-1ubuntu2.7
  Candidate: 8.18.0-1ubuntu2.8
```

### 10. Tips and tricks

_ls -ltr sorts by modified time, newest last._

```console
$ ls -ltr
total 16
drwxr-xr-x 2 gaikw gaikw 4096 Oct 18 12:19 project
-rw-r--r-- 1 gaikw gaikw   51 Oct 18 12:19 nums.txt
-rw-r--r-- 1 gaikw gaikw   52 Oct 18 12:19 app.log
-rwxr-xr-x 1 gaikw gaikw   20 Oct 18 12:19 run.sh
```

_alias creates a shortcut (expand_aliases is needed because this runs in a non-interactive shell; in a normal terminal just type the alias line)._

```console
$ shopt -s expand_aliases
alias ll="ls -alF"
ll | head -4
total 24
drwxr-xr-x 3 gaikw gaikw 4096 Oct 18 12:19 ./
drwxr-x--- 8 gaikw gaikw 4096 Oct 18 12:19 ../
-rw-r--r-- 1 gaikw gaikw   52 Oct 18 12:19 app.log
```

_xargs turns input into command arguments._

```console
$ echo one two three | xargs -n1 echo item:
item: one
item: two
item: three
```

_file identifies a file type; ss -plnt lists listening ports with the owning process._

```console
$ file /bin/ls; ss -plnt | head -3
/bin/ls: symbolic link to ../lib/cargo/bin/coreutils/ls
State        Recv-Q        Send-Q                Local Address:Port               Peer Address:Port       Process       
LISTEN       0             4096                  127.0.0.53%lo:53                      0.0.0.0:*                        
LISTEN       0             4096                     127.0.0.54:53                      0.0.0.0:*                        
```

_A few cheat-sheet tools need extra packages; this is what is missing on this machine._

```console
$ for t in htop iostat sar nmap tldr lsof traceroute; do if command -v $t >/dev/null; then echo "$t: installed"; else echo "$t: not installed (apt install needed)"; fi; done
htop: not installed (apt install needed)
iostat: not installed (apt install needed)
sar: not installed (apt install needed)
nmap: not installed (apt install needed)
tldr: not installed (apt install needed)
lsof: installed
traceroute: not installed (apt install needed)
```

### Things that are interactive and cannot be shown as plain output

`less`/`more` (pager), `htop`, `crontab -e` (editor), `history`, `!!`, `!n`, `Ctrl+C`, `Ctrl+L`. Cron syntax I practised on paper: `0 2 * * * /home/user/backup.sh` runs every day at 02:00 (minute hour day-of-month month day-of-week).
