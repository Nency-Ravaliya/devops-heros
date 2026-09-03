# Session 3 – Shell Scripting: `sysinfo.sh`

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123

A Bash script that prints the date, hostname, user, disk usage and running processes, asks the user for a report folder name, creates the folder and a file inside it, and redirects the full process list into that file.

```text
kushal-24bcs10123/
├── sysinfo.sh                # the script
├── README.md                 # this file
└── sample-run/
    ├── terminal-output.txt   # exactly what the terminal showed
    └── processes.txt         # trimmed copy of the generated file
```

## Requirement checklist

| Requirement | Where in the script |
|---|---|
| Print current date | `today=$(date "+%A, %d %B %Y %H:%M:%S %Z")` then `echo` |
| Print hostname | `host=$(hostname)` |
| Print username | `user=$(whoami)` |
| Print disk usage | `df -h` |
| Print running processes | `ps -eo pid,user,%cpu,%mem,comm -r | head -n 16` (top 15 by CPU) |
| Use variables | `today host user os proc_count report_dir label report_file` |
| Take input with `read -p` | `read -p "Name a folder for the report: " report_dir` and a second prompt for a label |
| Create a directory with `mkdir` | `mkdir -p "$report_dir"` |
| Create a file with `touch` | `touch "$report_file"` |
| Store processes with `>` | `{ ...; ps -ef; } > "$report_file"` |

Extras I added while practising: `#!/usr/bin/env bash` shebang, `set -u` so a typo in a variable name fails loudly, a default value with `${report_dir:-sysinfo-report}` if the user just presses Enter, quoting every expansion, and a group command `{ ...; } > file` so the header lines and `ps -ef` land in the same file with a single redirection.

## How to run

```bash
chmod +x sysinfo.sh
./sysinfo.sh
```

Non-interactive run (what I used to capture `sample-run/`):

```bash
printf 'sysinfo-report\nhomework run on my MacBook\n' | ./sysinfo.sh
```

## Output

Full text in [`sample-run/terminal-output.txt`](sample-run/terminal-output.txt). Trimmed here:

```text
================ SYSTEM INFORMATION ================
Label            : homework run on my MacBook
Date             : Thursday, 03 September 2026 21:08:56 IST
Hostname         : Kushals-MacBook-Pro.local
Logged-in user   : kushalscaler
Kernel           : Darwin 25.5.0 arm64
Running processes: 653

---------------- DISK USAGE (df -h) ----------------
Filesystem        Size    Used   Avail Capacity iused ifree %iused  Mounted on
/dev/disk3s1s1   460Gi    16Gi    11Gi    59%    459k  119M    0%   /
/dev/disk3s5     460Gi   412Gi    11Gi    98%    3.6M  119M    3%   /System/Volumes/Data
...

------------- RUNNING PROCESSES (top 15 by CPU) -------------
  PID USER              %CPU %MEM COMM
  499 _mds_stores       89.2  2.1 .../Metadata.framework/Versions/A/Support/mds_stores
  520 root              23.1  0.1 /usr/libexec/syspolicyd
...

Full process list (653 processes) written to: sysinfo-report/processes.txt
Report folder contents:
total 296
-rw-r--r--  1 kushalscaler  staff  151551 Sep  3 21:08 processes.txt
```

## Things I learned / debugged

* `read -p` reads from stdin, so the script works both interactively and when fed through a pipe (handy for testing and CI).
* My first version used `set -euo pipefail`. `ps ... | head -n 16` makes `ps` receive SIGPIPE when `head` exits early, `pipefail` turns that into a non-zero status, and `set -e` killed the script before it wrote the file. Fix: drop `pipefail` for that pipeline (`|| true`) and keep `set -u`.
* `>` truncates and writes; `>>` would append. Using a `{ ... }` group lets several commands share one redirection.
* `ps -e` on macOS/BSD vs `ps -ef`/`ps aux` on Linux: `-e`/`-f` are POSIX and work on both, so I used those.
