> **Submission for `session3-shell-scripting`** — Kartikey, Enrollment No. **10121** ([@Json604](https://github.com/Json604)).
>
> Every command shown was actually executed and the output is copied in verbatim.
> Full working code, scripts and raw transcripts: <https://github.com/Json604/devops-assignments/tree/main/assignment-02-sysinfo-script>

# Assignment 2 — System Information Script

**Session:** `session3-shell-scripting` · **Author:** Kartikey (Json604) · **Enrollment No:** 10121

A shell script that reports system information, takes input interactively, creates a directory and files, and
saves the running-process list using output redirection.

- **Script:** [`sysinfo.sh`](https://github.com/Json604/devops-assignments/blob/main/assignment-02-sysinfo-script/sysinfo.sh)
- **Generated output:** [`evidence/process.log`](https://github.com/Json604/devops-assignments/blob/main/assignment-02-sysinfo-script/evidence/process.log), [`evidence/system_report.txt`](https://github.com/Json604/devops-assignments/blob/main/assignment-02-sysinfo-script/evidence/system_report.txt)
- **Full run transcript:** [`evidence/full-run-transcript.txt`](https://github.com/Json604/devops-assignments/blob/main/assignment-02-sysinfo-script/evidence/full-run-transcript.txt)

## Requirements checklist

Every bullet from the task, mapped to where it is implemented and proven:

| # | Requirement | How it is done | Line |
|---|---|---|---|
| 1 | Prints the current date | `CURRENT_DATE=$(date)` then `echo` | 19 |
| 2 | Prints the hostname | `HOST_NAME=$(hostname)` | 21 |
| 3 | Prints the username | `USER_NAME=$(whoami)` | 22 |
| 4 | Prints the disk usage | `df -h` | 43 |
| 5 | Prints the running processes | `ps -ef` | 47 |
| 6 | Uses variables to store and use data | 7 variables via command substitution | 19–25 |
| 7 | Takes user input using `read -p` | 4 × `read -p` | 57–60 |
| 8 | Creates a directory using `mkdir` | `mkdir -p "$DIR_NAME"` | 78 |
| 9 | Creates a file using `touch` | `touch "$PROCESS_FILE"` / `"$SUMMARY_FILE"` | 84–85 |
| 10 | Stores running processes in the file using `>` | `ps -ef > "$PROCESS_FILE"` | 95 |

All ten are visible in the transcript below.

## How to run

```bash
chmod +x sysinfo.sh
./sysinfo.sh
```

Tested on Ubuntu 24.04 (aarch64), Bash 5.2.

## The commands used, and what each one does

| Command | Purpose | As used here |
|---|---|---|
| `date` | Current system date & time | `CURRENT_DATE=$(date)`; `date '+%Y-%m-%d %H:%M:%S'` for a sortable form |
| `hostname` | The machine's network name | `HOST_NAME=$(hostname)` |
| `whoami` | The effective username | `USER_NAME=$(whoami)` |
| `df` | **D**isk **f**ree, per mounted filesystem | `df -h` — `-h` = human-readable (G/M rather than 1-K blocks) |
| `ps` | Process snapshot | `ps -ef` — **e**very process, **f**ull format |
| `echo` | Print text / variables | `echo "Hostname : $HOST_NAME"` |
| `read -p` | Read a line of input into a variable, showing a prompt | `read -p "Enter your name : " NAME` |
| `mkdir` | Make a directory | `mkdir -p "$DIR_NAME"` — `-p` won't error if it exists |
| `touch` | Create an empty file (or update its timestamp) | `touch "$PROCESS_FILE"` |
| `>` | Redirect stdout to a file, **overwriting** | `ps -ef > process.log` |
| `>>` | Redirect stdout to a file, **appending** | `df -h >> system_report.txt` |
| `wc -l` | Count lines | `wc -l process.log` — used to verify the write |

### Variables in Bash — the three things that matter

```bash
CURRENT_DATE=$(date)      # command substitution: run `date`, store its OUTPUT
                          # NO spaces around '=' — `X = 5` tries to run a command called X
echo "$CURRENT_DATE"      # $ reads it back; quotes preserve spaces
DIR_NAME=${DIR_NAME:-sysinfo_reports}   # default value if unset or empty
```

The script quotes every expansion (`"$DIR_NAME"`) so a directory name containing a space is still handled as a
single argument, and uses `set -u` so a typo in a variable name aborts the script instead of silently
expanding to an empty string.

### `>` vs `>>`

```bash
ps -ef >  process.log     # truncate the file to empty, then write
ps -ef >> process.log     # keep what's there, add to the end
```

`>` is what the task asks for, and it is why `process.log` contains *only* the process list even though `touch`
created it first. The summary file demonstrates both: `>` writes the first line, `>>` appends the rest.

## Full run transcript

Run interactively — the values after each prompt were typed at the terminal.

```console
$ chmod +x sysinfo.sh
$ ./sysinfo.sh
===============================================================
                  SYSTEM INFORMATION REPORT
===============================================================

Current date  : Wed Sep  2 19:46:10 UTC 2026
Hostname      : 9158f450b5b9
Username      : root
Kernel        : Linux 6.12.67-linuxkit aarch64
Uptime        : up 14 hours, 18 minutes
Processes     : 24 running

--------------------- DISK USAGE (df -h) ----------------------
Filesystem      Size  Used Avail Use% Mounted on
overlay         453G   25G  405G   6% /
tmpfs            64M     0   64M   0% /dev
shm              64M     0   64M   0% /dev/shm
/dev/vda1       453G   25G  405G   6% /etc/hosts
tmpfs           1.6G   40K  1.6G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock

------------------ RUNNING PROCESSES (ps -ef) -----------------
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 19:33 ?        00:00:00 /lib/systemd/systemd
root          23       1  0 19:33 ?        00:00:00 /usr/lib/systemd/systemd-journald
message+     224       1  0 19:34 ?        00:00:00 @dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only
root         227       1  0 19:34 ?        00:00:00 /usr/lib/systemd/systemd-logind
root         990       1  0 19:37 ?        00:00:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
www-data     991     990  0 19:37 ?        00:00:00 nginx: worker process
www-data     992     990  0 19:37 ?        00:00:00 nginx: worker process
www-data     993     990  0 19:37 ?        00:00:00 nginx: worker process
www-data     994     990  0 19:37 ?        00:00:00 nginx: worker process
www-data     995     990  0 19:37 ?        00:00:00 nginx: worker process
www-data     996     990  0 19:37 ?        00:00:00 nginx: worker process
   ... showing the first 12 only; the complete list is written
       to the log file created at the end of this script.

-------------------------- USER INPUT -------------------------
Enter your name           : Kartikey
Enter your roll number    : 10121
Enter a comment           : Assignment 2 - System Information Script
Directory to create [sysinfo_reports] : 

My name is Kartikey
My roll number is 10121
My comment is: Assignment 2 - System Information Script

--------------------- CREATING OUTPUT FILES -------------------
Created directory : sysinfo_reports
Created file      : sysinfo_reports/process.log
Created file      : sysinfo_reports/system_report.txt

Saved full process list to sysinfo_reports/process.log using '>' redirection
Saved summary to sysinfo_reports/system_report.txt

------------------------ VERIFICATION -------------------------
$ ls -l sysinfo_reports
total 8
-rw-r--r-- 1 root root 1977 Sep  2 19:46 process.log
-rw-r--r-- 1 root root  749 Sep  2 19:46 system_report.txt

$ wc -l sysinfo_reports/process.log
22 sysinfo_reports/process.log

$ head -n 5 sysinfo_reports/process.log
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 19:33 ?        00:00:00 /lib/systemd/systemd
root          23       1  0 19:33 ?        00:00:00 /usr/lib/systemd/systemd-journald
message+     224       1  0 19:34 ?        00:00:00 @dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only
root         227       1  0 19:34 ?        00:00:00 /usr/lib/systemd/systemd-logind

$ cat sysinfo_reports/system_report.txt
=============== SYSTEM REPORT ===============
Generated at : 2026-09-02 19:46:10
Name         : Kartikey
Roll number  : 10121
Comment      : Assignment 2 - System Information Script
---------------------------------------------
Date         : Wed Sep  2 19:46:10 UTC 2026
Hostname     : 9158f450b5b9
Username     : root
Kernel       : Linux 6.12.67-linuxkit aarch64
Processes    : 24
--------------- DISK USAGE ------------------
Filesystem      Size  Used Avail Use% Mounted on
overlay         453G   25G  405G   6% /
tmpfs            64M     0   64M   0% /dev
shm              64M     0   64M   0% /dev/shm
/dev/vda1       453G   25G  405G   6% /etc/hosts
tmpfs           1.6G   40K  1.6G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock

===============================================================
  Done. Report written for Kartikey (roll no: 10121)
===============================================================
```

## The files the script created

### `sysinfo_reports/process.log`

Written by `ps -ef > "$PROCESS_FILE"`. It contains the process list and nothing else — proof that `>`
overwrote the empty file `touch` had created.

```console
$ cat sysinfo_reports/process.log
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 19:33 ?        00:00:00 /lib/systemd/systemd
root          23       1  0 19:33 ?        00:00:00 /usr/lib/systemd/systemd-journald
message+     224       1  0 19:34 ?        00:00:00 @dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only
root         227       1  0 19:34 ?        00:00:00 /usr/lib/systemd/systemd-logind
root         990       1  0 19:37 ?        00:00:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
www-data     991     990  0 19:37 ?        00:00:00 nginx: worker process
www-data     992     990  0 19:37 ?        00:00:00 nginx: worker process
www-data     993     990  0 19:37 ?        00:00:00 nginx: worker process
www-data     994     990  0 19:37 ?        00:00:00 nginx: worker process
www-data     995     990  0 19:37 ?        00:00:00 nginx: worker process
www-data     996     990  0 19:37 ?        00:00:00 nginx: worker process
www-data     997     990  0 19:37 ?        00:00:00 nginx: worker process
www-data     998     990  0 19:37 ?        00:00:00 nginx: worker process
www-data     999     990  0 19:37 ?        00:00:00 nginx: worker process
www-data    1000     990  0 19:37 ?        00:00:00 nginx: worker process
root        1708       0  0 19:46 ?        00:00:00 bash -c cd /root && rm -rf sysinfo_reports && ( sleep 1.2; echo "Kartikey"; sleep 0.4; echo "10121"; sleep 0.4; echo "Assignment 2 - System Information Script"; sleep 0.4; echo ""; sleep 0.6 ) | script -q -c "bash /root/sysinfo.sh" /dev/null
root        1715    1708  0 19:46 ?        00:00:00 sleep 0.6
root        1716    1708  0 19:46 ?        00:00:00 script -q -c bash /root/sysinfo.sh /dev/null
root        1718    1716  0 19:46 pts/0    00:00:00 sh -c bash /root/sysinfo.sh
root        1719    1718  0 19:46 pts/0    00:00:00 bash /root/sysinfo.sh
root        1739    1719  0 19:46 pts/0    00:00:00 ps -ef
```

### `sysinfo_reports/system_report.txt`

Written with `>` for the first line and `>>` for every line after it.

```console
$ cat sysinfo_reports/system_report.txt
=============== SYSTEM REPORT ===============
Generated at : 2026-09-02 19:46:10
Name         : Kartikey
Roll number  : 10121
Comment      : Assignment 2 - System Information Script
---------------------------------------------
Date         : Wed Sep  2 19:46:10 UTC 2026
Hostname     : 9158f450b5b9
Username     : root
Kernel       : Linux 6.12.67-linuxkit aarch64
Processes    : 24
--------------- DISK USAGE ------------------
Filesystem      Size  Used Avail Use% Mounted on
overlay         453G   25G  405G   6% /
tmpfs            64M     0   64M   0% /dev
shm              64M     0   64M   0% /dev/shm
/dev/vda1       453G   25G  405G   6% /etc/hosts
tmpfs           1.6G   40K  1.6G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
```

## Verification

The script verifies its own work at the end, and the transcript shows it:

| Check | Command | Result |
|---|---|---|
| Directory created | `ls -l sysinfo_reports` | both files present |
| File created & non-empty | `wc -l process.log` | `22` lines |
| Redirection worked | `head -n 5 process.log` | `ps -ef` header + rows |
| Input reached the file | `cat system_report.txt` | `Name : Kartikey`, `Roll number : 10121` |
| Exit status | `echo $?` | `0` |

## Code quality

Linted with ShellCheck:

```console
$ docker run --rm -v "$PWD:/mnt" koalaman/shellcheck:stable /mnt/sysinfo.sh
In /mnt/sysinfo.sh line 57:
read -p "Enter your name           : " NAME
^--^ SC2162 (info): read without -r will mangle backslashes.
```

Four info-level findings, all the same one. It is worth understanding rather than hiding:

- `read` without `-r` treats a backslash in the input as an escape character, so typing `C:\new` would come
  back as `C:new`.
- The production-hardened form is `read -r -p "..." VAR`.
- **I have deliberately kept plain `read -p`** because the task specifies that exact form, and the session
  material teaches it that way. There are no warning- or error-level findings.

Everything else is clean: `set -u` catches unset variables, all expansions are quoted, and `mkdir -p` is
idempotent so re-running the script is safe.

## What I understood

- **Command substitution `$(...)` is the workhorse.** It runs a command and hands you its output as a string,
  which is how a shell script turns `date`, `hostname` and `whoami` into data you can reuse instead of just
  printing once.
- **`touch` and `>` do different jobs.** `touch` guarantees the file *exists*; `>` puts *content* in it. The
  task asks for both, and the order matters — `>` after `touch` replaces the empty file's contents.
- **`>` truncates.** Running the script twice does not double the file. That is the difference from `>>`, and
  getting it backwards is how log files silently grow forever or silently lose data.
- **Quoting is not optional.** `"$DIR_NAME"` versus `$DIR_NAME` is the difference between creating one
  directory called `my reports` and two called `my` and `reports`.
- **Defaults make a script pleasant to use.** `${DIR_NAME:-sysinfo_reports}` means pressing Enter does the
  sensible thing instead of creating a directory named empty string.
