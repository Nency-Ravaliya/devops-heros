# Session 03 — Shell Scripting

| | |
|---|---|
| **Student** | Ujjawal Prabhat |
| **Enrollment No.** | 24BCS10267 |
| **Session** | 03 — Shell Scripting |

## Task checklist

- [x] Write `system_info.sh`
- [x] Print current date, hostname and username
- [x] Print disk usage (`df -h`) and running processes (`ps`)
- [x] Use variables
- [x] Take user input with `read -p` (directory name)
- [x] Create that directory with `mkdir`
- [x] Create a file inside it with `touch`
- [x] Redirect `ps` output into that file with `>`
- [x] Make the script executable and run it (real output below)

## The script

File: [`system_info.sh`](./system_info.sh)

```bash
#!/bin/bash
# system_info.sh - Session 03 Shell Scripting task
# Author: Ujjawal Prabhat (24BCS10267)
#
# Prints basic system information, asks the user for a directory name,
# creates that directory, creates a file inside it and saves the
# running-process list into that file.

# ---------- variables ----------
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)
file_name="process.log"

echo "========== SYSTEM INFO =========="
echo "Date      : $current_date"
echo "Hostname  : $host_name"
echo "Username  : $user_name"
echo

echo "---------- Disk usage (df -h) ----------"
df -h
echo

echo "---------- Running processes (ps) ----------"
ps
echo

# ---------- user input ----------
read -p "Enter a directory name to create: " dir_name

if [ -z "$dir_name" ]; then
    echo "No directory name given, exiting."
    exit 1
fi

mkdir -p "$dir_name"
echo "Directory '$dir_name' created."

touch "$dir_name/$file_name"
echo "File '$dir_name/$file_name' created."

# ---------- redirect ps output into the file ----------
ps aux > "$dir_name/$file_name"
echo "Process list saved to '$dir_name/$file_name' ($(wc -l < "$dir_name/$file_name") lines)."

echo "Done."
```

## Explanation of each command

| Command / syntax | What it does in this script |
|---|---|
| `#!/bin/bash` | The **shebang**. It tells the OS to run this file with bash. |
| `var=$(command)` | **Command substitution**. Runs the command and stores its output in a variable (no spaces around `=`). |
| `date` | Prints the current date and time. |
| `hostname` | Prints the machine's name. |
| `whoami` | Prints the user running the script. |
| `echo "...$var"` | Prints text. Inside double quotes, `$var` is replaced by the variable's value. |
| `df -h` | Shows disk space for each mounted filesystem. `-h` means human-readable sizes (G, M). |
| `ps` | Lists processes running in the current terminal session. `ps aux` lists **all** processes of all users with CPU/MEM columns. |
| `read -p "prompt" var` | Shows a prompt and saves what the user types into `var`. |
| `[ -z "$dir_name" ]` / `if ... fi` | `-z` is true when the string is empty. This stops the script cleanly if no name was given. |
| `exit 1` | Ends the script with a non-zero (error) exit code. |
| `mkdir -p dir` | Creates the directory. `-p` means no error if it already exists. |
| `touch file` | Creates an empty file, or updates the timestamp if it exists. |
| `ps aux > file` | `>` **redirects** stdout into the file and **overwrites** it (`>>` would append instead). |
| `wc -l < file` | Counts the file's lines. `<` feeds the file in as stdin. |
| `chmod +x system_info.sh` | Adds the execute permission so the script can run as `./system_info.sh`. |

## Making it executable

```console
$ chmod +x system_info.sh
$ ls -l system_info.sh
-rwxr-xr-x 1 501 dialout 1173 Oct  6 11:09 system_info.sh
```

(This listing is from inside the Ubuntu container where I ran the script. The owner shows as `501 dialout` because I copied the file in from my Mac, and the numeric owner IDs came along with it.)

## Running the script (real output)

I ran the script in an **Ubuntu 24.04 Docker container** (hostname `ujj-ubuntu`), with the input coming from a heredoc instead of the keyboard.

### Run 1 — under a pseudo-terminal (so the `read -p` prompt shows)

`read -p` only shows its prompt when stdin is a terminal, so I wrapped the script in `script`, which creates a pseudo-terminal, and fed the answer `ujjawal_demo` through a heredoc:

