> **Submission for `session2-linux`** — Kartikey, Enrollment No. **10121** ([@Json604](https://github.com/Json604)).
>
> Every command shown was actually executed and the output is copied in verbatim.
> Full working code, scripts and raw transcripts: <https://github.com/Json604/devops-assignments/tree/main/assignment-01-linux-basics>

# Assignment 1 — Linux Basics

**Session:** `session2-linux` · **Author:** Json604

Covers four tasks: soft vs hard links, `adduser` vs `useradd`, `journalctl`, and the Linux command cheat sheet.

## How this was run

The exercises need a real Linux system — `useradd`, `adduser` and `journalctl` do not exist on macOS, and
`journalctl` additionally needs systemd **running** as PID 1. A plain `docker run ubuntu` does not give you
that, so I built an Ubuntu 24.04 image that boots systemd properly ([`evidence/Dockerfile.ubuntu-systemd`](https://github.com/Json604/devops-assignments/blob/main/assignment-01-linux-basics/evidence/Dockerfile.ubuntu-systemd)):

```bash
docker build -t devops-linux:24.04 .
docker run -d --name devops-linux --privileged --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw devops-linux:24.04
```

Verified before starting, so the `journalctl` output below is a genuine journal and not a mock:

```console
$ docker exec devops-linux systemctl is-system-running
running
$ docker exec devops-linux systemctl is-active systemd-journald
active
```

Every transcript in this file is copied verbatim from a real run. The scripts that produced them and their raw
output are in [`evidence/`](https://github.com/Json604/devops-assignments/tree/main/assignment-01-linux-basics/evidence/).

---

# Task 1 — Soft Link & Hard Link

## The one-sentence difference

A **hard link** is another *name* for the same data. A **soft link** is a small separate file that merely
*stores a path* to another name.

Everything else follows from that. On Linux a file's data and metadata live in an **inode**; a directory entry
is just a `name -> inode` mapping. A hard link adds a second name pointing at the *same inode*, so both names
are equal — neither is "the original". A soft link (symlink) gets its *own, different* inode, and its contents
are simply the text of the target path, which the kernel follows at access time.

## Comparison

| | Soft link (symbolic) | Hard link |
|---|---|---|
| Create with | `ln -s target linkname` | `ln target linkname` |
| Inode | **Different** inode from the target | **Same** inode as the target |
| Link count (`ls -l` col. 2) | target stays `1` | increments: `1` -> `2` |
| Delete the original | link **breaks** (dangling) | data **survives**, count drops |
| Across filesystems | **Allowed** | **Refused** (`Invalid cross-device link`) |
| To a directory | **Allowed** | **Refused** |
| Size | size of the stored path string | same size as the file |
| Shown by `ls -l` | `link -> target`, type `l` | indistinguishable from a normal file, type `-` |
| Analogy | a shortcut / a signpost | a second front door to the same room |

## The commands

```bash
ln -s original.txt softlink.txt   # soft / symbolic link
ln    original.txt hardlink.txt   # hard link

ls -li                            # -i shows the inode number (first column)
stat original.txt                 # shows Inode and Links count
readlink softlink.txt             # print what a symlink points at
find . -xtype l                   # list broken (dangling) symlinks

rm softlink.txt                   # delete a link - never touches the target's data
unlink softlink.txt               # same thing, one link only
```

## Full transcript

Creating both link types, editing through them, deleting the original, proving the cross-filesystem and
directory restrictions, and finally deleting the links.

```console
########## 1. CREATE THE ORIGINAL FILE ##########
$ echo "Hello from the original file" > original.txt

$ ls -li original.txt
571699 -rw-r--r-- 1 root root 29 Sep  2 19:33 original.txt

$ stat original.txt
  File: original.txt
  Size: 29        	Blocks: 8          IO Block: 4096   regular file
Device: 0,98	Inode: 571699      Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2026-09-02 19:33:58.263205012 +0000
Modify: 2026-09-02 19:33:58.263205012 +0000
Change: 2026-09-02 19:33:58.263205012 +0000
 Birth: 2026-09-02 19:33:58.263205012 +0000

########## 2. CREATE A SOFT LINK (symbolic link) ##########
$ ln -s original.txt softlink.txt

########## 3. CREATE A HARD LINK ##########
$ ln original.txt hardlink.txt

########## 4. COMPARE THEM (note the inode column, first field) ##########
$ ls -li
total 8
571699 -rw-r--r-- 2 root root 29 Sep  2 19:33 hardlink.txt
571699 -rw-r--r-- 2 root root 29 Sep  2 19:33 original.txt
571700 lrwxrwxrwx 1 root root 12 Sep  2 19:33 softlink.txt -> original.txt

$ stat -c "%n -> inode=%i links=%h size=%s type=%F" original.txt hardlink.txt softlink.txt
original.txt -> inode=571699 links=2 size=29 type=regular file
hardlink.txt -> inode=571699 links=2 size=29 type=regular file
softlink.txt -> inode=571700 links=1 size=12 type=symbolic link

########## 5. READ THROUGH BOTH LINKS ##########
$ cat original.txt
Hello from the original file

$ cat softlink.txt
Hello from the original file

$ cat hardlink.txt
Hello from the original file

########## 6. EDIT THE ORIGINAL - both links see the change ##########
$ echo "A second line was appended" >> original.txt

$ cat softlink.txt
Hello from the original file
A second line was appended

$ cat hardlink.txt
Hello from the original file
A second line was appended

########## 7. EDIT THROUGH THE HARD LINK - original sees the change ##########
$ echo "Written via the hard link" >> hardlink.txt

$ cat original.txt
Hello from the original file
A second line was appended
Written via the hard link

########## 8. THE DECIDING TEST: DELETE THE ORIGINAL ##########
$ rm original.txt

$ ls -li
total 4
571699 -rw-r--r-- 1 root root 82 Sep  2 19:33 hardlink.txt
571700 lrwxrwxrwx 1 root root 12 Sep  2 19:33 softlink.txt -> original.txt

--- soft link is now DANGLING (target gone) ---
$ cat softlink.txt
cat: softlink.txt: No such file or directory

$ readlink softlink.txt
original.txt

--- hard link still holds the data (link count dropped 2 -> 1) ---
$ cat hardlink.txt
Hello from the original file
A second line was appended
Written via the hard link

$ stat -c "%n inode=%i links=%h" hardlink.txt
hardlink.txt inode=571699 links=1

########## 9. FIND BROKEN SYMLINKS ##########
$ find . -xtype l
./softlink.txt

########## 10. RESTORE: recreating the name repairs the soft link ##########
$ ln hardlink.txt original.txt

$ cat softlink.txt
Hello from the original file
A second line was appended
Written via the hard link

########## 11. WHAT SOFT LINKS CAN DO THAT HARD LINKS CANNOT ##########
--- (a) soft link to a DIRECTORY: allowed ---
$ ln -s /etc etc-softlink

$ ls -ld etc-softlink
lrwxrwxrwx 1 root root 4 Sep  2 19:33 etc-softlink -> /etc

--- (b) hard link to a DIRECTORY: refused ---
$ ln /etc etc-hardlink
ln: /etc: hard link not allowed for directory

--- (c) hard link across filesystems: refused (EXDEV) ---
$ df -h /root /dev/shm | tail -3
Filesystem      Size  Used Avail Use% Mounted on
overlay         453G   25G  405G   6% /
shm              64M     0   64M   0% /dev/shm

$ ln /root/links-demo/hardlink.txt /dev/shm/cross-fs-link
ln: failed to create hard link '/dev/shm/cross-fs-link' => '/root/links-demo/hardlink.txt': Invalid cross-device link

--- (d) but a SOFT link across filesystems is fine ---
$ ln -s /root/links-demo/hardlink.txt /dev/shm/cross-fs-symlink

$ ls -l /dev/shm/cross-fs-symlink
lrwxrwxrwx 1 root root 29 Sep  2 19:33 /dev/shm/cross-fs-symlink -> /root/links-demo/hardlink.txt

$ cat /dev/shm/cross-fs-symlink
Hello from the original file
A second line was appended
Written via the hard link

########## 12. DELETING LINKS (rm removes the link, never the target) ##########
$ ls -li
total 8
571701 lrwxrwxrwx 1 root root  4 Sep  2 19:33 etc-softlink -> /etc
571699 -rw-r--r-- 2 root root 82 Sep  2 19:33 hardlink.txt
571699 -rw-r--r-- 2 root root 82 Sep  2 19:33 original.txt
571700 lrwxrwxrwx 1 root root 12 Sep  2 19:33 softlink.txt -> original.txt

$ rm softlink.txt

$ ls -li
total 8
571701 lrwxrwxrwx 1 root root  4 Sep  2 19:33 etc-softlink -> /etc
571699 -rw-r--r-- 2 root root 82 Sep  2 19:33 hardlink.txt
571699 -rw-r--r-- 2 root root 82 Sep  2 19:33 original.txt

--- data still intact after deleting the soft link ---
$ cat original.txt
Hello from the original file
A second line was appended
Written via the hard link

$ rm hardlink.txt

$ ls -li
total 4
571701 lrwxrwxrwx 1 root root  4 Sep  2 19:33 etc-softlink -> /etc
571699 -rw-r--r-- 1 root root 82 Sep  2 19:33 original.txt

--- deleting one hard link left the other name alive, link count back to 1 ---
$ cat original.txt
Hello from the original file
A second line was appended
Written via the hard link

$ unlink etc-softlink

$ ls -li
total 4
571699 -rw-r--r-- 1 root root 82 Sep  2 19:33 original.txt

--- only when the LAST hard link is removed is the data freed ---
$ rm original.txt

$ ls -li
total 0

```

## What that output proves, line by line

**Same inode, shared data.** Right after creating both links, `ls -li` showed:

```
571699 -rw-r--r-- 2 root root 29 ... hardlink.txt
571699 -rw-r--r-- 2 root root 29 ... original.txt
571700 lrwxrwxrwx 1 root root 12 ... softlink.txt -> original.txt
```

`original.txt` and `hardlink.txt` share inode **571699** and both show link count **2**. `softlink.txt` has its
own inode **571700**, link count **1**, type `l`, and a size of **12 bytes** — exactly the length of the string
`original.txt`. That size is the clearest proof a symlink stores a *path*, not the data.

**Deleting the original.** After `rm original.txt`:

- `cat softlink.txt` → `No such file or directory`. The symlink object still exists (`ls` still lists it, and
  `readlink` still reports `original.txt`), but the name it points at is gone. This is a *dangling* symlink,
  found with `find . -xtype l`.
- `cat hardlink.txt` still printed all three lines, and the link count fell from `2` to `1`. `rm` only ever
  removes a **name**; the kernel frees the data when the last hard link is gone.

**Repairing a symlink.** `ln hardlink.txt original.txt` recreated the missing *name*, and `cat softlink.txt`
started working again — without touching the symlink itself. A symlink resolves by path at access time, so
restoring the name is enough.

**The two hard-link restrictions**, both demonstrated with the real kernel errors:

```
ln: /etc: hard link not allowed for directory
ln: failed to create hard link '/dev/shm/cross-fs-link' => '...': Invalid cross-device link
```

A hard link is a directory entry pointing to an inode number, and **inode numbers are only unique within one
filesystem** — so a hard link fundamentally cannot cross one. Hard links to directories are refused because
they would let you build cycles in the directory tree, which would break `find`, `du` and every tree walker.
A soft link has neither problem: it stores a path, so it happily pointed from `/dev/shm` into `/root`.

## Interview preparation

**Q: What is the difference between a soft link and a hard link?**
A hard link is a second directory entry pointing to the same inode, so it is an equal name for the same data.
A soft link is a separate file whose content is the path to another file, resolved at access time. Practically:
delete the original and a hard link still works, a soft link breaks.

**Q: Which one survives deleting the original file?**
The hard link. Data is freed only when the inode's link count reaches zero *and* no process holds it open.

**Q: Why can't you hard-link across filesystems?**
Because a hard link is just a `name -> inode number` entry, and inode numbers are only meaningful inside a
single filesystem. Cross-device gives `EXDEV`, `Invalid cross-device link`.

**Q: Why can't you hard-link a directory?**
It would allow cycles in the directory tree and break tree traversal and reference counting. `.` and `..` are
the only directory hard links, and the kernel maintains those itself. (This is why an empty directory has a
link count of 2, and gains one per subdirectory.)

**Q: How do you tell them apart?**
`ls -li` — compare the inode number (column 1) and the link count (column 3 in `-l`). A symlink also shows
type `l` and an `->` arrow.

**Q: How do you find broken symlinks?**
`find /path -xtype l`.

**Q: If a symlink and its target are both deleted, then a new file with the target's name is created, what happens?**
The symlink silently starts pointing at the *new* file. Symlinks resolve by name, not identity — which is
exactly why they are useful (`/usr/bin/python3 -> python3.11` can be repointed by a package upgrade) and also
why they are a security consideration (symlink attacks).

**Q: Where are these actually used in DevOps?**
Symlinks everywhere: `/etc/nginx/sites-enabled/x -> ../sites-available/x`, systemd `.wants/` directories are
symlink farms, `/usr/bin/python3`, and atomic release switching (`current -> releases/2024-06-01`) in
Capistrano-style deploys. Hard links underpin deduplicating backups (rsync `--link-dest`, Time Machine) where
unchanged files across snapshots are one inode with many names.

---

# Task 2 — `adduser` vs `useradd`

## The difference

They are not two versions of the same tool.

- **`useradd`** is the **low-level binary** from the `passwd` (shadow-utils) package. It exists on every Linux
  distribution and does the bare minimum the flags tell it to. Non-interactive by design.
- **`adduser`** is a **high-level Perl wrapper script**, Debian/Ubuntu specific, from the `adduser` package.
  It *calls* `useradd` underneath and adds all the friendly policy: creates the home directory, copies
  `/etc/skel`, creates a matching user group, sets a proper login shell, and prompts for password and user
  details interactively.

Proven, not asserted:

```console
$ file -L /usr/sbin/adduser /usr/sbin/useradd
/usr/sbin/adduser: Perl script text executable
/usr/sbin/useradd: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, BuildID[sha1]=483f79642f7a936acdeb2cb2fd1c4e70c2f0ef9d, for GNU/Linux 3.7.0, stripped
```

`adduser` is a *Perl script text executable*; `useradd` is an *ELF 64-bit executable*. And `dpkg -S` confirms
they ship in different packages:

```console
$ dpkg -S /usr/sbin/adduser /usr/sbin/useradd
adduser: /usr/sbin/adduser
passwd: /usr/sbin/useradd
```

| | `adduser` | `useradd` |
|---|---|---|
| Type | Perl script (high level) | compiled binary (low level) |
| Package | `adduser` | `passwd` / shadow-utils |
| Availability | Debian & Ubuntu family only | **every** Linux distribution |
| Interactive | Yes — prompts for password, full name, etc. | No — silent, flags only |
| Home directory | **Created automatically** | **Not** created unless you pass `-m` |
| `/etc/skel` files copied | Yes | Only with `-m` |
| Default shell | `/bin/bash` | `/bin/sh` (from `/etc/default/useradd`) |
| User's own group | Created automatically | Created, but no extra groups |
| Password | Prompts you to set one | Left locked until you run `passwd` |
| Config file | `/etc/adduser.conf` | `/etc/default/useradd`, `/etc/login.defs` |
| Best for | Humans, at a terminal | Scripts, automation, Dockerfiles, Ansible |

## Which is preferred on Ubuntu/Linux, and why

**On Ubuntu/Debian, `adduser` is the recommended command for creating a user by hand.** The Debian manpage for
`useradd` itself points you to `adduser` as the preferred tool.

The reason is that `adduser` gives you a *complete, usable account in one step* and applies the distribution's
own conventions. Bare `useradd` gives you a half-configured account that is a classic source of bugs: the user
exists but has no home directory, so logging in dumps you somewhere unexpected with no `.bashrc`, and the
shell is `/bin/sh` rather than `bash`. The transcript below demonstrates exactly that failure mode.

The important caveat: **`adduser` is Debian/Ubuntu-only.** On RHEL, CentOS, Alpine or in a portable shell
script, `adduser` may be missing or be a different program entirely, so **`useradd -m` is the right choice for
scripting and for anything that must run across distributions.** So the honest answer to the interview version
of this question is: `adduser` interactively on Ubuntu, `useradd -m -s /bin/bash` in automation.

## Full transcript

```console
########## 1. WHERE DO THEY LIVE AND WHAT ARE THEY? ##########
$ which adduser useradd
/usr/sbin/adduser
/usr/sbin/useradd

$ file -L /usr/sbin/adduser /usr/sbin/useradd
/root/q1-users.sh: line 2: file: command not found

$ dpkg -S /usr/sbin/adduser /usr/sbin/useradd
adduser: /usr/sbin/adduser
passwd: /usr/sbin/useradd

$ head -3 /usr/sbin/adduser
#! /usr/bin/perl

# Copyright (C) 2000-2004 Roland Bauerschmidt <rb@debian.org>

########## 2. BASELINE: users and home dirs before we start ##########
$ ls -l /home
total 4
drwxr-x--- 2 ubuntu ubuntu 4096 Aug 10 14:55 ubuntu

$ tail -3 /etc/passwd
messagebus:x:100:101::/nonexistent:/usr/sbin/nologin
syslog:x:101:102::/nonexistent:/usr/sbin/nologin
systemd-resolve:x:995:995:systemd Resolver:/:/usr/sbin/nologin

########## 3. THE LOW-LEVEL WAY: useradd (no flags) ##########
$ useradd testuser-useradd

$ grep testuser-useradd /etc/passwd
testuser-useradd:x:1001:1001::/home/testuser-useradd:/bin/sh

$ grep testuser-useradd /etc/group
testuser-useradd:x:1001:

--- was a home directory created? ---
$ ls -l /home
total 4
drwxr-x--- 2 ubuntu ubuntu 4096 Aug 10 14:55 ubuntu

$ ls -ld /home/testuser-useradd
ls: cannot access '/home/testuser-useradd': No such file or directory

--- what is the password status? (L = locked, no password set) ---
$ passwd -S testuser-useradd
testuser-useradd L 2026-09-02 0 99999 7 -1

--- the defaults useradd applies, from /etc/default/useradd ---
$ useradd -D
GROUP=100
HOME=/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/sh
SKEL=/etc/skel
CREATE_MAIL_SPOOL=no
LOG_INIT=yes

$ grep -v "^#" /etc/default/useradd | grep -v "^$"
SHELL=/bin/sh

########## 4. THE RECOMMENDED WAY ON UBUNTU/DEBIAN: adduser ##########
--- (--disabled-password --gecos "" only so it runs unattended here;
---  run plain `adduser testuser-adduser` and it prompts interactively) ---
$ adduser --disabled-password --gecos "" testuser-adduser
info: Adding user `testuser-adduser' ...
info: Selecting UID/GID from range 1000 to 59999 ...
info: Adding new group `testuser-adduser' (1002) ...
info: Adding new user `testuser-adduser' (1002) with group `testuser-adduser (1002)' ...
info: Creating home directory `/home/testuser-adduser' ...
info: Copying files from `/etc/skel' ...
info: Adding new user `testuser-adduser' to supplemental / extra groups `users' ...
info: Adding user `testuser-adduser' to group `users' ...

$ grep testuser-adduser /etc/passwd
testuser-adduser:x:1002:1002:,,,:/home/testuser-adduser:/bin/bash

$ grep testuser-adduser /etc/group
users:x:100:testuser-adduser
testuser-adduser:x:1002:

--- home directory WAS created, and populated from /etc/skel ---
$ ls -la /home/testuser-adduser
total 20
drwxr-x--- 2 testuser-adduser testuser-adduser 4096 Sep  2 19:34 .
drwxr-xr-x 1 root             root             4096 Sep  2 19:34 ..
-rw-r--r-- 1 testuser-adduser testuser-adduser  220 Sep  2 19:34 .bash_logout
-rw-r--r-- 1 testuser-adduser testuser-adduser 3771 Sep  2 19:34 .bashrc
-rw-r--r-- 1 testuser-adduser testuser-adduser  807 Sep  2 19:34 .profile

$ ls -A /etc/skel
.bash_logout
.bashrc
.profile

$ id testuser-adduser
uid=1002(testuser-adduser) gid=1002(testuser-adduser) groups=1002(testuser-adduser),100(users)

########## 5. SIDE-BY-SIDE COMPARISON ##########
$ grep -E "testuser-(useradd|adduser)" /etc/passwd
testuser-useradd:x:1001:1001::/home/testuser-useradd:/bin/sh
testuser-adduser:x:1002:1002:,,,:/home/testuser-adduser:/bin/bash

$ ls -l /home
total 8
drwxr-x--- 2 testuser-adduser testuser-adduser 4096 Sep  2 19:34 testuser-adduser
drwxr-x--- 2 ubuntu           ubuntu           4096 Aug 10 14:55 ubuntu

$ passwd -S testuser-useradd; passwd -S testuser-adduser
testuser-useradd L 2026-09-02 0 99999 7 -1
testuser-adduser L 2026-09-02 0 99999 7 -1

########## 6. SETTING A PASSWORD FOR THE TEST USER ##########
$ echo "testuser-adduser:StrongPassw0rd!" | chpasswd

$ passwd -S testuser-adduser
testuser-adduser P 2026-09-02 0 99999 7 -1

--- proof the account now works: run a command as that user ---
$ su - testuser-adduser -c "whoami; pwd; echo HOME=\$HOME; id"
testuser-adduser
/home/testuser-adduser
HOME=/home/testuser-adduser
uid=1002(testuser-adduser) gid=1002(testuser-adduser) groups=1002(testuser-adduser),100(users)

########## 7. MAKING useradd BEHAVE LIKE adduser (the flags you must remember) ##########
$ userdel -r testuser-useradd
userdel: testuser-useradd mail spool (/var/mail/testuser-useradd) not found
userdel: testuser-useradd home directory (/home/testuser-useradd) not found

$ useradd -m -s /bin/bash -c "Test User" testuser-useradd

$ grep testuser-useradd /etc/passwd
testuser-useradd:x:1003:1003:Test User:/home/testuser-useradd:/bin/bash

$ ls -ld /home/testuser-useradd
drwxr-x--- 2 testuser-useradd testuser-useradd 4096 Sep  2 19:34 /home/testuser-useradd

########## 8. CLEANUP ##########
$ userdel -r testuser-useradd
userdel: testuser-useradd mail spool (/var/mail/testuser-useradd) not found

$ ls -l /home
total 8
drwxr-x--- 2 testuser-adduser testuser-adduser 4096 Sep  2 19:34 testuser-adduser
drwxr-x--- 2 ubuntu           ubuntu           4096 Aug 10 14:55 ubuntu

--- keeping testuser-adduser as the deliverable test user ---
$ grep testuser-adduser /etc/passwd
testuser-adduser:x:1002:1002:,,,:/home/testuser-adduser:/bin/bash

```

## What that output proves

**Bare `useradd` leaves a half-built account.** After `useradd testuser-useradd`:

```
testuser-useradd:x:1001:1001::/home/testuser-useradd:/bin/sh
$ ls -ld /home/testuser-useradd
ls: cannot access '/home/testuser-useradd': No such file or directory
```

`/etc/passwd` *claims* the home directory is `/home/testuser-useradd`, but that directory **was never created**.
The shell is `/bin/sh`, not bash. `passwd -S` reports **`L`** — locked, no password, so the account cannot log
in at all. `useradd -D` shows why: `SHELL=/bin/sh` and there is no `CREATE_HOME=yes`.

**`adduser` produced a complete account** in the same single command, and narrated each step:

```
info: Adding new group `testuser-adduser' (1002) ...
info: Creating home directory `/home/testuser-adduser' ...
info: Copying files from `/etc/skel' ...
```

The result has `/bin/bash` as its shell, a home directory owned by the user, and `.bashrc`, `.profile` and
`.bash_logout` copied in from `/etc/skel`.

**The test user works.** After setting a password with `chpasswd`, `passwd -S` flipped from `L` to **`P`**
(usable password) and switching to the account succeeded:

```
$ su - testuser-adduser -c "whoami; pwd; echo HOME=$HOME; id"
testuser-adduser
/home/testuser-adduser
HOME=/home/testuser-adduser
uid=1002(testuser-adduser) gid=1002(testuser-adduser) groups=1002(testuser-adduser),100(users)
```

**Closing the gap.** `useradd -m -s /bin/bash -c "Test User" testuser-useradd` produced an equivalent account —
`-m` makes the home directory and copies `/etc/skel`, `-s` sets the shell. Those are the flags to remember when
you must use `useradd` in a script.

## Test user created (deliverable)

Created with the recommended command for Ubuntu:

```bash
adduser testuser-adduser          # interactive: prompts for password and details
```

```console
$ grep testuser-adduser /etc/passwd
testuser-adduser:x:1002:1002:,,,:/home/testuser-adduser:/bin/bash
$ id testuser-adduser
uid=1002(testuser-adduser) gid=1002(testuser-adduser) groups=1002(testuser-adduser),100(users)
$ passwd -S testuser-adduser
testuser-adduser P 2026-09-02 0 99999 7 -1
```

> The transcript uses `adduser --disabled-password --gecos ""` purely so the script could run unattended, with
> the password set afterwards via `chpasswd`. Interactively you just run `adduser testuser-adduser` and answer
> the prompts.

### Related commands worth knowing

```bash
usermod -aG sudo alice     # add to a group (-a is essential: without it you REPLACE all groups)
userdel -r alice           # delete the user AND their home directory
passwd alice               # set/change password
chage -l alice             # password ageing / expiry policy
id alice ; groups alice    # inspect
getent passwd alice        # look up via NSS (works with LDAP/AD too, unlike grepping /etc/passwd)
```

---

# Task 3 — `journalctl`

## What it is used for

`journalctl` is the query tool for **the systemd journal** — the single, structured, indexed log store that
`systemd-journald` collects on a systemd Linux system. Before systemd, logs were scattered plain-text files in
`/var/log/` (`syslog`, `auth.log`, `messages`, plus whatever each application wrote) and reading them meant
`tail`, `grep` and knowing which file to open.

The journal replaces that with one queryable store, and this is why it matters:

- **It captures everything in one place** — kernel messages, systemd's own unit lifecycle messages, and
  anything a service writes to stdout/stderr. A service does not need any logging configuration to be logged.
- **Entries are structured records, not lines of text.** Every entry carries indexed metadata fields —
  `_PID`, `_UID`, `_SYSTEMD_UNIT`, `PRIORITY`, `_BOOT_ID`, `_HOSTNAME`. That is what makes `journalctl -u nginx`
  an exact index lookup rather than a `grep` that might match the word "nginx" in an unrelated line.
- **It is binary and can be cryptographically verified** (`journalctl --verify`), which matters for audit.
- **Retention is managed for you** — automatic rotation by size/time, no logrotate config per service.

The trade-off: it is a binary format, so you *must* use `journalctl` to read it — `cat` and `grep` cannot.

## The flags that matter

| Command | What it does |
|---|---|
| `journalctl` | Everything, oldest first |
| `journalctl -n 20` | Last 20 entries |
| `journalctl -f` | **Follow** live, like `tail -f` |
| `journalctl -r` | Reverse — newest first |
| `journalctl -u nginx.service` | **One specific service** (the flag you will use most) |
| `journalctl -u nginx -f` | Follow one service live |
| `journalctl -b` | Current boot only |
| `journalctl -b -1` | The *previous* boot — for diagnosing a crash/reboot |
| `journalctl --list-boots` | Every boot the journal still holds |
| `journalctl -k` | Kernel messages only (`dmesg` equivalent) |
| `journalctl -p err` | Priority `err` and worse (`emerg` 0 … `debug` 7) |
| `journalctl --since "10 min ago"` | Time window; `--until` also accepts `"2026-09-02 19:00"`, `"yesterday"` |
| `journalctl -t my-app` | By syslog identifier / tag |
| `journalctl _PID=1234` | By any indexed field |
| `journalctl -xeu nginx` | `-x` explanations, `-e` jump to end, `-u` unit — **the standard "why did it fail" command** |
| `journalctl -o json-pretty` | Structured output for machines; also `short-iso`, `cat`, `verbose` |
| `journalctl --disk-usage` | How much disk the journal is using |
| `journalctl --vacuum-time=7d` | Delete entries older than 7 days |
| `journalctl --verify` | Check journal file integrity |

## Full transcript

```console
########## 0. GENERATE SOME REAL SERVICE ACTIVITY TO READ BACK ##########
$ systemctl start nginx

$ systemctl is-active nginx
active

$ systemctl restart nginx

$ systemctl stop nginx

$ systemctl start nginx

$ logger -t my-demo-app "custom log line written with the logger command"

########## 1. THE WHOLE JOURNAL (oldest first) ##########
$ journalctl --no-pager | head -12
Sep 02 19:33:10 9158f450b5b9 systemd-journald[23]: Journal started
Sep 02 19:33:10 9158f450b5b9 systemd-journald[23]: Runtime Journal (/run/log/journal/98b453ea95114d27bf9974169d356f8c) is 8.0M, max 156.7M, 148.7M free.
Sep 02 19:33:10 9158f450b5b9 systemd-journald[23]: Missed 8703 kernel messages
Sep 02 19:33:10 9158f450b5b9 kernel: docker0: port 2(veth2d8c8a4) entered disabled state
Sep 02 19:33:10 9158f450b5b9 kernel: veth7e98b16: renamed from eth0
Sep 02 19:33:10 9158f450b5b9 kernel: docker0: port 2(veth2d8c8a4) entered disabled state
Sep 02 19:33:10 9158f450b5b9 kernel: veth2d8c8a4 (unregistering): left allmulticast mode
Sep 02 19:33:10 9158f450b5b9 kernel: veth2d8c8a4 (unregistering): left promiscuous mode
Sep 02 19:33:10 9158f450b5b9 kernel: docker0: port 2(veth2d8c8a4) entered disabled state
Sep 02 19:33:10 9158f450b5b9 kernel: docker0: port 2(vethd9c5203) entered blocking state
Sep 02 19:33:10 9158f450b5b9 kernel: docker0: port 2(vethd9c5203) entered disabled state
Sep 02 19:33:10 9158f450b5b9 kernel: vethd9c5203: entered allmulticast mode

########## 2. THE MOST RECENT N ENTRIES ##########
$ journalctl -n 15 --no-pager
Sep 02 19:34:35 9158f450b5b9 systemd[1]: Removed slice user-1002.slice - User Slice of UID 1002.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Reached target network-online.target - Network is Online.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: nginx.service: Deactivated successfully.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: nginx.service: Deactivated successfully.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 my-demo-app[508]: custom log line written with the logger command

########## 3. LOGS FROM THE CURRENT BOOT ONLY ##########
$ journalctl -b --no-pager | head -8
Sep 02 19:33:10 9158f450b5b9 systemd-journald[23]: Journal started
Sep 02 19:33:10 9158f450b5b9 systemd-journald[23]: Runtime Journal (/run/log/journal/98b453ea95114d27bf9974169d356f8c) is 8.0M, max 156.7M, 148.7M free.
Sep 02 19:33:10 9158f450b5b9 systemd-journald[23]: Missed 8703 kernel messages
Sep 02 19:33:10 9158f450b5b9 kernel: docker0: port 2(veth2d8c8a4) entered disabled state
Sep 02 19:33:10 9158f450b5b9 kernel: veth7e98b16: renamed from eth0
Sep 02 19:33:10 9158f450b5b9 kernel: docker0: port 2(veth2d8c8a4) entered disabled state
Sep 02 19:33:10 9158f450b5b9 kernel: veth2d8c8a4 (unregistering): left allmulticast mode
Sep 02 19:33:10 9158f450b5b9 kernel: veth2d8c8a4 (unregistering): left promiscuous mode

$ journalctl --list-boots --no-pager
IDX BOOT ID                          FIRST ENTRY                 LAST ENTRY
  0 339d6e4b286244ab9ee854b5c2cefedb Wed 2026-09-02 19:33:10 UTC Wed 2026-09-02 19:35:23 UTC

########## 4. LOGS FOR ONE SPECIFIC SERVICE  (the key skill) ##########
$ journalctl -u nginx.service --no-pager
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: nginx.service: Deactivated successfully.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: nginx.service: Deactivated successfully.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.

--- last 5 lines for that unit only ---
$ journalctl -u nginx -n 5 --no-pager
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: nginx.service: Deactivated successfully.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.

########## 5. FILTER BY TIME ##########
$ journalctl -u nginx --since "10 minutes ago" --no-pager
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: nginx.service: Deactivated successfully.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: nginx.service: Deactivated successfully.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.

$ journalctl --since "today" --no-pager | tail -5
Sep 02 19:35:23 9158f450b5b9 systemd[1]: nginx.service: Deactivated successfully.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 my-demo-app[508]: custom log line written with the logger command

########## 6. FILTER BY PRIORITY (emerg 0 .. debug 7) ##########
$ journalctl -p err --no-pager | tail -8
-- No entries --

$ journalctl -p warning..err --no-pager | tail -5
Sep 02 19:33:10 9158f450b5b9 systemd-sysctl[34]: Couldn't write '1' to 'kernel/yama/ptrace_scope', ignoring: No such file or directory

########## 7. FIND OUR OWN logger MESSAGE (filter by tag / identifier) ##########
$ journalctl -t my-demo-app --no-pager
Sep 02 19:35:23 9158f450b5b9 my-demo-app[508]: custom log line written with the logger command

########## 8. FOLLOW LIVE  (journalctl -f) - shown with a 4s timeout ##########
$ journalctl -u nginx -f     # Ctrl-C to quit; here bounded by `timeout 4`
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: nginx.service: Deactivated successfully.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: nginx.service: Deactivated successfully.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:23 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:26 9158f450b5b9 systemd[1]: Reloading nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:26 9158f450b5b9 nginx[531]: 2026/09/02 19:35:26 [notice] 531#531: signal process started
Sep 02 19:35:26 9158f450b5b9 systemd[1]: Reloaded nginx.service - A high performance web server and a reverse proxy server.

########## 9. OUTPUT FORMATS ##########
$ journalctl -u nginx -n 2 -o short-iso --no-pager
2026-09-02T19:35:26+00:00 9158f450b5b9 nginx[531]: 2026/09/02 19:35:26 [notice] 531#531: signal process started
2026-09-02T19:35:26+00:00 9158f450b5b9 systemd[1]: Reloaded nginx.service - A high performance web server and a reverse proxy server.

$ journalctl -u nginx -n 1 -o json-pretty --no-pager | head -25
{
	"__SEQNUM" : "4248",
	"_SYSTEMD_CGROUP" : "/init.scope",
	"SYSLOG_IDENTIFIER" : "systemd",
	"_HOSTNAME" : "9158f450b5b9",
	"_GID" : "0",
	"MESSAGE_ID" : "7b05ebc668384222baa8881179cfda54",
	"_COMM" : "systemd",
	"TID" : "1",
	"JOB_RESULT" : "done",
	"UNIT" : "nginx.service",
	"_TRANSPORT" : "journal",
	"_CMDLINE" : "/lib/systemd/systemd",
	"CODE_FUNC" : "job_emit_done_message",
	"JOB_ID" : "486",
	"__MONOTONIC_TIMESTAMP" : "50856610643",
	"__SEQNUM_ID" : "ad5da3978f9349f89f8673b4e22f3838",
	"MESSAGE" : "Reloaded nginx.service - A high performance web server and a reverse proxy server.",
	"_RUNTIME_SCOPE" : "system",
	"_SYSTEMD_SLICE" : "-.slice",
	"JOB_TYPE" : "reload",
	"_PID" : "1",
	"_BOOT_ID" : "339d6e4b286244ab9ee854b5c2cefedb",
	"_MACHINE_ID" : "98b453ea95114d27bf9974169d356f8c",
	"_SOURCE_REALTIME_TIMESTAMP" : "1788377726653491",

$ journalctl -u nginx -n 3 -o cat --no-pager
Reloading nginx.service - A high performance web server and a reverse proxy server...
2026/09/02 19:35:26 [notice] 531#531: signal process started
Reloaded nginx.service - A high performance web server and a reverse proxy server.

########## 10. KERNEL MESSAGES (dmesg equivalent) ##########
$ journalctl -k --no-pager | tail -5
Sep 02 19:33:10 9158f450b5b9 kernel: eth0: renamed from veth6026854
Sep 02 19:33:10 9158f450b5b9 kernel: docker0: port 1(veth3694eeb) entered blocking state
Sep 02 19:33:10 9158f450b5b9 kernel: docker0: port 1(veth3694eeb) entered forwarding state
Sep 02 19:33:10 9158f450b5b9 systemd-journald[23]: Collecting audit messages is disabled.
Sep 02 19:33:10 9158f450b5b9 systemd-journald[23]: Received client request to flush runtime journal.

########## 11. JOURNAL DISK USAGE AND RETENTION ##########
$ journalctl --disk-usage
Archived and active journals take up 16.0M in the file system.

$ journalctl --verify 2>&1 | tail -3
PASS: /var/log/journal/98b453ea95114d27bf9974169d356f8c/system.journal
PASS: /var/log/journal/98b453ea95114d27bf9974169d356f8c/user-1002.journal

########## 12. DEBUGGING A REAL FAILURE WITH journalctl ##########
--- deliberately break the nginx config ---
$ echo "this_is_not_valid_nginx_syntax;" > /etc/nginx/conf.d/broken.conf

$ systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.

$ systemctl is-active nginx
failed

--- now find out WHY, straight from the journal ---
$ journalctl -u nginx -n 12 --no-pager
Sep 02 19:35:26 9158f450b5b9 systemd[1]: Reloading nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:26 9158f450b5b9 nginx[531]: 2026/09/02 19:35:26 [notice] 531#531: signal process started
Sep 02 19:35:26 9158f450b5b9 systemd[1]: Reloaded nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:29 9158f450b5b9 systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:29 9158f450b5b9 systemd[1]: nginx.service: Deactivated successfully.
Sep 02 19:35:29 9158f450b5b9 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:29 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:29 9158f450b5b9 nginx[556]: 2026/09/02 19:35:29 [emerg] 556#556: unknown directive "this_is_not_valid_nginx_syntax" in /etc/nginx/conf.d/broken.conf:1
Sep 02 19:35:29 9158f450b5b9 nginx[556]: nginx: configuration file /etc/nginx/nginx.conf test failed
Sep 02 19:35:29 9158f450b5b9 systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Sep 02 19:35:29 9158f450b5b9 systemd[1]: nginx.service: Failed with result 'exit-code'.
Sep 02 19:35:29 9158f450b5b9 systemd[1]: Failed to start nginx.service - A high performance web server and a reverse proxy server.

$ journalctl -xeu nginx --no-pager | tail -15
░░ The process' exit code is 'exited' and its exit status is 1.
Sep 02 19:35:29 9158f450b5b9 systemd[1]: nginx.service: Failed with result 'exit-code'.
░░ Subject: Unit failed
░░ Defined-By: systemd
░░ Support: http://www.ubuntu.com/support
░░ 
░░ The unit nginx.service has entered the 'failed' state with result 'exit-code'.
Sep 02 19:35:29 9158f450b5b9 systemd[1]: Failed to start nginx.service - A high performance web server and a reverse proxy server.
░░ Subject: A start job for unit nginx.service has failed
░░ Defined-By: systemd
░░ Support: http://www.ubuntu.com/support
░░ 
░░ A start job for unit nginx.service has finished with a failure.
░░ 
░░ The job identifier is 487 and the job result is failed.

--- fix it and confirm recovery ---
$ rm /etc/nginx/conf.d/broken.conf

$ systemctl restart nginx

$ systemctl is-active nginx
active

$ journalctl -u nginx -n 3 --no-pager
Sep 02 19:35:29 9158f450b5b9 systemd[1]: Failed to start nginx.service - A high performance web server and a reverse proxy server.
Sep 02 19:35:29 9158f450b5b9 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 02 19:35:29 9158f450b5b9 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.

```

## Checking logs for a specific service (the task's core skill)

This is the part worth internalising — the transcript above contains a complete
**break → diagnose → fix → confirm** cycle done entirely through the journal.

**1. Break it.** An invalid directive was written into the nginx config and the service restarted:

```console
$ echo "this_is_not_valid_nginx_syntax;" > /etc/nginx/conf.d/broken.conf
$ systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
$ systemctl is-active nginx
failed
```

Note that systemd tells you *nothing about the cause* — only that it failed, and to go read the journal.

**2. Diagnose.** `journalctl -u nginx -n 12` gave the actual reason:

```
nginx[556]: 2026/09/02 19:35:29 [emerg] 556#556: unknown directive
            "this_is_not_valid_nginx_syntax" in /etc/nginx/conf.d/broken.conf:1
nginx[556]: nginx: configuration file /etc/nginx/nginx.conf test failed
systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
systemd[1]: nginx.service: Failed with result 'exit-code'.
```

The exact directive, the exact file, and the exact line number. This is the whole point of the journal:
nginx's own stderr and systemd's unit state are interleaved in one place, in order.

**3. `-x` adds the explanations.** `journalctl -xeu nginx` annotates entries with catalog text:

```
░░ The unit nginx.service has entered the 'failed' state with result 'exit-code'.
```

**4. Fix and confirm.**

```console
$ rm /etc/nginx/conf.d/broken.conf
$ systemctl restart nginx
$ systemctl is-active nginx
active
```

Other things the transcript demonstrates:

- **`-u` really is an index lookup.** `journalctl -u nginx.service` returned *only* nginx's twelve lifecycle
  entries out of a journal thousands of lines long.
- **`-f` is genuinely live.** While `journalctl -u nginx -f` was following, a `systemctl reload nginx` in
  another shell appeared in the output as it happened.
- **Structured data is real.** `-o json-pretty` exposed the indexed fields behind a single line —
  `UNIT`, `_PID`, `_BOOT_ID`, `_CMDLINE`, `JOB_RESULT` — which is what makes the filtering exact.
- **`-t my-demo-app`** pulled back exactly the line written with `logger -t my-demo-app`, out of the whole journal.

### Quick reference for real incidents

```bash
journalctl -u <service> -n 50 --no-pager   # what happened just now
journalctl -xeu <service>                  # why did it fail, with explanations
journalctl -u <service> -f                 # watch it live while reproducing
journalctl -u <service> --since "1 hour ago"
journalctl -p err -b                       # all errors this boot
journalctl -b -1 -p err                    # errors from before the last reboot
journalctl --disk-usage                    # journal eating the disk?
```

> `--no-pager` matters in scripts and CI — otherwise `journalctl` opens `less` and hangs waiting for input.

---

# Task 4 — Linux Command Cheat Sheet

Reviewed from the session material — `basic-linux.pdf`, `ad-linux.pdf` and `Linux Networking Cheat Sheet.pdf`
in `session2-linux/`. Below is each command's **purpose and basic usage**, followed by a transcript of me
actually running them.

## 1. File & directory

| Command | Purpose | Example |
|---|---|---|
| `ls` | List directory contents | `ls -l /etc`, `ls -ltr` (oldest→newest), `ls -a` (hidden) |
| `cd` | Change directory | `cd /var/log`, `cd -` (previous dir) |
| `pwd` | Print working directory | `pwd` |
| `mkdir` | Make a directory | `mkdir -p /tmp/a/b/c` (`-p` creates parents) |
| `rm` | Remove files/directories | `rm file`, `rm -rf dir` (**no undo — check your path**) |
| `touch` | Create an empty file / update timestamp | `touch index.html` |
| `cp` | Copy | `cp app.conf /etc/app/`, `cp -r dir/ dest/` |
| `mv` | Move **or rename** | `mv app.log backup_app.log` |
| `tree` | Show directory structure | `tree /tmp/devops_logs` |

## 2. File viewing & search

| Command | Purpose | Example |
|---|---|---|
| `cat` | Print a whole file | `cat /etc/os-release` |
| `less` | Page through a large file | `less /var/log/syslog` (`q` quit, `/text` search, `G` end) |
| `head` | First N lines | `head -n 10 myfile.txt` |
| `tail` | Last N lines | `tail -n 100 syslog`; **`tail -f`** to follow live |
| `grep` | Search inside files | `grep ERROR app.log`, `-i` ignore case, `-n` line numbers, `-c` count, `-r` recursive, `-v` invert |
| `wc` | Count lines/words/bytes | `wc -l app.log` |
| `find` | Find files by attribute | `find / -type f -name "file.txt"` |

## 3. Process & service management

| Command | Purpose | Example |
|---|---|---|
| `ps` | Snapshot of processes | `ps aux`, `ps -ef \| grep nginx` |
| `top` / `htop` | Live resource usage | `top`, `top -b -n 1` (batch, for scripts) |
| `kill` | Signal a process by PID | `kill 1234` (TERM, polite), `kill -9 1234` (KILL, last resort) |
| `pkill` / `pgrep` | Signal/find by name | `pgrep -f "sleep 600"`, `pkill -f nginx` |
| `nice` / `renice` | Set CPU priority | `nice -n 10 cmd`, `renice -n 15 -p PID` |
| `systemctl` | Manage services | `systemctl status/start/stop/restart/enable nginx` |
| `nohup` | Survive logout | `nohup python3 app.py &` |
| `bg` / `fg` / `jobs` | Job control | `Ctrl-Z` then `bg` |

## 4. Networking

| Command | Purpose | Example |
|---|---|---|
| `ip a` | Show IP/interface config | `ip a`, `ip addr show dev eth0` |
| `ip route` | Routing table | `ip route`, `ip route get 8.8.8.8` |
| `ping` | Test reachability (ICMP) | `ping -c 3 8.8.8.8` |
| `ss` | Socket statistics (modern) | `ss -tulnp` |
| `netstat` | Same, legacy (`net-tools`) | `netstat -tulnp` |
| `curl` | HTTP client | `curl -I https://api.github.com` (headers only) |
| `wget` | Download files | `wget https://example.com/file.zip` |
| `lsof -i` | Which process owns a port | `lsof -i :80` |
| `traceroute` | Path to a host | `traceroute google.com` |
| `dig` / `nslookup` | DNS lookups | `dig github.com` |

> `-tulnp` = **t**cp, **u**dp, **l**istening, **n**umeric (no DNS), **p**rocess. Worth memorising.

## 5. Permissions & ownership

| Command | Purpose | Example |
|---|---|---|
| `chmod` | Change permissions | `chmod 755 script.sh`, `chmod u+x,g-w file` |
| `chown` | Change owner/group | `chown user:group file.txt` |
| `umask` | Default permission mask | `umask` (`0022` → new files `644`, dirs `755`) |
| `sudo` | Run as another user | `sudo systemctl restart nginx` |
| `visudo` | Safely edit sudoers | `sudo visudo` |

Octal: **4** read, **2** write, **1** execute, applied as **owner-group-other**. `755` = `rwxr-xr-x`.

## 6. Package management

| Distro | Command | Example |
|---|---|---|
| Ubuntu/Debian | `apt` | `apt update && apt install -y nginx` |
| RHEL/CentOS | `yum` / `dnf` | `yum install nginx -y` |
| Any Debian | `dpkg` | `dpkg -l`, `dpkg -S /usr/sbin/useradd` (which package owns a file) |

## 7. Disk & storage

| Command | Purpose | Example |
|---|---|---|
| `df -h` | Free space per filesystem | `df -h`, `df -i` (inodes — "disk full" with space left) |
| `du -sh` | Size of a directory | `du -sh /var/log`, `du -sh * \| sort -h` |
| `lsblk` | List block devices | `lsblk` |
| `free -h` | Memory usage | `free -h` |
| `mount` / `umount` | Attach/detach filesystems | `mount /dev/sdb1 /mnt` |
| `tar` | Archive & compress | `tar -czf a.tar.gz dir/`, `-tzf` list, `-xzf` extract |
| `rsync` | Sync directories | `rsync -avz src/ dest/` |

## 8. Scheduling & background jobs

| Command | Purpose | Example |
|---|---|---|
| `crontab -e` | Edit your cron jobs | `crontab -e` |
| `crontab -l` | List them | `crontab -l` |
| `nohup ... &` | Run detached from the terminal | `nohup python3 app.py &` |

```
 ┌── minute (0-59)
 │ ┌── hour (0-23)
 │ │ ┌── day of month (1-31)
 │ │ │ ┌── month (1-12)
 │ │ │ │ ┌── day of week (0-7, 0 and 7 = Sunday)
 0 2 * * *  /home/user/backup.sh     ->  every day at 02:00
```

## 9. User management

| Command | Purpose | Example |
|---|---|---|
| `adduser` | Add a user (interactive, Ubuntu) | `adduser devops` |
| `useradd` | Create a user (scripting) | `useradd -m -s /bin/bash devuser` |
| `usermod` | Modify an account | `usermod -aG sudo devops` (**`-a` or you replace all groups**) |
| `userdel -r` | Delete user + home | `userdel -r devops` |
| `passwd` | Change password | `passwd devops` |
| `id` / `groups` | Show UID, GID, groups | `id devops` |

## 10. Logs, debugging & pro tips

| Command | Purpose | Example |
|---|---|---|
| `journalctl -xe` | Critical/recent system logs | `journalctl -xeu nginx` |
| `tail -f` | Follow a log file live | `tail -f /var/log/syslog` |
| `dmesg` | Kernel ring buffer | `dmesg \| less` |
| `lsof -i :80` | What is using port 80 | `lsof -i :80` |
| `strace -p PID` | Trace a process's syscalls | `strace -p 1234` |
| `file` | Identify a file's type | `file /usr/sbin/adduser` |
| `watch` | Re-run a command periodically | `watch -n 1 df -h` |
| `xargs` | Build commands from stdin | `find . -name "*.log" \| xargs rm` |
| `history` | Your shell history | `history \| grep ssh` |
| `alias` | Shortcut | `alias ll='ls -alF'` |
| `uptime` / `who` | Load average, logged-in users | `uptime && who` |
| `uname -a` | Kernel and architecture | `uname -a` |

## Practice transcript

Every command above run for real:

```console
===================== 1. FILE & DIRECTORY =====================
$ pwd
/root/practice

$ mkdir -p /tmp/devops_logs/archive

$ touch index.html app.conf app.log

$ ls -l
total 0
-rw-r--r-- 1 root root 0 Sep  2 19:37 app.conf
-rw-r--r-- 1 root root 0 Sep  2 19:37 app.log
-rw-r--r-- 1 root root 0 Sep  2 19:37 index.html

$ cp app.conf /tmp/devops_logs/

$ mv app.log backup_app.log

$ ls -ltr
total 0
-rw-r--r-- 1 root root 0 Sep  2 19:37 index.html
-rw-r--r-- 1 root root 0 Sep  2 19:37 backup_app.log
-rw-r--r-- 1 root root 0 Sep  2 19:37 app.conf

$ tree /tmp/devops_logs
/tmp/devops_logs
|-- app.conf
`-- archive

2 directories, 1 file

$ rm -rf /tmp/devops_logs/archive

$ ls -R /tmp/devops_logs
/tmp/devops_logs:
app.conf

===================== 2. FILE VIEWING & SEARCH =====================
$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo

$ printf "INFO  boot ok\nERROR disk full\nWARN  high memory\nERROR timeout\nINFO  done\n" > app.log; cat app.log
INFO  boot ok
ERROR disk full
WARN  high memory
ERROR timeout
INFO  done

$ head -n 2 app.log
INFO  boot ok
ERROR disk full

$ tail -n 2 app.log
ERROR timeout
INFO  done

$ grep ERROR app.log
ERROR disk full
ERROR timeout

$ grep -c ERROR app.log
2

$ grep -n -i error app.log
2:ERROR disk full
4:ERROR timeout

$ wc -l app.log
5 app.log

$ less app.log    # interactive pager - q to quit, /pattern to search

===================== 3. PROCESS & SERVICE MANAGEMENT =====================
$ ps aux | head -6
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.1  20904 11568 ?        Ss   19:33   0:00 /lib/systemd/systemd
root          23  0.0  0.1  41948 15400 ?        S<s  19:33   0:00 /usr/lib/systemd/systemd-journald
message+     224  0.0  0.0   9492  4448 ?        Ss   19:34   0:00 @dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only
root         227  0.0  0.0  17844  7808 ?        Ss   19:34   0:00 /usr/lib/systemd/systemd-logind
root         567  0.0  0.0  10452  1568 ?        Ss   19:35   0:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;

$ ps -ef | grep nginx | grep -v grep
root         567       1  0 19:35 ?        00:00:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
www-data     568     567  0 19:35 ?        00:00:00 nginx: worker process
www-data     569     567  0 19:35 ?        00:00:00 nginx: worker process
www-data     570     567  0 19:35 ?        00:00:00 nginx: worker process
www-data     571     567  0 19:35 ?        00:00:00 nginx: worker process
www-data     572     567  0 19:35 ?        00:00:00 nginx: worker process
www-data     573     567  0 19:35 ?        00:00:00 nginx: worker process
www-data     574     567  0 19:35 ?        00:00:00 nginx: worker process
www-data     575     567  0 19:35 ?        00:00:00 nginx: worker process
www-data     576     567  0 19:35 ?        00:00:00 nginx: worker process
www-data     577     567  0 19:35 ?        00:00:00 nginx: worker process

$ top -b -n 1 | head -12
top - 19:37:10 up 14:09,  0 user,  load average: 0.04, 0.10, 0.08
Tasks:  18 total,   1 running,  17 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st 
MiB Mem :   7836.6 total,   2605.2 free,    883.1 used,   4547.6 buff/cache     
MiB Swap:   1024.0 total,   1024.0 free,      0.0 used.   6953.6 avail Mem 

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
      1 root      20   0   20904  11568   8956 S   0.0   0.1   0:00.12 systemd
     23 root      19  -1   41948  15400  14420 S   0.0   0.2   0:00.03 systemd+
    224 message+  20   0    9492   4448   3884 S   0.0   0.1   0:00.01 dbus-da+
    227 root      20   0   17844   7808   6820 S   0.0   0.1   0:00.01 systemd+
    567 root      20   0   10452   1568    640 S   0.0   0.0   0:00.00 nginx

$ systemctl status nginx --no-pager | head -12
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: enabled)
     Active: active (running) since Wed 2026-09-02 19:35:29 UTC; 1min 41s ago
       Docs: man:nginx(8)
   Main PID: 567 (nginx)
      Tasks: 11 (limit: 9396)
     Memory: 7.4M (peak: 9.3M)
        CPU: 12ms
     CGroup: /docker/9158f450b5b98fd784f5764bb22c68edcdbba3034fece89f9f3c6b6c650330f2/system.slice/nginx.service
             ├─567 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"
             ├─568 "nginx: worker process"
             ├─569 "nginx: worker process"

$ systemctl restart nginx && systemctl is-active nginx
active

--- start a throwaway background process, then kill it by PID ---
$ sleep 600 & echo "started PID $!"
started PID 1003

$ pgrep -f "sleep 600"
1003

$ kill -9 $(pgrep -f "sleep 600") && echo "killed"
killed

$ pgrep -f "sleep 600" || echo "no such process any more"
/root/q1-cheat.sh: line 2:  1003 Killed                  sleep 600
no such process any more

--- kill by name with pkill ---
$ sleep 500 & sleep 0.3; pkill -f "sleep 500" && echo "pkill sent"
pkill sent

--- nice / renice: run at lower priority ---
$ nice -n 10 sleep 300 & sleep 0.3; ps -o pid,ni,cmd -p $!
    PID  NI CMD
   1010  10 sleep 300

$ renice -n 15 -p $(pgrep -f "sleep 300") | head -2
1010 (process ID) old priority 10, new priority 15

$ pkill -f "sleep 300"

===================== 4. NETWORKING =====================
$ ip a | head -12
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
3: gre0@NONE: <NOARP> mtu 1476 qdisc noop state DOWN group default qlen 1000
    link/gre 0.0.0.0 brd 0.0.0.0
4: gretap0@NONE: <BROADCAST,MULTICAST> mtu 1462 qdisc noop state DOWN group default qlen 1000
    link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff

$ ip route
default via 172.17.0.1 dev eth0 
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.2 

$ hostname -I
172.17.0.2 

$ ping -c 3 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=63 time=192 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=63 time=73.1 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=63 time=88.5 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2010ms
rtt min/avg/max/mdev = 73.069/117.739/191.608/52.613 ms

$ ss -tulnp | head -8
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                                                                                                                                                                                                                                                               
tcp   LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=1000,fd=5),("nginx",pid=999,fd=5),("nginx",pid=998,fd=5),("nginx",pid=997,fd=5),("nginx",pid=996,fd=5),("nginx",pid=995,fd=5),("nginx",pid=994,fd=5),("nginx",pid=993,fd=5),("nginx",pid=992,fd=5),("nginx",pid=991,fd=5),("nginx",pid=990,fd=5))
tcp   LISTEN 0      511             [::]:80           [::]:*    users:(("nginx",pid=1000,fd=6),("nginx",pid=999,fd=6),("nginx",pid=998,fd=6),("nginx",pid=997,fd=6),("nginx",pid=996,fd=6),("nginx",pid=995,fd=6),("nginx",pid=994,fd=6),("nginx",pid=993,fd=6),("nginx",pid=992,fd=6),("nginx",pid=991,fd=6),("nginx",pid=990,fd=6))

$ netstat -tulnp 2>/dev/null | head -8
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      990/nginx: master p 
tcp6       0      0 :::80                   :::*                    LISTEN      990/nginx: master p 

$ curl -s -I https://api.github.com | head -6
HTTP/2 200 
date: Wed, 02 Sep 2026 19:36:59 GMT
cache-control: public, max-age=60, s-maxage=60
vary: Accept,Accept-Encoding, Accept, X-Requested-With
x-github-api-version-selected: 2022-11-28
access-control-expose-headers: ETag, Link, Location, Retry-After, X-GitHub-OTP, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Used, X-RateLimit-Resource, X-RateLimit-Reset, X-OAuth-Scopes, X-Accepted-OAuth-Scopes, X-Poll-Interval, X-GitHub-Media-Type, X-GitHub-SSO, X-GitHub-Request-Id, Deprecation, Sunset, Warning

$ curl -s http://localhost | head -6
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }

$ lsof -i :80 | head -5
COMMAND  PID     USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
nginx    990     root    5u  IPv4 1911768      0t0  TCP *:http (LISTEN)
nginx    990     root    6u  IPv6 1911769      0t0  TCP *:http (LISTEN)
nginx    991 www-data    5u  IPv4 1911768      0t0  TCP *:http (LISTEN)
nginx    991 www-data    6u  IPv6 1911769      0t0  TCP *:http (LISTEN)

$ wget -q -O /dev/null -S https://example.com 2>&1 | head -6
  HTTP/1.1 200 OK
  Date: Wed, 02 Sep 2026 19:37:14 GMT
  Content-Type: text/html
  Transfer-Encoding: chunked
  Connection: keep-alive
  Server: cloudflare

===================== 5. PERMISSIONS & OWNERSHIP =====================
$ echo "#!/bin/bash" > script.sh; ls -l script.sh
-rw-r--r-- 1 root root 12 Sep  2 19:37 script.sh

$ chmod 755 script.sh; ls -l script.sh
-rwxr-xr-x 1 root root 12 Sep  2 19:37 script.sh

$ chmod u+x,g-w,o-r script.sh; ls -l script.sh
-rwxr-x--x 1 root root 12 Sep  2 19:37 script.sh

$ chown testuser-adduser:testuser-adduser script.sh; ls -l script.sh
-rwxr-x--x 1 testuser-adduser testuser-adduser 12 Sep  2 19:37 script.sh

$ umask
0022

$ id testuser-adduser
uid=1002(testuser-adduser) gid=1002(testuser-adduser) groups=1002(testuser-adduser),100(users)

$ stat -c "%A %a %U:%G %n" script.sh
-rwxr-x--x 751 testuser-adduser:testuser-adduser script.sh

===================== 6. PACKAGE MANAGEMENT (Ubuntu/Debian) =====================
$ apt-cache policy nginx | head -5
nginx:
  Installed: 1.24.0-2ubuntu7.17
  Candidate: 1.24.0-2ubuntu7.17
  Version table:
 *** 1.24.0-2ubuntu7.17 500

$ dpkg -l | grep -E "^ii  nginx" | head -3
ii  nginx                         1.24.0-2ubuntu7.17                arm64        small, powerful, scalable web/proxy server
ii  nginx-common                  1.24.0-2ubuntu7.17                all          small, powerful, scalable web/proxy server - common files

$ apt list --installed 2>/dev/null | head -5
Listing...
adduser/noble,now 3.137ubuntu1 all [installed]
apt/noble-updates,now 2.8.3 arm64 [installed]
base-files/noble-updates,now 13ubuntu10.4 arm64 [installed]
base-passwd/noble,now 3.6.3build1 arm64 [installed]

$ apt update && apt install -y nginx     # (already installed in this image)
$ yum install nginx -y                   # the RHEL/CentOS equivalent

===================== 7. DISK & STORAGE =====================
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
overlay         453G   25G  405G   6% /
tmpfs            64M     0   64M   0% /dev
shm              64M     0   64M   0% /dev/shm
/dev/vda1       453G   25G  405G   6% /etc/hosts
tmpfs           1.6G   40K  1.6G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock

$ df -i | head -3
Filesystem       Inodes  IUsed    IFree IUse% Mounted on
overlay        30179328 574322 29605006    2% /
tmpfs           1003090    179  1002911    1% /dev

$ du -sh /var/log
17M	/var/log

$ du -sh /var/log/* | sort -h | tail -5
12K	/var/log/nginx
60K	/var/log/bootstrap.log
100K	/var/log/apt
248K	/var/log/dpkg.log
17M	/var/log/journal

$ lsblk 2>/dev/null | head -6
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
nbd0    43:0    0     0B  0 disk 
nbd1    43:32   0     0B  0 disk 
nbd2    43:64   0     0B  0 disk 
nbd3    43:96   0     0B  0 disk 
nbd4    43:128  0     0B  0 disk 

$ free -h
               total        used        free      shared  buff/cache   available
Mem:           7.7Gi       965Mi       2.5Gi       1.0Mi       4.4Gi       6.7Gi
Swap:          1.0Gi          0B       1.0Gi

===================== 8. SCHEDULING & BACKGROUND JOBS =====================
$ echo "0 2 * * * /root/practice/script.sh" | crontab -

$ crontab -l
0 2 * * * /root/practice/script.sh

--- cron syntax:  minute hour day-of-month month day-of-week  command ---
---               0     2    *            *     *            /home/user/backup.sh   = daily at 02:00 ---

$ nohup sleep 200 > nohup-demo.log 2>&1 & echo "nohup PID $!"
nohup PID 1070

$ ps -o pid,ppid,cmd -p $(pgrep -f "sleep 200")
    PID    PPID CMD
   1070     950 sleep 200

$ pkill -f "sleep 200"; crontab -r; crontab -l 2>&1
no crontab for root

===================== 9. USER MANAGEMENT =====================
$ id testuser-adduser
uid=1002(testuser-adduser) gid=1002(testuser-adduser) groups=1002(testuser-adduser),100(users)

$ usermod -aG sudo testuser-adduser

$ id testuser-adduser
uid=1002(testuser-adduser) gid=1002(testuser-adduser) groups=1002(testuser-adduser),27(sudo),100(users)

$ groups testuser-adduser
testuser-adduser : testuser-adduser sudo users

$ getent passwd testuser-adduser
testuser-adduser:x:1002:1002:,,,:/home/testuser-adduser:/bin/bash

$ chage -l testuser-adduser | head -5
Last password change					: Sep 02, 2026
Password expires					: never
Password inactive					: never
Account expires						: never
Minimum number of days between password change		: 0

$ passwd testuser-adduser      # interactive password change

===================== 10. ARCHIVING, SEARCH & PRO TIPS =====================
$ tar -czf logs.tar.gz app.log script.sh; ls -lh logs.tar.gz
-rw-r--r-- 1 root root 249 Sep  2 19:37 logs.tar.gz

$ tar -tzf logs.tar.gz
app.log
script.sh

$ mkdir -p extracted && tar -xzf logs.tar.gz -C extracted && ls extracted
app.log
script.sh

$ find / -maxdepth 3 -type f -name "os-release" 2>/dev/null
/usr/lib/os-release

$ find /root/practice -type f -name "*.log"
/root/practice/backup_app.log
/root/practice/extracted/app.log
/root/practice/app.log
/root/practice/nohup-demo.log

$ grep -ir "error" /root/practice/ | head -3
/root/practice/extracted/app.log:ERROR disk full
/root/practice/extracted/app.log:ERROR timeout
/root/practice/app.log:ERROR disk full

$ ls /root/practice | xargs -n 1 echo "item:"
item: app.conf
item: app.log
item: backup_app.log
item: extracted
item: index.html
item: logs.tar.gz
item: nohup-demo.log
item: script.sh

$ alias ll="ls -alF"; alias ll
alias ll='ls -alF'

$ uptime && who
 19:37:15 up 14:09,  0 user,  load average: 0.04, 0.10, 0.08

$ uname -a
Linux 9158f450b5b9 6.12.67-linuxkit #1 SMP Mon Jan 26 23:07:00 UTC 2026 aarch64 aarch64 aarch64 GNU/Linux

$ whoami; hostname; date
root
9158f450b5b9
Wed Sep  2 19:37:15 UTC 2026

$ watch -n 1 df -h     # interactive: refresh disk usage every second
$ history | grep ssh   # search your own shell history

```

## What the practice run confirmed

- **`ls -ltr`** ordered files oldest-first — the habit worth having on a log directory.
- **`grep -c ERROR app.log`** returned `2`, and `grep -n -i error` gave `2:` and `4:` — line numbers make it
  useful for pointing someone at a config problem.
- **Signals:** `kill -9 $(pgrep -f "sleep 600")` removed the process, and the follow-up `pgrep` printed
  `no such process any more`. `pkill -f` did the same by name.
- **`nice`/`renice`:** `ps -o pid,ni,cmd` showed nice value `10`, then `renice -n 15` raised it to 15 —
  higher nice value means *lower* priority.
- **Networking is live, not simulated:** `ping -c 3 8.8.8.8` returned `0% packet loss` with real RTTs
  (73–192 ms), and `curl -s -I https://api.github.com` returned a real `HTTP/2 200`.
- **`ss -tulnp`, `netstat -tulnp` and `lsof -i :80` agree** — all three identified nginx (PID 990) on port 80.
  Three routes to the same answer; `ss` is the modern one, `netstat` needs `net-tools` installed.
- **`df -i`** was included deliberately: a filesystem can report free space yet still fail writes because it
  has run out of **inodes**. Checking `df -h` alone will not show that.
- **`crontab -l`** read back `0 2 * * * /root/practice/script.sh` exactly as installed.
- **`usermod -aG sudo testuser-adduser`** added the group while keeping the existing ones —
  `id` afterwards showed `1002(testuser-adduser),27(sudo),100(users)`.
- **`tar -czf` → `-tzf` → `-xzf`** round-tripped: archived, listed contents, extracted, files intact.

---

# Summary

| Task | Deliverable | Status |
|---|---|---|
| 1 — Soft & hard links | Difference explained, both created & deleted, inode/link-count proof, interview Q&A | Done |
| 2 — `adduser` vs `useradd` | Difference proven with `file`/`dpkg`, `adduser` justified as the Ubuntu default, `testuser-adduser` created and logged into | Done |
| 3 — `journalctl` | Purpose, flag reference, service-specific logs, live follow, and a full break→diagnose→fix cycle | Done |
| 4 — Cheat sheet | 10 categories documented with purpose + usage, every command executed | Done |

**Environment:** Ubuntu 24.04 (aarch64) with systemd PID 1 in Docker · nginx 1.24 · systemd 255

**Evidence files**

| File | Contents |
|---|---|
| [`evidence/q1-links.sh`](https://github.com/Json604/devops-assignments/blob/main/assignment-01-linux-basics/evidence/q1-links.sh) / [`.txt`](https://github.com/Json604/devops-assignments/blob/main/assignment-01-linux-basics/evidence/q1-links.txt) | Soft & hard link exercises |
| [`evidence/q1-users.sh`](https://github.com/Json604/devops-assignments/blob/main/assignment-01-linux-basics/evidence/q1-users.sh) / [`.txt`](https://github.com/Json604/devops-assignments/blob/main/assignment-01-linux-basics/evidence/q1-users.txt) | `adduser` vs `useradd` |
| [`evidence/q1-journal.sh`](https://github.com/Json604/devops-assignments/blob/main/assignment-01-linux-basics/evidence/q1-journal.sh) / [`.txt`](https://github.com/Json604/devops-assignments/blob/main/assignment-01-linux-basics/evidence/q1-journal.txt) | `journalctl` exercises |
| [`evidence/q1-cheat.sh`](https://github.com/Json604/devops-assignments/blob/main/assignment-01-linux-basics/evidence/q1-cheat.sh) / [`.txt`](https://github.com/Json604/devops-assignments/blob/main/assignment-01-linux-basics/evidence/q1-cheat.txt) | Cheat sheet practice |
| [`evidence/Dockerfile.ubuntu-systemd`](https://github.com/Json604/devops-assignments/blob/main/assignment-01-linux-basics/evidence/Dockerfile.ubuntu-systemd) | The systemd-enabled Ubuntu image |
