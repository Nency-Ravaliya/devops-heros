# Session 01 & 02 — Linux

| | |
|---|---|
| **Student** | Ujjawal Prabhat |
| **Enrollment No.** | 24BCS10267 |
| **Session** | 01 & 02 — Linux Fundamentals |

## Task checklist

- [x] Task 1 — Soft link vs hard link (create, delete, inode numbers, dangling symlink, interview Q&A)
- [x] Task 2 — `adduser` vs `useradd` (difference, which one Ubuntu prefers, create a test user)
- [x] Task 3 — `journalctl` (system logs, `-u`, `-f`, `--since`, `-p err`, practice on `cron` and `ssh`)
- [x] Task 4 — Linux command cheat sheet with real outputs

## Environment used

My laptop runs macOS, so I did all the tasks inside real Ubuntu 24.04 containers on Docker Desktop:

- `ujj-ubuntu`: plain `ubuntu:24.04` container (Tasks 1, 2, 4).
- `ujj-systemd`: an Ubuntu 24.04 image I built with `systemd`, `cron` and `openssh-server` installed, running `/sbin/init` as PID 1 (Task 3). The usual `jrei/systemd-ubuntu` image has no arm64 build, so I made my own:

```dockerfile
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y systemd systemd-sysv cron openssh-server procps && apt-get clean
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
```

```bash
docker build -t ujj-systemd-ubuntu:24.04 .
docker run -d --name ujj-systemd --hostname ujj-systemd --privileged \
  --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw ujj-systemd-ubuntu:24.04
```

All outputs below were copied from the terminal exactly as they came out. Where an output was very long I cut it and marked the cut with `...`. I ran the commands from my Mac with `docker exec <container> ...`. Most of them went through a small helper script (`/usr/local/bin/run.sh`) that prints each command and then runs it with `eval`. To make things easier to read, I show each command after a normal shell prompt (`root@ujj-ubuntu:~#`).

---

## Task 1 — Soft link vs hard link

### Theory

Every file on a Linux filesystem has an **inode**. The inode stores the file's metadata (owner, permissions, size, where the data blocks are). The **file name** is only a directory entry that points to an inode.

- **Hard link**: another name for the **same inode**. Both names are equal, and neither one is "the original". The data is only removed once the link count reaches 0.
- **Soft (symbolic) link**: a **separate small file with its own inode**. It stores the **path** of the target. If the target is deleted, the symlink still exists but points at nothing, which is called a *dangling* or broken link.

| | Hard link | Soft link |
|---|---|---|
| Command | `ln target link` | `ln -s target link` |
| Inode | Same as target | Its own new inode |
| Target deleted | Data still reachable | Link breaks (dangling) |
| Works for directories | No | Yes |
| Across filesystems/partitions | No | Yes |
| `ls -l` shows | Normal file, link count > 1 | `l` type and `link -> target` |

### Practical

Create a file, a hard link and a soft link, then check the inodes:

```console
root@ujj-ubuntu:~# mkdir -p links-demo && cd links-demo
root@ujj-ubuntu:~/links-demo# echo "Hello from original file" > original.txt
root@ujj-ubuntu:~/links-demo# ln original.txt hardlink.txt
root@ujj-ubuntu:~/links-demo# ln -s original.txt softlink.txt
root@ujj-ubuntu:~/links-demo# ls -li
total 8
286123 -rw-r--r-- 2 root root 25 Oct  6 10:58 hardlink.txt
286123 -rw-r--r-- 2 root root 25 Oct  6 10:58 original.txt
286124 lrwxrwxrwx 1 root root 12 Oct  6 10:58 softlink.txt -> original.txt
root@ujj-ubuntu:~/links-demo# cat hardlink.txt
Hello from original file
root@ujj-ubuntu:~/links-demo# cat softlink.txt
Hello from original file
root@ujj-ubuntu:~/links-demo# stat -c "%n inode=%i links=%h" original.txt hardlink.txt
original.txt inode=286123 links=2
hardlink.txt inode=286123 links=2
```

What this shows:
- `original.txt` and `hardlink.txt` have the **same inode (286123)**, and the link count is **2**.
- `softlink.txt` has a **different inode (286124)**. Its type is `l`, and its size is 12 bytes, which is the length of the string `original.txt`.

A write through the hard link also changes the original, because both names point to the same data:

```console
root@ujj-ubuntu:~/links-demo# echo "appended line" >> hardlink.txt
root@ujj-ubuntu:~/links-demo# cat original.txt
Hello from original file
appended line
```

Delete the original and check both links:

```console
root@ujj-ubuntu:~/links-demo# rm original.txt
root@ujj-ubuntu:~/links-demo# ls -li
total 4
286123 -rw-r--r-- 1 root root 39 Oct  6 10:58 hardlink.txt
286124 lrwxrwxrwx 1 root root 12 Oct  6 10:58 softlink.txt -> original.txt
root@ujj-ubuntu:~/links-demo# cat hardlink.txt
Hello from original file
appended line
root@ujj-ubuntu:~/links-demo# cat softlink.txt
cat: softlink.txt: No such file or directory
root@ujj-ubuntu:~/links-demo# file softlink.txt
softlink.txt: broken symbolic link to original.txt
root@ujj-ubuntu:~/links-demo# find . -xtype l
./softlink.txt
```

- The hard link still works. The link count dropped from 2 to 1, and the data is still there.
- The soft link is now **dangling**. It still points to `original.txt`, but that name no longer exists. `find -xtype l` is a handy way to find broken symlinks.

Delete the links, and try both kinds of link on a directory:

