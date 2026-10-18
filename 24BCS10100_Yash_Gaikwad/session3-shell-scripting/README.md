# Session 3: Shell Scripting - System Information Script

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

## Task

Write a shell script that prints the date, hostname, username, disk usage and running processes; uses variables; takes input with `read -p`; creates a directory with `mkdir` and a file with `touch`; and stores the running-process information in that file using `>` output redirection.

Script file: [`system_info.sh`](system_info.sh)

## Commands and features used

| Requirement | Used in the script |
|---|---|
| Print current date | `current_date=$(date)` then `echo "... $current_date"` |
| Print hostname | `host_name=$(hostname)` |
| Print username | `user_name=$(whoami)` |
| Print disk usage | `df -h` |
| Print running processes | `ps aux` |
| Use variables to store and use data | `current_date`, `host_name`, `user_name`, `name`, `dir_name`, `file_name` |
| Take user input | `read -p "Enter your name: " name` (and for directory/file name) |
| Create a directory | `mkdir -p "$dir_name"` |
| Create a file | `touch "$dir_name/$file_name"` |
| Save processes into the file | `ps aux > "$dir_name/$file_name"` (output redirection) |
| Messages | `echo` |

Extra touches: `${var:-default}` gives a default if the user just presses Enter, all variables are quoted so names with spaces do not break, and `mkdir -p` does not fail if the folder already exists.

## The script

_Full source of the script (identical to the file in this folder)._

```console
$ cat system_info.sh
#!/bin/bash
# system_info.sh - System Information Script
# Author: Yash Gaikwad (24BCS10100)
#
# Prints date, hostname, username, disk usage and running processes,
# then asks for a directory and file name, creates them and saves the
# process list into that file.

# ---- variables that store data ----
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)

echo "=============================================="
echo "          SYSTEM INFORMATION REPORT"
echo "=============================================="
echo "Current date : $current_date"
echo "Hostname     : $host_name"
echo "Username     : $user_name"

echo
echo "------------- Disk usage ---------------------"
df -h

echo
echo "------------- Running processes --------------"
ps aux

# ---- take user input with read -p ----
echo
echo "------------- User input ---------------------"
read -p "Enter your name: " name
read -p "Enter directory name to create: " dir_name
read -p "Enter file name to create: " file_name

# fall back to defaults when the user just presses Enter
name=${name:-Student}
dir_name=${dir_name:-system_report}
file_name=${file_name:-processes.log}

# ---- create directory and file ----
mkdir -p "$dir_name"
touch "$dir_name/$file_name"
echo "Hello $name, created directory '$dir_name' and file '$file_name'."

# ---- store the running processes in the file using > redirection ----
ps aux > "$dir_name/$file_name"
echo "Running processes saved to $dir_name/$file_name"
echo "Total lines saved: $(wc -l < "$dir_name/$file_name")"
```

_Check that the copy I run is byte-for-byte the committed script._

```console
$ cmp system_info.sh /mnt/e/devops-github-assgn/devops-homework/session3-shell-scripting/system_info.sh && echo "identical to the committed file"
identical to the committed file
```

## Running the script

_Make the script executable._

```console
$ chmod +x system_info.sh && ls -l system_info.sh
-rwxr-xr-x 1 gaikw gaikw 1524 Oct 18 12:19 system_info.sh
```

_Run it. The three values after the prompts (name, directory, file) were typed in by me; the screen below is the full terminal transcript._

