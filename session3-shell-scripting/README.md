# Session 3 Homework - Shell Scripting

## System Information Script

File name: `system_info.sh`

This script prints basic system information and saves the running process details inside a file.

## Commands Used

```bash
mkdir
touch
echo
df
ps
read -p
```

I also used variables and `>` output redirection.

## Script Output

Command:

```bash
./system_info.sh
```

Input:

```text
Enter your name: Nachiketr
Enter your roll number: 03
Enter directory name to save report: system_reports
```

Output:

```text
----------------------------------------
Name        : Nachiketr
Roll Number : 03
Date        : Tue Sep  1 15:10:00 IST 2026
Hostname    : Nachikets-Laptop.local
Username    : nachiketr
----------------------------------------
Disk usage:
Filesystem                                           Size    Used   Avail Capacity iused ifree %iused  Mounted on
/dev/disk3s1s1                                      460Gi    12Gi   249Gi     5%    459k  2.6G    0%   /
devfs                                               200Ki   200Ki     0Bi   100%     692     0  100%   /dev
/dev/disk3s5                                        460Gi   188Gi   249Gi    44%    2.2M  2.6G    0%   /System/Volumes/Data

----------------------------------------
Running processes:
  PID TTY           TIME CMD
23926 ttys000    0:00.01 /bin/bash ./system_info.sh
23927 ttys000    0:00.00 ps

----------------------------------------
Process information saved in system_reports/process.log
Script completed successfully
```

## Output File

The running process information is saved in:

```text
system_reports/process.log
```
