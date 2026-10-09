# Linux Command Cheat Sheet & Practice Guide

**Name:** Durga Prasad  
**Enrollment Number:** bdurga.24bcs10012@sst.scaler.com  

---

## Overview

This document provides a comprehensive cheat sheet and practice notes for essential Linux commands used in DevOps and system administration.

---

## 1. File & Directory Operations

| Command | Purpose | Basic Usage Example |
| :--- | :--- | :--- |
| `ls` | List directory contents | `ls -la` |
| `cd` | Change directory | `cd /var/log` |
| `pwd` | Print working directory | `pwd` |
| `mkdir` | Create new directory | `mkdir -p app/config` |
| `rmdir` | Remove empty directory | `rmdir empty_dir` |
| `rm` | Remove files or directories | `rm -rf temp_dir` |
| `cp` | Copy files or directories | `cp -r src/ dst/` |
| `mv` | Move or rename files/directories | `mv old.txt new.txt` |
| `touch` | Create empty file or update timestamp | `touch app.log` |
| `cat` | Concatenate and display file content | `cat /etc/os-release` |
| `head` | Output first part of files | `head -n 20 access.log` |
| `tail` | Output last part of files (or tail stream) | `tail -f /var/log/syslog` |
| `find` | Search for files in a directory hierarchy | `find /var/log -name "*.log"` |
| `grep` | Search text patterns using regex | `grep -i "error" app.log` |

---

## 2. File Permissions & Ownership

| Command | Purpose | Basic Usage Example |
| :--- | :--- | :--- |
| `chmod` | Change file access permissions | `chmod 755 script.sh` |
| `chown` | Change file owner and group | `chown www-data:www-data /var/www/html` |
| `chgrp` | Change group ownership | `chgrp devteam deploy.sh` |
| `umask` | Set default file creation mask | `umask 022` |

---

## 3. System Information & Monitoring

| Command | Purpose | Basic Usage Example |
| :--- | :--- | :--- |
| `uname` | Print system information | `uname -a` |
| `uptime` | Tell how long system has been running | `uptime` |
| `df` | Display disk space usage | `df -h` |
| `du` | Estimate file space usage | `du -sh /var/log` |
| `free` | Display amount of free and used memory | `free -h` |
| `top` | Dynamic real-time process viewer | `top` |
| `htop` | Interactive process viewer | `htop` |

---

## 4. Process Management

| Command | Purpose | Basic Usage Example |
| :--- | :--- | :--- |
| `ps` | Report snapshot of current processes | `ps aux \| grep nginx` |
| `kill` | Send signal to a process by PID | `kill -9 1234` |
| `pkill` | Kill processes by name | `pkill nginx` |
| `killall` | Kill processes by name | `killall -9 python3` |
| `bg` / `fg` | Run processes in background/foreground | `bg %1`, `fg %1` |

---

## 5. Network & Connectivity

| Command | Purpose | Basic Usage Example |
| :--- | :--- | :--- |
| `ip` | Show / manipulate network interfaces | `ip a`, `ip route` |
| `ping` | Send ICMP ECHO_REQUEST to network hosts | `ping -c 4 8.8.8.8` |
| `ss` / `netstat` | Investigate sockets / listening ports | `ss -tuln` |
| `curl` | Transfer data from or to a server | `curl -I https://google.com` |
| `wget` | Non-interactive network downloader | `wget https://example.com/file.tar.gz` |
| `nslookup` / `dig` | Query Internet name servers | `dig google.com` |

---

## Summary of Practice

All the listed commands were practiced in Ubuntu Linux environment to understand system administration and Linux troubleshooting fundamentals.
