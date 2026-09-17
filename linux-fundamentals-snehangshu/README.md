# Session 2 — Linux Fundamentals

**Name:** Snehangshu Roy
**Enrollment No:** 24BCS10155
**Topic:** Linux Fundamentals (Soft/Hard Links, `adduser` vs `useradd`, `journalctl`, Command Cheat Sheet)

All commands below were executed on a real Ubuntu 22.04 system running `systemd`
(so that `journalctl` and `adduser` behave exactly as they do on a normal server).
Every output block is the actual terminal output of the command shown above it.

---

## Task 1 — Soft Link & Hard Link

### 1.1 What is the difference?

| | Hard Link | Soft (Symbolic) Link |
|---|---|---|
| What it points to | The **inode** (the actual data on disk) | The **pathname** of another file |
| Own inode? | No — shares the inode of the original | Yes — it is a separate file of type *symbolic link* |
| Link count (`ls -l` col 2) | Increases on the target | Target's link count is unchanged |
| Survives deleting the original? | **Yes** — data lives until the last hard link is removed | **No** — becomes a *dangling* link |
| Can cross filesystems / partitions? | No | Yes |
| Can point to a directory? | No (not permitted, would create cycles) | Yes |
| Size | Same as the original file | Size = number of characters in the target path |
| Command | `ln target linkname` | `ln -s target linkname` |

### 1.2 Commands to create both

```bash
ln  original.txt hard_link.txt     # hard link
ln -s original.txt soft_link.txt   # soft (symbolic) link
```

### 1.3 Creating them

```bash
mkdir -p /root/linklab && cd /root/linklab
echo "Hello from the original file" > original.txt
ln -s original.txt soft_link.txt
ln    original.txt hard_link.txt
ls -li
```

```
total 8
102817 -rw-r--r-- 2 root root 29 Sep 17 20:26 hard_link.txt
102817 -rw-r--r-- 2 root root 29 Sep 17 20:26 original.txt
102820 lrwxrwxrwx 1 root root 12 Sep 17 20:26 soft_link.txt -> original.txt
```

Note the first column (the **inode number**): `original.txt` and `hard_link.txt` both show
`102817` — they are the *same file*. `soft_link.txt` has its own inode `102820`.
Also note the link count `2` on the hard-linked pair versus `1` on the symlink.

```bash
stat -c '%n -> inode %i, links %h, size %s, type %F' original.txt hard_link.txt soft_link.txt
```

```
original.txt -> inode 102817, links 2, size 29, type regular file
hard_link.txt -> inode 102817, links 2, size 29, type regular file
soft_link.txt -> inode 102820, links 1, size 12, type symbolic link
```

The symlink is only **12 bytes** — exactly the length of the string `original.txt`, because
that path *is* its content.

### 1.4 Writing through a link changes the original

```bash
echo "Second line added via hard link" >> hard_link.txt
cat original.txt
```

```
Hello from the original file
Second line added via hard link
```

### 1.5 Deleting the original — the key difference

```bash
rm original.txt
ls -li
cat soft_link.txt
cat hard_link.txt
```

```
total 4
102817 -rw-r--r-- 1 root root 61 Sep 17 20:26 hard_link.txt
102820 lrwxrwxrwx 1 root root 12 Sep 17 20:26 soft_link.txt -> original.txt

--- reading soft link after deleting original ---
cat: soft_link.txt: No such file or directory

--- reading hard link after deleting original ---
Hello from the original file
Second line added via hard link
```

The hard link still serves the data (its link count simply dropped from `2` to `1`).
The soft link is now **broken**:

```bash
ls -l soft_link.txt
test -e soft_link.txt && echo "soft link target EXISTS" || echo "soft link is DANGLING (broken)"
```

```
lrwxrwxrwx 1 root root 12 Sep 17 20:26 soft_link.txt -> original.txt
soft link is DANGLING (broken)
```

### 1.6 Hard links cannot point to directories

```bash
ln    /tmp /root/dirlink       # fails
ln -s /tmp /root/dirsoftlink   # works
ls -ld /root/dirsoftlink
```

```
ln: /tmp: hard link not allowed for directory
lrwxrwxrwx 1 root root 4 Sep 17 20:26 /root/dirsoftlink -> /tmp
```

