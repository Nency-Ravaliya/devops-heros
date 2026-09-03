# Session 2 - Linux Homework Answers

## Task 1: Soft Link vs Hard Link

### Difference
- **Soft link (symbolic link)**: points to a file path. If original file is deleted/moved, symlink breaks.
- **Hard link**: points to the same inode as original file. Works even if original filename is deleted (as long as at least one link exists).

### Create and verify
```bash
mkdir -p task1-links
cd task1-links
echo "linux practice" > original.txt

# soft link
ln -s original.txt soft_link.txt

# hard link
ln original.txt hard_link.txt

# verify
ls -li
```

### Delete and observe
```bash
rm original.txt
ls -li
cat hard_link.txt      # works
cat soft_link.txt      # broken link
```

### Interview-ready answer (short)
`ln -s` creates a soft link (path-based), and `ln` creates a hard link (inode-based). Soft links can cross filesystems and can link directories; hard links generally cannot cross filesystems and usually cannot link directories. Deleting original file breaks soft links, but hard links keep data alive until all hard links are removed.

---

## Task 2: `adduser` vs `useradd`

### Difference
- `useradd`: low-level binary, less interactive, often needs extra flags.
- `adduser` (Ubuntu/Debian): friendly wrapper around `useradd`, interactive, creates home directory and prompts for password/details.

### Recommended on Ubuntu
- **Preferred**: `adduser`
- **Why**: safer defaults + easier interactive setup for normal admin use.

### Create test user (recommended command)
```bash
sudo adduser devops_test_user
id devops_test_user
```

Cleanup:
```bash
sudo deluser --remove-home devops_test_user
```

---

## Task 3: `journalctl`

### Purpose
`journalctl` reads logs from `systemd-journald` (kernel, boot, and services).

### Useful commands
```bash
# full journal
journalctl

# latest boot logs
journalctl -b

# follow logs live
journalctl -f

# logs for a service
journalctl -u ssh.service

# last 100 lines for a service
journalctl -u ssh.service -n 100 --no-pager
```

---

## Task 4: Linux Command Cheat Sheet Practice

| Command | Purpose | Example |
|---|---|---|
| `pwd` | show current directory | `pwd` |
| `ls -lah` | list files with details | `ls -lah` |
| `cd` | change directory | `cd /var/log` |
| `mkdir` | create directory | `mkdir practice` |
| `touch` | create empty file | `touch notes.txt` |
| `cp` | copy files | `cp a.txt b.txt` |
| `mv` | move/rename files | `mv b.txt c.txt` |
| `rm` | remove files | `rm c.txt` |
| `cat` | print file content | `cat /etc/os-release` |
| `grep` | find text in files | `grep -i ubuntu /etc/os-release` |
| `find` | search files | `find . -name "*.sh"` |
| `chmod` | change permissions | `chmod +x script.sh` |
| `chown` | change owner | `sudo chown user:user file` |
| `df -h` | disk usage by filesystem | `df -h` |
| `du -sh` | folder size summary | `du -sh .` |
| `ps aux` | running processes | `ps aux` |
| `top` | live process monitor | `top` |
| `free -h` | memory usage | `free -h` |
| `uname -a` | kernel/system info | `uname -a` |

