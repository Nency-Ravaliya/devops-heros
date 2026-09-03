# Session 3 — Shell Scripting

**Name:** Rachit S  
**Enrollment Number:** 24bcs10139

---

## Task: System Information Script

### Requirements Covered

| Requirement | Implementation |
|---|---|
| Current date | `current_date=$(date)` |
| Hostname | `host_name=$(hostname)` |
| Username | `user_name=$(whoami)` |
| Disk usage | `disk_usage=$(df -h)` |
| Running processes | `processes=$(ps -eo pid,user,comm)` |
| Variables | All values stored in variables |
| `read -p` | Two user-input prompts |
| `mkdir` | `mkdir -p "$dir_name"` |
| `touch` | `touch "$dir_name/result.log" "$dir_name/process.log"` |
| `>` redirection | `echo "$processes" > "$dir_name/process.log"` |

---

## script.sh

```bash
#!/bin/bash

# ─── User Input ────────────────────────────────────────────────────────────────
read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no

# ─── System Variables ──────────────────────────────────────────────────────────
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)
disk_usage=$(df -h)
processes=$(ps -eo pid,user,comm)

# ─── Create Directory & Files ──────────────────────────────────────────────────
dir_name="sysinfo_output"
mkdir -p "$dir_name"
touch "$dir_name/result.log" "$dir_name/process.log"

# ─── Print System Information ──────────────────────────────────────────────────
echo "======================================"
echo "       SYSTEM INFORMATION REPORT      "
echo "======================================"
echo "Name        : $name"
echo "Roll Number : $roll_no"
echo "Date        : $current_date"
echo "Hostname    : $host_name"
echo "Username    : $user_name"

echo ""
echo "======================================"
echo "            DISK USAGE               "
echo "======================================"
echo "$disk_usage"

echo ""
echo "======================================"
echo "         RUNNING PROCESSES (top 10)  "
echo "======================================"
echo "$processes" | head -11

# ─── Write to Files ────────────────────────────────────────────────────────────
echo "$processes" > "$dir_name/process.log"
echo "System info captured on: $current_date" > "$dir_name/result.log"
echo "Name: $name" >> "$dir_name/result.log"
echo "Roll Number: $roll_no" >> "$dir_name/result.log"
echo "Host: $host_name" >> "$dir_name/result.log"
echo "User: $user_name" >> "$dir_name/result.log"

echo ""
echo "Output written to $dir_name/result.log and $dir_name/process.log"
```

---

## Sample Output

```text
Enter your name: Rachit
Enter your roll number: 24bcs10139

======================================
       SYSTEM INFORMATION REPORT
======================================
Name        : Rachit
Roll Number : 24bcs10139
Date        : Wed Sep  3 17:15:00 IST 2026
Hostname    : ubuntu
Username    : rachit

======================================
            DISK USAGE
======================================
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           392M  1.4M  391M   1% /run
/dev/sda1        20G  5.2G   14G  28% /
tmpfs           2.0G     0  2.0G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock

======================================
         RUNNING PROCESSES (top 10)
======================================
    PID USER     COMMAND
      1 root     systemd
      2 root     kthreadd
    431 root     systemd-journald
    468 root     sshd
    512 rachit   bash
    513 rachit   ps

Output written to sysinfo_output/result.log and sysinfo_output/process.log
```

---

## Commands Used

| Command | Purpose |
|---|---|
| `echo` | Print text to terminal |
| `read -p` | Prompt user for input |
| `date` | Get current date and time |
| `hostname` | Get machine hostname |
| `whoami` | Get current logged-in user |
| `df -h` | Disk usage in human-readable format |
| `ps -eo pid,user,comm` | List running processes |
| `mkdir -p` | Create directory (and parents if needed) |
| `touch` | Create empty file |
| `>` | Redirect output to file (overwrite) |
| `>>` | Redirect output to file (append) |
