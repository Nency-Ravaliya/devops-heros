# Shell Scripting Assignment: System Information & Process Monitoring

## Overview
This repository contains a shell script `system_info.sh` designed to collect system metadata, display disk space usage, dynamically prompt the user for input, create log directories/files, and write running process details to a file using shell output redirection (`>`).

## Features & Commands Used
- `date`: Retrieves and displays current date and timestamp.
- `hostname`: Retrieves system network node hostname.
- `whoami`: Retrieves currently logged-in username.
- `df -h`: Displays human-readable disk partition usage.
- `read -p`: Captures interactive user input.
- `mkdir -p`: Creates specified directory structure.
- `touch`: Creates empty log file.
- `ps aux`: Lists all currently active processes.
- `>` redirection: Overwrites/saves output of `ps aux` into the target file.
- Shell Variables: Stores strings, dates, and dynamic paths.

---

## How to Run the Script

1. Make the script executable:
   ```bash
   chmod +x system_info.sh
   ```

2. Execute the script:
   ```bash
   ./system_info.sh
   ```

---

## Sample Command Output

```text
======================================================
          SYSTEM INFORMATION MONITORING SCRIPT        
======================================================
Current Date & Time : Thu Sep  3 23:13:30 IST 2026
Hostname            : devops-workstation
Username            : shubh
------------------------------------------------------
Disk Usage Overview:
Filesystem      Size  Used Avail Use% Mounted on
overlay          64G   12G   49G  20% /
tmpfs            64M     0   64M   0% /dev
shm              64M     0   64M   0% /dev/shm
/dev/sda1        64G   12G   49G  20% /etc/hosts
------------------------------------------------------
Enter directory name to create (e.g., system_logs): sys_reports
Enter log filename to create (e.g., process_report.log): active_processes.log
Creating directory: 'sys_reports'...
Creating file: 'sys_reports/active_processes.log'...
Gathering running processes and writing to 'sys_reports/active_processes.log'...
------------------------------------------------------
Process information saved successfully to 'sys_reports/active_processes.log'!
Sample contents of generated process log file (Top 10 lines):
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.1   2888  1600 ?        Ss   22:00   0:00 /bin/sh
shubh        142  0.0  0.4  11588  4120 pts/0    Ss   22:05   0:00 bash
shubh       1204  0.0  0.3   9840  3210 pts/0    R+   23:13   0:00 ps aux
======================================================
```

---

## Verification of Output Redirection
You can inspect the contents of the generated file anytime using:
```bash
cat sys_reports/active_processes.log
```
Or check the file metadata:
```bash
ls -la sys_reports/active_processes.log
```
