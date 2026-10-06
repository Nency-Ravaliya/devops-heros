# Session 2 — Linux

Student: Viraj Bhanage, roll 24BCS10274

This Mac does not ship `useradd`, `adduser`, or `journalctl`. The link exercise below was run on this machine. The user and journal sections are the Ubuntu commands to run on a Linux lab VM.

## Task 1 — Soft link and hard link

A hard link is a second directory entry for the same inode. A soft link is a path that points at another path.

| | Hard link | Soft link |
|---|---|---|
| Command | `ln original.txt hardlink.txt` | `ln -s original.txt softlink.txt` |
| What it stores | Another name for the same inode | The target path |
| After the original is deleted | The data remains | The link becomes dangling |
| Across filesystems | No | Yes |
| Directories | Not used for normal directories | Yes |

Real output from `homework/session-02-linux/link-demo` is in [link-demo-output.txt](link-demo-output.txt).

```text
$ ls -li
44894611 -rw-r--r--  2  original.txt
44894611 -rw-r--r--  2  hardlink.txt
44894614 lrwxr-xr-x  1  softlink.txt -> original.txt
```

Both names share inode `44894611` and link count `2`. After `rm original.txt`, `cat hardlink.txt` still prints the text and `cat softlink.txt` fails because the path it stores is gone.

Interview answer: a hard link is another name for the same file data. A symlink is a pointer. Deleting one hard link does not delete the data while any name remains. Deleting the target of a symlink leaves a broken link.

## Task 2 — `adduser` vs `useradd`

On Ubuntu, `adduser` is the command to use. It is a friendlier Perl wrapper around `useradd`. It prompts for a password, creates a home directory, copies `/etc/skel`, and assigns a login shell. `useradd` is the low-level binary. With no flags it can create a user that has no home directory and no password.

```bash
sudo adduser labstudent
id labstudent
sudo deluser --remove-home labstudent
```

`useradd` is preferred in scripts when every option is explicit:

```bash
sudo useradd --create-home --shell /bin/bash labstudent
```

## Task 3 — `journalctl`

`journalctl` reads the systemd journal. It is the log viewer for system and service messages on modern Linux.

```bash
journalctl -xe
journalctl -u ssh --since "1 hour ago"
journalctl -u nginx -f
journalctl -p err -b
journalctl --disk-usage
```

`-u` selects one unit. `-f` follows new lines. `-p err` keeps error and higher. `-b` is the current boot.

## Task 4 — Commands worth remembering

| Command | Purpose |
|---|---|
| `ls -la` | List names, including hidden files |
| `pwd` / `cd` | Print or change the working directory |
| `cp` `mv` `rm` | Copy, move, delete |
| `mkdir` `touch` | Create a directory or an empty file |
| `cat` `less` `head` `tail` | Read file contents |
| `grep` | Search text |
| `chmod` `chown` | Change permissions or owner |
| `ps aux` `top` | Show processes |
| `df -h` `du -sh` | Disk free and disk used |
| `ip a` `ss -lnt` | Addresses and listening ports |
| `systemctl status` | Service state |
| `journalctl -u` | Service logs |
