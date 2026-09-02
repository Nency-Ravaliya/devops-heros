# Shell Scripting Homework Task

## 🖥️ System Information Script

A Bash script that collects and displays basic system information — the current date, hostname, username, disk usage, and running processes.

It also demonstrates variables, user input, directory and file creation, and output redirection.

---

## 📌 Requirements Covered

| Requirement | Implementation |
| --- | --- |
| Prints the current date | `current_date=$(date)` + `echo` |
| Prints the hostname | `hostname=$(hostname)` + `echo` |
| Prints the username | `username=$(whoami)` + `echo` |
| Prints the disk usage | `df -h` |
| Prints the running processes | `ps` |
| Uses variables | `dir_name`, `file_name`, `current_date`, `hostname`, `username` |
| Takes user input | `read -p "Enter directory name: " dir_name` |
| Creates a directory | `mkdir -p "$dir_name"` |
| Creates a file | `touch "$file_name"` |
| Output redirection | `ps > "$file_name"` |

---

## 📂 Project Structure

```text
.
├── system_info.sh
├── system_info/
│   └── processes.txt
└── README.md
```

---

## 📝 Script

```bash
#!/bin/bash

# Take user input
read -p "Enter directory name: " dir_name

# Create directory
mkdir -p "$dir_name"

# Create file inside the directory
file_name="$dir_name/processes.txt"
touch "$file_name"

# Store system information in variables
current_date=$(date)
hostname=$(hostname)
username=$(whoami)

# Display system information
echo "===== SYSTEM INFORMATION ====="
echo "Date: $current_date"
echo "Hostname: $hostname"
echo "Username: $username"

echo ""
echo "===== DISK USAGE ====="
df -h

echo ""
echo "===== RUNNING PROCESSES ====="
ps

# Store running processes in the file
ps > "$file_name"

echo ""
echo "Running processes have been saved to: $file_name"
```

---

## ▶️ Running the Script

Give the script execute permission:

```bash
chmod +x system_info.sh
```

Run the script:

```bash
./system_info.sh
```

---

## 💻 Actual Output

Run on macOS (Darwin 23.6.0) with the input `system_info`:

```text
Enter directory name: system_info
===== SYSTEM INFORMATION =====
Date: Wed Sep  2 22:31:18 IST 2026
Hostname: Jenys-MacBook.local
Username: anuskaroy

===== DISK USAGE =====
Filesystem        Size    Used   Avail Capacity iused ifree %iused  Mounted on
/dev/disk3s3s1   228Gi    11Gi    17Gi    39%    404k  181M    0%   /
devfs            201Ki   201Ki     0Bi   100%     694     0  100%   /dev
/dev/disk3s6     228Gi   7.0Gi    17Gi    29%       7  181M    0%   /System/Volumes/VM
/dev/disk3s4     228Gi    11Gi    17Gi    40%    1.5k  181M    0%   /System/Volumes/Preboot
/dev/disk3s2     228Gi   720Mi    17Gi     4%     278  181M    0%   /System/Volumes/Update
/dev/disk1s2     500Mi   6.0Mi   482Mi     2%       1  4.9M    0%   /System/Volumes/xarts
/dev/disk1s1     500Mi   5.6Mi   482Mi     2%      37  4.9M    0%   /System/Volumes/iSCPreboot
/dev/disk1s3     500Mi   2.1Mi   482Mi     1%      51  4.9M    0%   /System/Volumes/Hardware
/dev/disk3s1     228Gi   179Gi    17Gi    92%    1.4M  181M    1%   /System/Volumes/Data
map auto_home      0Bi     0Bi     0Bi   100%       0     0     -   /System/Volumes/Data/home
/dev/disk3s3     228Gi    11Gi    17Gi    39%    406k  181M    0%   /System/Volumes/Update/mnt1

===== RUNNING PROCESSES =====
  PID TTY           TIME CMD
31427 ttys001    0:00.14 /bin/zsh -il
33593 ttys002    0:00.11 /bin/zsh -i

Running processes have been saved to: system_info/processes.txt
```

> **Note:** On Linux, `df -h` prints `Size / Used / Avail / Use%` columns instead of the macOS `Capacity / iused / ifree` layout, and `ps` shows `bash` rather than `zsh`. The script itself is unchanged.

---

## 🔍 Commands Used

### 1. `read -p`

Takes input from the user and stores it in a variable.

```bash
read -p "Enter directory name: " dir_name
```

**Output:**

```text
Enter directory name: system_info
```

---

### 2. `mkdir`

Creates a directory. The `-p` option prevents an error if the directory already exists.

```bash
mkdir -p "$dir_name"
```

**Verify:**

```bash
$ ls -d system_info
system_info
```

---

### 3. `touch`

Creates an empty file.

```bash
file_name="$dir_name/processes.txt"
touch "$file_name"
```

**Verify:**

```bash
$ ls -l system_info/processes.txt
-rw-r--r--  1 anuskaroy  staff  156 Sep  2 22:31 system_info/processes.txt
```

---

### 4. `echo`

Prints text and variable values to the terminal.

```bash
echo "Date: $current_date"
echo "Hostname: $hostname"
echo "Username: $username"
```

**Output:**

```text
Date: Wed Sep  2 22:31:18 IST 2026
Hostname: Jenys-MacBook.local
Username: anuskaroy
```

---

### 5. `df`

Displays disk space usage. The `-h` option shows sizes in a human-readable format (MB, GB).

```bash
df -h
```

**Output (first lines):**

```text
Filesystem        Size    Used   Avail Capacity iused ifree %iused  Mounted on
/dev/disk3s3s1   228Gi    11Gi    17Gi    39%    404k  181M    0%   /
/dev/disk3s1     228Gi   179Gi    17Gi    92%    1.4M  181M    1%   /System/Volumes/Data
```

---

### 6. `ps`

Displays the currently running processes.

```bash
ps
```

**Output:**

```text
  PID TTY           TIME CMD
31427 ttys001    0:00.14 /bin/zsh -il
33593 ttys002    0:00.11 /bin/zsh -i
```

---

## 📦 Variables

Variables store information that can be reused later in the script. Values are assigned with `=` (no spaces around it) and read back with `$`.

```bash
current_date=$(date)
hostname=$(hostname)
username=$(whoami)
```

`$(...)` is **command substitution** — it runs the command and stores its output in the variable.

---

## ➡️ Output Redirection

The `>` operator sends a command's output into a file instead of the terminal.

```bash
ps > "$file_name"
```

**Contents of `system_info/processes.txt` after running:**

```text
  PID TTY           TIME CMD
31427 ttys001    0:00.14 /bin/zsh -il
33593 ttys002    0:00.11 /bin/zsh -i
```

**Important:** `>` overwrites the file. Use `>>` to append instead.

---

## 📄 Generated File

After running the script, this file is created:

```text
system_info/processes.txt
```

```bash
$ cat system_info/processes.txt
  PID TTY           TIME CMD
31427 ttys001    0:00.14 /bin/zsh -il
33593 ttys002    0:00.11 /bin/zsh -i
```

---

## 🧠 Key Learnings

* Writing and executing Bash scripts
* Using variables and command substitution `$(...)`
* Taking user input with `read -p`
* Creating directories with `mkdir -p`
* Creating files with `touch`
* Printing information with `echo`
* Checking disk usage with `df -h`
* Viewing running processes with `ps`
* Redirecting command output with `>` (and appending with `>>`)
* Giving execution permission with `chmod +x`
* Quoting variables (`"$dir_name"`) so names with spaces still work