```console
$ ./system_info.sh
==============================================
          SYSTEM INFORMATION REPORT
==============================================
Current date : Sun Oct 18 12:19:53 UTC 2026
Hostname     : Yashg-Laptop
Username     : gaikw

------------- Disk usage ---------------------
Filesystem                                Size  Used Avail Use% Mounted on
none                                      5.7G     0  5.7G   0% /usr/lib/modules/6.6.87.2-microsoft-standard-WSL2
none                                      5.7G  4.0K  5.7G   1% /mnt/wsl
none                                      5.7G  624K  5.7G   1% /mnt/wsl/docker-desktop/shared-sockets/host-services
/dev/sdd                                  136M   71M   54M  57% /mnt/wsl/docker-desktop/docker-desktop-user-distro
/dev/loop0                                783M  783M     0 100% /mnt/wsl/docker-desktop/cli-tools
drivers                                   247G  224G   24G  91% /usr/lib/wsl/drivers
/dev/sdf                                 1007G  1.8G  954G   1% /
none                                      5.7G   72K  5.7G   1% /mnt/wslg
none                                      5.7G     0  5.7G   0% /usr/lib/wsl/lib
rootfs                                    5.7G  2.7M  5.7G   1% /init
none                                      5.7G  568K  5.7G   1% /run
none                                      5.7G     0  5.7G   0% /run/lock
none                                      5.7G     0  5.7G   0% /run/shm
none                                      5.7G  100K  5.7G   1% /mnt/wslg/versions.txt
none                                      5.7G  100K  5.7G   1% /mnt/wslg/doc
C:\                                       247G  224G   24G  91% /mnt/c
D:\                                       110G  6.4G  103G   6% /mnt/d
E:\                                       120G   60G   61G  50% /mnt/e
tmpfs                                     5.7G     0  5.7G   0% /tmp
none                                      1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
none                                      1.0M     0  1.0M   0% /run/credentials/systemd-resolved.service
none                                      1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
tmpfs                                     1.2G   12K  1.2G   1% /run/user/1000
tmpfs                                     1.2G   12K  1.2G   1% /run/user/0
C:\Program Files\Docker\Docker\resources  247G  224G   24G  91% /Docker/host

------------- Running processes --------------
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.6  0.1  24300 14448 ?        Ss   12:11   0:03 /sbin/init
root           2  0.0  0.0   3120  2048 ?        Sl   12:11   0:00 /init
root           8  0.0  0.0   3120  1792 ?        Sl   12:11   0:00 plan9 --control-socket 7 --log-level 4 --server-fd 8 
root          54  0.1  0.1  50380 15744 ?        S<s  12:11   0:00 /usr/lib/systemd/systemd-journald
systemd+      91  0.0  0.1  22412 13952 ?        Ss   12:11   0:00 /usr/lib/systemd/systemd-resolved
root         101  0.4  0.1  35240 11904 ?        Ss   12:11   0:02 /usr/lib/systemd/systemd-udevd
root         172  0.0  0.0   2880  1792 ?        Ss   12:11   0:00 /bin/sh /usr/lib/systemd/scripts/chronyd-starter.sh -
root         173  0.0  0.0   4464  2944 ?        Ss   12:11   0:00 /usr/sbin/cron -f -P
message+     174  0.0  0.0   8808  4480 ?        Ss   12:11   0:00 @dbus-daemon --system --address=systemd: --nofork --n
root         178  0.1  0.2  44096 28112 ?        Ss   12:11   0:00 /usr/bin/python3 /usr/bin/networkd-dispatcher --run-s
root         189  0.0  0.0  18440  8448 ?        Ss   12:11   0:00 /usr/lib/systemd/systemd-logind
root         210  0.0  0.1 1792292 14336 ?       Ssl  12:11   0:00 /usr/libexec/wsl-pro-service
syslog       213  0.0  0.0 220532  4736 ?        Ssl  12:11   0:00 /usr/sbin/rsyslogd -n -iNONE
root         265  0.0  0.0  19700  8704 ?        Ss   12:11   0:00 (agetty)
root         273  0.1  0.2 123460 31696 ?        Ssl  12:11   0:00 /usr/bin/python3 /usr/share/unattended-upgrades/unatt
_chrony      275  0.0  0.0  20512  6912 ?        S    12:11   0:00 /usr/sbin/chronyd -n -F 1 -x
_chrony      284  0.0  0.0  12080  2240 ?        S    12:11   0:00 /usr/sbin/chronyd -n -F 1 -x
root         285  0.0  0.0   5484  2560 tty1     Ss+  12:11   0:00 /usr/sbin/agetty --noreset --noclear --issue-file=/et
root         343  0.0  0.0   3152   900 ?        Ss   12:11   0:00 /init
root         345  0.0  0.0   3136  1164 ?        S    12:11   0:00 /init
gaikw        348  0.0  0.0   2880  1792 pts/0    Ss+  12:11   0:00 sh
root         353  0.0  0.0   8632  4608 ?        Ss   12:11   0:00 login -- gaikw
gaikw        414  0.0  0.1  22796 12672 ?        Ss   12:11   0:00 /usr/lib/systemd/systemd --user
gaikw        416  0.0  0.0  22904  4048 ?        S    12:11   0:00 (sd-pam)
gaikw        443  0.0  0.0   6128  4992 pts/1    Ss+  12:11   0:00 -bash
root         480  0.0  0.0   8488  5120 ?        Ss   12:11   0:00 login -- root
root         511  0.1  0.1  22392 12800 ?        Ss   12:11   0:00 /usr/lib/systemd/systemd --user
root         515  0.0  0.0  22912  3912 ?        S    12:11   0:00 (sd-pam)
root         541  0.0  0.0   6128  5120 pts/3    Ss+  12:11   0:00 -bash
root         666  0.0  0.0   3168  1168 ?        S    12:11   0:00 /init
root         667  0.0  0.2 1252584 26476 pts/2   Ssl+ 12:11   0:00 /mnt/wsl/docker-desktop/docker-desktop-user-distro pr
root        1442  0.0  0.0  35244  6860 ?        S    12:19   0:00 (udev-worker)
root        1443  0.4  0.0  35244  6860 ?        S    12:19   0:00 (udev-worker)
root        1444  0.0  0.0   3128   908 ?        Ss   12:19   0:00 /init
root        1445  0.0  0.0   3144  1172 ?        S    12:19   0:00 /init
gaikw       1446 20.8  0.0   4940  3584 pts/4    Ss+  12:19   0:00 bash <path redacted>
root        1447  0.0  0.0  35244  6860 ?        S    12:19   0:00 (udev-worker)
root        1448  0.0  0.0  35244  6860 ?        S    12:19   0:00 (udev-worker)
root        1449  0.0  0.0  35244  6860 ?        S    12:19   0:00 (udev-worker)
root        1450  0.0  0.0  35244  6860 ?        S    12:19   0:00 (udev-worker)
gaikw       1462  0.0  0.0   4940  1800 pts/4    S+   12:19   0:00 bash <path redacted>
gaikw       1463  0.0  0.0  16104  7552 pts/4    S+   12:19   0:00 sleep 2
gaikw       1464  0.0  0.0   3232  2048 pts/4    S+   12:19   0:00 script -qec ./system_info.sh /dev/null
gaikw       1465  0.0  0.0  16236  7296 pts/4    S+   12:19   0:00 tr -d \r
gaikw       1466 20.0  0.0   4940  3456 pts/5    Ss+  12:19   0:00 /bin/bash ./system_info.sh
gaikw       1471  0.0  0.0   7152  4224 pts/5    R+   12:19   0:00 ps aux

------------- User input ---------------------
Enter your name: Yash Gaikwad
Enter directory name to create: system_report
Enter file name to create: processes.log
Hello Yash Gaikwad, created directory 'system_report' and file 'processes.log'.
Running processes saved to system_report/processes.log
Total lines saved: 40
```