### 1.7 Deleting links

```bash
rm soft_link.txt     # removes just the symlink, never the target
rm hard_link.txt     # removes one name; data is freed only when link count hits 0
unlink soft_link.txt # equivalent for a single file
```

### Interview answer (short version)

> A **hard link** is an additional directory entry pointing at the same inode, so it is
> indistinguishable from the original file — delete the original and the data survives.
> It cannot cross filesystems and cannot be made to a directory.
> A **soft link** is a small separate file whose content is a path. It can cross
> filesystems and point to directories, but if the target is removed or moved the link
> dangles. Inodes are per-filesystem, which is exactly why a hard link cannot cross one.

---

## Task 2 — `adduser` vs `useradd`

### 2.1 The difference

| | `useradd` | `adduser` |
|---|---|---|
| Type | Low-level **binary** from the `shadow` package | High-level **Perl script** that wraps `useradd` |
| Home directory | Not created unless you pass `-m` | Created automatically |
| `/etc/skel` files copied | Only with `-m` | Yes, automatically |
| Default shell | `/bin/sh` (from `/etc/default/useradd`) | `/bin/bash` (from `/etc/adduser.conf`) |
| Password | Not set — account stays locked | Prompts interactively |
| User group | Depends on config | Creates a matching user-private group |
| Interactive | No | Yes (asks for password, full name, etc.) |
| Portability | Present on every Linux distro | Debian/Ubuntu family |

```bash
which useradd adduser
```

```
/usr/sbin/useradd
/usr/sbin/adduser
```

### 2.2 Which is preferred on Ubuntu, and why?

**`adduser` is the recommended command on Ubuntu/Debian.** It is the friendly front-end
that does the whole job in one step: creates the home directory, copies the `/etc/skel`
skeleton files, creates a user-private group, sets a sensible interactive shell
(`/bin/bash`) and prompts for a password. `useradd` is the low-level tool — it does
exactly what you tell it and nothing more, so with plain `useradd` you get a user with
**no home directory and no usable password**. `useradd` is the right choice in scripts and
automation (Ansible, Dockerfiles, cloud-init) where you want deterministic,
non-interactive behaviour and portability across distributions.

### 2.3 Proof — `useradd` alone leaves no home directory

```bash
useradd testuser_low
grep '^testuser_low' /etc/passwd
ls -ld /home/testuser_low
```

```
testuser_low:x:1000:1000::/home/testuser_low:/bin/sh
ls: cannot access '/home/testuser_low': No such file or directory
```

The `/etc/passwd` entry *claims* a home at `/home/testuser_low`, but the directory was
never created, and the shell defaulted to `/bin/sh`.

### 2.4 Creating a test user with the recommended command

```bash
adduser testuser_hw
```

(run non-interactively here as `adduser --disabled-password --gecos "" testuser_hw`)

