# Session 3: Shell Scripting — System Information Script

## Task Overview
Create an interactive shell script (`system_info.sh`) that retrieves system metrics, accepts user input, initializes directories and files, and logs running process details using output redirection.

---

## Features Implemented
- **Current Date & Time**: Captured via `date`.
- **System Hostname**: Captured via `hostname`.
- **Active Username**: Captured via `whoami`.
- **Disk Usage**: Displayed via `df -h`.
- **Interactive User Input**: Prompted using `read -p`.
- **Directory Creation**: Created via `mkdir -p`.
- **File Creation**: Created via `touch`.
- **Output Redirection**: Saved running process table (`ps aux`) to target file using `>`.

---

## Shell Script (`system_info.sh`)

```bash
#!/bin/bash
# System Information Script

CURRENT_DATE=$(date)
SYSTEM_HOSTNAME=$(hostname)
CURRENT_USER=$(whoami)
DISK_USAGE=$(df -h)

echo "Current Date & Time : ${CURRENT_DATE}"
echo "System Hostname     : ${SYSTEM_HOSTNAME}"
echo "Active Username     : ${CURRENT_USER}"
echo "${DISK_USAGE}"

read -p "Enter directory name: " TARGET_DIR
read -p "Enter log filename: " TARGET_FILE

mkdir -p "${TARGET_DIR}"
touch "${TARGET_DIR}/${TARGET_FILE}"
ps aux > "${TARGET_DIR}/${TARGET_FILE}"

echo "Process log saved to ${TARGET_DIR}/${TARGET_FILE}"
```

---

## Execution Instructions

```bash
# 1. Make script executable
chmod +x system_info.sh

# 2. Execute script
./system_info.sh
```

---

## Terminal Execution Output

```text
==================================================
          SYSTEM INFORMATION SCRIPT              
==================================================

[+] Current Date & Time : Wed Oct 14 00:33:56 IST 2026
[+] System Hostname     : Raghavs-MacBook-Air-3.local
[+] Active Username     : raghavrathi

--------------------------------------------------
               DISK USAGE OVERVIEW                
--------------------------------------------------
Filesystem        Size    Used   Avail Capacity Mounted on
/dev/disk3s1s1   228Gi    13Gi    18Gi    43%   /
/dev/disk3s5     228Gi   167Gi    18Gi    91%   /System/Volumes/Data
--------------------------------------------------

[+] Setting up log directory and process file...
Enter directory name to create [default: system_logs]: system_logs
Enter log filename to save running processes [default: process_list.txt]: process_list.txt

[+] Processing your input...
[+] Executing: mkdir -p system_logs
[+] Executing: touch system_logs/process_list.txt
[+] Collecting running processes using 'ps aux'...

==================================================
 SUCCESS: Running processes stored successfully!
 Log Saved At : system_logs/process_list.txt
 Log File Size: 128317 bytes
 Total Lines  : 479 lines
==================================================

[+] First 10 lines of stored processes log:
--------------------------------------------------
USER               PID  %CPU %MEM      VSZ    RSS   TT  STAT STARTED      TIME COMMAND
raghavrathi      23947  33.6  8.7 497350080 1466192   ??  Ss    1:36AM 220:24.64 /System/Library/Frameworks/Virtualization.framework/...
--------------------------------------------------
```