```console
root@ujj-ubuntu:~/links-demo# rm hardlink.txt softlink.txt
root@ujj-ubuntu:~/links-demo# ls -li
total 0
root@ujj-ubuntu:~/links-demo# mkdir dir1; ln dir1 dirhard; ln -s dir1 dirsoft; ls -li
ln: dir1: hard link not allowed for directory
total 4
286123 drwxr-xr-x 2 root root 4096 Oct  6 10:58 dir1
286124 lrwxrwxrwx 1 root root    4 Oct  6 10:58 dirsoft -> dir1
```

You can't hard link a directory, but a soft link to a directory works.

### Interview-style Q&A

**Q1. What is an inode?**
A data structure that holds a file's metadata (permissions, owner, size, timestamps, pointers to data blocks). It does not hold the file name. Names live in directory entries that point to inodes. You can see inode numbers with `ls -i`.

**Q2. Difference between a hard link and a soft link?**
A hard link is another directory entry for the same inode. A soft link is a separate file whose content is the path of the target. Hard links survive deletion of the "original". Soft links break.

**Q3. What happens to a hard link when the original file is deleted?**
Nothing visible. `rm` only removes one name and lowers the link count. The data is freed only when the link count reaches 0 and no process has the file open.

**Q4. What is a dangling symlink and how do you find one?**
A symlink whose target no longer exists. `ls -l` still shows `link -> target`, but reading it fails with "No such file or directory". Find them with `find /path -xtype l`.

**Q5. Why can't you hard link a directory?**
It could create loops in the directory tree (a directory could end up inside itself), which would break tools like `find` and `du` and confuse the filesystem's `..` handling. The kernel blocks it (`hard link not allowed for directory`).

**Q6. Can a hard link cross filesystems or partitions?**
No. Inode numbers only mean something inside one filesystem. A soft link stores a path, so it can point anywhere, even to a different disk or an NFS mount.

**Q7. Do a hard link and its target share permissions?**
Yes. Permissions live in the inode, so a `chmod` on one name shows up on the other. The permission bits on a symlink itself (`lrwxrwxrwx`) are ignored. The target's permissions are what count.

**Q8. Real-world uses?**
Soft links: switching versions (`/usr/bin/python3 -> python3.12`), `/etc/nginx/sites-enabled/* -> ../sites-available/*`, and "current" release folders in deployments. Hard links: backup tools like `rsync --link-dest` and Time Machine-style snapshots, which store unchanged files once.

**Q9. How do you tell from `ls -l` that a file has hard links?**
Look at the second column (link count). A count above 1 on a regular file means other names point to the same inode. `find / -samefile file` or `find / -inum <inode>` lists them.

---

## Task 2 — `adduser` vs `useradd`

### Difference

| | `useradd` | `adduser` |
|---|---|---|
| What it is | Low-level compiled binary from the `shadow`/`passwd` package (on every Linux distro) | Friendly **Perl script** (on Debian/Ubuntu) that calls `useradd` and friends underneath |
| Home directory | **Not created** unless you pass `-m` | Created automatically, `/etc/skel` copied in |
| Default shell | From `/etc/default/useradd` (on Ubuntu: `/bin/sh`) | `/bin/bash` (from `/etc/adduser.conf`) |
| Password | Not set; you run `passwd` yourself | Asks for a password interactively (or `--disabled-password`) |
| User info (GECOS) | Only with `-c` | Asks for Full Name, Room, Phone... (or `--gecos`) |
| Best for | Scripts and portable automation (works the same on RHEL, Alpine, etc.) | Humans creating users by hand on Ubuntu/Debian |

```console
root@ujj-ubuntu:~# file /usr/sbin/adduser /usr/sbin/useradd
/usr/sbin/adduser: Perl script text executable
/usr/sbin/useradd: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, BuildID[sha1]=483f79642f7a936acdeb2cb2fd1c4e70c2f0ef9d, for GNU/Linux 3.7.0, stripped
```

### Which one is preferred on Ubuntu, and why?

**`adduser`** is the recommended tool on Ubuntu/Debian. The `useradd` man page on Debian itself says to use `adduser` instead. One command gives a ready-to-use account: its own group, a home directory with the skeleton dotfiles, `/bin/bash` as the shell, and a UID picked from the correct range. With bare `useradd` it's easy to forget `-m` or `-s` and end up with a broken account (no home, `sh` shell). `useradd` is still the right choice in scripts that must run on any distro.

### Practical — create a user with `adduser` (non-interactive)

`--disabled-password` skips the password prompt and `--gecos` fills in the user-info fields, so no questions are asked:

