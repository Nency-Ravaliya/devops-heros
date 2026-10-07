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
