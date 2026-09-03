# Session 2 - Linux Fundamentals Assignment

## Task 1: Soft Link vs Hard Link

Demo files are in [`links-demo/`](links-demo/). Real commands run, output captured below.

```bash
echo "This is the original file content." > original.txt
ln    original.txt hardlink.txt   # hard link
ln -s original.txt softlink.txt   # soft/symbolic link
```

**`ls -li` (inode numbers):**
```
51425425 -rw-r--r--@ 2 anshalkumar  staff  35 Sep  3 22:57 hardlink.txt
51425425 -rw-r--r--@ 2 anshalkumar  staff  35 Sep  3 22:57 original.txt
51425428 lrwxr-xr-x@ 1 anshalkumar  staff  12 Sep  3 22:57 softlink.txt -> original.txt
```

`hardlink.txt` shares the **same inode** (51425425) as `original.txt` - it's a second name for the exact same
data on disk, and its link count is 2. `softlink.txt` has its **own inode** and is just a pointer
(a path string) to `original.txt`.

**Editing `original.txt` and reading through the links:**
```
hardlink.txt now shows:
This is the original file content.
Appended line via original.
softlink.txt now shows:
This is the original file content.
Appended line via original.
```
Both links reflect the change immediately, since they both ultimately resolve to the same data.

**Deleting `original.txt`:**
```
hardlink.txt after original removed (still has data):
This is the original file content.
Appended line via original.
softlink.txt after original removed (now broken):
cat: softlink.txt: No such file or directory
```

### Key differences

| | Hard Link | Soft (Symbolic) Link |
|---|---|---|
| Command | `ln target link` | `ln -s target link` |
| Inode | Same as target | Own inode, stores a path |
| Across filesystems/partitions | No | Yes |
| Can link a directory | No (usually) | Yes |
| Survives target deletion | Yes (data stays until last link removed) | No (becomes a dangling/broken link) |
| Size shown by `ls -l` | Real file size | Length of the target path string |

Deleting a link (`rm`) just decrements the link count / removes the pointer; a hard link's data is only
freed once **all** hard links to that inode are removed.

---

## Task 2: `adduser` vs `useradd`

Ran both inside a disposable `ubuntu:22.04` container (`docker run --rm ubuntu:22.04 bash -c '...'`) so the
real system commands (and their real output) could be captured without touching this Mac's own user accounts.

```bash
useradd testuser1
```
```
exit code: 0
testuser1:x:1000:1000::/home/testuser1:/bin/sh
```
```bash
ls -ld /home/testuser1
```
```
ls: cannot access '/home/testuser1': No such file or directory
```

Plain `useradd testuser1` creates the account but **does not** create the home directory and assigns
`/bin/sh` as the default shell - it's the low-level, no-frills tool.

```bash
useradd -m -s /bin/bash testuser1b
```
```
testuser1b:x:1001:1001::/home/testuser1b:/bin/bash
drwxr-x--- 2 testuser1b testuser1b 4096 Sep  3 17:27 /home/testuser1b
```
With `-m` (make home dir) and `-s /bin/bash`, `useradd` behaves like `adduser`, but you have to remember
to pass those flags yourself.

```bash
DEBIAN_FRONTEND=noninteractive adduser --disabled-password --gecos "" testuser2
```
```
Adding user `testuser2' ...
Adding new group `testuser2' (1002) ...
Adding new user `testuser2' (1002) with group `testuser2' ...
Creating home directory `/home/testuser2' ...
Copying files from `/etc/skel' ...
testuser2:x:1002:1002:,,,:/home/testuser2:/bin/bash
drwxr-x--- 2 testuser2 testuser2 4096 Sep  3 17:27 /home/testuser2
```

### Comparison

| | `useradd` | `adduser` |
|---|---|---|
| Type | Low-level binary (from `shadow-utils`), always present | Higher-level Perl script wrapping `useradd`/`usermod`/etc. |
| Home directory | Not created unless `-m` is passed | Created automatically, populated from `/etc/skel` |
| Default shell | `/bin/sh` unless `-s` given | `/bin/bash` by default |
| Own private group | Not created by default | Creates a matching group automatically |
| Interactivity | Non-interactive, all flags required | Prompts for password/full name/etc. (unless run with `--disabled-password` like above) |
| Availability | POSIX-standard, on virtually every distro | Debian/Ubuntu-family only (not on RHEL/CentOS/Alpine by default) |

**Preferred command on Ubuntu/Debian:** `adduser`, for interactive/manual account creation, because it's
friendlier and safer by default (home dir + skeleton files + private group are all handled for you). For
scripting/automation (Ansible, Dockerfiles, provisioning scripts) `useradd` is generally preferred because
it is POSIX/portable and its non-interactive, explicit-flags behavior is predictable across distros.

---

## Task 3: `journalctl`

`journalctl` is the CLI for reading the **systemd journal** - the centralized, binary log store that
`systemd`-based services write to (replacing/complementing flat files under `/var/log`).

> Note: this Mac runs macOS (no systemd), and a plain Docker container has no init/systemd running inside
> it either, so `journalctl` itself isn't runnable in this environment (`journalctl: command not found` /
> no `systemctl` in a base `ubuntu:22.04` container). The commands below are the standard reference for a
> real systemd-based Linux host (e.g. a plain Ubuntu/Debian/RHEL VM or bare-metal box).

Common usage:

```bash
journalctl                      # show the whole journal, oldest first
journalctl -e                   # jump to the end (like tail)
journalctl -f                   # follow, like tail -f
journalctl -u nginx.service     # logs for a specific service/unit
journalctl -u nginx -f          # follow a specific service's logs live
journalctl --since "1 hour ago" --until "now"
journalctl -p err               # only error-priority-and-above entries
journalctl -b                   # logs since the current boot only
journalctl -k                   # kernel messages only (like dmesg)
journalctl --disk-usage         # how much space the journal is using
```

Typical use case: `sudo journalctl -u docker.service -f` while debugging why the Docker daemon failed to
start - it shows the exact startup errors in real time, the same way `tail -f /var/log/syslog` would on an
older non-systemd system, but scoped to just that one service.

---

## Task 4: Linux Command Cheat Sheet review

Reference material used: [`basic-linux.pdf`](basic-linux.pdf), [`ad-linux.pdf`](ad-linux.pdf),
[`Linux Networking Cheat Sheet.pdf`](Linux%20Networking%20Cheat%20Sheet.pdf).

Commands practiced for real on this machine while going through the cheat sheet:

```bash
pwd            # print working directory
whoami         # current user
uname -a       # kernel/OS info
ls -la         # list all files, long format, incl. hidden
df -h          # disk usage, human readable
ps aux         # all running processes
top -l 1       # one-shot snapshot of process/CPU/memory usage
```

| Command | Purpose |
|---|---|
| `pwd` | Print the current working directory |
| `ls -la` | List all files (incl. hidden `.` files) with permissions, owner, size, date |
| `cd` | Change directory |
| `whoami` / `who` / `w` | Show current user / logged-in users / logged-in users + activity |
| `uname -a` | Kernel name, version, architecture |
| `ps aux` | List all running processes with owner/CPU/mem |
| `top` / `htop` | Live process/resource monitor |
| `df -h` | Disk space usage per filesystem, human-readable |
| `du -sh <dir>` | Total size of a directory |
| `chmod` / `chown` | Change file permissions / ownership |
| `grep` | Search text by pattern |
| `find` | Search for files by name/type/time/etc. |
| `tar` / `gzip` | Archive / compress files |
| `systemctl` | Manage systemd services (start/stop/status/enable) |
| `journalctl` | Read systemd service/system logs (see Task 3) |