```console
root@ujj-ubuntu:~# adduser --disabled-password --gecos "Ujjawal Test,,," ujjtest
info: Adding user `ujjtest' ...
info: Selecting UID/GID from range 1000 to 59999 ...
info: Adding new group `ujjtest' (1001) ...
info: Adding new user `ujjtest' (1001) with group `ujjtest (1001)' ...
info: Creating home directory `/home/ujjtest' ...
info: Copying files from `/etc/skel' ...
info: Adding new user `ujjtest' to supplemental / extra groups `users' ...
info: Adding user `ujjtest' to group `users' ...
root@ujj-ubuntu:~# grep ujjtest /etc/passwd
ujjtest:x:1001:1001:Ujjawal Test,,,:/home/ujjtest:/bin/bash
root@ujj-ubuntu:~# id ujjtest
uid=1001(ujjtest) gid=1001(ujjtest) groups=1001(ujjtest),100(users)
root@ujj-ubuntu:~# ls -la /home/ujjtest
total 20
drwxr-x--- 2 ujjtest ujjtest 4096 Oct  6 10:58 .
drwxr-xr-x 1 root    root    4096 Oct  6 10:58 ..
-rw-r--r-- 1 ujjtest ujjtest  220 Oct  6 10:58 .bash_logout
-rw-r--r-- 1 ujjtest ujjtest 3771 Oct  6 10:58 .bashrc
-rw-r--r-- 1 ujjtest ujjtest  807 Oct  6 10:58 .profile
root@ujj-ubuntu:~# grep ujjtest /etc/group
users:x:100:ujjtest
ujjtest:x:1001:
root@ujj-ubuntu:~# passwd -S ujjtest
ujjtest L 2026-10-06 0 99999 7 -1
```

(UID 1000 is already taken by the default `ubuntu` user in the image, so `ujjtest` got 1001. `passwd -S` shows `L`, meaning the password is locked, as expected with `--disabled-password`.)

The `/etc/passwd` fields are `username:x:UID:GID:GECOS:home:shell`. The `x` means the password hash is stored in `/etc/shadow`.

### Same thing with `useradd`, for comparison

```console
root@ujj-ubuntu:~# useradd plainuser
root@ujj-ubuntu:~# grep plainuser /etc/passwd
plainuser:x:1002:1002::/home/plainuser:/bin/sh
root@ujj-ubuntu:~# ls -ld /home/plainuser
ls: cannot access '/home/plainuser': No such file or directory
root@ujj-ubuntu:~# useradd -m -s /bin/bash -c "Plain With Home" plainuser2
root@ujj-ubuntu:~# grep plainuser2 /etc/passwd
plainuser2:x:1003:1003:Plain With Home:/home/plainuser2:/bin/bash
root@ujj-ubuntu:~# ls -la /home/plainuser2
total 20
drwxr-x--- 2 plainuser2 plainuser2 4096 Oct  6 10:58 .
drwxr-xr-x 1 root       root       4096 Oct  6 10:58 ..
-rw-r--r-- 1 plainuser2 plainuser2  220 Mar 31  2024 .bash_logout
-rw-r--r-- 1 plainuser2 plainuser2 3771 Mar 31  2024 .bashrc
-rw-r--r-- 1 plainuser2 plainuser2  807 Mar 31  2024 .profile
```

Plain `useradd` gave `plainuser` **no home directory** and the `/bin/sh` shell. To get the same result as `adduser` you need `-m -s /bin/bash -c ...`.

---

## Task 3 — `journalctl`

### What is it?

On systemd-based distros (Ubuntu 16.04 and later), **systemd-journald** collects logs from the kernel, from every systemd service (their stdout/stderr), and from syslog calls. It stores them in a structured binary journal under `/run/log/journal` or `/var/log/journal`. **`journalctl`** is the command for reading and filtering that journal. Every entry has fields such as `_SYSTEMD_UNIT`, `PRIORITY`, `_PID` and `_HOSTNAME`, so you can filter by service, by time and by severity without needing `grep`.

Before practising, I generated some log activity in the systemd container:

```bash
systemctl restart cron
systemctl start ssh
echo "* * * * * root echo hello-from-cron-24BCS10267 >> /tmp/cronlog" > /etc/cron.d/ujjdemo   # a job every minute
logger -p user.err "24BCS10267 demo: this is a test ERROR message"                          # an error-level entry
logger -t ujjapp "24BCS10267 demo: info message from ujjapp"
# a service that always fails, to have something to debug
printf "[Unit]\nDescription=Demo service that always fails\n[Service]\nExecStart=/bin/false\n" > /etc/systemd/system/faildemo.service
systemctl daemon-reload && systemctl start faildemo
```

### System logs

```console
root@ujj-systemd:/# journalctl --no-pager | head -12
Oct 06 11:02:23 ujj-systemd kernel: Booting Linux on physical CPU 0x0000000000 [0x610f0000]
Oct 06 11:02:23 ujj-systemd kernel: Linux version 7.0.12-linuxkit (root@buildkitsandbox) (gcc (Alpine 15.2.0) 15.2.0, GNU ld (GNU Binutils) 2.45.1) #1 SMP PREEMPT Wed Aug 12 20:18:49 UTC 2026 ()
Oct 06 11:02:23 ujj-systemd kernel: OF: reserved mem: Reserved memory: No reserved-memory node in the DT
Oct 06 11:02:23 ujj-systemd kernel: psci: probing for conduit method from DT.
Oct 06 11:02:23 ujj-systemd kernel: psci: PSCIv1.1 detected in firmware.
Oct 06 11:02:23 ujj-systemd kernel: psci: Using standard PSCI v0.2 function IDs
Oct 06 11:02:23 ujj-systemd kernel: psci: Trusted OS migration not required
Oct 06 11:02:23 ujj-systemd kernel: psci: SMC Calling Convention v1.1
Oct 06 11:02:23 ujj-systemd kernel: Zone ranges:
Oct 06 11:02:23 ujj-systemd kernel:   DMA      [mem 0x0000000070000000-0x00000000ffffffff]
Oct 06 11:02:23 ujj-systemd kernel:   DMA32    empty
Oct 06 11:02:23 ujj-systemd kernel:   Normal   [mem 0x0000000100000000-0x000000026fffffff]
```

`journalctl` with no options shows everything, oldest first. In a terminal it opens in a pager; `--no-pager` prints straight to stdout. (The kernel lines come from Docker Desktop's Linux VM, since containers share the host kernel.)

```console
root@ujj-systemd:/# journalctl --no-pager -n 8
Oct 06 11:03:02 ujj-systemd kernel: docker0: port 10(veth1dc5999) entered blocking state
Oct 06 11:03:02 ujj-systemd kernel: docker0: port 10(veth1dc5999) entered forwarding state
Oct 06 11:03:03 ujj-systemd kernel: docker0: port 10(veth1dc5999) entered disabled state
Oct 06 11:03:03 ujj-systemd kernel: vethe8dd51b: renamed from eth0
Oct 06 11:03:03 ujj-systemd kernel: docker0: port 10(veth1dc5999) entered disabled state
Oct 06 11:03:03 ujj-systemd kernel: veth1dc5999 (unregistering): left allmulticast mode
Oct 06 11:03:03 ujj-systemd kernel: veth1dc5999 (unregistering): left promiscuous mode
Oct 06 11:03:03 ujj-systemd kernel: docker0: port 10(veth1dc5999) entered disabled state

