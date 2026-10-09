# Session 3 — Shell Scripting

**Name:** Snehangshu Roy
**Enrollment No:** 24BCS10155
**Task:** System Information Script

Every script in this folder was executed and the real terminal output is recorded below.

---

## Requirements checklist

| Requirement | Where it is done |
|---|---|
| Prints the current date | `01_system_info.sh`, `05_system_info_complete.sh` |
| Prints the hostname | `01_system_info.sh`, `05_system_info_complete.sh` |
| Prints the username | `01_system_info.sh`, `05_system_info_complete.sh` |
| Prints the disk usage | `05_system_info_complete.sh` (`df -h`) |
| Prints the running processes | `01_system_info.sh`, `05_system_info_complete.sh` (`ps -ef`) |
| Uses variables to store and use data | `02_variables.sh`, `05_system_info_complete.sh` |
| Takes user input using `read -p` | `03_input.sh`, `04_create_dir_file.sh`, `05_system_info_complete.sh` |
| Creates a directory using `mkdir` | `04_create_dir_file.sh`, `05_system_info_complete.sh` |
| Creates a file using `touch` | `05_system_info_complete.sh` |
| Stores running processes in a file using `>` | `01_system_info.sh`, `04_create_dir_file.sh`, `05_system_info_complete.sh` |

---

## Script 1 — `01_system_info.sh`

Date, hostname, username, running processes, and `>` redirection into a log file.

```bash
#!/bin/bash

log_file="process.log"

echo "===== System Info ====="
echo "Date     : $(date)"
echo "Hostname : $(hostname)"
echo "Username : $(whoami)"

echo
echo "===== Running Processes ====="
ps -ef | head -15

ps -ef > "$log_file"
echo
echo "Process info saved in $log_file"
```

### Output

```bash
./01_system_info.sh
```

```
===== System Info =====
Date     : Thu Sep 17 21:08:51 UTC 2026
Hostname : ee647242261e
Username : root

===== Running Processes =====
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  1 21:08 ?        00:00:00 sleep 600
root          13       0  2 21:08 ?        00:00:00 bash /root/run.sh
root          20      13  0 21:08 ?        00:00:00 /bin/bash ./01_system_info.sh
root          24      20  0 21:08 ?        00:00:00 ps -ef
root          25      20  0 21:08 ?        00:00:00 head -15

Process info saved in process.log
```

### Verifying the redirected output

```bash
wc -l < process.log
head -3 process.log
```

```
process.log line count: 5
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  1 21:08 ?        00:00:00 sleep 600
root          13       0  2 21:08 ?        00:00:00 bash /root/run.sh
```

`ps -ef > process.log` sent **stdout to the file instead of the terminal**. `>` creates the
file if it does not exist and **overwrites** it if it does; `>>` appends instead.

Note the command substitution `$(date)` — it runs `date` and substitutes its output into the
string. `$(...)` is preferred over the older backtick form because it nests cleanly.

---

## Script 2 — `02_variables.sh`

Storing data in variables and using them.

```bash
#!/bin/bash

name="Snehangshu Roy"
roll_no="24BCS10155"
comment="Shell scripting makes repetitive DevOps work a lot easier"

echo "Name    : $name"
echo "Roll No : $roll_no"
echo "Comment : $comment"
```

### Output

```
Name    : Snehangshu Roy
Roll No : 24BCS10155
Comment : Shell scripting makes repetitive DevOps work a lot easier
```

Assignment takes **no spaces** around `=` (`name="value"`, never `name = "value"`), and the
value is read back with `$name`. Double quotes allow variable expansion; single quotes would
print `$name` literally.

---

## Script 3 — `03_input.sh`

Taking user input with `read -p`.

```bash
#!/bin/bash

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter a comment: " comment

echo
echo "Name    : $name"
echo "Roll No : $roll_no"
echo "Comment : $comment"
```

### Output

```
Enter your name: Snehangshu Roy
Enter your roll number: 24BCS10155
Enter a comment: Shell scripting makes repetitive DevOps work a lot easier

Name    : Snehangshu Roy
Roll No : 24BCS10155
Comment : Shell scripting makes repetitive DevOps work a lot easier
```