```
Adding user `testuser_hw' ...
Adding new group `testuser_hw' (1001) ...
Adding new user `testuser_hw' (1001) with group `testuser_hw' ...
Creating home directory `/home/testuser_hw' ...
Copying files from `/etc/skel' ...
```

### 2.5 Verifying

```bash
grep '^testuser_hw' /etc/passwd
ls -ld /home/testuser_hw
ls -A  /home/testuser_hw
id testuser_hw
```

```
testuser_hw:x:1001:1001:,,,:/home/testuser_hw:/bin/bash
drwxr-x--- 2 testuser_hw testuser_hw 4096 Sep 17 20:26 /home/testuser_hw
.bash_logout
.bashrc
.profile
uid=1001(testuser_hw) gid=1001(testuser_hw) groups=1001(testuser_hw)
```

### 2.6 Side-by-side

```
useradd  : testuser_low:x:1000:1000::/home/testuser_low:/bin/sh
adduser  : testuser_hw:x:1001:1001:,,,:/home/testuser_hw:/bin/bash
```

Same file, two very different results: `adduser` filled in the GECOS field, created the
home directory and gave a real login shell.

### 2.7 Related commands

```bash
deluser  testuser_hw --remove-home   # Debian/Ubuntu high-level removal
userdel -r testuser_low              # low-level removal, -r drops the home dir
passwd   testuser_hw                 # set/change password
usermod -aG sudo testuser_hw         # add to a supplementary group
```

---

## Task 3 — `journalctl`

### 3.1 What it is used for

`journalctl` is the query tool for the **systemd journal** — the single, indexed, binary
log store that `systemd-journald` collects from the kernel ring buffer, early boot, stdout
/stderr of every service, and syslog. Instead of grepping through a dozen files under
`/var/log`, you query one journal and filter it by unit, priority, time window, boot, or
field. Log rotation, indexing and structured metadata come for free.

### 3.2 Viewing system logs

```bash
journalctl -b -n 5          # last 5 lines from the current boot
```

```
Sep 17 20:26:42 bd467e9edb8a groupadd[78]: group added to /etc/gshadow: name=testuser_hw
Sep 17 20:26:42 bd467e9edb8a groupadd[78]: new group: name=testuser_hw, GID=1001
Sep 17 20:26:42 bd467e9edb8a useradd[84]: new user: name=testuser_hw, UID=1001, GID=1001, home=/home/testuser_hw, shell=/bin/bash, from=none
Sep 17 20:26:42 bd467e9edb8a usermod[95]: change user 'testuser_hw' password
Sep 17 20:26:42 bd467e9edb8a chfn[102]: changed user 'testuser_hw' information
```

Notice the journal already captured the user creation from Task 2 — that is the point of a
unified log.

### 3.3 Checking logs for a specific service

```bash
systemctl start cron
journalctl -u cron -n 5      # -u = filter by systemd unit
```

```
-- No entries --
```

(`cron` had not logged anything yet in this freshly booted system — `-- No entries --` is
`journalctl` correctly reporting an empty result set for that unit, not an error.)

Typical real-world usage:

```bash
journalctl -u nginx.service            # everything nginx has logged
journalctl -u nginx.service -f         # live tail (like tail -f)
journalctl -u nginx.service --since today
journalctl -u docker -u containerd     # several units at once
```

### 3.4 Filtering by priority

```bash
journalctl -p err -b -n 5    # only errors and worse from this boot
```

```
Sep 17 20:25:43 bd467e9edb8a kernel: misc dxg: dxgk: dxgkio_query_adapter_info: Ioctl failed: -22
Sep 17 20:25:43 bd467e9edb8a kernel: misc dxg: dxgk: dxgkio_query_adapter_info: Ioctl failed: -22
Sep 17 20:25:43 bd467e9edb8a kernel: misc dxg: dxgk: dxgkio_query_adapter_info: Ioctl failed: -2
Sep 17 20:25:43 bd467e9edb8a kernel: virtiofs: Unknown parameter 'negative_dentry_timeout'
Sep 17 20:25:43 bd467e9edb8a unknown: WSL (372) ERROR: CheckConnection: getaddrinfo() failed: -5
```

Priority levels: `emerg` (0), `alert` (1), `crit` (2), `err` (3), `warning` (4),
`notice` (5), `info` (6), `debug` (7).

### 3.5 Filtering by time

```bash
journalctl --since "10 minutes ago" -n 5
```

```
Sep 17 20:25:43 bd467e9edb8a kernel: Linux version 6.6.87.2-microsoft-standard-WSL2 (root@439a258ad544) (gcc (GCC) 11.2.0, GNU ld (GNU Binutils) 2.37) #1 SMP PREEMPT_DYNAMIC Thu Jun  5 18:30:46 UTC 2025
Sep 17 20:25:43 bd467e9edb8a kernel: Command line: initrd=\initrd.img WSL_ROOT_INIT=1 panic=-1 nr_cpus=32 hv_utils.timesync_implicit=1 console=hvc0 debug pty.legacy_count=0 WSL_ENABLE_CRASH_DUMP=1
Sep 17 20:25:43 bd467e9edb8a kernel: KERNEL supported cpus:
Sep 17 20:25:43 bd467e9edb8a kernel:   Intel GenuineIntel
Sep 17 20:25:43 bd467e9edb8a kernel:   AMD AuthenticAMD
```

Other accepted forms: `--since "2026-09-17 20:00" --until "2026-09-17 21:00"`,
`--since yesterday`, `--since "1 hour ago"`.

### 3.6 Journal disk usage and retention

```bash
journalctl --disk-usage
```

```
Archived and active journals take up 8.0M in the file system.
```

```bash
journalctl --vacuum-size=200M    # trim the journal down to 200 MB
journalctl --vacuum-time=7d      # drop anything older than 7 days
```

### 3.7 Structured output

```bash
journalctl -n 1 -o json-pretty
```

```
{
	"SYSLOG_PID" : "102",
	"_GID" : "0",
	"_BOOT_ID" : "6c2c7f938e3648ccb9f532f462b71ead",
	"_CAP_EFFECTIVE" : "1ffffffffff",
	"_CMDLINE" : "/bin/chfn -f \"\" testuser_hw",
	"_COMM" : "chfn",
	"_HOSTNAME" : "bd467e9edb8a",
	"SYSLOG_FACILITY" : "10",
	"_UID" : "0",
	"__CURSOR" : "s=4a20d7c74bd444228b1a73f45b10ce86;i=22e;b=6c2c7f938e3648ccb9f532f462b71ead;m=cc7ee8c;t=65bb39a1aab36",
	"_TRANSPORT" : "syslog",
	"SYSLOG_TIMESTAMP" : "Sep 17 20:26:42 ",
	"_SYSTEMD_SLICE" : "-.slice",
	"__REALTIME_TIMESTAMP" : "1789676802976566",
```

This is what makes the journal different from a plain text log — every entry carries
structured metadata you can filter on (`_COMM`, `_UID`, `_SYSTEMD_UNIT`, …).

### 3.8 `journalctl` quick reference

| Command | Purpose |
|---|---|
| `journalctl` | Everything, oldest first |
| `journalctl -r` | Newest first |
| `journalctl -n 50` | Last 50 lines |
| `journalctl -f` | Follow live |
| `journalctl -u <unit>` | One service |
| `journalctl -b` / `-b -1` | This boot / previous boot |
| `journalctl -k` | Kernel messages only (`dmesg` equivalent) |
| `journalctl -p err` | Priority filter |
| `journalctl --since/--until` | Time window |
| `journalctl -o json-pretty` | Structured output |
| `journalctl --disk-usage` | Space used |
| `journalctl --vacuum-time=7d` | Retention cleanup |

---

## Task 4 — Linux Command Cheat Sheet (practised)

Each command below was run and its real output captured.

### Identity & system

```bash
whoami
uname -a
pwd
uptime
```

```
root
Linux bd467e9edb8a 6.6.87.2-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Thu Jun  5 18:30:46 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
/
 20:26:44 up 3 min,  0 users,  load average: 0.38, 0.29, 0.12
```

| Command | Purpose |
|---|---|
| `whoami` | Current effective username |
| `uname -a` | Kernel name, version, architecture |
| `pwd` | Print working directory |
| `uptime` | How long the box has been up + load average |

### Disk and memory

```bash
df -h
free -h
du -sh /etc
```

```
Filesystem      Size  Used Avail Use% Mounted on
overlay        1007G  6.9G  949G   1% /
tmpfs            64M     0   64M   0% /dev
shm              64M     0   64M   0% /dev/shm
/dev/sde       1007G  6.9G  949G   1% /etc/hosts

               total        used        free      shared  buff/cache   available
Mem:            11Gi       770Mi       9.2Gi        35Mi       1.3Gi        10Gi
Swap:          3.0Gi          0B       3.0Gi

924K	/etc
```

`df` = free space **per filesystem**; `du` = space consumed **by a path**; `-h` makes both
human-readable.

### Processes

```bash
ps aux | head -5
top -bn1 | head -5
```

```
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0  17060  9472 ?        Ss   20:25   0:00 /lib/systemd/systemd
root        22  0.0  0.0  23020  7424 ?        S<s  20:25   0:00 /lib/systemd/systemd-journald
root        58  2.0  0.0   4364  3072 ?        Ss   20:26   0:00 bash /root/linux_t2.sh
root       128  0.0  0.0   7072  3072 ?        R    20:26   0:00 ps aux

top - 20:26:44 up 3 min,  0 users,  load average: 0.38, 0.29, 0.12
Tasks:   5 total,   1 running,   4 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  11476.1 total,   9409.8 free,    770.0 used,   1296.3 buff/cache
MiB Swap:   3072.0 total,   3072.0 free,      0.0 used.  10493.7 avail Mem
```

PID 1 is `systemd` — the init process every other process descends from.
Related: `kill -9 <pid>`, `pkill <name>`, `htop`, `pgrep`.

### Searching

```bash
grep -n 'root' /etc/passwd
find /etc -name '*.conf' | head -5
```

```
1:root:x:0:0:root:/root:/bin/bash

/etc/systemd/pstore.conf
/etc/systemd/sleep.conf
/etc/systemd/networkd.conf
/etc/systemd/user.conf
/etc/systemd/resolved.conf
```

`grep` searches *inside* files; `find` searches *for* files. Useful flags:
`grep -r` recursive, `-i` case-insensitive, `-v` invert, `-n` line numbers.

### Permissions & ownership

```bash
touch /root/perm.txt
chmod 754 /root/perm.txt
chown testuser_hw:testuser_hw /root/perm.txt
ls -l /root/perm.txt
```

```
-rwxr-xr-- 1 testuser_hw testuser_hw 0 Sep 17 20:26 /root/perm.txt
```

`754` = owner `rwx` (7), group `r-x` (5), others `r--` (4).

### Archiving

```bash
tar -czf /root/etcsample.tar.gz /etc/hostname /etc/hosts
ls -lh /root/etcsample.tar.gz
tar -tzf /root/etcsample.tar.gz
```

```
-rw-r--r-- 1 root root 244 Sep 17 20:26 /root/etcsample.tar.gz
etc/hostname
etc/hosts
```

`c` create, `x` extract, `t` list, `z` gzip, `f` file, `v` verbose.

### Text processing

```bash
head -3 /etc/passwd ; tail -3 /etc/passwd
wc -l /etc/passwd
cut -d: -f7 /etc/passwd | sort | uniq -c | sort -rn
awk -F: '$3>=1000 {print $1, $3}' /etc/passwd
echo "devops heros" | sed 's/heros/heroes/'
```

```
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
...
systemd-timesync:x:104:105:systemd Time Synchronization,,,:/run/systemd:/usr/sbin/nologin
testuser_low:x:1000:1000::/home/testuser_low:/bin/sh
testuser_hw:x:1001:1001:,,,:/home/testuser_hw:/bin/bash

25 /etc/passwd

     21 /usr/sbin/nologin
      2 /bin/bash
      1 /bin/sync
      1 /bin/sh

nobody 65534
testuser_low 1000
testuser_hw 1001
```

The `cut | sort | uniq -c | sort -rn` pipeline is the classic "count and rank" idiom — here
it shows 21 of the 25 accounts are service accounts that cannot log in (`/usr/sbin/nologin`).
The `awk` filter picks out UIDs ≥ 1000, which is the convention for *real human* accounts —
and it correctly finds both users created in Task 2.

### Cheat-sheet summary

| Category | Commands |
|---|---|
| Navigation | `pwd`, `cd`, `ls -l`, `ls -a`, `tree` |
| Files | `touch`, `cp`, `mv`, `rm`, `mkdir -p`, `ln`, `ln -s` |
| Viewing | `cat`, `less`, `head`, `tail -f`, `wc` |
| Search | `grep -rn`, `find`, `locate`, `which` |
| Text | `cut`, `sort`, `uniq`, `awk`, `sed`, `tr` |
| Permissions | `chmod`, `chown`, `chgrp`, `umask` |
| Users | `adduser`, `useradd`, `passwd`, `usermod -aG`, `id`, `su`, `sudo` |
| Processes | `ps aux`, `top`, `htop`, `kill`, `pkill`, `jobs`, `bg`, `fg` |
| Disk | `df -h`, `du -sh`, `mount`, `lsblk` |
| Archive | `tar -czf`, `tar -xzf`, `zip`, `unzip` |
| Services | `systemctl status/start/stop/enable`, `journalctl -u` |
| Network | `ip a`, `ping`, `curl`, `ss -tulpn`, `netstat` |

---

## Summary

| Task | Status |
|---|---|
| Task 1 — Soft & hard links created, tested, deleted; interview answer prepared | Done |
| Task 2 — `adduser` vs `useradd` compared; test user created with `adduser` | Done |
| Task 3 — `journalctl` used for system, service, priority and time-based log queries | Done |
| Task 4 — Cheat-sheet commands practised with real output | Done |