root@ujj-systemd:/# journalctl --list-boots --no-pager
IDX BOOT ID                          FIRST ENTRY                 LAST ENTRY
  0 03e48b6c7e46415c9b2218b1e960b324 Tue 2026-10-06 11:02:23 UTC Tue 2026-10-06 11:03:03 UTC

root@ujj-systemd:/# journalctl --disk-usage
Archived and active journals take up 8.0M in the file system.
```

`-n 8` shows the last 8 lines, `--list-boots` lists recorded boots (`-b` alone means "current boot", `-b -1` the previous one), and `--disk-usage` shows how much space the journal takes up.

### Service logs with `-u` (practised on `cron` and `ssh`)

```console
root@ujj-systemd:/# journalctl -u ssh --no-pager
Oct 06 11:02:48 ujj-systemd systemd[1]: Starting ssh.service - OpenBSD Secure Shell server...
Oct 06 11:02:48 ujj-systemd sshd[117]: Server listening on 0.0.0.0 port 22.
Oct 06 11:02:48 ujj-systemd sshd[117]: Server listening on :: port 22.
Oct 06 11:02:48 ujj-systemd systemd[1]: Started ssh.service - OpenBSD Secure Shell server.
```

Next I made a failed SSH login on purpose and checked the ssh log for it, which is what you do when looking into a brute-force attempt:

```console
root@ujj-systemd:/# ssh -o BatchMode=yes -o StrictHostKeyChecking=no hacker@localhost true
Warning: Permanently added 'localhost' (ED25519) to the list of known hosts.
hacker@localhost: Permission denied (publickey,password).

root@ujj-systemd:/# journalctl -u ssh --since "2 minutes ago" --no-pager
Oct 06 11:02:48 ujj-systemd systemd[1]: Starting ssh.service - OpenBSD Secure Shell server...
Oct 06 11:02:48 ujj-systemd sshd[117]: Server listening on 0.0.0.0 port 22.
Oct 06 11:02:48 ujj-systemd sshd[117]: Server listening on :: port 22.
Oct 06 11:02:48 ujj-systemd systemd[1]: Started ssh.service - OpenBSD Secure Shell server.
Oct 06 11:04:37 ujj-systemd sshd[192]: Invalid user hacker from ::1 port 58642

root@ujj-systemd:/# journalctl -u ssh -u cron -n 4 --no-pager -r
Oct 06 11:04:37 ujj-systemd sshd[192]: Connection closed by invalid user hacker ::1 port 58642 [preauth]
Oct 06 11:04:37 ujj-systemd sshd[192]: Invalid user hacker from ::1 port 58642
Oct 06 11:04:01 ujj-systemd CRON[168]: pam_unix(cron:session): session closed for user root
Oct 06 11:04:01 ujj-systemd CRON[169]: (root) CMD (echo hello-from-cron-24BCS10267 >> /tmp/cronlog)
```

You can repeat `-u` to combine units, and `-r` shows the newest entries first.

Debugging a failed service, with `-u` alongside `systemctl status`:

```console
root@ujj-systemd:/# journalctl -u faildemo --no-pager
Oct 06 11:02:48 ujj-systemd systemd[1]: Started faildemo.service - Demo service that always fails.
Oct 06 11:02:48 ujj-systemd systemd[1]: faildemo.service: Main process exited, code=exited, status=1/FAILURE
Oct 06 11:02:48 ujj-systemd systemd[1]: faildemo.service: Failed with result 'exit-code'.

root@ujj-systemd:/# systemctl status faildemo --no-pager
× faildemo.service - Demo service that always fails
     Loaded: loaded (/etc/systemd/system/faildemo.service; static)
     Active: failed (Result: exit-code) since Tue 2026-10-06 11:02:48 UTC; 19s ago
   Duration: 1ms
    Process: 141 ExecStart=/bin/false (code=exited, status=1/FAILURE)
   Main PID: 141 (code=exited, status=1/FAILURE)
        CPU: 455us

