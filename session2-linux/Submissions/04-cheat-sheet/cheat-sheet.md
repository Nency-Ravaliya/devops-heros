# Linux Basic Commands — Cheat Sheet

> Reproduced for **DevOps Homework — Task 4**.
> Source/credit: **Nensi Ravaliya — Yatri Cloud** (YouTube: <https://www.youtube.com/@yatricloud>).
> Screenshots: `../screenshots/04-cheat-sheet-1.png`, `04-cheat-sheet-2.png`,
> and `04-cheat-sheet-practice.png` (the commands run live).

## 1. File & Directory Commands

| Command | Description | Example |
|---|---|---|
| `ls` | List directory contents | `ls -l /etc` |
| `cd` | Change directory | `cd /var/log` |
| `pwd` | Print working directory | `pwd` |
| `mkdir` | Make new directory | `mkdir /tmp/devops_logs` |
| `rm` | Remove files/directories | `rm -rf /tmp/devops_logs` |
| `touch` | Create a new file | `touch index.html` |
| `cp` | Copy files | `cp app.conf /etc/app/` |
| `mv` | Move or rename files | `mv app.log backup_app.log` |

## 2. File Viewing & Search

| Command | Description | Example |
|---|---|---|
| `cat` | View file content | `cat /etc/os-release` |
| `less` / `more` | View large files | `less /var/log/syslog` |
| `tail` | View end of file | `tail -n 100 /var/log/syslog` |
| `head` | View top of file | `head -n 10 myfile.txt` |
| `grep` | Search inside files | `grep ERROR /var/log/syslog` |

## 3. Process & Service Management

| Command | Description | Example |
|---|---|---|
| `ps` | Show processes | `ps aux` |
| `top` / `htop` | System resource usage | `top` |
| `kill` | Kill process by PID | `kill -9 1234` |
| `systemctl status` | Check service status | `systemctl status nginx` |
| `systemctl restart` | Restart a service | `systemctl restart nginx` |

## 4. Networking Commands

| Command | Description | Example |
|---|---|---|
| `ping` | Check connectivity | `ping google.com` |
| `ip a` / `ifconfig` | Show IP/network config | `ip a` |
| `netstat` | Show network connections | `netstat -tulnp` |
| `curl` | Fetch URL data | `curl https://api.github.com` |
| `wget` | Download file | `wget https://example.com/file.zip` |

## 5. Permissions & Ownership

| Command | Description | Example |
|---|---|---|
| `chmod` | Change file permissions | `chmod 755 script.sh` |
| `chown` | Change file owner | `chown user:group file.txt` |

## 6. Package Management

| OS | Command | Example |
|---|---|---|
| Ubuntu/Debian | Install packages | `apt update && apt install nginx -y` |
| RHEL/CentOS | Install packages | `yum install nginx -y` |

## 7. Disk & Storage

| Command | Description | Example |
|---|---|---|
| `df` | Show disk usage | `df -h` |
| `du` | Show file/folder size | `du -sh /var/log` |

## 8. Scheduling & Background Jobs

| Command | Description | Example |
|---|---|---|
| `crontab -e` | Edit cron jobs | `crontab -e` |
| Cron syntax | Run daily at 2AM | `0 2 * * * /home/user/backup.sh` |
| `nohup` | Run command in background | `nohup python3 app.py &` |

## 9. User Management

| Command | Description | Example |
|---|---|---|
| `adduser` | Add a new user | `adduser devops` |
| `useradd` | Create user (non-interactive) | `useradd -m -s /bin/bash devuser` |
| `usermod` | Modify user account | `usermod -aG sudo devops` |
| `passwd` | Change user password | `passwd devops` |
| `id` | Display UID, GID, and groups | `id devops` |
| `groups` | Show groups user belongs to | `groups devops` |
| `deluser` / `userdel` | Delete a user | `deluser devops` / `userdel devops` |
| `who` | List logged-in users | `who` |
| `w` | Show who is logged in and what doing | `w` |
| `last` | Show login history | `last` |

## 10. System Information & Utilities

| Command | Description | Example |
|---|---|---|
| `uname -a` | Kernel & system info | `uname -a` |
| `hostname` | Show system hostname | `hostname` |
| `uptime` | Show system uptime | `uptime` |
| `whoami` | Current logged-in username | `whoami` |
| `history` | Show command history | `history` |
| `date` | Current system date/time | `date` |
| `clear` | Clear terminal screen | `clear` |

## Useful Shortcuts

| Shortcut | Description |
|---|---|
| `!!` | Run last command again |
| `!n` | Run nth command from history |
| `Ctrl+C` | Cancel running command |
| `Ctrl+L` | Clear terminal screen |