`read -p "prompt" var` prints the prompt **on the same line** and stores the reply in `var`.
Without `-p` you would need a separate `echo -n`.

---

## Script 4 — `04_create_dir_file.sh`

Directory creation with a guard, writing a file with `>` and `>>`, and `ps -ef` redirection.

```bash
#!/bin/bash

dir_name="my_details"
file_name="$dir_name/details.txt"

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter a comment: " comment

if [ -d "$dir_name" ]; then
    echo "Directory $dir_name already exists"
else
    mkdir "$dir_name"
    echo "Directory $dir_name created"
fi

echo "Date     : $(date)" > "$file_name"
echo "Hostname : $(hostname)" >> "$file_name"
echo "Username : $(whoami)" >> "$file_name"
echo "Name     : $name" >> "$file_name"
echo "Roll No  : $roll_no" >> "$file_name"
echo "Comment  : $comment" >> "$file_name"

ps -ef > "$dir_name/process.log"

echo
echo "Details written to $file_name"
cat "$file_name"
```

### Output

```
Directory my_details created

Details written to my_details/details.txt
Date     : Thu Sep 17 21:08:51 UTC 2026
Hostname : ee647242261e
Username : root
Name     : Snehangshu Roy
Roll No  : 24BCS10155
Comment  : Automating system reports with shell scripts
```

### Verifying the created files

```bash
ls -l my_details
cat my_details/details.txt
```

```
total 8
-rw-r--r-- 1 root root 184 Sep 17 21:08 details.txt
-rw-r--r-- 1 root root 333 Sep 17 21:08 process.log

Date     : Thu Sep 17 21:08:51 UTC 2026
Hostname : ee647242261e
Username : root
Name     : Snehangshu Roy
Roll No  : 24BCS10155
Comment  : Automating system reports with shell scripts
```

Two things worth pointing out:

- `[ -d "$dir_name" ]` tests whether the directory exists, so re-running the script does not
  fail with `mkdir: cannot create directory`. (`mkdir -p` achieves the same without the `if`.)
- The **first** line uses `>` to create/overwrite, and every following line uses `>>` to
  append. Using `>` throughout would leave only the last line in the file.

---

## Script 5 — `05_system_info_complete.sh`

One script covering **every** requirement in the task, including `df` (disk usage) and
`touch`, which the earlier scripts did not use.

```bash
#!/bin/bash
# ---- variables ----
dir_name="system_report"
process_file="$dir_name/processes.txt"
summary_file="$dir_name/summary.txt"
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)

echo "Date      : $current_date"
echo "Hostname  : $host_name"
echo "Username  : $user_name"

df -h                       # disk usage
ps -ef | head -10           # running processes

read -p "Enter your name: " input_name
read -p "Enter your roll number: " input_roll
read -p "Enter a comment: " input_comment

mkdir "$dir_name"           # create a directory
touch "$process_file"       # create files
touch "$summary_file"

ps -ef > "$process_file"    # store processes using > redirection

echo "===== System Summary =====" >  "$summary_file"
echo "Date      : $current_date"  >> "$summary_file"
# ... (see the script for the full set of appends)
```

### Output