```console
$ docker exec -i -w /root ujj-ubuntu script -qec "./system_info.sh" /dev/null <<'EOF'
ujjawal_demo
EOF
ujjawal_demo
========== SYSTEM INFO ==========
Date      : Tue Oct  6 11:09:49 UTC 2026
Hostname  : ujj-ubuntu
Username  : root

---------- Disk usage (df -h) ----------
Filesystem      Size  Used Avail Use% Mounted on
overlay         911G   29G  837G   4% /
tmpfs            64M     0   64M   0% /dev
shm              64M     0   64M   0% /dev/shm
virtiofs0       927G  236G  691G  26% /pdfs
/dev/vda1       911G   29G  837G   4% /etc/hosts
tmpfs           4.0K     0  4.0K   0% /proc/scsi

---------- Running processes (ps) ----------
    PID TTY          TIME CMD
   4916 pts/0    00:00:00 sh
   4917 pts/0    00:00:00 system_info.sh
   4922 pts/0    00:00:00 ps

Enter a directory name to create: Directory 'ujjawal_demo' created.
File 'ujjawal_demo/process.log' created.
Process list saved to 'ujjawal_demo/process.log' (6 lines).
Done.
```

(The `ujjawal_demo` on the first line is the pseudo-terminal echoing my piped input. The heredoc text reached the terminal before the script started printing, so the echo appears at the top.)

### Run 2 — plain stdin redirect

```console
$ docker exec -i -w /root ujj-ubuntu ./system_info.sh <<'EOF'
ujjawal_logs
EOF
========== SYSTEM INFO ==========
Date      : Tue Oct  6 11:09:45 UTC 2026
Hostname  : ujj-ubuntu
Username  : root

---------- Disk usage (df -h) ----------
Filesystem      Size  Used Avail Use% Mounted on
overlay         911G   29G  837G   4% /
tmpfs            64M     0   64M   0% /dev
shm              64M     0   64M   0% /dev/shm
virtiofs0       927G  236G  691G  26% /pdfs
/dev/vda1       911G   29G  837G   4% /etc/hosts
tmpfs           4.0K     0  4.0K   0% /proc/scsi

---------- Running processes (ps) ----------
    PID TTY          TIME CMD
      1 ?        00:00:00 sleep
   4894 ?        00:00:00 system_info.sh
   4904 ?        00:00:00 ps

Directory 'ujjawal_logs' created.
File 'ujjawal_logs/process.log' created.
Process list saved to 'ujjawal_logs/process.log' (4 lines).
Done.
```

Here stdin is not a terminal, so bash skips the prompt text, but `read` still gets the value.

### The created directory and file

```console
root@ujj-ubuntu:~# ls -l ujjawal_demo/
total 4
-rw-r--r-- 1 root root 521 Oct  6 11:09 process.log

root@ujj-ubuntu:~# head ujjawal_demo/process.log
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0   2280  1108 ?        Ss   10:56   0:00 sleep infinity
root        4910  0.0  0.0   2304  1588 ?        Ss   11:09   0:00 script -qec ./system_info.sh /dev/null
root        4916  0.0  0.0   2392  1584 pts/0    Ss+  11:09   0:00 sh -c ./system_info.sh
root        4917  0.0  0.0   4044  3044 pts/0    S+   11:09   0:00 /bin/bash ./system_info.sh
root        4925  0.0  0.0   7640  3656 pts/0    R+   11:09   0:00 ps aux

root@ujj-ubuntu:~# cat ujjawal_logs/process.log
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0   2280  1108 ?        Ss   10:56   0:00 sleep infinity
root        4894  0.0  0.0   4044  3044 ?        Ss   11:09   0:00 /bin/bash ./system_info.sh
root        4907  0.0  0.0   7640  3648 ?        R    11:09   0:00 ps aux
```

The process list is short because a container only runs a few processes (PID 1 is the container's `sleep infinity`).

### Edge case — empty input

```console
root@ujj-ubuntu:~# echo "" | ./system_info.sh | tail -2; echo "exit code: ${PIPESTATUS[1]}"

No directory name given, exiting.
exit code: 1
```

## What I learned

- Variables plus `$(...)` keep a script readable: work out a value once, then reuse it.
- `read -p` makes a script interactive, but the same script can be automated by piping input into it (a heredoc, `echo ... |`, or a file).
- `>` overwrites and `>>` appends. Always quote paths such as `"$dir_name"` so names with spaces don't break the script.
- Checking the input (`[ -z ]`) and returning a proper exit code makes the script safe to use from other scripts or a CI pipeline.
