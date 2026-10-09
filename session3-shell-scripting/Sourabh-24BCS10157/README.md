# Session 3 — Shell Scripting

**Name:** Sourabh Srivastva
**Enrollment Number:** 24BCS10157

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
Enter your name: Sourabh
Enter your roll number: 24BCS10157
======================================
       SYSTEM INFORMATION REPORT
======================================
Name        : Sourabh
Roll Number : 24BCS10157
Date        : Fri Sep  4 17:44:08 UTC 2026
Hostname    : DESKTOP-E0F3569
Username    : sourabh

======================================
            DISK USAGE
======================================
Filesystem      Size  Used Avail Use% Mounted on
none            3.8G     0  3.8G   0% /usr/lib/modules/6.18.33.2-microsoft-standard-WSL2
none            3.8G  4.0K  3.8G   1% /mnt/wsl
drivers         953G  872G   82G  92% /usr/lib/wsl/drivers
/dev/sdd       1007G  2.2G  954G   1% /
none            3.8G   44K  3.7G   1% /mnt/wslg
none            3.8G     0  3.8G   0% /usr/lib/wsl/lib
rootfs          3.7G  2.8M  3.7G   1% /init
none            3.8G  864K  3.7G   1% /run
none            3.8G     0  3.8G   0% /run/lock
none            3.8G     0  3.8G   0% /run/shm
none            3.8G   80K  3.7G   1% /mnt/wslg/versions.txt
none            3.8G   80K  3.7G   1% /mnt/wslg/doc
C:\             953G  872G   82G  92% /mnt/c
none            1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
tmpfs           3.8G     0  3.8G   0% /tmp
none            1.0M     0  1.0M   0% /run/credentials/systemd-resolved.service
snapfuse         67M   67M     0 100% /snap/core24/1643
snapfuse         10M   10M     0 100% /snap/nmap/4838
snapfuse         51M   51M     0 100% /snap/snapd/27710
none            1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
tmpfs           758M   12K  758M   1% /run/user/1000

======================================
         RUNNING PROCESSES (top 10)
======================================
    PID USER     COMMAND
      1 root     systemd
      2 root     init-systemd(Ub
      6 root     init
     43 root     systemd-journal
     63 systemd+ systemd-resolve
     82 root     systemd-udevd
    168 root     snapfuse
    170 root     snapfuse
    173 root     snapfuse
    199 root     chronyd-starter

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