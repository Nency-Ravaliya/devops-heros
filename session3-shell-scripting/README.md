> **Submission for `session3-shell-scripting`** — Piyush Bansal.
>
> Every command shown was actually executed and the output is copied in verbatim.

# Session 3 — System Information Script

A shell script that reports system information, takes input interactively, creates a directory and files, and
saves the running-process list using output redirection.

**Environment:** Ubuntu 24.04 (aarch64 container, systemd as PID 1), Bash 5.2 — same
[`session2-linux`](../session2-linux/README.md) container.

- **Script:** [`sysinfo.sh`](./sysinfo.sh)
- Run inside the same Ubuntu 24.04 + systemd container used for [`session2-linux`](../session2-linux/README.md).

## Requirements checklist

| # | Requirement | How it's done |
|---|---|---|
| 1 | Prints the current date | `CURRENT_DATE=$(date)` then `echo` |
| 2 | Prints the hostname | `HOST_NAME=$(hostname)` |
| 3 | Prints the username | `USER_NAME=$(whoami)` |
| 4 | Prints the disk usage | `df -h` |
| 5 | Prints the running processes | `ps -ef` |
| 6 | Uses variables to store and use data | 6 variables via command substitution |
| 7 | Takes user input using `read -p` | 4 × `read -p` |
| 8 | Creates a directory using `mkdir` | `mkdir -p "$DIR_NAME"` |
| 9 | Creates a file using `touch` | `touch "$PROCESS_FILE"` / `"$SUMMARY_FILE"` |
| 10 | Stores running processes in the file using `>` | `ps -ef > "$PROCESS_FILE"` |

All ten are visible in the transcript below.

## How to run

```bash
chmod +x sysinfo.sh
./sysinfo.sh
```

Tested on Ubuntu 24.04 (aarch64 container, systemd as PID 1), Bash 5.2.

## The commands used, and what each one does

| Command | Purpose | As used here |
|---|---|---|
| `date` | Current system date & time | `CURRENT_DATE=$(date)` |
| `hostname` | The machine's network name | `HOST_NAME=$(hostname)` |
| `whoami` | The effective username | `USER_NAME=$(whoami)` |
| `df` | Disk free, per mounted filesystem | `df -h` — `-h` = human-readable |
| `ps` | Process snapshot | `ps -ef` — every process, full format |
| `echo` | Print text / variables | `echo "Hostname : $HOST_NAME"` |
| `read -p` | Read a line of input into a variable, showing a prompt | `read -p "Enter your name : " NAME` |
| `mkdir` | Make a directory | `mkdir -p "$DIR_NAME"` — `-p` won't error if it exists |
| `touch` | Create an empty file (or update its timestamp) | `touch "$PROCESS_FILE"` |
| `>` | Redirect stdout to a file, **overwriting** | `ps -ef > process.log` |
| `>>` | Redirect stdout to a file, **appending** | `df -h >> system_report.txt` |

### Variables in Bash — what matters

```bash
CURRENT_DATE=$(date)      # command substitution: run `date`, store its OUTPUT
                           # NO spaces around '=' -- `X = 5` tries to run a command called X
echo "$CURRENT_DATE"      # $ reads it back; quotes preserve spaces
DIR_NAME=${DIR_NAME:-sysinfo_reports}   # default value if unset or empty
```

### `>` vs `>>`

```bash
ps -ef >  process.log     # truncate the file to empty, then write
ps -ef >> process.log     # keep what's there, add to the end
```
`>` is what the task asks for — that's why `process.log` contains *only* the process list even though `touch`
created it first. The summary file demonstrates both: `>` writes the first line, `>>` appends the rest.

## Full run transcript

Run interactively — the values after each prompt were typed at the terminal (`Piyush Bansal`, `piyushb0407`,
`Session 3 - System Information Script`, and the default directory name).