Oct 06 11:02:48 ujj-systemd systemd[1]: Started faildemo.service - Demo service that always fails.
Oct 06 11:02:48 ujj-systemd systemd[1]: faildemo.service: Main process exited, code=exited, status=1/FAILURE
Oct 06 11:02:48 ujj-systemd systemd[1]: faildemo.service: Failed with result 'exit-code'.
```

### Live follow with `-f`

`-f` works like `tail -f`: it prints the latest lines and then waits for new ones. I wrapped it in `timeout 70` so it would stop by itself. During those 70 seconds the cron job fired once (at 11:04:01), and the new lines showed up live:

```console
$ docker exec ujj-systemd timeout 70 journalctl -u cron -f --no-pager; echo "(timeout stopped -f, exit=$?)"
Oct 06 11:02:48 ujj-systemd systemd[1]: Stopping cron.service - Regular background program processing daemon...
Oct 06 11:02:48 ujj-systemd systemd[1]: cron.service: Deactivated successfully.
Oct 06 11:02:48 ujj-systemd systemd[1]: Stopped cron.service - Regular background program processing daemon.
Oct 06 11:02:48 ujj-systemd systemd[1]: Started cron.service - Regular background program processing daemon.
Oct 06 11:02:48 ujj-systemd (cron)[113]: cron.service: Referenced but unset environment variable evaluates to an empty string: EXTRA_OPTS
Oct 06 11:02:48 ujj-systemd cron[113]: (CRON) INFO (pidfile fd = 3)
Oct 06 11:02:48 ujj-systemd cron[113]: (CRON) INFO (Skipping @reboot jobs -- not system startup)
Oct 06 11:03:01 ujj-systemd CRON[143]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)
Oct 06 11:03:01 ujj-systemd CRON[144]: (root) CMD (echo hello-from-cron-24BCS10267 >> /tmp/cronlog)
Oct 06 11:03:01 ujj-systemd CRON[143]: pam_unix(cron:session): session closed for user root
Oct 06 11:04:01 ujj-systemd CRON[168]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)
Oct 06 11:04:01 ujj-systemd CRON[169]: (root) CMD (echo hello-from-cron-24BCS10267 >> /tmp/cronlog)
Oct 06 11:04:01 ujj-systemd CRON[168]: pam_unix(cron:session): session closed for user root
(timeout stopped -f, exit=124)
```

The cron job really ran:

```console
root@ujj-systemd:/# cat /tmp/cronlog
hello-from-cron-24BCS10267
hello-from-cron-24BCS10267
```

### Time filters with `--since` / `--until`

```console
root@ujj-systemd:/# journalctl -u cron --since "5 minutes ago" --no-pager | tail -6
Oct 06 11:03:01 ujj-systemd CRON[143]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)
Oct 06 11:03:01 ujj-systemd CRON[144]: (root) CMD (echo hello-from-cron-24BCS10267 >> /tmp/cronlog)
Oct 06 11:03:01 ujj-systemd CRON[143]: pam_unix(cron:session): session closed for user root
Oct 06 11:04:01 ujj-systemd CRON[168]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)
Oct 06 11:04:01 ujj-systemd CRON[169]: (root) CMD (echo hello-from-cron-24BCS10267 >> /tmp/cronlog)
Oct 06 11:04:01 ujj-systemd CRON[168]: pam_unix(cron:session): session closed for user root

root@ujj-systemd:/# journalctl -u cron --since "11:03:30" --until "11:05:00" --no-pager
Oct 06 11:04:01 ujj-systemd CRON[168]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)
Oct 06 11:04:01 ujj-systemd CRON[169]: (root) CMD (echo hello-from-cron-24BCS10267 >> /tmp/cronlog)
Oct 06 11:04:01 ujj-systemd CRON[168]: pam_unix(cron:session): session closed for user root
```

`--since`/`--until` take absolute times (`"2026-10-06 11:00"`, `"11:03:30"`) or relative ones (`"5 minutes ago"`, `today`, `yesterday`).

### Priority filter with `-p`

Priorities: 0 emerg, 1 alert, 2 crit, **3 err**, 4 warning, 5 notice, 6 info, 7 debug. `-p err` shows level 3 **and anything more severe**.

```console
root@ujj-systemd:/# journalctl -p err --no-pager
Oct 06 11:02:48 ujj-systemd root[118]: 24BCS10267 demo: this is a test ERROR message

root@ujj-systemd:/# journalctl -p warning --since today --no-pager | grep -v kernel | head
Oct 06 11:02:23 ujj-systemd (cron)[82]: cron.service: Referenced but unset environment variable evaluates to an empty string: EXTRA_OPTS
Oct 06 11:02:48 ujj-systemd (cron)[113]: cron.service: Referenced but unset environment variable evaluates to an empty string: EXTRA_OPTS
Oct 06 11:02:48 ujj-systemd root[118]: 24BCS10267 demo: this is a test ERROR message
Oct 06 11:02:48 ujj-systemd systemd[1]: faildemo.service: Failed with result 'exit-code'.
```

### Other useful options

```console
root@ujj-systemd:/# journalctl -t ujjapp --no-pager
Oct 06 11:02:48 ujj-systemd ujjapp[119]: 24BCS10267 demo: info message from ujjapp

root@ujj-systemd:/# journalctl -u cron -n 3 -o short-iso --no-pager
2026-10-06T11:04:01+00:00 ujj-systemd CRON[168]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)
2026-10-06T11:04:01+00:00 ujj-systemd CRON[169]: (root) CMD (echo hello-from-cron-24BCS10267 >> /tmp/cronlog)
2026-10-06T11:04:01+00:00 ujj-systemd CRON[168]: pam_unix(cron:session): session closed for user root