## Verifying the results

_The directory and the script are there._

```console
$ ls -l
total 8
-rwxr-xr-x 1 gaikw gaikw 1524 Oct 18 12:19 system_info.sh
drwxr-xr-x 2 gaikw gaikw 4096 Oct 18 12:19 system_report
```

_The file created with touch (and filled by the redirection) is inside the new directory._

```console
$ ls -l system_report
total 4
-rw-r--r-- 1 gaikw gaikw 3660 Oct 18 12:19 processes.log
```

_The file really contains the process list (the same ps aux output)._

```console
$ head -n 5 system_report/processes.log; echo ...; wc -l system_report/processes.log
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.6  0.1  24300 14448 ?        Ss   12:11   0:03 /sbin/init
root           2  0.0  0.0   3120  2048 ?        Sl   12:11   0:00 /init
root           8  0.0  0.0   3120  1792 ?        Sl   12:11   0:00 plan9 --control-socket 7 --log-level 4 --server-fd 8 
root          54  0.1  0.1  50380 15744 ?        S<s  12:11   0:00 /usr/lib/systemd/systemd-journald
...
40 system_report/processes.log
```

_Run again and just press Enter at the prompts: the defaults (Student / system_report / processes.log) are used and mkdir -p does not complain that the folder already exists._

```console
$ echo | ./system_info.sh >/dev/null; ls -l system_report
total 4
-rw-r--r-- 1 gaikw gaikw 3524 Oct 18 12:19 processes.log
```

## What I learned

- Command substitution `$(...)` stores a command's output in a variable.
- `read -p` prints a prompt and reads one line into a variable (the prompt is only shown on an interactive terminal).
- `>` creates or **overwrites** a file with the command's output (`>>` appends).
- `mkdir -p` and `touch` are safe to repeat; `${var:-default}` avoids empty-input bugs.