```console
$ chmod +x sysinfo.sh
$ ./sysinfo.sh
===============================================================
                  SYSTEM INFORMATION REPORT
===============================================================

Current date  : Thu Sep  3 18:03:48 UTC 2026
Hostname      : 3061048a4363
Username      : root
Kernel        : 7.0.12-linuxkit
Uptime        : up 2 hours, 6 minutes
Processes     : 6 running

--------------------- DISK USAGE (df -h) ----------------------
Filesystem      Size  Used Avail Use% Mounted on
overlay         224G   22G  192G  10% /
tmpfs            64M     0   64M   0% /dev
shm              64M     0   64M   0% /dev/shm
/dev/vda1       224G   22G  192G  10% /etc/hosts
tmpfs           784M  8.1M  776M   2% /run
tmpfs           5.0M     0  5.0M   0% /run/lock

------------------ RUNNING PROCESSES (ps -ef) -----------------
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  1 18:03 ?        00:00:00 /lib/systemd/systemd
root          21       1  0 18:03 ?        00:00:00 /usr/lib/systemd/systemd-journald
root          45       0 40 18:03 ?        00:00:00 /bin/bash ./sysinfo.sh
root          61      45  0 18:03 ?        00:00:00 ps -ef
root          62      45  0 18:03 ?        00:00:00 head -n 12
   ... showing the first 12 only; the complete list is written
       to the log file created at the end of this script.

-------------------------- USER INPUT -------------------------
Enter your name           : Piyush Bansal
Enter your roll number    : piyushb0407
Enter a comment           : Session 3 - System Information Script
Directory to create [sysinfo_reports] :

My name is Piyush Bansal
My roll number is piyushb0407
My comment is: Session 3 - System Information Script

--------------------- CREATING OUTPUT FILES -------------------
Created directory : sysinfo_reports
Created file      : sysinfo_reports/process.log
Created file      : sysinfo_reports/system_report.txt

Saved full process list to sysinfo_reports/process.log using '>' redirection
Saved summary to sysinfo_reports/system_report.txt

------------------------ VERIFICATION -------------------------
$ ls -l sysinfo_reports
total 8
-rw-r--r-- 1 root root 349 Sep  3 18:03 process.log
-rw-r--r-- 1 root root 741 Sep  3 18:03 system_report.txt

$ wc -l sysinfo_reports/process.log
5 sysinfo_reports/process.log

$ head -n 5 sysinfo_reports/process.log
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  1 18:03 ?        00:00:00 /lib/systemd/systemd
root          21       1  0 18:03 ?        00:00:00 /usr/lib/systemd/systemd-journald
root          45       0 33 18:03 ?        00:00:00 /bin/bash ./sysinfo.sh
root          66      45  0 18:03 ?        00:00:00 ps -ef

$ cat sysinfo_reports/system_report.txt
=============== SYSTEM REPORT ===============
Generated at : 2026-09-03 18:03:48
Name         : Piyush Bansal
Roll number  : piyushb0407
Comment      : Session 3 - System Information Script
---------------------------------------------
Date         : Thu Sep  3 18:03:48 UTC 2026
Hostname     : 3061048a4363
Username     : root
Kernel       : 7.0.12-linuxkit
Processes    : 6
--------------- DISK USAGE ------------------
Filesystem      Size  Used Avail Use% Mounted on
overlay         224G   22G  192G  10% /
tmpfs            64M     0   64M   0% /dev
shm              64M     0   64M   0% /dev/shm
/dev/vda1       224G   22G  192G  10% /etc/hosts
tmpfs           784M  8.1M  776M   2% /run
tmpfs           5.0M     0  5.0M   0% /run/lock

===============================================================
  Done. Report written for Piyush Bansal (roll no: piyushb0407)
===============================================================
```

## The files the script created

`sysinfo_reports/process.log` — written by `ps -ef > "$PROCESS_FILE"`. Contains the process list and nothing
else — proof that `>` overwrote the empty file `touch` had created.

`sysinfo_reports/system_report.txt` — written with a mix of `>` (first line, creating fresh content) and `>>`
(every following line, appending) — demonstrating the difference between the two redirection operators in one
file.

---

# Files in this folder

| File | Purpose |
|---|---|
| `sysinfo.sh` | The system information script |
| `README.md` | This file |
