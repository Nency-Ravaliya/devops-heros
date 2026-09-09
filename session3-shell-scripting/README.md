# Session 3 — Shell Scripting Homework

## Task: System Information Script

[`system_info.sh`](system_info.sh) is a bash script that:
- Prints the current date, hostname and username.
- Prints disk usage (`df -h`) and running processes (`ps aux`).
- Uses variables (`current_date`, `current_host`, `current_user`, etc.).
- Takes user input with `read -p` (name, roll number, comment).
- Creates a directory with `mkdir -p` (`sysinfo_output/`).
- Creates a file with `touch` (`processes.log`).
- Stores the full process list in that file using `>` output redirection.

### Commands used
`mkdir`, `touch`, `echo`, `df`, `ps`, `read -p`, variables, `>` output redirection.

### How to run
```bash
chmod +x system_info.sh
./system_info.sh
# then answer the three prompts (name, roll number, comment)
```

### Sample run output
Captured from an actual run on this machine (macOS/bash) — see [`run-output.txt`](run-output.txt) for the full transcript, or the excerpt below:

```
===== System Information =====
Date      : Thu Sep  3 19:52:28 IST 2026
Hostname  : Shreyass-MacBook-Air.local
User      : shreyas

===== Disk Usage =====
Filesystem      Size  Used Avail Capacity  Mounted on
/dev/disk3s3s1 460Gi  16Gi  322Gi     5%   /
...

===== Running Processes (top 10) =====
USER   PID  %CPU %MEM  COMMAND
...

Hello, Shreyas Reddy (Roll No: ENR12345).
Your comment: Homework demo run

Process information saved to sysinfo_output/processes.log
```

Running the script creates `sysinfo_output/processes.log` (not committed — it's a runtime artifact regenerated on every run, and it also captures live process info from whoever runs it).