root@ujj-systemd:/# journalctl -u cron -n 1 -o json-pretty --no-pager
{
	"_SYSTEMD_SLICE" : "system.slice",
	"SYSLOG_FACILITY" : "10",
	"SYSLOG_PID" : "168",
	"PRIORITY" : "6",
	...
	"_COMM" : "cron",
	"_SYSTEMD_UNIT" : "cron.service",
	"SYSLOG_IDENTIFIER" : "CRON",
	"MESSAGE" : "pam_unix(cron:session): session closed for user root",
	"_HOSTNAME" : "ujj-systemd",
	...
}
```

The JSON output shows that journal entries are structured key/value records, which is why filters like `-u` (`_SYSTEMD_UNIT`) and `-p` (`PRIORITY`) work.

### Quick reference

| Command | Purpose |
|---|---|
| `journalctl` | All logs, oldest first |
| `journalctl -n 50` / `-r` | Last 50 lines / newest first |
| `journalctl -b` / `-b -1` | Current boot / previous boot |
| `journalctl -k` | Kernel messages only (like `dmesg`) |
| `journalctl -u nginx` | Logs of one service |
| `journalctl -f` / `-u ssh -f` | Follow live |
| `journalctl --since "1 hour ago" --until now` | Time window |
| `journalctl -p err -b` | Errors (and worse) this boot |
| `journalctl -t TAG` | By syslog identifier |
| `journalctl -o json-pretty` / `short-iso` | Output formats |
| `journalctl --disk-usage` / `--vacuum-time=7d` | Check / shrink journal size |

---

## Task 4 — Linux command cheat sheet (practised, real output)

All commands below were run inside `ujj-ubuntu` (Ubuntu 24.04), in `/root/practice` unless shown otherwise.

### Files and directories

```console
root@ujj-ubuntu:~# pwd                                   # print current directory
/root
root@ujj-ubuntu:~# mkdir -p practice/logs                # make dir (and parents)
root@ujj-ubuntu:~# cd practice                           # change directory
root@ujj-ubuntu:~/practice# touch notes.txt              # create empty file / update timestamp
root@ujj-ubuntu:~/practice# printf "apple 3\nbanana 1\ncherry 7\napple 2\ndate 5\n" > fruits.txt
root@ujj-ubuntu:~/practice# ls -l                        # long listing
total 8
-rw-r--r-- 1 root root   41 Oct  6 11:04 fruits.txt
drwxr-xr-x 2 root root 4096 Oct  6 11:04 logs
-rw-r--r-- 1 root root    0 Oct  6 11:04 notes.txt
root@ujj-ubuntu:~/practice# ls -la                       # include hidden entries
total 16
drwxr-xr-x 3 root root 4096 Oct  6 11:04 .
drwx------ 1 root root 4096 Oct  6 11:04 ..
-rw-r--r-- 1 root root   41 Oct  6 11:04 fruits.txt
drwxr-xr-x 2 root root 4096 Oct  6 11:04 logs
-rw-r--r-- 1 root root    0 Oct  6 11:04 notes.txt
root@ujj-ubuntu:~/practice# cp fruits.txt fruits.bak     # copy
root@ujj-ubuntu:~/practice# mv fruits.bak logs/          # move / rename
root@ujj-ubuntu:~/practice# ls -R                        # recursive listing
.:
fruits.txt
logs
notes.txt

./logs:
fruits.bak
root@ujj-ubuntu:~/practice# rm logs/fruits.bak           # remove file
root@ujj-ubuntu:~/practice# rmdir logs                   # remove empty directory
root@ujj-ubuntu:~/practice# cat fruits.txt               # print file
apple 3
banana 1
cherry 7
apple 2
date 5
root@ujj-ubuntu:~/practice# head -n 2 fruits.txt         # first N lines
apple 3
banana 1
root@ujj-ubuntu:~/practice# tail -n 1 fruits.txt         # last N lines (tail -f to follow)
date 5
root@ujj-ubuntu:~/practice# echo "line one" > notes.txt  # > overwrite
root@ujj-ubuntu:~/practice# echo "line two" >> notes.txt # >> append
root@ujj-ubuntu:~/practice# cat notes.txt
line one
line two
root@ujj-ubuntu:~/practice# tree /root/practice          # directory tree
/root/practice
|-- fruits.txt
`-- notes.txt

1 directory, 2 files
root@ujj-ubuntu:~/practice# find /root -name "*.txt"     # search files by name
/root/practice/fruits.txt
/root/practice/notes.txt
root@ujj-ubuntu:~/practice# stat fruits.txt              # full metadata incl. inode
  File: fruits.txt
  Size: 41        	Blocks: 8          IO Block: 4096   regular file
Device: 0,397	Inode: 406757      Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2026-10-06 11:04:50.386861012 +0000
Modify: 2026-10-06 11:04:50.381710220 +0000
Change: 2026-10-06 11:04:50.381710220 +0000
 Birth: 2026-10-06 11:04:50.381710220 +0000
```

Archiving (run later, after `hello.sh` was created in the next section):

```console
root@ujj-ubuntu:~/practice# tar -czf practice.tar.gz fruits.txt notes.txt hello.sh && tar -tzf practice.tar.gz   # archive + list
fruits.txt
notes.txt
hello.sh
```

### Permissions and users

Permission bits: `r=4, w=2, x=1` for **u**ser / **g**roup / **o**thers. `640` = `rw-r-----`.

```console
root@ujj-ubuntu:~/practice# printf "#!/bin/bash\necho hi from script\n" > hello.sh
root@ujj-ubuntu:~/practice# ls -l hello.sh
-rw-r--r-- 1 root root 32 Oct  6 11:04 hello.sh
root@ujj-ubuntu:~/practice# ./hello.sh
/usr/local/bin/run.sh: line 5: ./hello.sh: Permission denied
root@ujj-ubuntu:~/practice# chmod +x hello.sh                # add execute bit
root@ujj-ubuntu:~/practice# ls -l hello.sh
-rwxr-xr-x 1 root root 32 Oct  6 11:04 hello.sh
root@ujj-ubuntu:~/practice# ./hello.sh
hi from script
root@ujj-ubuntu:~/practice# chmod 640 notes.txt              # numeric mode
root@ujj-ubuntu:~/practice# ls -l notes.txt
-rw-r----- 1 root root 18 Oct  6 11:04 notes.txt
root@ujj-ubuntu:~/practice# chmod u=rwx,g=rx,o= hello.sh     # symbolic mode
root@ujj-ubuntu:~/practice# ls -l hello.sh
-rwxr-x--- 1 root root 32 Oct  6 11:04 hello.sh
root@ujj-ubuntu:~/practice# chown ujjtest:ujjtest notes.txt  # change owner:group
root@ujj-ubuntu:~/practice# ls -l notes.txt
-rw-r----- 1 ujjtest ujjtest 18 Oct  6 11:04 notes.txt
root@ujj-ubuntu:~/practice# umask                            # default permission mask
0022
root@ujj-ubuntu:~/practice# whoami                           # current user
root
root@ujj-ubuntu:~/practice# id                               # uid, gid, groups
uid=0(root) gid=0(root) groups=0(root)
```

