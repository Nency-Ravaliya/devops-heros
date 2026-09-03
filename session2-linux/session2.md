# Session 2 — Linux Fundamentals Homework

## Task 1: Soft Link vs Hard Link

| | Soft (symbolic) link | Hard link |
|---|---|---|
| What it is | A pointer/shortcut that stores the **path** to the target file | Another directory entry pointing to the **same inode** as the target |
| Inode | Has its own, different inode number | Shares the exact same inode number as the original |
| Across filesystems/partitions | Yes, can point anywhere | No, must be on the same filesystem |
| Can link to a directory | Yes | No (not allowed on most systems) |
| If the original is deleted | Breaks — becomes a "dangling"/broken link | Still works — data isn't removed until the last hard link (link count) drops to 0 |
| Size shown by `ls -l` | Size of the path string it stores | Same size as the original file |

Commands:
```bash
ln -s <target> <soft-link-name>   # create a soft link
ln <target> <hard-link-name>      # create a hard link
rm <link-name>                    # delete either kind of link (does not touch the target's data unless it's the last hard link)
```

### Practice (real run, captured output)
See [`demo/demo-output.txt`](demo/demo-output.txt) for the full terminal transcript. Steps performed:
1. Created `original.txt`.
2. Created `soft-link.txt` with `ln -s`, and `hard-link.txt` with `ln`.
3. `ls -li` showed `hard-link.txt` and `original.txt` sharing the same inode number, while `soft-link.txt` has its own inode and an `l` (symlink) file-type flag.
4. Deleted `original.txt`.
5. `cat soft-link.txt` → `No such file or directory` (broken link).
6. `cat hard-link.txt` → still printed the file's content (the data is only actually freed when every hard link to that inode is removed).

**Interview takeaway:** a hard link is a second name for the *same data*; a soft link is a *pointer to a path* and breaks if that path disappears.

---

## Task 2: `adduser` vs `useradd`

| | `useradd` | `adduser` |
|---|---|---|
| Type | Low-level binary, part of `shadow-utils` | Friendlier Perl/shell script wrapper around `useradd` (Debian/Ubuntu) |
| Interactivity | Non-interactive — does nothing extra unless you pass flags (`-m`, `-s`, etc.) | Interactive — prompts for password, full name, and other GECOS info |
| Home directory | **Not created by default** (need `-m`) | Created automatically |
| Default shell | Often `/bin/sh` unless specified | Set to a sane default (e.g. `/bin/bash`) automatically |
| Availability | Present on virtually all Linux distros | Only on Debian/Ubuntu-family distros (not RHEL/CentOS by default) |

**Preferred on Ubuntu:** `adduser`, because it is interactive, safer for humans (fewer flags to forget), automatically creates the home directory and sets a shell, and prompts to set the password immediately. `useradd` is what scripts/automation use under the hood when they need precise, non-interactive control.

Recommended command to create a test user on Ubuntu:
```bash
sudo adduser testuser
```
This prompts for a password and optional details, then creates `/home/testuser` with a default shell.

> Note: this environment is macOS (no `adduser`/`useradd`, and creating real system accounts isn't something to do on someone else's machine unattended), so this task is documented conceptually with the exact commands rather than executed here. Run the command above on an Ubuntu box/VM/container to try it live.

---

## Task 3: `journalctl`

`journalctl` reads and displays logs collected by `systemd-journald`, the logging service on systemd-based Linux distros (covers kernel messages, boot logs, and any service managed by systemd).

Useful commands:
```bash
journalctl                        # show all logs, oldest first
journalctl -e                     # jump to the end (most recent) entries
journalctl -f                     # follow logs live, like `tail -f`
journalctl -u <service-name>      # logs for one specific systemd service, e.g. -u nginx
journalctl -u <service-name> -f   # follow a specific service's logs live
journalctl --since "1 hour ago"   # time-filtered logs
journalctl --since today --until now
journalctl -p err                 # only error-priority and above
journalctl -b                     # logs from the current boot only
journalctl -k                     # kernel messages only (like dmesg)
```

Example — checking logs for a specific service (e.g. `nginx` or `ssh`):
```bash
sudo journalctl -u ssh --since "1 hour ago" -f
```

> Note: `journalctl`/`systemd` don't exist on macOS, so this is documented with the exact commands to run on a Linux box rather than executed here.

---

## Task 4: Linux Command Cheat Sheet

Reference material: [`Linux Networking Cheat Sheet.pdf`](Linux%20Networking%20Cheat%20Sheet.pdf), [`basic-linux.pdf`](basic-linux.pdf), [`ad-linux.pdf`](ad-linux.pdf).

Commands practiced from the cheat sheet, with their purpose:

| Command | Purpose |
|---|---|
| `pwd` | Print current working directory |
| `ls -la` | List all files (incl. hidden) with details |
| `cd` | Change directory |
| `cp` / `mv` / `rm` | Copy / move-rename / remove files |
| `mkdir` / `rmdir` | Create / remove a directory |
| `touch` | Create an empty file / update its timestamp |
| `cat` / `less` / `head` / `tail` | View file contents (full / paged / start / end) |
| `grep` | Search text inside files |
| `find` | Search for files by name/type/size/etc. |
| `chmod` / `chown` | Change permissions / ownership |
| `ps` / `top` | View running processes |
| `df -h` / `du -sh` | Disk usage of filesystems / a directory |
| `ln` / `ln -s` | Create hard / soft links (see Task 1) |
| `whoami` / `id` | Current user / user & group IDs |
