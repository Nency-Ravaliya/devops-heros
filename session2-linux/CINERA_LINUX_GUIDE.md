# 🍿 CINERA (Netflix Clone) - Complete Linux Fundamentals & Administration Guide

Welcome to the **Complete Linux Administration & Commands Guide** built around managing Linux servers hosting **CINERA** (a scalable Netflix clone application).

This guide covers all core Linux commands, file hierarchy rules, permission management, process inspection, and system monitoring taught in DevOps Session 2, using **CINERA** as our hands-on example.

---

## 📁 1. Linux Filesystem Hierarchy (FHS) in Production

In a Linux production environment hosting CINERA, files are organized according to the **Filesystem Hierarchy Standard**:

```text
/ (Root Directory)
├── bin/          # Essential system binaries (ls, cd, cp)
├── etc/          # System & application configuration files (etc/nginx/nginx.conf, etc/environment)
├── home/         # User home directories (/home/durga-prasad)
├── var/          # Variable data (var/log/cinera/api.log, var/www/html)
├── opt/          # Optional third-party application software (/opt/cinera)
├── tmp/          # Temporary files deleted on reboot
└── usr/          # User programs & utilities (/usr/bin/node)
```

---

## 🛠️ 2. File & Directory Navigation Commands

### A. Navigation Basics

* **Print Current Working Directory**:
  ```bash
  pwd
  ```
  * Shows where you are located (e.g., `/opt/cinera/server`).

* **List Files & Directories (with detailed permissions, size & hidden files)**:
  ```bash
  ls -la
  ```
  * `-l`: Long listing format (permissions, owner, size, modification date).
  * `-a`: Show all files including hidden dotfiles (`.env`, `.gitignore`).
  * `-h`: Human-readable file sizes (`50M` instead of `52428800` bytes).

* **Navigate Directories**:
  ```bash
  cd /opt/cinera/client      # Change to absolute path
  cd ..                      # Go up one level
  cd ~                       # Jump to home directory
  ```

---

### B. Creating, Copying & Deleting Files/Folders

* **Create nested directory structure for CINERA**:
  ```bash
  mkdir -p /opt/cinera/logs/nginx
  ```
  * `-p`: Parent flag (creates intermediate directories automatically if missing).

* **Create empty files or update timestamps**:
  ```bash
  touch /opt/cinera/logs/server.log
  ```

* **Copy files & directories**:
  ```bash
  cp .env.example .env                         # Copy single file
  cp -r /opt/cinera/server /opt/cinera/backup  # Copy folder recursively (-r)
  ```

* **Move or rename files**:
  ```bash
  mv server.js app.js                           # Rename file
  mv /tmp/new_banner.png /opt/cinera/client/public/  # Move file
  ```

* **Remove files & directories**:
  ```bash
  rm /opt/cinera/logs/old.log                   # Delete single file
  rm -rf /opt/cinera/tmp                        # Force delete directory recursively (-rf)
  ```
  * ⚠️ *Caution*: `rm -rf` deletes files permanently without confirmation!

---

## 👁️ 3. File Viewing, Searching & Text Manipulation

### A. Inspecting Logs & Files

* **View full content of a small file**:
  ```bash
  cat /opt/cinera/server/package.json
  ```

* **View top N lines**:
  ```bash
  head -n 10 /opt/cinera/logs/server.log
  ```

* **Live-tail continuous incoming logs (Crucial for debugging!)**:
  ```bash
  tail -f /opt/cinera/logs/server.log
  ```
  * `-f`: Follows the file in real-time as Express logs new HTTP requests or errors.

* **Page through large log files interactively**:
  ```bash
  less /var/log/nginx/access.log
  ```
  * Press `/` to search text, `q` to exit.

---

### B. Searching Text & Files (`grep` & `find`)

* **Search for errors inside CINERA server logs (`grep`)**:
  ```bash
  grep -i "ERROR" /opt/cinera/logs/server.log
  ```
  * `-i`: Case-insensitive search (`error`, `ERROR`, `Error`).
  * `-n`: Display line numbers of matches.
  * `-r`: Search recursively through all files in a folder.

