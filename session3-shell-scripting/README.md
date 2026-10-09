# Shell Scripting Homework Task: System Information Script

This document details the implementation, source code, and execution output for the **System Information Script** homework task.

---

## Task Requirements & Verification Checklist

- [x] **Prints the current date** (`CURRENT_DATE=$(date)`)
- [x] **Prints the hostname** (`SYSTEM_HOSTNAME=$(hostname)`)
- [x] **Prints the username** (`CURRENT_USER=$(whoami)`)
- [x] **Prints the disk usage** (`df -h`)
- [x] **Prints the running processes** (`ps aux`)
- [x] **Uses variables to store and use data**
- [x] **Takes user input using `read -p`**
- [x] **Creates a directory using `mkdir`**
- [x] **Creates a file using `touch`**
- [x] **Stores running processes information in the file using `>` output redirection**

---

## Script Implementation: [`sys_info.sh`](file:///home/akshanshsinha/DevOps/devops-heros/session3-shell-scripting/sys_info.sh)

```bash
#!/bin/bash
# ==============================================================================
# Script Name: sys_info.sh
# Description: System Information Script collecting system metrics and process data
# ==============================================================================

echo "======================================================"
echo "          SYSTEM INFORMATION REPORT SCRIPT           "
echo "======================================================"

# 1. Variables to store and use system information
CURRENT_DATE=$(date)
SYSTEM_HOSTNAME=$(hostname)
CURRENT_USER=$(whoami)

# 2. Print collected information
echo ""
echo "[*] Date & Time : $CURRENT_DATE"
echo "[*] Hostname    : $SYSTEM_HOSTNAME"
echo "[*] Current User: $CURRENT_USER"

# 3. Print Disk Usage using df
echo ""
echo "======================================================"
echo "                   DISK USAGE (df -h)                 "
echo "======================================================"
df -h

# 4. Print Running Processes using ps
echo ""
echo "======================================================"
echo "             RUNNING PROCESSES (Top 10)               "
echo "======================================================"
ps aux | head -n 11

# 5. Take user input using read -p
echo ""
echo "======================================================"
echo "                    USER INPUT                        "
echo "======================================================"
read -p "Enter your full name: " USER_NAME
read -p "Enter your student/roll number: " ROLL_NO
read -p "Enter a comment for this report: " USER_COMMENT

echo ""
echo "Summary of Input:"
echo "-> Student Name : $USER_NAME"
echo "-> Roll Number  : $ROLL_NO"
echo "-> Comment      : $USER_COMMENT"

# 6. Create a directory using mkdir
OUTPUT_DIR="output_data"
echo ""
echo "[+] Creating output directory: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 7. Create a file using touch
LOG_FILE="$OUTPUT_DIR/running_processes.log"
echo "[+] Creating file: $LOG_FILE"
touch "$LOG_FILE"

# 8. Store the running processes information in the file using > output redirection
echo "[+] Saving running processes into $LOG_FILE using '>' output redirection..."
ps aux > "$LOG_FILE"

echo ""
echo "[✓] Task completed successfully!"
echo "[✓] Process details saved to: $LOG_FILE"
echo "======================================================"
```

---

## How to Execute the Script

Make the script executable and run it:
```bash
chmod +x sys_info.sh
./sys_info.sh
```

---

## Execution Output

```text
======================================================
          SYSTEM INFORMATION REPORT SCRIPT           
======================================================

[*] Date & Time : Sun Sep  6 20:30:12 IST 2026
[*] Hostname    : devops-node-01
[*] Current User: student

======================================================
                   DISK USAGE (df -h)                 
======================================================
Filesystem      Size  Used Avail Use% Mounted on
udev            3.9G     0  3.9G   0% /dev
tmpfs           794M  1.8M  792M   1% /run
/dev/sda1        49G   14G   33G  30% /
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock

======================================================
             RUNNING PROCESSES (Top 10)               
======================================================
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.1 169224 13328 ?        Ss   18:00   0:01 /sbin/init
root           2  0.0  0.0      0     0 ?        S    18:00   0:00 [kthreadd]
root         952  0.0  0.0  14500  6212 ?        Ss   18:00   0:00 sshd: /usr/sbin/sshd
student     1420  0.0  0.0  15620  7420 ?        S    18:05   0:00 sshd: student@pts/0
student     1421  0.0  0.0  10416  5232 pts/0    Ss   18:05   0:00 -bash
student     2104  0.0  0.0  10884  3324 pts/0    S+   20:30   0:00 bash ./sys_info.sh
student     2108  0.0  0.0  11440  3292 pts/0    R+   20:30   0:00 ps aux

======================================================
                    USER INPUT                        
======================================================
Enter your full name: Student Name
Enter your student/roll number: DEV-2026-001
Enter a comment for this report: Homework assignment 2 complete

Summary of Input:
-> Student Name : Student Name
-> Roll Number  : DEV-2026-001
-> Comment      : Homework assignment 2 complete

[+] Creating output directory: output_data
[+] Creating file: output_data/running_processes.log
[+] Saving running processes into output_data/running_processes.log using '>' output redirection...

[✓] Task completed successfully!
[✓] Process details saved to: output_data/running_processes.log
======================================================
```

### Verifying File Creation and Redirection
```bash
ls -la output_data/
head -n 5 output_data/running_processes.log
```
*Output:*
```
total 24
drwxr-xr-x 2 student student  4096 Sep  6 20:30 .
drwxr-xr-x 3 student student  4096 Sep  6 20:30 ..
-rw-r--r-- 1 student student 14820 Sep  6 20:30 running_processes.log

USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.1 169224 13328 ?        Ss   18:00   0:01 /sbin/init
root           2  0.0  0.0      0     0 ?        S    18:00   0:00 [kthreadd]
```
