# Session 2 - Linux Fundamentals

Dhruv Bansal - 24BCS10114

I practised file commands, permissions, links, users, processes, storage, memory, and system logs.

## Hard link and symbolic link

The `links-lab.sh` script creates a normal file, a hard link, and a symbolic link inside a temporary folder. It checks the inode numbers, deletes the original filename, and then shows that the hard link still works while the symbolic link becomes broken.

```bash
bash links-lab.sh --verify
```

## Commands I used

```bash
pwd
ls -lah
find . -type f
grep -R "text" .
df -h
free -h
ps aux
journalctl -b
journalctl -p warning..alert -b
```

For user management on Ubuntu, `adduser` is convenient for an interactive task, while `useradd` gives lower-level control for scripts. A temporary practice user can be created and removed with:

```bash
sudo adduser labuser
sudo deluser --remove-home labuser
```

I checked the command output before changing permissions, users, or running processes.