* **Find specific files on disk (`find`)**:
  ```bash
  find /opt/cinera -name "*.js"
  ```
  * Finds all JavaScript files under `/opt/cinera`.

---

## 🔒 4. Linux File Permissions & Ownership (`chmod` & `chown`)

Linux file permissions protect CINERA configuration files and secret keys (`.env`).

### A. Permission Structure Representation

```text
-  rwx  r-x  r--   1 cinera  cinera   4096 Aug 25 12:00 server.js
|   |    |    |
|   |    |    +--> Others (World) Permissions: Read (4)
|   |    +-------> Group Permissions: Read + Execute (4+1 = 5)
|   +------------> Owner Permissions: Read + Write + Execute (4+2+1 = 7)
+----------------> File Type (- = Regular file, d = Directory)
```

#### Permission Numerical Values:
* **`r` (Read)** = `4`
* **`w` (Write)** = `2`
* **`x` (Execute)** = `1`

---

### B. Modifying Permissions (`chmod`)

* **Grant Read/Write to owner only (`.env` file protection)**:
  ```bash
  chmod 600 /opt/cinera/server/.env
  ```
  * `6` (4+2 = Owner Read/Write), `0` (Group None), `0` (Others None).

* **Make a deployment script executable**:
  ```bash
  chmod 755 deploy_cinera.sh
  ```
  * `7` (Owner Full: rwx), `5` (Group: r-x), `5` (Others: r-x).

---

### C. Modifying Ownership (`chown`)

Change the file owner and group to a dedicated service user named `cinera`:
```bash
sudo chown -R cinera:cinera /opt/cinera
```

---

## ⚡ 5. Process Management & System Monitoring

When CINERA high-traffic streaming spikes, DevOps engineers inspect Linux processes and resources:

### A. Monitoring Running Processes

* **List all running processes**:
  ```bash
  ps aux
  ```
  * `a`: All users
  * `u`: Displays user/owner format
  * `x`: Includes processes without a controlling TTY

* **Find the specific Process ID (PID) of CINERA Express Server**:
  ```bash
  ps aux | grep node
  ```

* **Interactive real-time task manager**:
  ```bash
  top
  # OR (Enhanced colored UI)
  htop
  ```

---

### B. Stopping / Terminating Processes (`kill`)

* **Gracefully terminate a process by PID**:
  ```bash
  kill 1234
  ```

* **Force-kill an unresponsive CINERA server process**:
  ```bash
  kill -9 1234
  ```

---

### C. System Resource Metrics

* **Check System Memory Usage (RAM)**:
  ```bash
  free -h
  ```
  * Displays total, used, and free RAM in Gigabytes (`-h`).

* **Check Disk Space Usage**:
  ```bash
  df -h
  ```
  * Displays disk usage for all mounted filesystems.

* **Check System Uptime & Load Average**:
  ```bash
  uptime
  ```

---

## 📋 Quick Linux Command Cheat Sheet Summary

| Action | Command | Example |
| :--- | :--- | :--- |
| **Print Directory** | `pwd` | `pwd` |
| **List Detailed Files** | `ls -lh` | `ls -lh /opt/cinera` |
| **Tail Live Logs** | `tail -f <file>` | `tail -f /var/log/syslog` |
| **Search Pattern** | `grep -rn "pattern" .` | `grep -rn "500 Internal Error" logs/` |
| **Change Permissions** | `chmod <mode> <file>` | `chmod 600 .env` |
| **Change Ownership** | `chown -R user:group <dir>` | `chown -R cinera:cinera /opt/cinera` |
| **Check Memory** | `free -h` | `free -h` |
| **Check Disk** | `df -h` | `df -h` |
| **Find Process PID** | `ps aux \| grep <name>` | `ps aux \| grep nginx` |
| **Kill Process** | `kill -9 <PID>` | `kill -9 4512` |