```
===================================================
            SYSTEM INFORMATION REPORT
===================================================
Date      : Thu Sep 17 21:08:51 UTC 2026
Hostname  : ee647242261e
Username  : root

===== Disk Usage (df -h) =====
Filesystem      Size  Used Avail Use% Mounted on
overlay        1007G   18G  939G   2% /
tmpfs            64M     0   64M   0% /dev
shm              64M     0   64M   0% /dev/shm
/dev/sde       1007G   18G  939G   2% /etc/hosts
tmpfs           5.7G     0  5.7G   0% /proc/acpi
tmpfs           5.7G     0  5.7G   0% /proc/scsi
tmpfs           5.7G     0  5.7G   0% /sys/firmware

===== Running Processes (ps -ef | head -10) =====
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  1 21:08 ?        00:00:00 sleep 600
root          13       0  2 21:08 ?        00:00:00 bash /root/run.sh
root          44      13  0 21:08 ?        00:00:00 /bin/bash ./05_system_info_complete.sh
root          49      44  0 21:08 ?        00:00:00 ps -ef
root          50      44  0 21:08 ?        00:00:00 head -10

Enter your name: Snehangshu Roy
Enter your roll number: 24BCS10155
Enter a comment: One script covering every task requirement

Directory 'system_report' created with mkdir
Empty files created with touch:
total 0
-rw-r--r-- 1 root root 0 Sep 17 21:08 processes.txt
-rw-r--r-- 1 root root 0 Sep 17 21:08 summary.txt

Running processes stored in system_report/processes.txt using > redirection
Lines captured: 5

===== Contents of system_report/summary.txt =====
===== System Summary =====
Date      : Thu Sep 17 21:08:51 UTC 2026
Hostname  : ee647242261e
Username  : root
Disk used : 18G of 1007G (2%)
Processes : 6 running
Name      : Snehangshu Roy
Roll No   : 24BCS10155
Comment   : One script covering every task requirement

===== First 5 lines of system_report/processes.txt =====
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  1 21:08 ?        00:00:00 sleep 600
root          13       0  2 21:08 ?        00:00:00 bash /root/run.sh
root          44      13  0 21:08 ?        00:00:00 /bin/bash ./05_system_info_complete.sh
root          55      44  0 21:08 ?        00:00:00 ps -ef

Report complete.
```

### Verifying the files afterwards

```bash
ls -l system_report
```

```
total 8
-rw-r--r-- 1 root root 338 Sep 17 21:08 processes.txt
-rw-r--r-- 1 root root 267 Sep 17 21:08 summary.txt
```

`touch` created both files at **0 bytes**, and they only gained content once `>` and `>>`
wrote into them — which is the clearest demonstration of what `touch` actually does: it
creates an empty file (or updates the timestamp of an existing one) and nothing more.

The summary line

```bash
echo "Disk used : $(df -h / | awk 'NR==2 {print $3 " of " $2 " (" $5 ")"}')" >> "$summary_file"
```

pipes `df` into `awk`, takes row 2 and prints columns 3, 2 and 5 — producing
`18G of 1007G (2%)`. Combining commands in a pipeline like this is where shell scripting
becomes genuinely useful.

---

## Commands used

| Command | Purpose |
|---|---|
| `date` | Current date and time |
| `hostname` | Machine name |
| `whoami` | Current user |
| `df -h` | Disk usage, human-readable |
| `ps -ef` | Every running process, full format |
| `mkdir` | Create a directory |
| `touch` | Create an empty file / update its timestamp |
| `echo` | Print text |
| `read -p` | Prompt for and read user input |
| `>` | Redirect stdout to a file (overwrite) |
| `>>` | Redirect stdout to a file (append) |
| `$(...)` | Command substitution |
| `[ -d dir ]` | Test whether a directory exists |
| `wc -l`, `head`, `awk` | Count lines, take the first N, extract columns |

---

## Files in this folder

| File | Purpose |
|---|---|
| `01_system_info.sh` | Date, hostname, username, processes, `>` redirection |
| `02_variables.sh` | Variables |
| `03_input.sh` | `read -p` input |
| `04_create_dir_file.sh` | `mkdir`, file creation, `>` and `>>` |
| `05_system_info_complete.sh` | All requirements in one script, incl. `df` and `touch` |
| `shell-scripting-transcript.txt` | Full terminal transcript of every run |

## How to run

```bash
chmod +x *.sh
./05_system_info_complete.sh
```

## Summary

| Requirement | Status |
|---|---|
| Current date, hostname, username printed | Done |
| Disk usage printed | Done |
| Running processes printed | Done |
| Variables used to store and use data | Done |
| User input taken with `read -p` | Done |
| Directory created with `mkdir` | Done |
| File created with `touch` | Done |
| Running processes stored in a file with `>` | Done |
| README with all command outputs | Done |