(The `Permission denied` message is prefixed with `/usr/local/bin/run.sh: line 5:` because the commands ran through my helper script. In a normal interactive shell the prefix would be `bash:`.)

### Text processing

```console
root@ujj-ubuntu:~/practice# grep apple fruits.txt            # lines matching a pattern
apple 3
apple 2
root@ujj-ubuntu:~/practice# grep -c apple fruits.txt         # count matches
2
root@ujj-ubuntu:~/practice# grep -v apple fruits.txt         # invert match
banana 1
cherry 7
date 5
root@ujj-ubuntu:~/practice# grep -i APPLE fruits.txt         # case-insensitive
apple 3
apple 2
root@ujj-ubuntu:~/practice# sort fruits.txt                  # sort alphabetically
apple 2
apple 3
banana 1
cherry 7
date 5
root@ujj-ubuntu:~/practice# sort -k2 -n fruits.txt           # numeric sort on column 2
banana 1
apple 2
apple 3
date 5
cherry 7
root@ujj-ubuntu:~/practice# cut -d" " -f1 fruits.txt | sort | uniq -c   # count unique values
      2 apple
      1 banana
      1 cherry
      1 date
root@ujj-ubuntu:~/practice# awk '{sum += $2} END {print "total =", sum}' fruits.txt   # column maths
total = 18
root@ujj-ubuntu:~/practice# sed "s/apple/APPLE/g" fruits.txt # find & replace (stream)
APPLE 3
banana 1
cherry 7
APPLE 2
date 5
root@ujj-ubuntu:~/practice# wc -l fruits.txt                 # line count
5 fruits.txt
root@ujj-ubuntu:~/practice# wc fruits.txt                    # lines, words, bytes
 5 10 41 fruits.txt
root@ujj-ubuntu:~/practice# tr "a-z" "A-Z" < fruits.txt      # translate characters
APPLE 3
BANANA 1
CHERRY 7
APPLE 2
DATE 5
root@ujj-ubuntu:~/practice# cat fruits.txt | grep a | sort -r   # pipes chain commands
date 5
banana 1
apple 3
apple 2
```

### Processes

```console
root@ujj-ubuntu:~/practice# sleep 300 &                      # run in background
root@ujj-ubuntu:~/practice# jobs                             # background jobs of this shell
[1]+  Running                 sleep 300 &
root@ujj-ubuntu:~/practice# ps -ef                           # all processes, full format
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 10:56 ?        00:00:00 sleep infinity
root        4837       0  0 11:05 ?        00:00:00 bash /usr/local/bin/run.sh ... (my helper runner, args trimmed)
root        4843    4837  0 11:05 ?        00:00:00 sleep 300
root        4844    4837  0 11:05 ?        00:00:00 ps -ef
root@ujj-ubuntu:~/practice# pgrep -af "sleep 300"            # find PID by name
4837 bash /usr/local/bin/run.sh ... (helper runner, its args contain the text "sleep 300")
4843 sleep 300
root@ujj-ubuntu:~/practice# kill %1                          # send SIGTERM (by job id or PID)
root@ujj-ubuntu:~/practice# sleep 0.2; pgrep -af "sleep 300" || echo "sleep 300 is gone"
4837 bash /usr/local/bin/run.sh ... (helper runner only — PID 4843 is gone)
```

In an earlier run:

```console
root@ujj-ubuntu:~/practice# ps aux | head -8                 # all processes with CPU/MEM
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0   2280  1124 ?        Ss   10:56   0:00 sleep infinity
root        4805  0.0  0.0   4044  3036 ?        Ss   11:05   0:00 bash /usr/local/bin/run.sh ... (args trimmed)
root        4813  0.0  0.0   2280  1284 ?        S    11:05   0:00 sleep 300
root        4815  0.0  0.0   7640  3628 ?        R    11:05   0:00 ps aux
root        4816  0.0  0.0   2292  1232 ?        S    11:05   0:00 head -8
root@ujj-ubuntu:~/practice# top -b -n 1 | head -12           # live process monitor (batch mode, 1 iteration)
top - 11:05:04 up 19 min,  0 user,  load average: 3.11, 2.52, 1.37
Tasks:   5 total,   1 running,   4 sleeping,   0 stopped,   0 zombie
%Cpu(s):  2.8 us, 10.4 sy,  0.0 ni, 80.2 id,  0.0 wa,  0.0 hi,  6.6 si,  0.0 st 
MiB Mem :   7934.1 total,    368.8 free,   4653.9 used,   3136.3 buff/cache     
MiB Swap:   1024.0 total,    760.4 free,    263.6 used.   3280.2 avail Mem 

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
      1 root      20   0    2280   1124   1120 S   0.0   0.0   0:00.00 sleep
   4805 root      20   0    4044   3036   2772 S   0.0   0.0   0:00.00 bash
   4813 root      20   0    2280   1284   1204 S   0.0   0.0   0:00.00 sleep
   4818 root      20   0    8500   4656   2680 R   0.0   0.1   0:00.00 top
   4819 root      20   0    2292   1228   1144 S   0.0   0.0   0:00.00 head
```

