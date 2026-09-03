# Task 4 – Linux command cheat sheet (practised)

Grouped the way I actually use them. Everything here was run either on macOS or in the Ubuntu container while doing tasks 1-3.

## Where am I, what is here

| Command | Purpose | Example I ran |
|---|---|---|
| `pwd` | print working directory | `pwd` → `/root/links` |
| `ls -la`, `ls -li`, `ls -lh` | list with hidden files / inode numbers / human sizes | `ls -li` to compare inodes |
| `cd`, `cd -`, `cd ~` | change dir, jump back, home | |
| `tree -L 2` | directory tree (may need install) | |
| `file x` | what kind of file is this | `file /usr/sbin/adduser` → Perl script |
| `stat x` | inode, links, perms, timestamps | `stat -c '%i %h' hard.txt` |

## Create, copy, move, delete

| Command | Purpose |
|---|---|
| `mkdir -p a/b/c` | create nested dirs, no error if exists |
| `touch f` | create empty file / update mtime |
| `cp -r src dst`, `cp -a` | copy (recursive / preserve everything) |
| `mv old new` | rename or move |
| `rm -rf dir` | delete recursively, no prompt (dangerous) |
| `ln target name`, `ln -s target name` | hard link / symlink (Task 1) |

## Look inside files

| Command | Purpose |
|---|---|
| `cat f`, `cat -n f` | print (with line numbers) |
| `less f` | page through; `/pattern` to search, `q` to quit |
| `head -n 20 f`, `tail -n 20 f`, `tail -f log` | start / end / follow |
| `wc -l f` | count lines (`-w` words, `-c` bytes) |
| `grep -rniE 'pat' dir` | search recursively, ignore case, with line numbers, extended regex |
| `diff a b`, `diff -u a b` | compare files |
| `sort | uniq -c | sort -rn` | frequency count pipeline (used it on `netstat` output in session 4) |
| `cut -d: -f1 /etc/passwd` | pick a column |
| `awk '{print $2}'`, `sed -i 's/a/b/g' f` | column extraction / in-place replace |

## Users, groups, permissions

| Command | Purpose |
|---|---|
| `whoami`, `id`, `id user` | who am I / uid, gid, groups |
| `sudo cmd`, `sudo -i` | run as root / root shell |
| `adduser u`, `useradd -m -s /bin/bash u`, `passwd u`, `deluser u` | Task 2 |
| `usermod -aG sudo u` | add to a group (append!) |
| `chmod 644 f`, `chmod +x s.sh`, `chmod -R 755 dir` | permissions (rwx = 421) |
| `chown user:group f` | ownership |
| `getent passwd u`, `getent group g` | query the user/group database |
| `su - u` | switch user |

## Processes and resources

| Command | Purpose |
|---|---|
| `ps -ef`, `ps aux`, `ps -eo pid,%cpu,comm -r` | list processes (used in the session 3 script) |
| `top`, `htop` | live view |
| `kill PID`, `kill -9 PID`, `pkill name` | send SIGTERM / SIGKILL / by name |
| `jobs`, `bg`, `fg`, `cmd &`, `nohup cmd &` | job control |
| `df -h` | disk space per filesystem |
| `du -sh dir`, `du -sh * | sort -h` | directory sizes |
| `free -h` (Linux), `vm_stat` (macOS) | memory |
| `uptime`, `uname -srm`, `cat /etc/os-release` | load / kernel / distro |

## Services and logs (systemd)

| Command | Purpose |
|---|---|
| `systemctl status|start|stop|restart|enable|disable unit` | manage a service |
| `systemctl is-active unit`, `systemctl list-units --type=service` | state / list |
| `journalctl -u unit -f`, `journalctl -b -p err` | Task 3 |

## Packages (Debian/Ubuntu)

| Command | Purpose |
|---|---|
| `apt update && apt install -y pkg` | install |
| `apt remove pkg`, `apt autoremove` | remove |
| `apt search x`, `apt show pkg`, `dpkg -l | grep x` | find / inspect |

## Networking (details in session 4)

`ip a`, `ip r`, `ping`, `traceroute`, `dig`, `nslookup`, `ss -ltnp`, `curl -I`, `nc -zv host port`, `scp`, `ssh user@host`.

## Archives and transfer

| Command | Purpose |
|---|---|
| `tar -czvf out.tgz dir`, `tar -xzvf out.tgz` | create / extract gzip tarball |
| `zip -r out.zip dir`, `unzip out.zip` | zip |
| `scp f user@host:/path`, `rsync -avz src/ dst/` | copy over ssh / sync |
| `wget URL`, `curl -O URL` | download |

## Shell helpers

| Command | Purpose |
|---|---|
| `history`, `!!`, `!$` | history, repeat last, last arg |
| `which cmd`, `type cmd`, `man cmd`, `cmd --help` | where / what / docs |
| `echo $VAR`, `export VAR=x`, `env` | variables |
| `cmd1 | cmd2`, `>`, `>>`, `2>&1`, `< file` | pipes and redirection (session 3) |
| `xargs`, `find . -name '*.log' -mtime +7 -delete` | batch operations |
| `alias ll='ls -la'` | shortcuts |