Other process commands: `kill -9 PID` (SIGKILL, can't be caught), `pkill name`, `nice`/`renice` (priority), `fg`/`bg`, `htop`.

### System info, memory and disk

```console
root@ujj-ubuntu:~/practice# uptime                           # time up + load average
 11:05:04 up 19 min,  0 user,  load average: 3.11, 2.52, 1.37
root@ujj-ubuntu:~/practice# free -h                          # RAM and swap
               total        used        free      shared  buff/cache   available
Mem:           7.7Gi       4.5Gi       362Mi        26Mi       3.1Gi       3.2Gi
Swap:          1.0Gi       263Mi       760Mi
root@ujj-ubuntu:~/practice# nproc                            # CPU count
10
root@ujj-ubuntu:~/practice# uname -a                         # kernel info
Linux ujj-ubuntu 7.0.12-linuxkit #1 SMP PREEMPT Wed Aug 12 20:18:49 UTC 2026 aarch64 aarch64 aarch64 GNU/Linux
root@ujj-ubuntu:~/practice# cat /etc/os-release | head -4    # distro version
PRETTY_NAME="Ubuntu 24.04.5 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.5 LTS (Noble Numbat)"
root@ujj-ubuntu:~/practice# hostname                         # machine name
ujj-ubuntu
root@ujj-ubuntu:~/practice# df -h                            # free space per filesystem
Filesystem      Size  Used Avail Use% Mounted on
overlay         911G   24G  841G   3% /
tmpfs            64M     0   64M   0% /dev
shm              64M     0   64M   0% /dev/shm
virtiofs0       927G  229G  699G  25% /pdfs
/dev/vda1       911G   24G  841G   3% /etc/hosts
tmpfs           4.0K     0  4.0K   0% /proc/scsi
root@ujj-ubuntu:~/practice# du -sh /root/practice /usr/share/doc   # size of directories
20K	/root/practice
6.3M	/usr/share/doc
root@ujj-ubuntu:~/practice# du -h --max-depth=1 /var | sort -h      # what's using space
4.0K	/var/backups
4.0K	/var/local
4.0K	/var/mail
4.0K	/var/opt
4.0K	/var/tmp
12K	/var/spool
448K	/var/log
1.8M	/var/cache
64M	/var/lib
67M	/var
root@ujj-ubuntu:~/practice# lsblk 2>&1 | head -5             # block devices
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
nbd0    43:0    0     0B  0 disk 
nbd1    43:32   0     0B  0 disk 
nbd2    43:64   0     0B  0 disk 
nbd3    43:96   0     0B  0 disk 
```

### Networking (basics — more in Session 04)

```console
root@ujj-ubuntu:~/practice# ip -br addr                      # interfaces + IPs (brief)
lo               UNKNOWN        127.0.0.1/8 ::1/128 
tunl0@NONE       DOWN           
...
eth0@if22        UP             172.17.0.3/16 
root@ujj-ubuntu:~/practice# ping -c 2 8.8.8.8                # reachability + latency
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=63 time=71.9 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=63 time=637 ms

--- 8.8.8.8 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 71.942/354.266/636.591/282.324 ms
root@ujj-ubuntu:~/practice# curl -sI https://example.com | head -5   # HTTP headers only
HTTP/2 200 
date: Tue, 06 Oct 2026 11:05:25 GMT
content-type: text/html; charset=utf-8
server: cloudflare
last-modified: Sun, 04 Oct 2026 20:44:03 GMT
root@ujj-ubuntu:~/practice# ss -tuln                         # listening TCP/UDP ports (none in this container)
Netid State Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
root@ujj-ubuntu:~/practice# cat /etc/resolv.conf | grep nameserver   # DNS server in use
nameserver 192.168.65.7
```

### Packages (apt)

```console
root@ujj-ubuntu:~/practice# apt list --installed 2>/dev/null | wc -l   # count installed packages
253
root@ujj-ubuntu:~/practice# apt-get install -y -qq tree >/dev/null && echo tree installed   # install
tree installed
root@ujj-ubuntu:~/practice# dpkg -l | grep -E "^ii  (curl|tree) "     # check installed versions
ii  curl                          8.5.0-2ubuntu10.15                arm64        command line tool for transferring data with URL syntax
ii  tree                          2.1.1-2ubuntu3.24.04.2            arm64        displays an indented directory tree, in color
root@ujj-ubuntu:~/practice# apt show tree 2>/dev/null | head -4       # package details
Package: tree
Version: 2.1.1-2ubuntu3.24.04.2
Priority: optional
Section: universe/utils
root@ujj-ubuntu:~/practice# which curl                                # where a command lives
/usr/bin/curl
```

Others: `apt update` (refresh package lists), `apt upgrade`, `apt remove pkg`, `apt purge pkg`, `apt search word`.

### Environment and help

```console
root@ujj-ubuntu:~/practice# echo $PATH                       # where the shell looks for commands
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
root@ujj-ubuntu:~/practice# export MY_VAR=devops; echo $MY_VAR   # set env variable
devops
root@ujj-ubuntu:~/practice# ls --help | head -3              # built-in help
Usage: ls [OPTION]... [FILE]...
List information about the FILEs (the current directory by default).
Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.
```

(`man ls` doesn't work in the `ubuntu` Docker image because it is "minimized" with man pages removed. On a normal Ubuntu install `man` works, and `unminimize` restores the pages.)

## Cleanup

After finishing I removed both containers (`docker rm -f ujj-ubuntu ujj-systemd`).
